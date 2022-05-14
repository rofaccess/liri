=begin
  Este módulo es el punto de entrada del programa agente
=end
require 'net/scp'
require 'all_libraries'

module Liri
  class Agent
    attr_reader :managers

    class << self
      # Inicia la ejecución del Agent
      # @param stop [Boolean] el valor true es para que no se ejecute infinitamente el método en el test unitario.
      def run(work_folder_path, stop = false)
        setup_manager = Liri.set_setup(work_folder_path)
        agent_folder_path = setup_manager.agent_folder_path

        Liri.set_logger(setup_manager.logs_folder_path, 'liri-agent.log')
        Liri.logger.info("Proceso Agent iniciado")
        puts "Presione Ctrl + c para terminar el proceso Agent manualmente\n\n"

        decompressed_source_code_path = File.join(agent_folder_path, '/', Common::SourceCode::DECOMPRESSED_FOLDER_NAME)
        source_code = Common::SourceCode.new(decompressed_source_code_path, agent_folder_path, Liri.compression_class, Liri.unit_test_class)
        runner = Agent::Runner.new(Liri.unit_test_class, source_code.decompressed_file_folder_path)
        tests_result = Common::TestsResult.new(agent_folder_path)
        agent = Agent.new(Liri.udp_port, Liri.tcp_port, source_code, runner, tests_result, agent_folder_path)
        threads = []
        threads << agent.start_server_socket_to_process_manager_connection_request # Esperar y procesar la petición de conexión del Manager

        Liri.init_exit(stop, threads, 'Agent')
        Liri.logger.info("Proceso Agent terminado")
      rescue SignalException => e
        Liri.logger.info("Exception(#{e}) Proceso Agent terminado manualmente")
        Liri.kill(threads)
      end
    end

    def initialize(udp_port, tcp_port, source_code, runner, tests_result, agent_folder_path)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port

      @source_code = source_code
      @runner = runner
      @tests_result = tests_result

      @all_tests = {}

      @managers = {}

      @agent_folder_path = agent_folder_path
    end

    # Inicia un servidor udp que se mantiene en espera de la primera petición de conexión del Manager
    def start_server_socket_to_process_manager_connection_request
      # El servidor udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue esperando
      # que un Manager se conecte, cuando se conecta un Manager, se guarda la ip de este manager y se vuelve a esperar otra petición
      Thread.new do
        BasicSocket.do_not_reverse_lookup = true
        begin
          @udp_socket.bind('0.0.0.0', @udp_port)
        rescue Errno::EADDRINUSE => e
          Liri.logger.error("Exception(#{e}) Puerto UDP #{@udp_port} ocupado")
          Thread.exit
        end
        Liri.logger.info("En espera de peticiones de Managers en el puerto UDP #{@udp_port}
                                     (Se espera que algún Manager se contacte por primera vez para establecer una conexión TCP)
        ")

        loop do
          @manager_request = @udp_socket.recvfrom(1024)
          manager_ip_address = @manager_request.last.last
          manager_data = get_manager_data(JSON.parse(@manager_request.first))
          process_manager_connection_request(manager_ip_address, manager_data)
        end
      end
    end

    # Inicia un cliente tcp para responder a la petición broadcast del Manager para que éste sepa donde enviar las pruebas
    def start_client_socket_to_process_tests(manager_ip_address, manager_data)
      tcp_socket = TCPSocket.open(manager_ip_address, @tcp_port)
      agent_ip_address = tcp_socket.addr[2]
      Liri.logger.info("Se inicia una conexión con el Manager: #{manager_ip_address} en el puerto TCP: #{@tcp_port}
                                     (Se establece una conexión para procesar la ejecución de las pruebas)
      ")

      tcp_socket.print("Listo para ejecutar pruebas") # Se envía un mensaje inicial al Manager
      puts "\nConexión iniciada con el Manager: #{manager_ip_address}"

      # Se procesan las pruebas enviadas por el Manager
      while line = tcp_socket.gets
        response = line.chop
        break if response == 'exit'

        tests_batch = JSON.parse(response)
        tests = get_tests(tests_batch, manager_ip_address)

        raw_tests_result = @runner.run_tests(tests)

        tests_batch_number = tests_batch['tests_batch_number']
        tests_result_file_name = @tests_result.build_file_name(agent_ip_address, tests_batch_number)
        tests_result_file_path = @tests_result.save(tests_result_file_name, raw_tests_result)

        send_tests_results_file(manager_ip_address, manager_data, tests_result_file_path)
        result = { tests_batch_number: tests_batch_number, tests_result_file_name: tests_result_file_name }
        tcp_socket.puts(result.to_json) # Envía el número de lote y el nombre del archivo de resultados.
      end

      tcp_socket.close
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")

      Liri.clean_folder_content(@agent_folder_path)

      start_client_to_close_manager_server(manager_ip_address, 'Conexión Terminada')
      unregister_manager(manager_ip_address)
    rescue Errno::EADDRINUSE => e
      Liri.logger.error("Exception(#{e}) Puerto TCP #{@tcp_port} ocupado")
    rescue Errno::ECONNRESET => e
      tcp_socket.close
      Liri.logger.error("Exception(#{e}) Conexión cerrada en el puerto TCP #{@tcp_port}")
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")
      unregister_manager(manager_ip_address)
    rescue Errno::ECONNREFUSED => e
      Liri.logger.error("Exception(#{e}) Conexión rechazada en el puerto TCP #{@tcp_port}")
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")
      unregister_manager(manager_ip_address)
    end

    private

    # Inserta el ip recibido dentro del hash si es que ya no existe en el hash
    # Nota: Se requieren imprimir datos para saber el estado de la aplicación, sería muy útil usar algo para logear
    # estas cosas en los diferentes niveles, debug, info, etc.
    def process_manager_connection_request(manager_ip_address, manager_data)
      unless registered_manager?(manager_ip_address)
        register_manager(manager_ip_address)
        Liri.logger.info("Petición broadcast UDP recibida del Manager: #{manager_ip_address} en el puerto UDP: #{@udp_port}")
        if get_source_code(manager_ip_address, manager_data)
          start_client_socket_to_process_tests(manager_ip_address, manager_data)
        else
          unregister_manager(manager_ip_address)
        end
      end
    end

    # Se establece una nueva comunicación con el servidor TCP del Manager con el único objetivo de cerrar el servidor
    # Esta conexión permitirá al Manager cerrar sus hilos pendientes con servidores TCP en espera y terminar el proceso
    def start_client_to_close_manager_server(manager_ip_address, msg)
      tcp_socket = TCPSocket.open(manager_ip_address, @tcp_port)
      Liri.logger.info("Se termina cualquier proceso pendiente con el Manager #{manager_ip_address}")
      tcp_socket.print({msg: msg}.to_json)
      tcp_socket.close
    end

    def get_source_code(manager_ip_address, manager_data)
      #puts "#{manager_data.to_h}"
      puts ''
      Liri::Common::Benchmarking.start(start_msg: "Obteniendo código fuente. Espere... ") do
        puts ''
        Net::SCP.start(manager_ip_address, manager_data.user, password: manager_data.password) do |scp|
          scp.download!(manager_data.compressed_file_path, @source_code.compressed_file_folder_path)
        end
      end
      puts ''

      downloaded_file_name = manager_data.compressed_file_path.split('/').last
      downloaded_file_path = File.join(@source_code.compressed_file_folder_path, '/', downloaded_file_name)

      Liri::Common::Benchmarking.start(start_msg: "Descomprimiendo código fuente. Espere... ") do
        @source_code.decompress_file(downloaded_file_path)
        @all_tests = @source_code.all_tests
      end
      puts ''

      # Se cambia temporalmente la carpeta de trabajo a la carpeta de código fuente descomprimida
      Dir.chdir(@source_code.decompressed_file_folder_path) do
        # Se borra el directorio .git para evitar el siguiente error al ejecutar las pruebas: fatal: not a git repository (or any of the parent directories): .git
        # Una mejor alternativa es no traer siquiera esa carpeta junto al código fuente excluyendo la carpeta .git al comprimir el código fuente.
        # Por cuestiones de tiempo se procede a borrar la carpeta .git por ahora, aunque al parecer el error mostrado no afecta la ejecución del Agent
        # Al realizar pruebas, el error mencionado se sigue viendo en producción así que no es seguro que este borrado de la carpeta .git solucione el problema
        git_folder_path = File.join(Dir.pwd, '/.git')
        FileUtils.rm_rf(git_folder_path) if Dir.exist?(git_folder_path)

        # Descomentar para la depuración en entorno de desarrollo (Creo que aún así no se puede depurar)
        # system("bundle install")
        # Descomentar para el entorno de producción
        # Se setea la versión de ruby y el gemset para el código fuente descomprimido
        # Se especifica el Gemfile del cual se van a instalar los requerimientos
        # Esto se hace porque por defecto se usa la versión de Ruby de Liri y su Gemset y por ello hay que cambiarlos explicitamente aquí
        Liri::Common::Benchmarking.start(start_msg: "Ejecutando bundle install. Espere... ", end_msg: "Ejecución de bundle install. Duración: ") do
          puts ''
          system("bash -lc 'rvm use #{Liri.current_folder_ruby_and_gemset}; BUNDLE_GEMFILE=Gemfile bundle install'")
        end
        puts ''

        Liri::Common::Benchmarking.start(start_msg: "Ejecutando rake db:migrate RAILS_ENV=test. Espere... ", end_msg: "Ejecución de rake db:migrate RAILS_ENV=test. Duración: ") do
          puts ''
          system("bash -lc 'rvm use #{Liri.current_folder_ruby_and_gemset}; rake db:migrate RAILS_ENV=test'")
        end
        puts ''

        #Liri::Common::Benchmarking.start(start_msg: "Ejecutando rake db:migrate:reset RAILS_ENV=test. Espere... ", end_msg: "Ejecución de rake db:migrate:reset RAILS_ENV=test. Duración: ") do
        # puts ''
        # system("bash -lc 'rvm use #{Liri.current_folder_ruby_and_gemset}; rake db:migrate:reset RAILS_ENV=test'")
        #end
        #puts ''
      end
      true
    rescue Errno::ECONNREFUSED => e
      Liri.logger.error("Exception(#{e}) Conexión rechazada por #{manager_ip_address}. Posiblemente ssh no esté ejecutandose en #{manager_ip_address}")
      false
    rescue Errno::ENOTTY => e
      # Este rescue es temporal, hay que ver una mejor manera de detectar si la contraseña es incorrecta
      Liri.logger.error("Exception(#{e}) Contraseña incorrecta recibida de #{manager_ip_address} para la conexión ssh")
      start_client_to_close_manager_server(manager_ip_address, "No se puede obtener el archivo de código fuente. Posiblemente se envío una contraseña incorrencta desde #{manager_ip_address}")
      false
    rescue Net::SSH::AuthenticationFailed => e
      # Este rescue es temporal, hay que ver una mejor manera de detectar si la contraseña es incorrecta
      Liri.logger.error("Exception(#{e}) Contraseña incorrecta recibida de #{manager_ip_address} para la conexión ssh")
      start_client_to_close_manager_server(manager_ip_address, "No se puede obtener el archivo de código fuente. Posiblemente se envío una contraseña incorrencta desde #{manager_ip_address}")
      false
    rescue Net::SCP::Error => e
      Liri.logger.warn("Exception(#{e}) Archivo no encontrado en #{manager_ip_address} a través de scp")
      false
    rescue TypeError => e
      Liri.logger.warn("Exception(#{e}) Error indeterminado")
      false
    end

    def get_manager_data(manager_data_hash)
      Common::ManagerData.new(
        folder_path: manager_data_hash['folder_path'],
        compressed_file_path: manager_data_hash['compressed_file_path'],
        user: manager_data_hash['user'],
        password: manager_data_hash['password']
      )
    end

    def send_tests_results_file(manager_ip_address, manager_data, tests_result_file_path)
      puts ''
      Liri::Common::Benchmarking.start(start_msg: "Enviando archivo de resultados. Espere... ") do
        Net::SCP.start(manager_ip_address, manager_data.user, password: manager_data.password) do |scp|
          scp.upload!(tests_result_file_path, manager_data.folder_path)
        end
      end
      puts ''
    end

    def get_tests(tests_batch, manager_ip_address)
      # Se convierte "[5, 9, 13, 1]" a un arreglo [5, 9, 13, 1]
      tests_keys = tests_batch['tests_batch_keys']
      Liri.logger.debug("Claves de pruebas recibidas del Manager #{manager_ip_address}: #{tests_keys}")
      # Se buscan obtienen los tests que coincidan con las claves recibidas de @all_tests = {1=>"spec/hash_spec.rb:2", 2=>"spec/hash_spec.rb:13", 3=>"spec/hash_spec.rb:24", ..., 29=>"spec/liri_spec.rb:62"}
      # Se retorna un arreglo con los tests a ejecutar ["spec/liri_spec.rb:4", "spec/hash_spec.rb:5", "spec/hash_spec.rb:59", ..., "spec/hash_spec.rb:37"]
      tests_keys.map { |test_key| @all_tests[test_key] }
    end

    def registered_manager?(manager_ip_address)
      @managers[manager_ip_address]
    end

    def register_manager(manager_ip_address)
      @managers[manager_ip_address] = manager_ip_address
    end

    def unregister_manager(manager_ip_address)
      @managers.remove!(manager_ip_address)
    end
  end
end
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
        setup_manager = Liri.set_setup(work_folder_path, :agent)
        agent_folder_path = setup_manager.agent_folder_path

        Liri.set_logger(setup_manager.logs_folder_path, 'liriagent.log')
        Liri.logger.info("Agent process started", true)
        Liri.logger.info("Press Ctrl + c to finish Agent process manually\n", true)

        decompressed_source_code_path = File.join(agent_folder_path, '/', Common::SourceCode::DECOMPRESSED_FOLDER_NAME)
        source_code = Common::SourceCode.new(decompressed_source_code_path, agent_folder_path, "", Liri.compression_class, Liri.unit_test_class)
        runner = Agent::Runner.new(Liri.unit_test_class, source_code.decompressed_file_folder_path)
        tests_result = Common::TestsResult.new(agent_folder_path)
        agent = Agent.new(Liri.udp_port, Liri.tcp_port, source_code, runner, tests_result, agent_folder_path)
        threads = []
        threads << agent.start_server_socket_to_process_manager_connection_request # Esperar y procesar la petición de conexión del Manager

        Liri.init_exit(stop, threads)
      rescue SignalException
        Liri.logger.info("Agent process finished manually", true)
      rescue InxiCommandNotFoundError => e
        Liri.logger.error("Exception(#{e}) Please, install inxi in your operating system", true)
      ensure
        # Siempre se ejecutan estos comandos, haya o no excepción
        Liri.kill(threads) if threads && threads.any?
        Liri.clean_folder_content(agent_folder_path)
        Liri.logger.info("Agent process finished", true)
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

      @processing = true

      @hardware_specs = hardware_specs
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
          Liri.logger.error("Exception(#{e}) Busy UDP port #{@udp_port}", true)
          Thread.exit
        end
        Liri.logger.info("Waiting managers request in UDP port #{@udp_port}")

        while @processing
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
      tcp_socket.puts({ msg: 'get_source_code', hardware_specs: @hardware_specs }.to_json)

      # Las siguientes variables se usan para guardar momentaneamente los resultados mientras se hace un chequeo de que
      # el Manager siga ejecutandose o que ya no haya procesado los mismos tests ya ejecutados por otro agente
      tests_result_file_name = ""
      tests_result_file_path = ""
      tests_result = {}

      while line = tcp_socket.gets
        tcp_socket_data = JSON.parse(line.chop)
        msg = tcp_socket_data['msg']

        if msg == 'already_connected' || msg == 'no_exist_tests' || msg == 'finish_agent'
          break
        end

        if msg == 'proceed_get_source_code'
          result = get_source_code(manager_ip_address, manager_data)
          tcp_socket.puts({ msg: result }.to_json)
        end

        if msg == 'process_tests'
          tests_batch = tcp_socket_data
          tests = get_tests(tests_batch, manager_ip_address)
          raw_tests_result = @runner.run_tests(tests)
          batch_num = tests_batch['batch_num']
          tests_result_file_name = @tests_result.build_file_name(agent_ip_address, batch_num)
          tests_result_file_path = @tests_result.save(tests_result_file_name, raw_tests_result)
          # TODO No se debería enviar el resultado si otro agente ya lo procesó, porque osinó reemplazaría el archivo de resultados
          # ya procesado
          send_tests_results_file(manager_ip_address, manager_data, tests_result_file_path)
          tests_result = { msg: 'processed_tests', batch_num: batch_num, tests_result_file_name: tests_result_file_name}
          tcp_socket.puts(tests_result.to_json) # Envía el número de lote y el nombre del archivo de resultados.
        end
      end

      tcp_socket.close
      unregister_manager(manager_ip_address)
    rescue Errno::EADDRINUSE => e
      Liri.logger.error("Exception(#{e}) Busy UDP port #{@udp_port}")
      @processing = false
    rescue Errno::ECONNRESET => e
      tcp_socket.close
      Liri.logger.error("Exception(#{e}) Closed connection in TCP port #{@tcp_port}", true)
      unregister_manager(manager_ip_address)
    rescue Errno::ECONNREFUSED => e
      Liri.logger.error("Exception(#{e}) Rejected connection in TCP port #{@tcp_port}", true)
      unregister_manager(manager_ip_address)
    end

    private

    # Inserta el ip recibido dentro del hash si es que ya no existe en el hash
    # Nota: Se requieren imprimir datos para saber el estado de la aplicación, sería muy útil usar algo para logear
    # estas cosas en los diferentes niveles, debug, info, etc.
    def process_manager_connection_request(manager_ip_address, manager_data)
      unless registered_manager?(manager_ip_address)
        register_manager(manager_ip_address)
        Liri.logger.info("Broadcast request received from Manager: #{manager_ip_address} in UDP port: #{@udp_port}")
        start_client_socket_to_process_tests(manager_ip_address, manager_data)
      end
    end

    def get_source_code(manager_ip_address, manager_data)
      puts ''
      Liri::Common::Benchmarking.start(start_msg: "Getting source code. Wait... ", stdout: true) do
        puts ''
        Net::SCP.start(manager_ip_address, manager_data.user, password: manager_data.password) do |scp|
          scp.download!(manager_data.compressed_file_path, @source_code.compressed_file_folder_path)
        end
      end
      puts ''

      downloaded_file_name = manager_data.compressed_file_path.split('/').last
      downloaded_file_path = File.join(@source_code.compressed_file_folder_path, '/', downloaded_file_name)

      Liri::Common::Benchmarking.start(start_msg: "Uncompressing source code. Wait... ", stdout: true) do
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
        Liri::Common::Benchmarking.start(start_msg: "Running bundle install. Wait... ", end_msg: "Running bundle install. Duration: ", stdout: true) do
          puts ''
          system("bash -lc 'rvm use #{Liri.current_folder_ruby_and_gemset}; BUNDLE_GEMFILE=Gemfile bundle install'")
        end
        puts ''

        Liri::Common::Benchmarking.start(start_msg: "Running rake db:migrate RAILS_ENV=test. Wait... ", end_msg: "Running rake db:migrate RAILS_ENV=test. Duration: ", stdout: true) do
          puts ''
          system("bash -lc 'rvm use #{Liri.current_folder_ruby_and_gemset}; rake db:migrate RAILS_ENV=test'")
        end
        puts ''
      end
      'get_tests_files'
    rescue Liri::FileNotFoundError => e
      Liri.logger.error("Exception(#{e}) Not found file to decompress in Agent")
      'get_source_code_fail'
    rescue Errno::ECONNREFUSED => e
      Liri.logger.error("Exception(#{e}) Rejected connection by #{manager_ip_address}. Maybe ssh is not running in #{manager_ip_address}")
      'get_source_code_fail'
    rescue Errno::ENOTTY => e
      # Este rescue es temporal, hay que ver una mejor manera de detectar si la contraseña es incorrecta
      Liri.logger.error("Exception(#{e}) Invalid password received in #{manager_ip_address} for ssh connection")
      'get_source_code_fail'
    rescue Net::SSH::AuthenticationFailed => e
      # Este rescue es temporal, hay que ver una mejor manera de detectar si la contraseña es incorrecta
      Liri.logger.error("Exception(#{e}) Invalid password received in #{manager_ip_address} for ssh connection")
      'get_source_code_fail'
    rescue Net::SCP::Error => e
      Liri.logger.warn("Exception(#{e}) File not found in #{manager_ip_address} through scp")
      'get_source_code_fail'
    rescue TypeError => e
      Liri.logger.warn("Exception(#{e}) Undetermined error")
      'get_source_code_fail'
    end

    def get_manager_data(manager_data_hash)
      Common::ManagerData.new(
        tests_results_folder_path: manager_data_hash['tests_results_folder_path'],
        compressed_file_path: manager_data_hash['compressed_file_path'],
        user: manager_data_hash['user'],
        password: manager_data_hash['password']
      )
    end

    def send_tests_results_file(manager_ip_address, manager_data, tests_result_file_path)
      puts ''
      Liri::Common::Benchmarking.start(start_msg: "Sending test files results. Wait... ", stdout: true) do
        Net::SCP.start(manager_ip_address, manager_data.user, password: manager_data.password) do |scp|
          scp.upload!(tests_result_file_path, manager_data.tests_results_folder_path)
        end
      end
      puts ''
    end

    def get_tests(tests_batch, manager_ip_address)
      # Se convierte "[5, 9, 13, 1]" a un arreglo [5, 9, 13, 1]
      tests_keys = tests_batch['tests_batch_keys']
      Liri.logger.debug("Tests keys received from Manager #{manager_ip_address}: #{tests_keys}")
      # Se buscan obtienen los tests que coincidan con las claves recibidas de @all_tests = {1=>"spec/hash_spec.rb:2", 2=>"spec/hash_spec.rb:13", 3=>"spec/hash_spec.rb:24", ..., 29=>"spec/liri_spec.rb:62"}
      # Se retorna un arreglo con los tests a ejecutar ["spec/liri_spec.rb:4", "spec/hash_spec.rb:5", "spec/hash_spec.rb:59", ..., "spec/hash_spec.rb:37"]
      tests_keys.map { |test_key| @all_tests[test_key] }
    end

    def hardware_specs
      "#{Common::Hardware.cpu} #{Common::Hardware.memory}GB"
    end

    def registered_manager?(manager_ip_address)
      @managers[manager_ip_address]
    end

    def register_manager(manager_ip_address)
      @managers[manager_ip_address] = manager_ip_address
    end

    def unregister_manager(manager_ip_address)
      @managers.remove!(manager_ip_address)
      Liri.logger.info("Finish connection with Manager #{manager_ip_address} in TCP port: #{@tcp_port}")
    end
  end
end

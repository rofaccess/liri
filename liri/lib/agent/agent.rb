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
      def run(stop = false)
        Liri.create_folders('agent')

        Liri.set_logger(Liri::AGENT_LOGS_FOLDER_PATH, 'liri-agent.log')
        Liri.logger.info("Proceso Agent iniciado")
        puts "Presione Ctrl + c para terminar el proceso Agent manualmente\n\n"

        source_code = Liri::Common::SourceCode.new(Liri::AGENT_FOLDER_PATH, Liri.compression_class, Liri.unit_test_class)
        runner = Liri::Agent::Runner.new(Liri.unit_test_class, source_code.decompressed_file_folder_path)
        agent = Agent.new(Liri.udp_port, Liri.tcp_port, source_code, runner)
        threads = []
        threads << agent.start_server_socket_to_process_manager_connection_request # Esperar y procesar la petición de conexión del Manager

        Liri.init_exit(stop, threads, 'Agent')
        Liri.logger.info("Proceso Agent terminado")
      rescue SignalException => e
        Liri.logger.info('Proceso Agent terminado manualmente')
        Liri.kill(threads)
      end
    end

    def initialize(udp_port, tcp_port, source_code, runner)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port

      @source_code = source_code
      @runner = runner

      @managers = {}
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
          Liri.logger.error("Error: Puerto UDP #{@udp_port} ocupado")
          Thread.exit
        end
        Liri.logger.info("En espera de peticiones de Managers en el puerto UDP #{@udp_port}
                                     (Se espera que algún Manager se contacte por primera vez para para establecer una conexión TCP)
        ")

        loop do
          @manager_request = @udp_socket.recvfrom(1024)
          manager_ip_address = @manager_request.last.last
          user, pass, dir = @manager_request.first.split(";")
          process_manager_connection_request(manager_ip_address, user, pass, dir)
        end
      end
    end

    # Inicia un cliente tcp para responder a la petición broadcast del Manager para que éste sepa donde enviar las pruebas
    def start_client_socket_to_process_tests(manager_ip_address)
      tcp_socket = TCPSocket.open(manager_ip_address, @tcp_port)

      Liri.logger.info("Se inicia una conexión con el Manager: #{manager_ip_address} en el puerto TCP: #{@tcp_port}
                                     (Se establece una conexión para procesar la ejecución de las pruebas)
      ")

      tcp_socket.print("Listo para ejecutar pruebas") # Se envía un mensaje inicial al Manager
      puts "\nConexión iniciada con el Manager: #{manager_ip_address}"

      # Se procesan las pruebas enviadds por el Manager
      while line = tcp_socket.gets
        response = line.chop
        break if response == 'exit'

        tests = JSON.parse(response)
        Liri.logger.debug("Pruebas recibidas del Manager #{manager_ip_address}:")
        Liri.logger.debug(tests)

        tests_result = @runner.run_tests(tests)
        Liri.logger.debug("Resultados de la ejecución de las pruebas recibidas del Manager #{manager_ip_address}:")
        Liri.logger.debug(tests_result)

        Liri.logger.info("
                                       #{tests.size} pruebas recibidas, #{tests_result[:example_quantity]} pruebas ejecutadas
        ")
        tcp_socket.print(tests_result.to_json)
      end

      tcp_socket.close
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")

      Liri.clean_folder(Liri::AGENT_FOLDER_PATH)

      start_client_to_close_manager_server(manager_ip_address, 'Conexión Terminada')
      unregister_manager(manager_ip_address)
    rescue Errno::EADDRINUSE => e
      Liri.logger.error("Error: Puerto TCP #{@tcp_port} ocupado")
    rescue Errno::ECONNRESET => e
      tcp_socket.close
      Liri.logger.error("Error: Conexión cerrada en el puerto TCP #{@tcp_port}")
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")
      unregister_manager(manager_ip_address)
    rescue Errno::ECONNREFUSED => e
      Liri.logger.error("Error: Conexión rechazada en el puerto TCP #{@tcp_port}")
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")
      unregister_manager(manager_ip_address)
    end

    private

    # Inserta el ip recibido dentro del hash si es que ya no existe en el hash
    # Nota: Se requieren imprimir datos para saber el estado de la aplicación, sería muy útil usar algo para logear
    # estas cosas en los diferentes niveles, debug, info, etc.
    def process_manager_connection_request(manager_ip_address, user, pass, dir)
      unless registered_manager?(manager_ip_address)
        register_manager(manager_ip_address)
        Liri.logger.info("Petición broadcast UDP recibida del Manager: #{manager_ip_address} en el puerto UDP: #{@udp_port}")
        if process_manager_connection_scp(manager_ip_address, user, pass, dir)
          start_client_socket_to_process_tests(manager_ip_address)
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

    def process_manager_connection_scp(manager_ip_address, user, pass, dir)
      Net::SCP.start(manager_ip_address, user, :password => pass) do |scp|
        scp.download!(dir, @source_code.compressed_file_folder_path)
      end
      downloaded_file_name = dir.split('/').last
      downloaded_file_path = File.join(@source_code.compressed_file_folder_path, '/', downloaded_file_name)
      @source_code.decompress_file(downloaded_file_path)

      # Se cambia temporalmente la carpeta de trabajo a la carpeta de código fuente descomprimida
      Dir.chdir(@source_code.decompressed_file_folder_path) do
        # Se borra el directorio .git para evitar el siguiente error al ejecutar las pruebas: fatal: not a git repository (or any of the parent directories): .git
        # Una mejor alternativa es no traer siquiera esa carpeta junto al código fuente excluyendo la carpeta .git al comprimir el código fuente.
        # Por cuestiones de tiempo se procede a borrar la carpeta .git por ahora, aunque al parecer el error mostrado no afecta la ejecución del Agent
        # Al realizar pruebas, el error mencionado se sigue viendo en producción así que no es seguro que este borrado de la carpeta .git solucione el problema
        git_folder_path = File.join(Dir.pwd, '/.git')
        FileUtils.rm_rf(git_folder_path) if Dir.exist?(git_folder_path)

        # Se instalan las dependencias del código fuente recibido
        system("bundle install")
      end
      true
    rescue Errno::ECONNREFUSED => e
      Liri.logger.error("Error ssh. Conexión rechazada por #{manager_ip_address}. Posiblemente ssh no esté ejecutandose en #{manager_ip_address}")
      false
    rescue Errno::ENOTTY => e
      # Este rescue es temporal, hay que ver una mejor manera de detectar si la contraseña es incorrecta
      Liri.logger.error("Error ssh. Contraseña incorrecta recibida de #{manager_ip_address}")
      start_client_to_close_manager_server(manager_ip_address, "No se puede obtener el archivo de código fuente. Posiblemente se envío una contraseña incorrencta desde #{manager_ip_address}")
      false
    rescue Net::SSH::AuthenticationFailed => e
      # Este rescue es temporal, hay que ver una mejor manera de detectar si la contraseña es incorrecta
      Liri.logger.error("Error ssh. Contraseña incorrecta recibida de #{manager_ip_address}")
      start_client_to_close_manager_server(manager_ip_address, "No se puede obtener el archivo de código fuente. Posiblemente se envío una contraseña incorrencta desde #{manager_ip_address}")
      false
    rescue Net::SCP::Error => e
      Liri.logger.warn("Error scp. Archivo no encontrado en #{manager_ip_address}")
      false
    rescue TypeError => e
      Liri.logger.warn(puts 'Para que ande nomas')
      false
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
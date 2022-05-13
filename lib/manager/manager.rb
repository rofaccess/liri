=begin
  Este modulo es el punto de entrada del programa principal
=end
require 'all_libraries'

module Liri
  class Manager
    UDP_REQUEST_DELAY = 3
    attr_reader :agents

    class << self
      # Inicia la ejecución del Manager
      # @param stop [Boolean] el valor true es para que no se ejecute infinitamente el método en el test unitario.
      def run(stop = false)
        return unless valid_project

        Liri.create_folders('manager')

        Liri.set_logger(Liri::MANAGER_LOGS_FOLDER_PATH, 'liri-manager.log')
        Liri.logger.info("Proceso Manager iniciado")
        puts "Presione Ctrl + c para terminar el proceso Manager manualmente\n\n"

        user, password = get_credentials
        source_code = compress_source_code
        manager_data = get_manager_data(user, password, source_code)
        all_tests = get_all_tests(source_code)
        tests_result = Common::TestsResult.new(Liri::MANAGER_FOLDER_PATH)

        manager = Manager.new(Liri.udp_port, Liri.tcp_port, all_tests, tests_result)

        threads = []
        threads << manager.start_client_socket_to_search_agents(manager_data) # Enviar peticiones broadcast a toda la red para encontrar Agents
        manager.start_server_socket_to_process_tests(threads[0]) # Esperar y enviar los test unitarios a los Agents

        Liri.init_exit(stop, threads, 'Manager')
        Liri.logger.info("Proceso Manager terminado")
      rescue SignalException => e
        Liri.logger.info("Exception(#{e}) Proceso Manager terminado manualmente")
        Liri.kill(threads)
      end

      def test_samples_by_runner
        Liri.setup.test_samples_by_runner
      end

      private
      def valid_project
        if File.exist?(File.join(Dir.pwd, 'Gemfile'))
          true
        else
          Liri.logger.info("No se encuentra un archivo Gemfile por lo que se asume que el directorio actual no corresponde a un proyecto Ruby")
          Liri.logger.info("Liri sólo puede ejecutarse en proyectos Ruby")
          Liri.logger.info("Proceso Manager terminado")
          false
        end
      end

      def compressed_file_folder_path
        File.join(Liri::Common.setup_folder_path, '/manager')
      end

      def decompressed_file_folder_path
        compressed_file_folder_path
      end

      def get_credentials
        credential = Liri::Manager::Credential.new(Liri::SETUP_FOLDER_PATH)
        credential.get
      end

      def compress_source_code
        source_code = Common::SourceCode.new(Liri::MANAGER_FOLDER_PATH, Liri.compression_class, Liri.unit_test_class)
        Common::Benchmarking.start(start_msg: "Comprimiendo código fuente. Espere... ") do
          source_code.compress_folder
        end
        puts ''
        source_code
      end

      def get_manager_data(user, password, source_code)
        Common::ManagerData.new(
          folder_path: Liri::MANAGER_FOLDER_PATH,
          compressed_file_path: source_code.compressed_file_path,
          user: user,
          password: password
        )
      end

      def get_all_tests(source_code)
        all_tests = {}
        Liri::Common::Benchmarking.start(start_msg: "Obteniendo conjunto de pruebas. Espere... ") do
          all_tests = source_code.all_tests
        end
        puts ''
        all_tests
      end
    end

    def initialize(udp_port, tcp_port, all_tests, tests_result)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port

      @all_tests = all_tests
      @all_tests_count = all_tests.size
      @all_tests_results = {}
      @all_tests_results_count = 0
      @all_tests_processing_count = 0
      @agents = {}

      @agents_search_processing_enabled = true
      @test_processing_enabled = true

      @tests_batch_number = 0
      @tests_batches = {}

      @tests_result = tests_result
      @semaphore = Mutex.new
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents(manager_data)
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents. Una vez que los tests terminan de ejecutarse, este hilo será finalizado.
      Thread.new do
        puts "\nBuscando Agentes... Espere"
        Liri.logger.info("Se emite un broadcast cada #{UDP_REQUEST_DELAY} segundos en el puerto UDP: #{@udp_port}
                                     (Se mantiene escaneando la red para encontrar Agents)
        ")
        while agents_search_processing_enabled
          @udp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
          @udp_socket.send(manager_data.to_h.to_json, 0, '<broadcast>', @udp_port)
          sleep(UDP_REQUEST_DELAY) # Se pausa un momento antes de efectuar nuevamente la petición broadcast
        end
      end
    end

    # Inicia un servidor tcp para procesar los pruebas después de haberse iniciado la conexión a través de udp
    def start_server_socket_to_process_tests(search_agents_thread)
      begin
        tcp_socket = TCPServer.new(@tcp_port) # se hace un bind al puerto dado
      rescue Errno::EADDRINUSE => e
        Liri.logger.error("Exception(#{e}) Puerto TCP #{@tcp_port} ocupado.")
        Thread.kill(search_agents_thread)
        Thread.exit
      end

      Liri.logger.info("En espera para establecer conexión con los Agents en el puerto TCP: #{@tcp_port}
                                     (Se espera que algún Agent se conecte para ejecutar las pruebas como respuesta al broadcast UDP)
      ")
      # El siguiente bucle permite que varios clientes es decir Agents se conecten
      # De: http://www.w3big.com/es/ruby/ruby-socket-programming.html
      while test_processing_enabled
        Thread.start(tcp_socket.accept) do |client|
          agent_ip_address = client.remote_address.ip_address
          response = client.recvfrom(1000).first

          if all_tests.empty?
            # No importa lo que le haga, el broadcast udp no se muere al instante y el agente sigue respondiendo
            # Las siguientes dos lineas son para que se deje de hacer el broadcast pero aun asi se llegan a hacer
            # 3 a 4 broadcast antes de que se finalize el proceso, al parecer el broadcast va a tener que quedar asi
            # y mejorar el codigo para que se envien test pendientes para eso hay que llevar una lista de test pendientes
            # tests enviados sin resultados, tests finalizados, si se recibe respuesta al broadcast se trata de enviar primero test pendientes
            # luego test enviados sin resultados o sino ignorar
            Thread.kill(search_agents_thread)
            agents_search_processing_enabled = false
            Liri.logger.info("Se termina cualquier proceso pendiente con el Agent #{agent_ip_address}")
            Liri.logger.info(response)
            client.close
            Thread.exit
          end

          puts "\nConexión iniciada con el Agente: #{agent_ip_address}"
          Liri.logger.info("Respuesta al broadcast recibida del Agent: #{agent_ip_address} en el puerto TCP: #{@tcp_port}
                                         => Agent #{agent_ip_address}: #{response}
          ")

          while all_tests.any?
            tests_batch = tests_batch(agent_ip_address)
            break unless tests_batch

            begin
              Liri.logger.debug("Conjunto de pruebas enviadas al Agent #{agent_ip_address}: #{tests_batch}")

              client.puts(tests_batch.to_json) # Se envia el lote de tests
              response = client.recvfrom(1000).first # Se recibe la respuesta. Cuando mas alto es el parámetro de recvfrom, mas datos se reciben osino se truncan.
            rescue Errno::EPIPE => e
              # Esto al parecer se da cuando el Agent ya cerró las conexiones y el Manager intenta contactar
              Liri.logger.error("Exception(#{e}) El Agent #{agent_ip_address} ya terminó la conexión")
              # Si el Agente ya no responde es mejor romper el bucle para que no quede colgado
              break
            end
            # A veces se tiene un error de parseo JSON, de ser asi los resultados no pueden procesarse,
            # hay que arreglar esto, mientras, se captura el error para que no falle
            begin
              tests_result = JSON.parse(response)
              Liri.logger.debug("Respuesta del Agent #{agent_ip_address}: #{tests_result}")
              process_tests_result(tests_result)
            rescue JSON::ParserError => e
              Liri.logger.error("Exception(#{e}) Error de parseo JSON")
            end
          end

          update_processing_statuses
          puts ''
          Liri.logger.info("Se termina la conexión con el Agent #{agent_ip_address}")
          begin
            client.puts('exit') # Se envía el string exit para que el Agent sepa que el proceso terminó
            client.close # se desconecta el cliente
          rescue Errno::EPIPE => e
            # Esto al parecer se da cuando el Agent ya cerró las conexiones y el Manager intenta contactar
            Liri.logger.error("Exception(#{e}) El Agent #{agent_ip_address} ya terminó la conexión")
			      # Si el Agente ya no responde es mejor terminar el hilo. Aunque igual quedará colgado el Manager
			      # mientras sigan pruebas pendientes
            Thread.exit
          end
        end
      end

      Liri.clean_folder(Liri::MANAGER_FOLDER_PATH)
      @tests_result.print_summary
    end

    def all_tests
      @semaphore.synchronize do
        @all_tests
      end
    end

    def agents_search_processing_enabled=(value)
      @semaphore.synchronize do
        @agents_search_processing_enabled = value
      end
    end

    def agents_search_processing_enabled
      @semaphore.synchronize do
        @agents_search_processing_enabled
      end
    end

    def test_processing_enabled
      @semaphore.synchronize do
        @test_processing_enabled
      end
    end

    def update_processing_statuses
      @semaphore.synchronize do
        @test_processing_enabled = false if @all_tests_count == @all_tests_results_count
        @agents_search_processing_enabled = false if @all_tests_count == @all_tests_processing_count
      end
    end

    def tests_batch(agent_ip_address)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        return nil if @all_tests.empty?

        @tests_batch_number += 1 # Se numera cada lote
        samples = @all_tests.sample!(Manager.test_samples_by_runner) # Se obtiene algunos tests
        samples_keys = samples.keys # Se obtiene la clave asignada a los tests
        @all_tests_processing_count += samples_keys.size
        @tests_batches[@tests_batch_number] = { agent_ip_address: agent_ip_address, tests_batch_keys: samples_keys } # Se guarda el lote a enviar
        tests_batch = { tests_batch_number: @tests_batch_number, tests_batch_keys: samples_keys } # Se construye el lote a enviar
        tests_batch
      end
    end

    def process_tests_result(tests_result)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        tests_batch_number = tests_result['tests_batch_number']
        tests_result_file_name = tests_result['tests_result_file_name']
        tests_batch_keys = @tests_batches[tests_batch_number][:tests_batch_keys]
        @all_tests_results_count += tests_batch_keys.size
        @tests_batches[tests_batch_number][:tests_result_file_name] = tests_result_file_name
        @tests_result.process(tests_result_file_name)
      end
    end
  end
end
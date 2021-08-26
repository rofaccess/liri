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
        Liri.logger.info("Proceso Manager iniciado")
        puts "Presione Ctrl + c para terminar el proceso Manager manualmente\n\n"

        source_code = Liri::Common::SourceCode.new(compression_class, unit_test_class)
        puts "Comprimiendo el archivo"
        source_code.compress_folder
        all_tests = source_code.all_tests
		    test_result = Liri::Manager::TestResult.new
        manager = Manager.new(udp_port, tcp_port, all_tests, test_result)
        credential = Liri::Manager::Credential.new
        credential.get
        threads = []
        threads << manager.start_client_socket_to_search_agents(user_data)# Enviar peticiones broadcast a toda la red para encontrar Agents
        manager.start_server_socket_to_process_tests(threads[0]) # Esperar y enviar los test unitarios a los Agents

        #source_code.delete_compressed_folder

        Liri.init_exit(stop, threads, 'Manager')
        Liri.logger.info("Proceso Manager terminado")
      rescue SignalException => e
        Liri.logger.info("Proceso Manager terminado manualmente")
        Liri.kill(threads)
      end

      def test_samples_by_runner
        Liri.setup.test_samples_by_runner
      end

      private

      def compression_class
        "Liri::Common::Compressor::#{Liri.setup.library.compression}"
      end

      def unit_test_class
        "Liri::Manager::UnitTest::#{Liri.setup.library.unit_test}"
      end

      def udp_port
        Liri.setup.ports.udp
      end

      def tcp_port
        Liri.setup.ports.tcp
      end

      def user_data
        [Liri.setup.manager_user.user, Liri.setup.manager_user.password, Liri.setup.path_compress_file].join(';')
      end

    end

    def initialize(udp_port, tcp_port_1, all_tests, test_result)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port_1

      @all_tests = all_tests
      @all_tests_count = all_tests.size
      @all_tests_results = {}
      @all_tests_results_count = 0
      @all_tests_processing_count = 0
      @agents = {}

      @agents_search_processing_enabled = true
      @test_processing_enabled = true

      @test_result = test_result
      @semaphore = Mutex.new
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents(user_data)
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents. Una vez que los tests terminan de ejecutarse, este hilo será finalizado.
      Thread.new do
        Liri.logger.info("Se emite un broadcast cada #{UDP_REQUEST_DELAY} segundos en el puerto UDP: #{@udp_port}
                                      (Se mantiene escaneando la red para encontrar Agents)
        ")
        puts "Estoy enviando: #{user_data}"
        while @agents_search_processing_enabled
          @udp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
          @udp_socket.send(user_data, 0, '<broadcast>', @udp_port)
          sleep(UDP_REQUEST_DELAY) # Se pausa un momento antes de efectuar nuevamente la petición broadcast
        end
      end
    end

    # Inicia un servidor tcp para procesar los pruebas después de haberse iniciado la conexión a través de udp
    def start_server_socket_to_process_tests(search_agents_thread)
      begin
        tcp_socket = TCPServer.new(@tcp_port) # se hace un bind al puerto dado
      rescue Errno::EADDRINUSE => e
        Liri.logger.error("Error: Puerto TCP #{@tcp_port} ocupado.")
        Thread.kill(search_agents_thread)
        Thread.exit
      end

      Liri.logger.info("En espera para establecer conexión con los Agents en el puerto TCP: #{@tcp_port}
                                      (Se espera que algún Agent se conecte para ejecutar las pruebas como respuesta al broadcast UDP)
      ")
      # El siguiente bucle permite que varios clientes es decir Agents se conecten
      # De: http://www.w3big.com/es/ruby/ruby-socket-programming.html
      while @test_processing_enabled
        Thread.start(tcp_socket.accept) do |client|
          agent_ip_address = client.remote_address.ip_address
          response = client.recvfrom(1000).first

          if @all_tests.empty?
            # No importa lo que le haga, el broadcast udp no se muere al instante y el agente sigue respondiendo
            # Las siguientes dos lineas son para que se deje de hacer el broadcast pero aun asi se llegan a hacer
            # 3 a 4 broadcast antes de que se finalize el proceso, al parecer el broadcast va a tener que quedar asi
            # y mejorar el codigo para que se envien test pendientes para eso hay que llevar una lista de test pendientes
            # tests enviados sin resultados, tests finalizados, si se recibe respuesta al broadcast se trata de enviar primero test pendientes
            # luego test enviados sin resultados o sino ignorar
            Thread.kill(search_agents_thread)
            @agents_search_processing_enabled = false
            Liri.logger.info("Se termina cualquier proceso pendiente con el Agent #{agent_ip_address}")
            puts response
            client.close
            Thread.exit
          end

          Liri.logger.info("Respuesta al broadcast recibida del Agent: #{agent_ip_address} en el puerto TCP: #{@tcp_port}
                                          => Agent #{agent_ip_address}: #{response}
          ")

          while @all_tests.any?
            tests = samples
            break if tests.empty?
            client.puts(tests.to_json)
            response = client.recvfrom(1000).first
            # TODO A veces se tiene un error de parseo JSON, de ser asi los resultado no pueden procesarse,
            # hay que arreglar esto, mientras, se captura el error para que no falle
            begin
              tests_result = JSON.parse(response)
              process_tests_result(tests, tests_result)
            rescue JSON::ParserError => e
              Liri.logger.error("Error #{e}: Error de parseo JSON")
            end
          end

          update_processing_statuses
          puts ''
          Liri.logger.info("Se termina la conexión con el Agent #{agent_ip_address}")
          client.puts('exit') # Se envía el string exit para que el Agent sepa que el proceso terminó
          client.close # se desconecta el cliente
        end
      end

      @test_result.print_summary
    end

    def update_processing_statuses
      @semaphore.synchronize {
        @test_processing_enabled = false if @all_tests_count == @all_tests_results_count
        @agents_search_processing_enabled = false if @all_tests_count == @all_tests_processing_count
      }
    end

    def update_all_tests_results_count(new_count)
      @all_tests_results_count += new_count
    end

    def update_all_tests_processing_count(new_count)
      @all_tests_processing_count += new_count
    end

    def samples
      _samples = nil
      # Varios hilos no deben acceder simultaneamente al siguiente bloque porque actualiza variables compartidas
      @semaphore.synchronize {
        _samples = @all_tests.sample!(Manager.test_samples_by_runner)
        update_all_tests_processing_count(_samples.size)
      }
      _samples
    end

    def process_tests_result(tests, tests_result)
      # Varios hilos no deben acceder simultaneamente al siguiente bloque porque actualiza variables compartidas
      @semaphore.synchronize {
        update_all_tests_results_count(tests.size)
        @test_result.print_process(tests_result)
        @test_result.update(tests_result)
      }
    end
  end
end
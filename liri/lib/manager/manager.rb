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

        source_code = Liri::Manager::SourceCode.new(compression_class, unit_test_class)
        #source_code.compress_folder
        all_tests = source_code.all_tests
        test_result = Liri::Manager::TestResult.new
        manager = Manager.new(udp_port, tcp_port, all_tests, test_result)
        threads = []
        threads << manager.start_client_socket_to_search_agents # Enviar peticiones broadcast a toda la red para encontrar Agents
        manager.start_server_socket_to_process_tests(threads[0]) # Esperar y enviar los test unitarios a los Agents

        #source_code.delete_compressed_folder

        Liri.init_exit(stop, threads, 'Manager')
        Liri.logger.debug("Proceso Manager terminado")
      rescue SignalException => e
        Liri.logger.debug("Proceso Manager terminado manualmente")
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
    end

    def initialize(udp_port, tcp_port_1, all_tests, test_result)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port_1

      @process_tests_threads = []

      @all_tests = all_tests
      @all_tests_count = all_tests.size
      @all_tests_results = {}
      @all_tests_results_count = 0
      @agents = {}

      @test_result = test_result
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents. Una vez que los tests terminan de ejecutarse, este hilo será finalizado.
      Thread.new do
        Liri.logger.info("Se emite un broadcast cada #{UDP_REQUEST_DELAY} segundos en el puerto UDP: #{@udp_port}")
        Liri.logger.info('(Se mantiene escaneando la red para encontrar Agents)')
        Liri.logger.info('')
        loop do
          @udp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
          @udp_socket.send('', 0, '<broadcast>', @udp_port)
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

      Liri.logger.info("En espera para establecer conexión con los Agents en el puerto TCP: #{@tcp_port}")
      Liri.logger.info('(Se espera que algún Agent se conecte para ejecutar las pruebas como respuesta al broadcast UDP)')
      Liri.logger.info('')
      # El siguiente bucle permite que varios clientes es decir Agents se conecten
      # De: http://www.w3big.com/es/ruby/ruby-socket-programming.html
      # Obs.: Parece que este bucle deja un hilo corriendo el cual no estoy pudiendo eliminar, sospecho que este
      # hilo permanece en espera de que el agente se conecte, por eso desde el agente se realiza de nuevo una conexion
      # lo que hace que el Manager termine al no tener tests pendientes
      loop do
        break if @all_tests_count == @all_tests_results_count
        @process_tests_threads << Thread.start(tcp_socket.accept) do |client|
          client_ip_address = client.remote_address.ip_address
          puts "Conexión iniciada con el Agent: #{client_ip_address}"
          Liri.logger.info("Respuesta al broadcast recibida del Agent: #{client_ip_address} en el puerto TCP: #{@tcp_port}")
          response = client.recvfrom(1000).first
          Liri.logger.info("    => Agent #{client_ip_address}: #{response}\n")

          while @all_tests.any?
            samples = @all_tests.sample!(Manager.test_samples_by_runner)
            client.puts(samples.to_json)

            response = client.recvfrom(1000).first
            begin
              # TODO A veces se tiene un error de parseo JSON, de ser asi los resultado no pueden procesarse, hay que arreglar esto, mientras se captura el error para que no falle
              test_result = JSON.parse(response)
              @test_result.print_process(test_result)
              @test_result.update(test_result)
              update_all_tests_results_count(samples.size)
            rescue JSON::ParserError => e
              Liri.logger.error("Error #{e}: Error de parseo JSON")
            end
          end

          Thread.kill(search_agents_thread)

          # Se envía el string exit para que el Agent termine la conexión
          client.puts('exit')
          client.close # se desconecta el cliente
          puts "\nConexión terminada con el Agent: #{client_ip_address}"
        end
      end

      @test_result.print_summary
    end

    def update_all_tests_results_count(new_count)
      @all_tests_results_count += new_count
    end
  end
end
=begin
  Este módulo es el punto de entrada del programa agente
=end
require 'all_libraries'

module Liri
  class Agent
    attr_reader :managers

    class << self
      # Inicia la ejecución del Agent
      # @param stop [Boolean] el valor true es para que no se ejecute infinitamente el método en el test unitario.
      def run(stop = false)
        Liri.logger.info("Proceso Agent iniciado")
        puts "Presione Ctrl + c para terminar el proceso Agent manualmente\n\n"

        runner = Liri::Agent::Runner.new(unit_test_class)
        agent = Agent.new(udp_port, tcp_port, runner)
        threads = []
        threads << agent.start_server_socket_to_process_manager_connection_request # Esperar y procesar la petición de conexión del Manager

        Liri.init_exit(stop, threads, 'Agent')
        Liri.logger.info("Proceso Agent terminado")
      rescue SignalException => e
        Liri.logger.info('Proceso Agent terminado manualmente')
        Liri.kill(threads)
      end

      private

      def udp_port
        Liri.setup.ports.udp
      end

      def tcp_port
        Liri.setup.ports.tcp
      end

      def unit_test_class
        "Liri::Agent::UnitTest::#{Liri.setup.library.unit_test}"
      end
    end

    def initialize(udp_port, tcp_port, runner)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port

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

        Liri.logger.info("En espera de peticiones de Managers en el puerto UDP #{@udp_port}")
        Liri.logger.info('(Se espera que algún Manager se contacte por primera vez para para establecer una conexión TCP)')
        Liri.logger.info('')
        loop do
          @manager_request = @udp_socket.recvfrom(1024)
          manager_ip_address = @manager_request.last.last
          process_manager_connection_request(manager_ip_address)
        end
      end
    end

    # Inicia un cliente tcp para responder a la petición broadcast del Manager para que éste sepa donde enviar las pruebas
    def start_client_socket_to_process_tests(manager_ip_address)
      tcp_socket = TCPSocket.open(manager_ip_address, @tcp_port)

      Liri.logger.info('')
      Liri.logger.info("Se inicia una conexión con el Manager: #{manager_ip_address} en el puerto TCP: #{@tcp_port}")
      Liri.logger.info('(Se establece una conexión para procesar la ejecución de las pruebas)')
      tcp_socket.print("Listo para ejecutar pruebas")
      puts "\nConexión iniciada con el Manager: #{manager_ip_address}"

      while line = tcp_socket.gets
        response = line.chop
        if response == 'exit'
          break
        else
          tests = JSON.parse(response)
          Liri.logger.info("Pruebas recibidas del Manager #{manager_ip_address}:")
          Liri.logger.debug(tests)

          tests_result = @runner.run_tests(tests)
          Liri.logger.info("Resultados de la ejecución de las pruebas recibidas del Manager #{manager_ip_address}:")
          Liri.logger.debug(tests_result)
          puts "#{tests.size} pruebas recibidas, #{tests_result[:example_quantity]} pruebas ejecutadas"
          tcp_socket.print(tests_result.to_json)
        end
      end

      tcp_socket.close
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")
      @managers.remove!(manager_ip_address)

      start_client_to_close_manager_server(manager_ip_address)
    rescue Errno::EADDRINUSE => e
      Liri.logger.error("Error: Puerto TCP #{@tcp_port} ocupado")
    rescue Errno::ECONNRESET => e
      tcp_socket.close
      Liri.logger.error("Error: Conexión cerrada en el puerto TCP #{@tcp_port}")
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")
      @managers.remove!(manager_ip_address)
    rescue Errno::ECONNREFUSED => e
      Liri.logger.error("Error: Conexión rechazada en el puerto TCP #{@tcp_port}")
      Liri.logger.info("Se termina la conexión con el Manager #{manager_ip_address}")
      @managers.remove!(manager_ip_address)
    end

    private

    # Inserta el ip recibido dentro del hash si es que ya no existe en el hash
    # Nota: Se requieren imprimir datos para saber el estado de la aplicación, sería muy útil usar algo para logear
    # estas cosas en los diferentes niveles, debug, info, etc.
    def process_manager_connection_request(manager_ip_address)
      unless @managers[manager_ip_address]
        @managers[manager_ip_address] = manager_ip_address
        Liri.logger.info("Petición broadcast UDP recibida del Manager: #{manager_ip_address} en el puerto UDP: #{@udp_port}")
        start_client_socket_to_process_tests(manager_ip_address)
      end
    end

    # Se establece una nueva comunicación con el servidor TCP del Manager con el único objetivo de cerrar el servidor
    # Esta conexión permitirá al Manager cerrar sus hilos pendientes y terminar el proceso
    def start_client_to_close_manager_server(manager_ip_address)
      # Por algún motivo el siguiente método permite cerrar la conexión, por ahora se usará esto
      # tal vez en algún momento se haga un método más específico usando el contenido relevante del siguiente método
      start_client_socket_to_process_tests(manager_ip_address)
    end
  end
end
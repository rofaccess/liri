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
      def run(stop=false)
        puts "Presione Ctrl + c para terminar el Agent manualmente\n\n"
        runner = Liri::Agent::Runner.new(unit_test_class)
        agent = Agent.new(udp_port, tcp_port_1, tcp_port_2, runner)
        threads = []
        threads << agent.start_server_socket_to_process_address_request_from_manager # Esperar y procesar la petición de dirección del Manager
        threads << agent.start_server_socket_to_run_tests_sent_from_manager # Esperar y ejecutar pruebas enviadas por los Managers

        Liri.init_exit(stop, threads, 'Agent')
      end

      private
      def udp_port
        Liri.setup.ports.udp
      end

      def tcp_port_1
        Liri.setup.ports.tcp_1
      end

      def tcp_port_2
        Liri.setup.ports.tcp_2
      end

      def unit_test_class
        "Liri::Agent::UnitTest::#{Liri.setup.library.unit_test}"
      end
    end

    def initialize(udp_port, tcp_port_1, tcp_port_2, runner)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port_1 = tcp_port_1
      @tcp_port_2 = tcp_port_2

      @stop_server_socket_to_process_address_request_from_manager = false
      @stop_server_socket_to_run_tests_sent_from_manager = false

      @runner = runner
      @managers = {}
    end

    # Inicia un servidor udp que se mantiene en espera de la primera petición de conexión del Manager
    def start_server_socket_to_process_address_request_from_manager
      # El servidor udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue esperando
      # que un Manager se conecte, cuando se conecta un Manager, se guarda la ip de este manager y se vuelve a esperar otra petición
      Thread.new do
        BasicSocket.do_not_reverse_lookup = true
        begin
          @udp_socket.bind('0.0.0.0', @udp_port)
        rescue Errno::EADDRINUSE => e
         puts "Error: Puerto UDP #{@udp_port} ocupado"
         Thread.exit
        end

        puts "En espera de peticiones de Managers en el puerto UDP #{@udp_port}"
        puts '(Se espera que algún Manager se contacte por primera vez para responderle con la dirección ip del Agent)'
        puts ''
        while !@stop_server_socket_to_process_address_request_from_manager
          @manager_request = @udp_socket.recvfrom(1024)
          manager_ip_address = @manager_request.last.last
          process_address_request_from_manager(manager_ip_address)
          break if @stop_server_socket_to_process_address_request_from_manager
        end
      end
    end

    # Termina la ejecución del bucle e hilo iniciado en start_server_socket_to_process_address_request_from_manager
    def stop_server_socket_to_process_address_request_from_manager
      @stop_server_socket_to_process_address_request_from_manager = true
      puts "Se finaliza la espera de peticiones broadcast de Managers en el puerto UDP: #{@udp_port}"
    end

    # Inicia un cliente tcp para responder a la petición broadcast del Manager para que éste sepa donde enviar las pruebas
    def start_client_socket_to_send_address_to_manager(manager_ip_address)
      begin
        tcp_socket = TCPSocket.open(manager_ip_address, @tcp_port_1)
      rescue Errno::EADDRINUSE => e
        puts "Error: Puerto TCP #{@tcp_port_1} ocupado"
        Thread.exit
      end

      puts "Se inicia una conexión con el Manager: #{manager_ip_address} en el puerto TCP: #{@tcp_port_1}"
      puts '(Se responde al Manager para que éste sepa donde enviar las pruebas)'
      puts ''
      while line = tcp_socket.gets
        response_msg = line.chop
        puts response_msg
      end
      tcp_socket.close
    end

    # Inicia un servidor tcp que se mantiene en espera para recibir las pruebas unitarias enviadas por el Manager
    def start_server_socket_to_run_tests_sent_from_manager
      Thread.new do
        begin
          tcp_socket = TCPServer.new(@tcp_port_2) # se hace un bind al puerto dado
        rescue Errno::EADDRINUSE => e
          puts "Error: Puerto TCP #{@tcp_port_2} ocupado"
          Thread.exit
        end

        puts "En espera de peticiones de Managers en el puerto TCP: #{@tcp_port_2}"
        puts '(Se espera que algún Manager envíe las pruebas unitarias)'
        puts ''
        while !@stop_server_socket_to_run_tests_sent_from_manager
          Thread.start(tcp_socket.accept) do |client|
            puts "Pruebas recibidas del Manager: #{client.remote_address.ip_address} en el puerto TCP: #{@tcp_port_2}"
            tests = JSON.parse(client.recvfrom(1000).first)
            puts tests
            tests_result = @runner.run_tests(tests)
            puts tests_result
            client.puts(tests_result)
            puts "Resultados de Pruebas enviadas al Manager: #{client.remote_address.ip_address}"
            client.close # se desconecta el cliente
          end

          break if @stop_server_socket_to_run_tests_sent_from_manager
        end
      end
    end

    def stop_server_socket_to_run_tests_sent_from_manager
      @stop_server_socket_to_run_tests_sent_from_manager = true
      puts "Se finaliza la espera de peticiones para ejecutar pruebas de Managers en el puerto TCP: #{@tcp_port_1}"
    end

    private
    # Inserta el ip recibido dentro del hash si es que ya no existe en el hash
    # Nota: Se requieren imprimir datos para saber el estado de la aplicación, sería muy útil usar algo para logear
    # estas cosas en los diferentes niveles, debug, info, etc.
    def process_address_request_from_manager(manager_ip_address)
      unless @managers[manager_ip_address]
        @managers[manager_ip_address] = manager_ip_address
        puts "Petición broadcast UDP recibida del Manager: #{manager_ip_address} en el puerto TCP: #{@udp_port}"
        start_client_socket_to_send_address_to_manager(manager_ip_address)
      end
    end
  end
end
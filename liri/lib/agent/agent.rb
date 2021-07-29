=begin
  Este modulo es el punto de entrada del programa agente
=end
require 'all_libraries'

module Liri
  class Agent
    attr_reader :managers

    class << self
      # Inicia la ejecución del Agent
      # @param stop [Boolean] el valor true es para que no se ejecute infinitamente el método en el test unitario.
      def run(stop=false)
        puts "Presione s y luego Enter o Ctrl + c para salir\n\n"
        runner = Liri::Agent::Runner.new(unit_test_class)
        agent = Agent.new(udp_port, tcp_port, runner)
        threads = []
        threads << agent.start_server_to_process_first_request_from_manager # Esperar y procesar primeras peticiones de Managers
        threads << agent.start_server_to_run_tests_sent_from_manager # Esperar y ejecutar pruebas enviadas por los Managers

        Liri.init_exit(stop, threads)

        # Con la siguiente línea se asegura que los hilos no mueran antes de que finalize el programa principal
        # Fuente: https://underc0de.org/foro/ruby/hilos-en-ruby/
        threads.each{|thread| thread.join}
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

      @stop_server_to_process_first_request_from_manager = false
      @stop_server_to_run_tests_sent_from_manager = false

      @runner = runner
      @managers = {}
    end

    # Inicia un servidor udp que se mantiene en espera de la primera petición de conexión del Manager
    def start_server_to_process_first_request_from_manager
      # El servidor udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue esperando
      # que un Manager se conecte, cuando se conecta un Manager, se guarda la ip de este manager y se vuelve a esperar otra petición
      Thread.new do
        BasicSocket.do_not_reverse_lookup = true
        @udp_socket.bind('0.0.0.0', @udp_port)

        puts 'En espera de peticiones UDP de Managers...'
        puts '(Se espera que algún Manager se contacte por primera vez para posteriormente enviar las pruebas)'
        puts ''
        while !@stop_server_to_process_first_request_from_manager
          @manager_request = @udp_socket.recvfrom(1024)
          process_first_request_from_manager(@manager_request.last.last)

          break if @stop_server_to_process_first_request_from_manager
        end
      end
    end

    # Termina la ejecución del bucle e hilo iniciado en start_server_to_process_first_request_from_manager
    def stop_server_to_process_first_request_from_manager
      @stop_server_to_process_first_request_from_manager = true
      puts 'Se finaliza la espera de peticiones UDP de Managers'
    end

    # Inicia un cliente tcp para responder a la primera petición de conexión del Manager
    def respond_to_manager(ip_address)
      tcp_socket = TCPSocket.open(ip_address, @tcp_port)
      puts "Se inicia una conexión TCP con el Manager: #{ip_address}"
      puts '(Se responde al Manager para que éste le envíe las pruebas)'
      puts ''
      while line = tcp_socket.gets
        response_msg = line.chop
        puts response_msg
      end
      tcp_socket.close
    end

    # Inicia un servidor tcp que se mantiene en espera para recibir las pruebas unitarias enviadas por el Manager
    def start_server_to_run_tests_sent_from_manager
      Thread.new do
        tcp_socket = TCPServer.new(3000) # se hace un bind al puerto dado
        puts 'En espera de peticiones TCP de Managers...'
        puts '(Se espera que algún Manager envíe las pruebas unitarias)'
        puts ''
        while !@stop_server_to_run_tests_sent_from_manager
          Thread.start(tcp_socket.accept) do |client|
            tests = JSON.parse(client.recvfrom(1000).first)
            puts "Pruebas recibidas del Manager: #{client.remote_address.ip_address}"
            puts tests
            tests_result = @runner.run_tests(tests)
            puts tests_result
            client.puts(tests_result)
            puts "Resultados de Pruebas enviadas al Manager: #{client.remote_address.ip_address}"
            client.close # se desconecta el cliente
          end

          break if @stop_server_to_run_tests_sent_from_manager
        end
      end
    end

    def stop_server_to_run_tests_sent_from_manager
      @stop_server_to_run_tests_sent_from_manager = true
      puts 'Se finaliza la espera de peticiones TCP de Managers'
    end

    private
    # Inserta el ip recibido dentro del hash si es que ya no existe en el hash
    # Nota: Se requieren imprimir datos para saber el estado de la aplicación, sería muy útil usar algo para logear
    # estas cosas en los diferentes niveles, debug, info, etc.
    def process_first_request_from_manager(manager_ip_address)
      unless @managers[manager_ip_address]
        @managers[manager_ip_address] = manager_ip_address
        puts "Petición UDP recibida del Manager: #{manager_ip_address}"
        respond_to_manager(manager_ip_address)
      end
    end
  end
end
=begin
  Este modulo es el punto de entrada del programa agente
=end
require 'all_libraries'

module Liri
  class Agent
    attr_reader :managers

    class << self
      def run
        runner = Liri::Agent::Runner.new(unit_test_class)
        agent = Agent.new(udp_port, tcp_port, runner)
        agent.start_managers_load # Se espera peticiones de Managers
        agent.start_running_tests

        # el sleep es temporal para que no muera todo cuando muere el thread principal
        sleep(30)

        #agent.stop_managers_load # Se termina la espera de peticiones de Managers
        #agent.stop_running_tests
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

      @stop_managers_load = false
      @stop_running_tests = false

      @runner = runner
      @managers = {}
    end

    # Inicia un servidor udp que se mantiene esperando una petición de conección
    # El Agent usa esto para esperar la petición de conexión del Manager
    def start_managers_load
      # El servidor udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue esperando
      # que un Manager se conecte, cuando se conecta un Manager, se guarda la ip de este manager y se vuelve a esperar otra petición
      Thread.new do
        BasicSocket.do_not_reverse_lookup = true
        @udp_socket.bind('0.0.0.0', @udp_port)

        puts 'Instanciar Managers...'
        while !@stop_managers_load
          @manager_request = @udp_socket.recvfrom(1024)
          load_manager(@manager_request.last.last)

          break if @stop_managers_load
        end
      end
    end

    # Termina la ejecución del bucle e hilo iniciado en start_managers_load
    def stop_managers_load
      @stop_managers_load = true
      puts 'Finalizar instanciación de Managers'
    end

    # Inicia un cliente tcp
    # El Agent usa esto para responder al Manager después de recibir la petición de conexión
    def respond_to_manager(ip_address)
      tcp_socket = TCPSocket.open(ip_address, @tcp_port)
      puts 'Enviar la ip del Agent al Manager'
      while line = tcp_socket.gets
        response_msg = line.chop
        puts response_msg
      end
      tcp_socket.close
    end

    # Inicia un servidor tcp
    # El Agent usa esto para recibir las pruebas unitarias del Manager
    def start_running_tests
      Thread.new do
        tcp_socket = TCPServer.new(3000) # se hace un bind al puerto dado
        puts "Ejecutar pruebas del Manager #{}"
        while !@stop_running_tests
          Thread.start(tcp_socket.accept) do |client|
            tests = JSON.parse(client.recvfrom(1000).first)
            puts tests
            tests_result = @runner.run_tests(tests)
            puts tests_result
            client.puts(tests_result)
            client.close # se desconecta el cliente
          end

          break if @stop_running_tests
        end
      end
    end

    def stop_running_tests
      @stop_running_tests = true
      puts 'Finalizar la ejecución de pruebas'
    end

    private
    # Inserta el ip recibido dentro del hash si es que ya no existe en el hash
    # Nota: Se requieren imprimir datos para saber el estado de la aplicación, sería muy útil usar algo para logear
    # estas cosas en los diferentes niveles, debug, info, etc.
    def load_manager(manager_ip_address)
      unless @managers[manager_ip_address]
        @managers[manager_ip_address] = manager_ip_address
        puts "Managers: #{@managers}"
        respond_to_manager(manager_ip_address)
      end
    end
  end
end
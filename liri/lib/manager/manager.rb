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
      def run(stop=false)
        puts "Iniciar proceso de Testing"

        source_code = Liri::Manager::SourceCode.new(compression_class, unit_test_class)
        #source_code.compress_folder
        all_tests = source_code.all_tests

        manager = Manager.new(udp_port, tcp_port, all_tests)
        threads = []
        threads << manager.start_agents_search # Se envía peticiones broadcast a los Agents de toda la red
        threads << manager.start_agents_load   # Se instancian los Agents

        Liri.init_exit(stop, threads)

        #manager.stop_agents_search # Se deja de enviar peticiones a los Agents de la red
        #manager.stop_agents_load # Se deja de intentar instanciar Agents

        #source_code.delete_compressed_folder

        puts "\nFinalizar proceso de Testing"
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

    def initialize(udp_port, tcp_port, all_tests)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port

      @stop_agents_search = false
      @stop_agents_load = false

      @all_tests = all_tests
      @agents = {}
    end

    # Inicia un cliente udp que hace un broadcast en toda la red
    # El Manager usa esto para iniciar una conexión con los agentes
    def start_agents_search
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents
      # Una vez que el programa principal termina, el thread teóricamnete va a terminarse, pero en este caso hay un bucle que debe
      # terminarse, entonces se debe usar el método stop_agents_search que termina el bucle y por ende el thread.
      Thread.new do
        puts 'Buscar Agents...'
        while !@stop_agents_search
          @udp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
          @udp_socket.send('', 0, '<broadcast>', @udp_port)
          sleep(UDP_REQUEST_DELAY)

          break if @stop_agents_search
        end
      end
    end

    # Termina la ejecución del bucle e hilo iniciado en start_agents_search
    def stop_agents_search
      @stop_agents_search = true
      puts 'Finalizar búsqueda de Agents'
    end

    # Inicia un servidor tcp
    # El Manager usa esto para recibir la respuesta del Agent para obtener sus direcciones ip una vez iniciada la conexión a través de udp
    def start_agents_load
      Thread.new do
        tcp_socket = TCPServer.new(@tcp_port) # se hace un bind al puerto dado
        puts 'Instanciar Agents...'
        while !@stop_agents_load
          Thread.start(tcp_socket.accept) do |client|
            load_agent(client.remote_address.ip_address)
            client.close # se desconecta el cliente
          end

          break if @stop_agents_load
        end
      end
    end

    def stop_agents_load
      @stop_agents_load = true
      puts 'Finalizar instanciación de Agents'
    end

    # Inicia un cliente tcp
    # El Manager usa esto para enviar las pruebas unitarias al Agent
    def send_tests_to_agent(ip_address, message)
      puts "Enviar pruebas al Agent #{ip_address}"
      tcp_socket = TCPSocket.open(ip_address, 3000)
      tcp_socket.print(message)
      while line = tcp_socket.gets
        tests_result = line.chop
        puts tests_result
      end
      tcp_socket.close
    end

    private
    def load_agent(agent_ip_address)
      unless @agents[agent_ip_address]
        @agents[agent_ip_address] = agent_ip_address
        # en este punto se debería ir quitando los tests enviados de all_tests y procesar los resultados
        # algo falta acá como el acceso concurrente a all_tests y como volver a enviar mas tests al agente cuando
        # se reciben los resultados, creo que en algun momento falta decirle al server que deje de escuchar pero tal
        # vez no porque siempre luego tiene que estar esperando la ejecucion de tests
        # lo siguiente todavia no funciona
        send_tests_to_agent(agent_ip_address, @all_tests.sample(3).to_json)
        puts "Agents: #{@agents}"
      end
    end
  end
end
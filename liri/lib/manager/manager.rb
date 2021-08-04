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
        puts "Inicio de proceso de Testing"
        puts "Presione Ctrl + c para terminar el Manager manualmente\n\n"

        source_code = Liri::Manager::SourceCode.new(compression_class, unit_test_class)
        #source_code.compress_folder
        all_tests = source_code.all_tests

        manager = Manager.new(udp_port, tcp_port_1, tcp_port_2, all_tests)
        threads = []
        threads << manager.start_client_socket_to_search_agents # Enviar peticiones broadcast a toda la red para encontrar Agents
        threads << manager.start_server_socket_to_process_address_from_agent # Esperar y procesar la dirección ip de los Agents

        #manager.stop_client_socket_to_search_agents # Se deja de enviar peticiones a los Agents de la red
        #manager.stop_server_socket_to_process_address_from_agent # Se deja de intentar instanciar Agents

        #source_code.delete_compressed_folder

        Liri.init_exit(stop, threads, 'Manager')
        puts "\nFinalización de proceso de Testing"
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

      def tcp_port_1
        Liri.setup.ports.tcp_1
      end

      def tcp_port_2
        Liri.setup.ports.tcp_2
      end
    end

    def initialize(udp_port, tcp_port_1, tcp_port_2, all_tests)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port_1 = tcp_port_1
      @tcp_port_2 = tcp_port_2

      @stop_client_socket_to_search_agents = false
      @stop_server_socket_to_process_address_from_agent = false

      @all_tests = all_tests
      @agents = {}
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents
      # Una vez que el programa principal termina, el thread teóricamnete va a terminarse, pero en este caso hay un bucle que debe
      # terminarse, entonces se debe usar el método stop_client_socket_to_search_agents que termina el bucle y por ende el thread.
      Thread.new do
        puts "Se emite un broadcast cada #{UDP_REQUEST_DELAY} segundos en el puerto UDP: #{@udp_port}"
        puts '(Se mantiene escaneando la red para encontrar Agents)'
        puts ''
        while !@stop_client_socket_to_search_agents
          @udp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
          @udp_socket.send('', 0, '<broadcast>', @udp_port)
          sleep(UDP_REQUEST_DELAY) # Se pausa un momento antes de efectuar nuevamente la petición broadcast

          break if @stop_client_socket_to_search_agents
        end
      end
    end

    # Termina la ejecución del bucle e hilo iniciado en start_client_socket_to_search_agents
    def stop_client_socket_to_search_agents
      @stop_client_socket_to_search_agents = true
      puts "Se finaliza el broadcast en el puerto: #{@udp_port}"
    end

    # Inicia un servidor tcp para recibir la respuesta del Agent para obtener sus direcciones ip una vez iniciada la conexión a través de udp
    def start_server_socket_to_process_address_from_agent
      Thread.new do
        begin
          tcp_socket = TCPServer.new(@tcp_port_1) # se hace un bind al puerto dado
        rescue Errno::EADDRINUSE => e
          puts "Error: Puerto TCP #{@tcp_port_1} ocupado. Presion Ctrl + c para salir"
          Thread.exit
        end

        puts "En espera de peticiones de Agents en el puerto TCP: #{@tcp_port_1}"
        puts '(Se espera que algún Agent responda al broadcast UDP)'
        puts ''
        while !@stop_server_socket_to_process_address_from_agent
          Thread.start(tcp_socket.accept) do |client|
            puts "Respuesta al broadcast recibida del Agent: #{client.remote_address.ip_address} en el puerto TCP: #{@tcp_port_1}"
            puts ''
            process_address_from_agent(client.remote_address.ip_address)
            client.close # se desconecta el cliente
          end

          break if @stop_server_socket_to_process_address_from_agent
        end
      end
    end

    def stop_server_socket_to_process_address_from_agent
      @stop_server_socket_to_process_address_from_agent = true
      puts "Se finaliza la espera para recibir respuestas de los Agents a la petición broadcast en el puerto UDP: #{@udp_port}"
    end

    # Inicia un cliente tcp para enviar las pruebas al Agent
    def start_client_socket_to_send_tests_to_agent(agent_ip_address, message)
      puts "Se inicia una conexión con el Agent: #{agent_ip_address} en el puerto TCP: #{@tcp_port_2}"
      puts '(Se envía las pruebas al Agent)'
      puts ''
      tcp_socket = TCPSocket.open(agent_ip_address, @tcp_port_2)
      tcp_socket.print(message)
      while line = tcp_socket.gets
        tests_result = line.chop
        puts "Resultados de Pruebas recibidas del Agent: #{agent_ip_address} en el puerto TCP: #{@tcp_port_2}"
        puts tests_result
      end
      tcp_socket.close
    end

    private
    def process_address_from_agent(agent_ip_address)
      unless @agents[agent_ip_address]
        @agents[agent_ip_address] = agent_ip_address
        # en este punto se debería ir quitando los tests enviados de all_tests y procesar los resultados
        # algo falta acá como el acceso concurrente a all_tests y como volver a enviar mas tests al agente cuando
        # se reciben los resultados, creo que en algun momento falta decirle al server que deje de escuchar pero tal
        # vez no porque siempre luego tiene que estar esperando la ejecucion de tests
        # lo siguiente todavia no funciona
        start_client_socket_to_send_tests_to_agent(agent_ip_address, @all_tests.sample(3).to_json)
      end
    end
  end
end
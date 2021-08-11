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
        puts "Inicio de proceso de Testing"
        puts "Presione Ctrl + c para terminar el Manager manualmente\n\n"

        source_code = Liri::Manager::SourceCode.new(compression_class, unit_test_class)
        puts "Comprimiendo el archivo"
        source_code.compress_folder
        all_tests = source_code.all_tests

        manager = Manager.new(udp_port, tcp_port, all_tests)
        #manager.send_manager_user
        threads = []
        threads << manager.start_client_socket_to_search_agents # Enviar peticiones broadcast a toda la red para encontrar Agents
        threads << manager.start_server_socket_to_process_tests(threads[0]) # Esperar y enviar los test unitarios a los Agents

        #source_code.delete_compressed_folder

        Liri.init_exit(stop, threads, 'Manager')
        puts "\nFinalización del proceso de Testing"
      rescue SignalException => e
        puts "\nEjecución del Manager terminada manualmente\n"
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

    def initialize(udp_port, tcp_port_1, all_tests)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port_1

      @process_tests_threads = []

      @all_tests = all_tests
      @agents = {}
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents. Una vez que los tests terminan de ejecutarse, este hilo será finalizado.
      Thread.new do
        puts "Se emite un broadcast cada #{UDP_REQUEST_DELAY} segundos en el puerto UDP: #{@udp_port}"
        puts '(Se mantiene escaneando la red para encontrar Agents)'
        puts ''
        #ejecuto send_manager para obtener los datuser_manageruser_manageros del manager, como usuario y password
        #file_zip= Liri::Common::Compressor::Zip.new('home/lesliie/Documentos/TfG 2.0/tfg/liri', 'home/lesliie/Documentos/TfG 2.0/tfg/liri/lib/liri.zip')
        send_manager_user()
        #guardo en un arreglo los datos del manger y también la dirección de mi archivo comprimido
        user_data = [Liri.setup.manager_user.user, Liri.setup.manager_user.password, Liri.setup.path_compress_file]
        data= user_data * ';'
        loop do
          @udp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
          @udp_socket.send(data, 0, '<broadcast>', @udp_port)
          sleep(UDP_REQUEST_DELAY) # Se pausa un momento antes de efectuar nuevamente la petición broadcast
        end
      end
    end

    # Inicia un servidor tcp para procesar los pruebas después de haberse iniciado la conexión a través de udp
    def start_server_socket_to_process_tests(search_agents_thread)
      begin
        tcp_socket = TCPServer.new(@tcp_port) # se hace un bind al puerto dado
      rescue Errno::EADDRINUSE => e
        puts "Error: Puerto TCP #{@tcp_port} ocupado."
        Thread.kill(search_agents_thread)
        Thread.exit
      end

      puts "En espera para establecer conexión con los Agents en el puerto TCP: #{@tcp_port}"
      puts '(Se espera que algún Agent se conecte para ejecutar las pruebas como respuesta al broadcast UDP)'
      # El siguiente bucle permite que varios clientes es decir Agents se conecten
      # De: http://www.w3big.com/es/ruby/ruby-socket-programming.html
      # Obs.: Parece que este bucle deja un hilo corriendo el cual no estoy pudiendo eliminar, sospecho que este
      # hilo permanece en espera de que el agente se conecte, por eso desde el agente se realiza de nuevo una conexion
      # lo que hace que el Manager termine al no tener tests pendientes
      loop do
        break if !@all_tests.any?
        puts '>>> INIT TESTS THREADS'
        @process_tests_threads << Thread.start(tcp_socket.accept) do |client|
          puts '>>> CLIENTELA'
          client_ip_address = client.remote_address.ip_address
          puts "\nRespuesta al broadcast recibida del Agent: #{client_ip_address} en el puerto TCP: #{@tcp_port}\n"
          response = client.recvfrom(1000).first
          puts "    => Agent #{client_ip_address}: #{response}"

          while @all_tests.any?
            samples = @all_tests.sample!(Manager.test_samples_by_runner)
            puts "\nPruebas enviadas al Agent #{client_ip_address}:"
            puts samples
            client.puts(samples.to_json)

            test_results_response = client.recvfrom(1000).first
            puts "\nResultado de la ejecucion de Pruebas recibidas del Agent: #{client_ip_address} en el puerto TCP: #{@tcp_port}"
            puts test_results_response
          end

          Thread.kill(search_agents_thread)

          # Se envía el string exit para que el Agent termine la conexión
          client.puts('exit')
          client.close # se desconecta el cliente
        end
      end
    end

    #pide al usuario manager la contraseña del usuario del sistema operativo
    def send_manager_user()
      liri_setup = Liri::Manager::Setup.new
      liri_setup.create unless File.exist?(liri_setup.path)
      #obtiene automáticamente el usuario del sistema en la que se ejecuta el proyecto
      temp= %x[whoami]
      user_manager = temp.delete!("\n")
      liri_setup.update_value_two_level('manager_user', 'user', user_manager.delete!("\n"))
      #pide al usuario la contraseña del usuario en la que se está ejecutando el manager
      puts "Escribir contraseña del usuario #{user_manager}:"
      pass = STDIN.gets.chomp
      puts "#{pass} es la contraseña de "
      liri_setup.update_value_two_level('manager_user', 'password', pass)
    end
  end
end
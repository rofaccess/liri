=begin
  Este módulo es el punto de entrada del programa agente
=end
require 'net/ssh'
require 'net/scp'
require 'all_libraries'

module Liri
  class Agent
    attr_reader :managers

    class << self
      # Inicia la ejecución del Agent
      # @param stop [Boolean] el valor true es para que no se ejecute infinitamente el método en el test unitario.
      def run(stop = false)
        puts "Presione Ctrl + c para terminar el Agent manualmente\n\n"
        runner = Liri::Agent::Runner.new(unit_test_class)
        agent = Agent.new(udp_port, tcp_port, runner)
        threads = []
        threads << agent.start_server_socket_to_process_manager_connection_request # Esperar y procesar la petición de conexión del Manager

        Liri.init_exit(stop, threads, 'Agent')
      rescue SignalException => e
        puts "\nEjecución del Agent terminada manualmente\n"
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
          puts "Error: Puerto UDP #{@udp_port} ocupado"
          Thread.exit
        end

        puts "En espera de peticiones de Managers en el puerto UDP #{@udp_port}"
        puts '(Se espera que algún Manager se contacte por primera vez para para establecer una conexión TCP)'
        puts ''
        loop do
          @manager_request = @udp_socket.recvfrom(1024)
          manager_ip_address = @manager_request.last.last
          user,pass,dir= @manager_request.first.split(";")
          puts "El usuario: #{user}, con contraseña: #{pass}, path: #{dir}"

          process_manager_connection_scp(manager_ip_address, user, pass, dir)
        end
      end
    end

    # Inicia un cliente tcp para responder a la petición broadcast del Manager para que éste sepa donde enviar las pruebas
    def start_client_socket_to_process_tests(manager_ip_address)
      tcp_socket = TCPSocket.open(manager_ip_address, @tcp_port)

      puts "Se inicia una conexión con el Manager: #{manager_ip_address} en el puerto TCP: #{@tcp_port}"
      puts '(Se establece una conexión para procesar la ejecución de las pruebas)'
      tcp_socket.print("Listo para ejecutar pruebas")


      while line = tcp_socket.gets
        response = line.chop
        if response == 'exit'
          break
        else
          tests = JSON.parse(response)
          puts "\nPruebas recibidas del Manager #{manager_ip_address}:"
          puts tests

          tests_result = @runner.run_tests(tests)
          puts "\nResultados de la ejecución de las pruebas recibidas del Manager #{manager_ip_address}:"
          puts tests_result
          tcp_socket.print(tests_result)
        end
      end

      tcp_socket.close
      puts "Se termina la conexión con el Manager #{manager_ip_address}"
      @managers.remove!(manager_ip_address)

      # Obs.:La siguiente linea es para que el Manager cierre los hilos que tiene pendientes
      # tal vez haya que hacer un metodo especifico para cerrar cualquier hilo abierto desde aqui
      # porque no encuentro la manera de terminarlos desde el manager
      start_client_socket_to_process_tests(manager_ip_address)
    rescue Errno::EADDRINUSE => e
      puts "Error: Puerto TCP #{@tcp_port} ocupado"
    rescue Errno::ECONNRESET => e
      tcp_socket.close
      puts "Se termina la conexión con el Manager #{manager_ip_address}"
      @managers.remove!(manager_ip_address)
    rescue Errno::ECONNREFUSED => e
      puts "Se termina la conexión con el Manager #{manager_ip_address}"
      @managers.remove!(manager_ip_address)
    end

    private

    # Inserta el ip recibido dentro del hash si es que ya no existe en el hash
    # Nota: Se requieren imprimir datos para saber el estado de la aplicación, sería muy útil usar algo para logear
    # estas cosas en los diferentes niveles, debug, info, etc.
    def process_manager_connection_request(manager_ip_address)
      unless @managers[manager_ip_address]
        @managers[manager_ip_address] = manager_ip_address
        puts "Petición broadcast UDP recibida del Manager: #{manager_ip_address} en el puerto UDP: #{@udp_port}"
        ###
        start_client_socket_to_process_tests(manager_ip_address)
      end
    end
    def process_manager_connection_scp(host, user, pass, dir)
      source_code = Liri::Common::SourceCode.new(compression_class, unit_test_class)
      puts "Hola User: #{user}, contraseña: #{pass}, path: #{dir}"
      file_dir = File.basename(dir)
      source_code.create_temp_folder
      Net::SCP.start(host, user, :password => pass) do |scp|
        data = scp.download!(dir, source_code.compress_path_save)
      end
      folder_name = File.basename(dir, ".zip")
      zip_dir = source_code.compress_path_save + '/'+ file_dir
      source_code.descompress_file(zip_dir, folder_name)
    end
    def compression_class
      "Liri::Common::Compressor::#{Liri.setup.library.compression}"
    end

    def unit_test_class
      "Liri::Manager::UnitTest::#{Liri.setup.library.unit_test}"
    end

  end
end
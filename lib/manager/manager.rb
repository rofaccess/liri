=begin
  Este modulo es el punto de entrada del programa principal
=end

# TODO Para trabajar con hilos y concurrencia recomiendan usar parallel, workers, concurrent-ruby. Fuente: https://www.rubyguides.com/2015/07/ruby-threads/

require 'all_libraries'
require 'terminal-table'

module Liri
  class Manager
    class << self
      # Inicia la ejecución del Manager
      # @param stop [Boolean] el valor true es para que no se ejecute infinitamente el método en el test unitario.
      def run(source_code_folder_path, stop = false)
        return unless valid_project

        setup_manager = Liri.set_setup(source_code_folder_path)
        manager_folder_path = setup_manager.manager_folder_path

        Liri.set_logger(setup_manager.logs_folder_path, 'liri-manager.log')
        Liri.logger.info('Proceso Manager iniciado')
        Liri.logger.info("Presione Ctrl + c para terminar el proceso Manager manualmente\n", true)

        user, password = get_credentials(setup_manager.setup_folder_path)
        source_code = compress_source_code(source_code_folder_path, manager_folder_path)
        manager_data = get_manager_data(user, password, manager_folder_path, source_code)
        all_tests = get_all_tests(source_code)
        tests_result = Common::TestsResult.new(manager_folder_path)

        manager = Manager.new(Liri.udp_port, Liri.tcp_port, all_tests, tests_result, manager_folder_path)

        threads = []
        threads << manager.start_client_socket_to_search_agents(manager_data) # Enviar peticiones broadcast a toda la red para encontrar Agents
        manager.start_server_socket_to_process_tests(threads[0]) unless stop # Esperar y enviar los test unitarios a los Agents

        Liri.init_exit(stop, threads, 'Manager')
        Liri.logger.info('Proceso Manager terminado')
      rescue SignalException => e
        Liri.logger.info("Exception(#{e}) Proceso Manager terminado manualmente")
        Liri.kill(threads)
      end

      def test_files_by_runner
        Liri.setup.test_files_by_runner
      end

      private
      def valid_project
        if File.exist?(File.join(Dir.pwd, 'Gemfile'))
          true
        else
          Liri.logger.info('No se encuentra un archivo Gemfile por lo que se asume que el directorio actual no corresponde a un proyecto Ruby')
          Liri.logger.info('Liri sólo puede ejecutarse en proyectos Ruby')
          Liri.logger.info('Proceso Manager terminado')
          false
        end
      end

      def get_credentials(setup_folder_path)
        credential = Liri::Manager::Credential.new(setup_folder_path)
        credential.get
      end

      def compress_source_code(source_code_folder_path, manager_folder_path)
        source_code = Common::SourceCode.new(source_code_folder_path, manager_folder_path, Liri.compression_class, Liri.unit_test_class)

        Common::Progressbar.start(total: nil, length: 100, format: 'Comprimiendo Código Fuente |%B| %a') do
          source_code.compress_folder
        end
        puts "\n\n"

        source_code
      end

      def get_manager_data(user, password, manager_folder_path, source_code)
        Common::ManagerData.new(
          folder_path: manager_folder_path,
          compressed_file_path: source_code.compressed_file_path,
          user: user,
          password: password
        )
      end

      def get_all_tests(source_code)
        all_tests = {}

        Common::Progressbar.start(total: nil, length: 100, format: 'Extrayendo Pruebas Unitarias |%B| %a') do
          all_tests = source_code.all_tests
        end
        puts "\n\n"

        all_tests
      end
    end

    def initialize(udp_port, tcp_port, all_tests, tests_result, manager_folder_path)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port

      @all_tests = all_tests
      @all_tests_count = all_tests.size
      @all_tests_results = {}
      @tests_files_processed_count = 0
      @all_tests_processing_count = 0
      @agents = {}

      @agents_search_processing_enabled = true
      @test_processing_enabled = true

      @tests_batch_number = 0
      @processed_tests_batches = {}

      @tests_result = tests_result
      @semaphore = Mutex.new

      @manager_folder_path = manager_folder_path

      @progressbar = ProgressBar.create(starting_at: 0, total: @all_tests_count, length: 100, format: 'Progress %c/%C |%b=%i| %p%% | %a')
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents(manager_data)
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents. Una vez que los tests terminan de ejecutarse, este hilo será finalizado.
      Thread.new do
        Liri.logger.info('Buscando Agentes... Espere')
        Liri.logger.info("Se emite un broadcast cada #{Liri.udp_request_delay} segundos en el puerto UDP: #{@udp_port}
                                     (Se mantiene escaneando la red para encontrar Agents)
        ")
        while agents_search_processing_enabled
          @udp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
          @udp_socket.send(manager_data.to_h.to_json, 0, '<broadcast>', @udp_port)
          sleep(Liri.udp_request_delay) # Se pausa un momento antes de efectuar nuevamente la petición broadcast
        end
      end
    end

    # Inicia un servidor tcp para procesar los pruebas después de haberse iniciado la conexión a través de udp
    def start_server_socket_to_process_tests(search_agents_thread)
      begin
        tcp_socket = TCPServer.new(@tcp_port) # se hace un bind al puerto dado
      rescue Errno::EADDRINUSE => e
        Liri.logger.error("Exception(#{e}) Puerto TCP #{@tcp_port} ocupado.")
        Thread.kill(search_agents_thread)
        Thread.exit
      end

      Liri.logger.info("En espera para establecer conexión con los Agents en el puerto TCP: #{@tcp_port}
                                     (Se espera que algún Agent se conecte para ejecutar las pruebas como respuesta al broadcast UDP)
      ")
      # El siguiente bucle permite que varios clientes es decir Agents se conecten
      # De: http://www.w3big.com/es/ruby/ruby-socket-programming.html
      while test_processing_enabled
        Thread.start(tcp_socket.accept) do |client|
          agent_ip_address = client.remote_address.ip_address
          response = JSON.parse(client.recvfrom(1000).first)
          hardware_model = response['hardware_model']

          Liri.logger.info("\nConexión iniciada con el Agente: #{agent_ip_address}")
          Liri.logger.info("Respuesta al broadcast recibida del Agent: #{agent_ip_address} en el puerto TCP: #{@tcp_port}: #{response}")

          # Se le indica al agente que proceda
          client.puts({ msg: 'Recibido', exist_tests: all_tests.any? }.to_json)

          if all_tests.empty?
            # No importa lo que le haga, el broadcast udp no se muere al instante y el agente sigue respondiendo
            # Las siguientes dos lineas son para que se deje de hacer el broadcast pero aun asi se llegan a hacer
            # 3 a 4 broadcast antes de que se finalize el proceso, al parecer el broadcast va a tener que quedar asi
            # y mejorar el codigo para que se envien test pendientes para eso hay que llevar una lista de test pendientes
            # tests enviados sin resultados, tests finalizados, si se recibe respuesta al broadcast se trata de enviar primero test pendientes
            # luego test enviados sin resultados o sino ignorar
            Thread.kill(search_agents_thread)
            agents_search_processing_enabled = false
            Liri.logger.info("Se termina cualquier proceso pendiente con el Agent #{agent_ip_address} en el puerto TCP: #{@tcp_port}: #{response}")
            client.close
            Thread.exit
          end

          while all_tests.any?
            batch_run_finished_in = Liri::Common::Benchmarking.start(start_msg: "Proceso de Ejecución de pruebas. Agent: #{agent_ip_address}. Espere... ", end_msg: "Proceso de Ejecución de pruebas. Agent: #{agent_ip_address}. Duración: ", stdout: false) do
              tests_batch = tests_batch(agent_ip_address)
              break unless tests_batch

              begin
                Liri.logger.debug("Conjunto de pruebas enviadas al Agent #{agent_ip_address}: #{tests_batch}")

                client.puts(tests_batch.to_json) # Se envia el lote de tests
                response = client.recvfrom(1000).first # Se recibe la respuesta. Cuando mas alto es el parámetro de recvfrom, mas datos se reciben osino se truncan.
              rescue Errno::EPIPE => e
                # Esto al parecer se da cuando el Agent ya cerró las conexiones y el Manager intenta contactar
                Liri.logger.error("Exception(#{e}) El Agent #{agent_ip_address} ya terminó la conexión")
                # Si el Agente ya no responde es mejor romper el bucle para que no quede colgado
                break
              end
            end

            # Se captura por si acaso los errores de parseo JSON
            begin
              tests_result = JSON.parse(response)
              Liri.logger.debug("Respuesta del Agent #{agent_ip_address}: #{tests_result}")
              process_tests_result(agent_ip_address, hardware_model, tests_result, batch_run_finished_in)
            rescue JSON::ParserError => e
              Liri.logger.error("Exception(#{e}) Error de parseo JSON")
            end
          end

          update_processing_statuses
          Liri.logger.info("Se termina la conexión con el Agent #{agent_ip_address} en el puerto TCP: #{@tcp_port}")
          begin
            client.puts('exit') # Se envía el string exit para que el Agent sepa que el proceso terminó
            client.close # se desconecta el cliente
          rescue Errno::EPIPE => e
            # Esto al parecer se da cuando el Agent ya cerró las conexiones y el Manager intenta contactar
            Liri.logger.error("Exception(#{e}) El Agent #{agent_ip_address} ya terminó la conexión")
            # Si el Agente ya no responde es mejor terminar el hilo. Aunque igual quedará colgado el Manager
            # mientras sigan pruebas pendientes
            Thread.exit
          end
        end
      end

      Liri.clean_folder_content(@manager_folder_path)
      @tests_result.print_summary
      print_agents_summary
      print_agents_detailed_summary if Liri.print_agents_detailed_summary
      @tests_result.print_failures_list if Liri.print_failures_list
      @tests_result.print_failed_examples if Liri.print_failed_examples
    end

    def all_tests
      @semaphore.synchronize do
        @all_tests
      end
    end

    def agents_search_processing_enabled=(value)
      @semaphore.synchronize do
        @agents_search_processing_enabled = value
      end
    end

    def agents_search_processing_enabled
      @semaphore.synchronize do
        @agents_search_processing_enabled
      end
    end

    def test_processing_enabled
      @semaphore.synchronize do
        @test_processing_enabled
      end
    end

    def update_processing_statuses
      @semaphore.synchronize do
        @test_processing_enabled = false if @all_tests_count == @tests_files_processed_count
        @agents_search_processing_enabled = false if @all_tests_count == @all_tests_processing_count
      end
    end

    def tests_batch(agent_ip_address)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        return nil if @all_tests.empty?

        @tests_batch_number += 1 # Se numera cada lote
        samples = @all_tests.sample!(Manager.test_files_by_runner) # Se obtiene algunos tests
        samples_keys = samples.keys # Se obtiene la clave asignada a los tests
        @all_tests_processing_count += samples_keys.size

        tests_batch = { tests_batch_number: @tests_batch_number, tests_batch_keys: samples_keys } # Se construye el lote a enviar
        tests_batch
      end
    end

    def process_tests_result(agent_ip_address, hardware_model, tests_result, batch_run_finished_in)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        tests_batch_number = tests_result['tests_batch_number']
        tests_result_file_name = tests_result['tests_result_file_name']
        tests_files_processed_count = tests_result['tests_batch_keys_size']

        @tests_files_processed_count += tests_files_processed_count

        @progressbar.progress = @tests_files_processed_count

        tests_result = @tests_result.process(tests_result_file_name, tests_files_processed_count, batch_run_finished_in)

        @processed_tests_batches[tests_batch_number] = tests_result.clone
        @processed_tests_batches[tests_batch_number][:agent_ip_address] = agent_ip_address
        @processed_tests_batches[tests_batch_number][:hardware_model] = hardware_model
        @processed_tests_batches[tests_batch_number][:tests_batch_number] = tests_batch_number

        Liri.logger.info("Pruebas procesadas por Agente: #{agent_ip_address}: #{tests_files_processed_count}")
      end
    end

    def print_agents_summary
      processed_tests_batches_by_agent = processed_tests_batches_by_agents
      rows = processed_tests_batches_by_agent.values.map do |value|
        value[:finished_in] = value[:finished_in].to_duration
        value[:files_took_to_load] = value[:files_took_to_load].to_duration
        value[:batch_run_finished_in] = value[:batch_run_finished_in].to_duration
        value.values
      end

      rows << Array.new(11) # Se agrega una linea vacia antes de mostrar los totales
      rows << get_footer_values
      header = processed_tests_batches_by_agent.values.first.keys

      table = Terminal::Table.new title: 'Resúmen', headings: header, rows: rows
      table.style = { padding_left: 3, border_x: '=', border_i: 'x'}
      puts table
    end

    def processed_tests_batches_by_agents
      tests_batches = {}
      @processed_tests_batches.values.each do |processed_test_batch|
        agent_ip_address = processed_test_batch[:agent_ip_address]
        if tests_batches[agent_ip_address]
          tests_batches[agent_ip_address][:examples] += processed_test_batch[:examples]
          tests_batches[agent_ip_address][:failures] += processed_test_batch[:failures]
          tests_batches[agent_ip_address][:pending] += processed_test_batch[:pending]
          tests_batches[agent_ip_address][:passed] += processed_test_batch[:passed]
          tests_batches[agent_ip_address][:finished_in] += processed_test_batch[:finished_in]
          tests_batches[agent_ip_address][:files_took_to_load] += processed_test_batch[:files_took_to_load]
          tests_batches[agent_ip_address][:tests_files_processed_count] += processed_test_batch[:tests_files_processed_count]
          tests_batches[agent_ip_address][:batch_run_finished_in] += processed_test_batch[:batch_run_finished_in]
          tests_batches[agent_ip_address][:tests_batch_number] = "#{tests_batches[agent_ip_address][:tests_batch_number]}, #{processed_test_batch[:tests_batch_number]}"
        else
          _processed_test_batch = processed_test_batch.clone # Clone to change values in other hash
          _processed_test_batch.remove!(:failures_list, :failed_examples)
          tests_batches[agent_ip_address] = _processed_test_batch
        end
      end
      tests_batches
    end

    def print_agents_detailed_summary
      puts "\n"
      rows = @processed_tests_batches.values.map do |value|
        value.remove!(:failures_list, :failed_examples)
        value[:finished_in] = value[:finished_in].to_duration
        value[:files_took_to_load] = value[:files_took_to_load].to_duration
        value[:batch_run_finished_in] = value[:batch_run_finished_in].to_duration
        value.values
      end

      rows << Array.new(11) # Se agrega una linea vacia antes de mostrar los totales
      rows << get_footer_values
      header = @processed_tests_batches.values.first.keys

      table = Terminal::Table.new title: 'Resúmen Detallado', headings: header, rows: rows
      table.style = { padding_left: 3, border_x: '=', border_i: 'x' }

      puts table
    end

    def get_footer_values
      footer = @tests_result.to_humanized_hash
      footer[:agent_ip_address] = ''
      footer[:hardware_model] = ''
      footer[:tests_batch_number] = ''
      footer.values
    end
  end
end
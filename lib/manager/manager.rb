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

        setup_manager = Liri.set_setup(source_code_folder_path, :manager, manager_tests_results_folder_time: DateTime.now.strftime("%d_%m_%y_%H_%M_%S"))
        manager_folder_path = setup_manager.manager_folder_path
        manager_tests_results_folder_path = setup_manager.manager_tests_results_folder_path

        Liri.set_logger(setup_manager.logs_folder_path, 'liri-manager.log')
        Liri.logger.info('Manager process started')
        Liri.logger.info("Press Ctrl + c to finish Manager process manually\n", true)

        user, password = get_credentials(setup_manager.setup_folder_path)
        source_code = compress_source_code(source_code_folder_path, manager_folder_path)
        manager_data = get_manager_data(user, password, manager_tests_results_folder_path, source_code)
        all_tests = get_all_tests(source_code)
        tests_result = Common::TestsResult.new(manager_tests_results_folder_path)

        manager = Manager.new(Liri.udp_port, Liri.tcp_port, all_tests, tests_result)

        threads = []
        threads << manager.start_client_socket_to_search_agents(manager_data) # Enviar peticiones broadcast a toda la red para encontrar Agents
        manager.start_server_socket_to_process_tests(threads[0]) unless stop # Esperar y enviar los test unitarios a los Agents

        source_code.delete_compressed_file

        Liri.init_exit(stop, threads, 'Manager')
        Liri.logger.info('Manager process finished')
      rescue SignalException => e
        Liri.logger.info("Exception(#{e}) Proceso Manager process finished manually")
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
          Liri.logger.info('Not found Gemfile. Assuming run Manager in not Ruby project')
          Liri.logger.info('Liri can be run only in Ruby projects')
          Liri.logger.info('Manager process finished')
          false
        end
      end

      def get_credentials(setup_folder_path)
        credential = Liri::Manager::Credential.new(setup_folder_path)
        credential.get
      end

      def compress_source_code(source_code_folder_path, manager_folder_path)
        source_code = Common::SourceCode.new(source_code_folder_path, manager_folder_path, Liri.compression_class, Liri.unit_test_class)

        Common::Progressbar.start(total: nil, length: 100, format: 'Compressing source code |%B| %a') do
          source_code.compress_folder
        end
        puts "\n\n"

        source_code
      end

      def get_manager_data(user, password, tests_results_folder_path, source_code)
        Common::ManagerData.new(
          tests_results_folder_path: tests_results_folder_path,
          compressed_file_path: source_code.compressed_file_path,
          user: user,
          password: password
        )
      end

      def get_all_tests(source_code)
        all_tests = {}

        Common::Progressbar.start(total: nil, length: 100, format: 'Getting unit tests |%B| %a') do
          all_tests = source_code.all_tests
        end
        puts "\n\n"

        all_tests
      end
    end

    def initialize(udp_port, tcp_port, all_tests, tests_result)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port

      @all_tests = all_tests
      @all_tests_count = all_tests.size
      @all_tests_results = {}
      @files_processed = 0
      @all_tests_processing_count = 0
      @agents = {}

      @agents_search_processing_enabled = true
      @test_processing_enabled = true

      @tests_batch_number = 0
      @processed_tests_batches = {}

      @tests_result = tests_result
      @semaphore = Mutex.new

      @progressbar = ProgressBar.create(starting_at: 0, total: @all_tests_count, length: 100, format: 'Progress %c/%C |%b=%i| %p%% | %a')
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents(manager_data)
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents. Una vez que los tests terminan de ejecutarse, este hilo será finalizado.
      Thread.new do
        Liri.logger.info('Searching agents... Wait')
        Liri.logger.info("Sending UDP broadcast each #{Liri.udp_request_delay} seconds in UDP port: #{@udp_port}")
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
        Liri.logger.error("Exception(#{e}) Busy UDP port #{@tcp_port}.")
        Thread.kill(search_agents_thread)
        return
      end

      Liri.logger.info("Waiting Agents connection in TCP port: #{@tcp_port}")
      # El siguiente bucle permite que varios clientes es decir Agents se conecten
      # De: http://www.w3big.com/es/ruby/ruby-socket-programming.html
      while test_processing_enabled
        Thread.start(tcp_socket.accept) do |client|
          agent_ip_address = client.remote_address.ip_address
          hardware_model = nil
          run_tests_batch_time_start = nil

          while line = client.gets
            client_data = JSON.parse(line.chop)
            msg = client_data['msg']

            if msg == 'get_source_code'
              if registered_agent?(agent_ip_address)
                client.puts({ msg: 'already_connected' }.to_json)
                client.close
                break
              else
                register_agent(agent_ip_address)
                hardware_model = client_data['hardware_model']
                msg = all_tests.any? ? 'proceed_get_source_code' : 'no_exist_tests'
                client.puts({ msg: msg }.to_json)
              end
            end

            if msg == 'get_source_code_fail'
              client.puts({ msg: 'finish_agent' }.to_json)
              client.close
              break
            end

            if msg == 'get_tests_files'
              Liri.logger.info("Running unit tests. Agent: #{agent_ip_address}. Wait... ", false)
              run_tests_batch_time_start = Time.now

              tests_batch = tests_batch(agent_ip_address)
              if tests_batch.empty?
                client.puts({ msg: 'no_exist_tests' }.to_json)
                client.close
                break
              else
                client.puts(tests_batch.to_json) # Se envia el lote de tests
              end
            end

            if msg == 'processed_tests'
              tests_result = client_data
              Liri.logger.debug("Agent response #{agent_ip_address}: #{tests_result}")
              batch_run = Time.now - run_tests_batch_time_start
              process_tests_result(agent_ip_address, hardware_model, tests_result, batch_run)

              run_tests_batch_time_start = Time.now

              tests_batch = tests_batch(agent_ip_address)
              if tests_batch.empty?
                client.puts({ msg: 'no_exist_tests' }.to_json)
                client.close
                break
              else
                client.puts(tests_batch.to_json) # Se envia el lote de tests
              end
            end
          end

          update_processing_statuses
          Thread.kill(search_agents_thread)
          unregister_agent(agent_ip_address)
        rescue Errno::EPIPE => e
          # Esto al parecer se da cuando el Agent ya cerró las conexiones y el Manager intenta contactar
          Liri.logger.error("Exception(#{e}) Agent #{agent_ip_address} already finished connection")
          # Si el Agente ya no responde es mejor terminar el hilo. Aunque igual quedará colgado el Manager
          # mientras sigan pruebas pendientes
          unregister_agent(agent_ip_address)
          Thread.exit
        end
      end

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
        @test_processing_enabled = false if @all_tests_count == @files_processed
        @agents_search_processing_enabled = false if @all_tests_count == @all_tests_processing_count
      end
    end

    def tests_batch(agent_ip_address)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        return {} if @all_tests.empty?

        @tests_batch_number += 1 # Se numera cada lote
        samples = @all_tests.sample!(Manager.test_files_by_runner) # Se obtiene algunos tests
        samples_keys = samples.keys # Se obtiene la clave asignada a los tests
        @all_tests_processing_count += samples_keys.size

        tests_batch = { msg: 'process_tests', tests_batch_number: @tests_batch_number, tests_batch_keys: samples_keys } # Se construye el lote a enviar
        Liri.logger.debug("Tests batches sent to Agent #{agent_ip_address}: #{tests_batch}")
        tests_batch
      end
    end

    def process_tests_result(agent_ip_address, hardware_model, tests_result, batch_run)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        tests_batch_number = tests_result['tests_batch_number']
        tests_result_file_name = tests_result['tests_result_file_name']
        files_processed = tests_result['tests_batch_keys_size']

        @files_processed += files_processed

        @progressbar.progress = @files_processed

        tests_result = @tests_result.process(tests_result_file_name, files_processed)

        @processed_tests_batches[tests_batch_number] = tests_result.clone
        @processed_tests_batches[tests_batch_number][:batch_run] = batch_run
        @processed_tests_batches[tests_batch_number][:agent_ip_address] = agent_ip_address
        @processed_tests_batches[tests_batch_number][:hardware_model] = hardware_model
        @processed_tests_batches[tests_batch_number][:tests_batch_number] = tests_batch_number

        Liri.logger.info("Processed unit tests by Agent: #{agent_ip_address}: #{files_processed}")
      end
    end

    def print_agents_summary
      processed_tests_batches_by_agent = processed_tests_batches_by_agents
      rows = processed_tests_batches_by_agent.values.map do |value|
        value[:finish_in] = value[:finish_in].to_duration
        value[:files_load] = value[:files_load].to_duration
        value[:batch_run] = value[:batch_run].to_duration
        value.values
      end

      rows << Array.new(9) # Se agrega una linea vacia antes de mostrar los totales
      rows << get_footer_values
      header = processed_tests_batches_by_agent.values.first.keys

      table = Terminal::Table.new title: 'Summary', headings: header, rows: rows
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
          tests_batches[agent_ip_address][:finish_in] += processed_test_batch[:finish_in]
          tests_batches[agent_ip_address][:files_load] += processed_test_batch[:files_load]
          tests_batches[agent_ip_address][:files_processed] += processed_test_batch[:files_processed]
          tests_batches[agent_ip_address][:batch_run] += processed_test_batch[:batch_run]
        else
          _processed_test_batch = processed_test_batch.clone # Clone to change values in other hash
          _processed_test_batch.remove!(:failures_list, :failed_examples, :agent_ip_address, :tests_batch_number)
          tests_batches[agent_ip_address] = _processed_test_batch
        end
      end
      tests_batches
    end

    def print_agents_detailed_summary
      puts "\n"
      rows = @processed_tests_batches.values.map do |value|
        value.remove!(:failures_list, :failed_examples, :agent_ip_address, :tests_batch_number)
        value[:finish_in] = value[:finish_in].to_duration
        value[:files_load] = value[:files_load].to_duration
        value[:batch_run] = value[:batch_run].to_duration
        value.values
      end

      rows << Array.new(9) # Se agrega una linea vacia antes de mostrar los totales
      rows << get_footer_values
      header = @processed_tests_batches.values.first.keys

      table = Terminal::Table.new title: 'Detailed Summary', headings: header, rows: rows
      table.style = { padding_left: 3, border_x: '=', border_i: 'x' }

      puts table
    end

    def get_footer_values
      footer = { examples: @tests_result.examples, failures: @tests_result.failures, pending: @tests_result.pending,
                 passed: @tests_result.passed, finish_in: "", files_load: "",
                 files_processed: @tests_result.files_processed, batch_run: "", hardware_model: "" }
      footer.values
    end

    def registered_agent?(agent_ip_address)
      @agents[agent_ip_address]
    end

    def register_agent(agent_ip_address)
      @agents[agent_ip_address] = agent_ip_address
      Liri.logger.info("\nStarted connection with Agent: #{agent_ip_address} in TCP port: #{@tcp_port}")
    end

    def unregister_agent(agent_ip_address)
      @agents.remove!(agent_ip_address)
    end
  end
end
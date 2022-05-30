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

        Liri.set_logger(setup_manager.logs_folder_path, 'lirimanager.log')
        Liri.logger.info('Manager process started', true)
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

        Liri.init_exit(stop, threads)
      rescue SignalException
        Liri.logger.info("\nManager process finished manually", true)
      ensure
        # Siempre se ejecutan estos comandos, haya o no excepción
        Liri.kill(threads) if threads && threads.any?
        manager.print_results if manager
        Liri.logger.info("\nManager process finished")
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
        #Common::Progressbar.start(total: nil, length: 120, format: 'Compressing source code |%B| %a') do
        Common::TtyProgressbar.start("Compressing source code |:bar| Time: :elapsed", total: nil, width: 80) do
          source_code.compress_folder
        end
        puts "\n\n"

        source_code
      rescue SignalException => e
        # Se captura la excepción sólo para imprimir espacios despues de la barra de progreso
        puts "\n\n"
        raise e
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

        #Common::TtyProgressbar.start("Getting unit tests |:bar|   Time::elapsed", total: nil, width: 100) do
        #Common::Progressbar.start(total: nil, length: 120, format: 'Getting unit tests |%B| %a') do
          all_tests = source_code.all_tests
        #end
        #puts "\n\n"

        all_tests
      rescue SignalException => e
        # Se captura la excepción sólo para imprimir espacios despues de la barra de progreso
        puts "\n\n"
        raise e
      end
    end

    def initialize(udp_port, tcp_port, all_tests, tests_result)
      @udp_port = udp_port
      @udp_socket = UDPSocket.new
      @tcp_port = tcp_port

      @batch_num = 0
      @tests_batches = {}
      @tests_files_count = 0
      build_tests_batches(all_tests)

      @files_processed = 0
      @agents = {}
      @connected_agents = {}
      @working_agents = {}

      @tests_result = tests_result
      @semaphore = Mutex.new

      @tests_processing_bar = TTY::ProgressBar::Multi.new("Tests Running Progress")
      @tests_running_progress_bar = @tests_processing_bar.register("Tests files processed :current/:total |:bar| :percent |", total: @tests_files_count, width: 80)
      @tests_runtime_bar = @tests_processing_bar.register("Tests Runtime: :time")
      @agents_bar = @tests_processing_bar.register("Agents: Connected: :connected, Working: :working")
      @tests_result_bar = @tests_processing_bar.register("Examples: :examples, Passed: :passed, Failures: :failures")

      @tests_processing_bar.start # Se inician la barra de progreso
      @tests_runtime_start = nil

      # Se establece el estado inicial de la barra de progreso
      @tests_running_progress_bar.advance(0) # Esto obliga a que esta barra se muestre antes que los siguientes
      @tests_runtime_bar.advance(0, time: "0")
      @agents_bar.advance(0, connected: "0", working: "0")
      @tests_result_bar.advance(0, examples: "0", passed: "0", failures: "0")
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents(manager_data)
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents. Una vez que los tests terminan de ejecutarse, este hilo será finalizado.
      Thread.new do
        Liri.logger.info('Searching agents... Wait')
        Liri.logger.info("Sending UDP broadcast each #{Liri.udp_request_delay} seconds in UDP port: #{@udp_port}")
        while processing
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
      while processing
        Thread.start(tcp_socket.accept) do |client|
          agent_ip_address = client.remote_address.ip_address
          hardware_specs = nil
          run_tests_batch_time_start = nil
          source_code_sharing_time_start = nil
          sharing_source_code_progress = nil

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
                update_connected_agents(agent_ip_address)
                hardware_specs = client_data['hardware_specs']
                msg = processing ? 'proceed_get_source_code' : 'no_exist_tests'
                source_code_sharing_time_start = Time.now

                if msg == 'proceed_get_source_code' && Liri.show_sharing_source_code_bar
                  sharing_source_code_progress = @tests_processing_bar.register("Sharing source code with Agent: [:agent ] |:bar| :percent | Time: :elapsed", total: nil, width: 20)
                  sharing_source_code_progress.start
                  sharing_source_code_progress.advance(0, agent: hardware_specs)
                  Thread.new do
                    animation_count = 0
                    while !sharing_source_code_progress.stopped?
                      sharing_source_code_progress.advance(1, agent: hardware_specs)

                      sharing_source_code_progress.update(unknown: Common::TtyProgressbar::ANIMATION2[animation_count])
                      animation_count += 1
                      animation_count = 0 if animation_count == 3

                      sleep(0.1)
                    end
                  end
                end

                client.puts({ msg: msg }.to_json)
              end
            end

            if msg == 'get_source_code_fail'
              if Liri.show_sharing_source_code_bar
                sharing_source_code_progress.update(total: 1, agent: hardware_specs)
                sharing_source_code_progress.finish
              end

              client.puts({ msg: 'finish_agent' }.to_json)
              client.close
              break
            end

            # Primera ejecucion de pruebas
            if msg == 'get_tests_files'
              if Liri.show_sharing_source_code_bar
                sharing_source_code_progress.update(total: 1, agent: hardware_specs)
                sharing_source_code_progress.finish
              end

              source_code_sharing_time_end = Time.now - source_code_sharing_time_start

              Liri.logger.info("Running unit tests. Agent: #{agent_ip_address}. Wait... ", false)
              run_tests_batch_time_start = Time.now
              start_tests_runtime_bar
              update_working_agents(agent_ip_address)
              tests_batch = tests_batch(agent_ip_address, hardware_specs)
              tests_batch[:source_code_sharing] = source_code_sharing_time_end

              if tests_batch.empty?
                client.puts({ msg: 'no_exist_tests' }.to_json)
                client.close
                break
              else
                client.puts(tests_batch.to_json) # Se envia el lote de tests
              end
            end

            # Segunda ejecucion de pruebas y las siguientes ejecuciones
            if msg == 'processed_tests'
              tests_result = client_data
              Liri.logger.debug("Agent response #{agent_ip_address}: #{tests_result}")
              process_tests_result(agent_ip_address, hardware_specs, tests_result, run_tests_batch_time_start)

              run_tests_batch_time_start = Time.now

              tests_batch = tests_batch(agent_ip_address, hardware_specs)
              if tests_batch.empty?
                client.puts({ msg: 'no_exist_tests' }.to_json)
                client.close
                break
              else
                client.puts(tests_batch.to_json) # Se envia el lote de tests
              end
            end
          end

          Thread.kill(search_agents_thread)
        rescue Errno::EPIPE => e
          # Esto al parecer se da cuando el Agent ya cerró las conexiones y el Manager intenta contactar
          Liri.logger.error("Exception(#{e}) Agent #{agent_ip_address} already finished connection")
          # Si el Agente ya no responde es mejor terminar el hilo. Aunque igual quedará colgado el Manager
          # mientras sigan pruebas pendientes
          Thread.exit
        end
      end
    end

    def processing
      @semaphore.synchronize do
        @unfinished_tests_batches.positive?
      end
    end

    def tests_batch(agent_ip_address, hardware_specs)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        return {} if @unfinished_tests_batches.zero?

        pending_tests_batch = {}
        sent_tests_batch = {}

        @tests_batches.each_value do |batch|
          if batch[:status] == "pending"
            pending_tests_batch = batch
            batch[:status] = "sent"
            batch[:hardware_specs] = hardware_specs
            break
            #elsif sent_tests_batch.empty? && batch[:status] == "sent"
            #sent_tests_batch = batch
          end
        end

        #tests_batch = pending_tests_batch.any? ? pending_tests_batch : sent_tests_batch
        tests_batch = pending_tests_batch
        return {} if tests_batch.empty?

        tests_batch[:agent_ip_address] = agent_ip_address

        Liri.logger.debug("Tests batches sent to Agent #{agent_ip_address}: #{tests_batch}")
        tests_batch
      end
    end

    def process_tests_result(agent_ip_address, hardware_specs, tests_result, run_tests_batch_time_start)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        batch_num = tests_result['batch_num']
        tests_result_file_name = tests_result['tests_result_file_name']

        return if @tests_batches[batch_num][:status] == 'processed'

        tests_result = @tests_result.process(tests_result_file_name)
        return if tests_result.empty?

        @unfinished_tests_batches -= 1

        if @unfinished_tests_batches.zero?
          @tests_runtime_bar.stop
        end

        files_count = @tests_batches[batch_num][:files_count]
        @files_processed += files_count

        batch_run_time = Time.now - run_tests_batch_time_start

        @tests_running_progress_bar.advance(files_count)

        @tests_result_bar.advance(1, examples: @tests_result.examples.to_s, passed: @tests_result.passed.to_s, failures: @tests_result.failures.to_s)

        @tests_batches[batch_num][:status] = 'processed'
        @tests_batches[batch_num][:examples] = tests_result[:examples]
        @tests_batches[batch_num][:passed] = tests_result[:passed]
        @tests_batches[batch_num][:failures] = tests_result[:failures]
        @tests_batches[batch_num][:pending] = tests_result[:pending]
        @tests_batches[batch_num][:failed_files] = tests_result[:failed_files]
        @tests_batches[batch_num][:files_load] = tests_result[:files_load]
        @tests_batches[batch_num][:finish_in] = tests_result[:finish_in]
        @tests_batches[batch_num][:batch_run] = batch_run_time
        @tests_batches[batch_num][:hardware_specs] = hardware_specs

        Liri.logger.info("Processed unit tests by Agent: #{agent_ip_address}: #{files_count}")
      end
    end

    def print_results
      @tests_processing_bar.stop if @tests_processing_bar
      print_agents_summary
      print_agents_detailed_summary if Liri.print_agents_detailed_summary
      @tests_result.print_failures_list if Liri.print_failures_list
      @tests_result.print_failed_examples if Liri.print_failed_examples
    end

    def print_agents_summary
      processed_tests_batches_by_agent = processed_tests_batches_by_agents
      rows = processed_tests_batches_by_agent.values.map do |value|
        value[:files_load] = value[:files_load].to_duration if value[:files_load]
        value[:finish_in] = value[:finish_in].to_duration if value[:finish_in]
        value[:batch_run] = value[:batch_run].to_duration if value[:batch_run]
        value[:source_code_sharing] = value[:source_code_sharing].to_duration if value[:source_code_sharing]
        value[:tests_runtime] = value[:tests_runtime].to_duration if value[:tests_runtime]
        value.values
      end

      rows << Array.new(11) # Se agrega una linea vacia antes de mostrar los totales
      rows << summary_footer.remove!(:batch_num).values
      header = processed_tests_batches_by_agent.values.first.keys

      table = Terminal::Table.new title: 'Summary', headings: header, rows: rows
      table.style = { padding_left: 3, border_x: '=', border_i: 'x'}

      Liri.logger.info("\n#{table}", true)
    end

    def processed_tests_batches_by_agents
      tests_batches = {}
      files_count = {}
      @tests_batches.each_value do |processed_test_batch|
        agent_ip_address = processed_test_batch[:agent_ip_address]
        status = processed_test_batch[:status]
        key = "#{agent_ip_address}#{status}"
        if tests_batches[key]
          files_count[key] += processed_test_batch[:files_count]
          tests_batches[key][:files_status] = "#{files_count[key]} #{status}"
          tests_batches[key][:examples] += processed_test_batch[:examples]
          tests_batches[key][:passed] += processed_test_batch[:passed]
          tests_batches[key][:failures] += processed_test_batch[:failures]
          tests_batches[key][:failed_files] += processed_test_batch[:failed_files]
          tests_batches[key][:files_load] += processed_test_batch[:files_load]
          tests_batches[key][:finish_in] += processed_test_batch[:finish_in]
          tests_batches[key][:batch_run] += processed_test_batch[:batch_run]
          tests_batches[key][:source_code_sharing] += processed_test_batch[:source_code_sharing]
          tests_batches[key][:tests_runtime] += (processed_test_batch[:batch_run] + processed_test_batch[:source_code_sharing])
        else
          files_count[key] = processed_test_batch[:files_count]
          _processed_test_batch = processed_test_batch.clone # Clone to change values in other hash
          _processed_test_batch.remove!(:batch_num, :msg, :tests_batch_keys, :failures_list, :failed_examples,
                                        :agent_ip_address, :pending, :files_count, :status)
          tests_batches[key] = _processed_test_batch
          tests_batches[key][:files_status] = "#{files_count[key]} #{status}"
        end
      end
      tests_batches
    end

    def print_agents_detailed_summary
      rows = @tests_batches.values.map do |value|
        value[:files_status] = "#{value[:files_count]} #{value[:status]}"
        value.remove!(:msg, :tests_batch_keys, :failures_list, :failed_examples, :agent_ip_address, :pending,
                      :files_count, :status)
        value[:files_load] = value[:files_load].to_duration if value[:files_load]
        value[:finish_in] = value[:finish_in].to_duration if value[:finish_in]
        value[:tests_runtime] = (value[:batch_run] + value[:source_code_sharing])
        value[:batch_run] = value[:batch_run].to_duration if value[:batch_run]
        value[:source_code_sharing] = value[:source_code_sharing].to_duration if value[:source_code_sharing]
        value.values
      end

      rows << Array.new(12) # Se agrega una linea vacia antes de mostrar los totales
      rows << summary_footer.values
      header = @tests_batches.values.first.keys

      table = Terminal::Table.new title: 'Detailed Summary', headings: header, rows: rows
      table.style = { padding_left: 3, border_x: '=', border_i: 'x' }

      Liri.logger.info("\n#{table}", true)
    end

    def summary_footer
      {
          batch_num: "",
          files_status: "#{@tests_files_count} in total",
          examples: @tests_result.examples,
          passed: @tests_result.passed,
          failures: @tests_result.failures,
          failed_files: "",
          files_load: "",
          finish_in: "",
          batch_run: "",
          source_code_sharing: "",
          tests_runtime: "",
          hardware_specs: ""
      }
    end

    def registered_agent?(agent_ip_address)
      @agents[agent_ip_address]
    end

    def register_agent(agent_ip_address)
      @agents[agent_ip_address] = agent_ip_address
      Liri.logger.info("\nStarted connection with Agent: #{agent_ip_address} in TCP port: #{@tcp_port}")
    end

    def update_connected_agents(agent_ip_address)
      unless @connected_agents[agent_ip_address]
        @connected_agents[agent_ip_address] = agent_ip_address
        update_agents_bar
      end
    end

    def update_working_agents(agent_ip_address)
      unless @working_agents[agent_ip_address]
        @working_agents[agent_ip_address] = agent_ip_address
        update_agents_bar
      end
    end

    def update_agents_bar
      @agents_bar.advance(1, connected: @connected_agents.size.to_s, working: @working_agents.size.to_s)
    end

    def start_tests_runtime_bar
      @semaphore.synchronize do
        return if @tests_runtime_start

        @tests_runtime_start = Time.now
        Thread.new do
          while !@tests_runtime_bar.stopped?
            @tests_runtime_bar.advance(1, time: (Time.now - @tests_runtime_start).to_duration)
            sleep(1)
          end
        end
      end
    end

    def build_tests_batches(all_tests)
      while all_tests.any?
        @batch_num += 1 # Se numera cada lote
        samples = all_tests.sample!(Manager.test_files_by_runner) # Se obtiene algunos tests
        samples_keys = samples.keys # Se obtiene la clave asignada a los tests
        files_count = samples.size
        @tests_files_count += files_count
        # Se construye el lote a enviar
        tests_batch = {
            msg: 'process_tests',
            batch_num: @batch_num,
            tests_batch_keys: samples_keys,
            files_count: files_count,
            status: 'pending',
            files_status: "",
            examples: 0,
            passed: 0,
            failures: 0,
            pending: 0,
            failed_files: "",
            files_load: 0,
            finish_in: 0,
            batch_run: 0,
            source_code_sharing: 0,
            tests_runtime: 0,
            hardware_specs: ""
        }
        @tests_batches[@batch_num] = tests_batch
      end

      @unfinished_tests_batches = @batch_num
    end
  end
end
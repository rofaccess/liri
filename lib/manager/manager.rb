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
        unless stop
          # Esperar y enviar los test unitarios a los Agents
          manager.start_server_socket_to_process_tests(threads[0])
        end

        Liri.init_exit(stop, threads)
      rescue SignalException
        # Liri.logger.info("\nManager process finished manually", true)
      ensure
        # Siempre se ejecutan estos comandos, haya o no excepción
        Liri.kill(threads) if threads&.any?
        manager&.print_results
        source_code&.delete_compressed_file
        Liri.logger.info("Manager process finished", true)
      end

      def udp_request_delay
        Liri.setup.manager.udp_request_delay
      end

      def test_files_by_runner
        Liri.setup.manager.test_files_by_runner
      end

      def show_share_source_code_progress_bar
        Liri.setup.manager.bar.share_source_code
      end

      def print_summary_table
        Liri.setup.manager.print.table.summary
      end

      def print_detailed_table
        Liri.setup.manager.print.table.detailed
      end

      def print_summary_failures
        Liri.setup.manager.print.failures.summary
      end

      def print_detailed_failures
        Liri.setup.manager.print.failures.detailed
      end

      def show_failed_files_column
        Liri.setup.manager.print.column.failed_files
      end

      def show_files_load_column
        Liri.setup.manager.print.column.files_load
      end

      def show_finish_in_column
        Liri.setup.manager.print.column.finish_in
      end

      def show_batch_run_column
        Liri.setup.manager.print.column.batch_run
      end

      def show_share_source_code_column
        Liri.setup.manager.print.column.share_source_code
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
        source_code = Common::SourceCode.new(source_code_folder_path, manager_folder_path, Liri.ignored_folders_in_compress, Liri.compression_class, Liri.unit_test_class)
        #Common::Progressbar.start(total: nil, length: 120, format: 'Compressing source code |%B| %a') do
        Common::TtyProgressbar.start("Compressing source code |:bar| :percent | Time: :time", total: nil, width: 80, bar_format: :box) do
          source_code.compress_folder
        end
        puts "\n"

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
      @tests_running_progress_bar = @tests_processing_bar.register("Tests files processed :current/:total |:bar| :percent | Time: :time", total: @tests_files_count, width: 80, bar_format: :box)
      @agents_bar = @tests_processing_bar.register("Agents: Connected: :connected, Working: :working")
      @tests_result_bar = @tests_processing_bar.register("Examples: :examples, Passed: :passed, Failures: :failures")

      @tests_processing_bar.start # Se inicia la multi barra de progreso

      # Se establece el estado inicial de las barras
      @tests_running_progress_bar.use(Common::TtyProgressbar::TimeFormatter) # Se configura el uso de un nuevo token llamado time para mostrar el tiempo de ejcución
      @tests_running_progress_bar.advance(0) # Esto obliga a que esta barra se muestre antes que los siguientes
      @tests_running_progress_bar.pause

      @agents_bar.advance(0, connected: "0", working: "0")
      @tests_result_bar.advance(0, examples: "0", passed: "0", failures: "0")
    end

    # Inicia un cliente udp que hace un broadcast en toda la red para iniciar una conexión con los Agent que estén escuchando
    def start_client_socket_to_search_agents(manager_data)
      # El cliente udp se ejecuta en bucle dentro de un hilo, esto permite realizar otras tareas mientras este hilo sigue sondeando
      # la red para obtener mas Agents. Una vez que los tests terminan de ejecutarse, este hilo será finalizado.
      Thread.new do
        Liri.logger.info('Searching agents... Wait')
        Liri.logger.info("Sending UDP broadcast each #{Manager.udp_request_delay} seconds in UDP port: #{@udp_port}")
        while processing
          @udp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
          @udp_socket.send(manager_data.to_h.to_json, 0, '<broadcast>', @udp_port)
          sleep(Manager.udp_request_delay) # Se pausa un momento antes de efectuar nuevamente la petición broadcast
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
          share_source_code_time_start = nil
          share_source_code_progress_bar = nil

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
                share_source_code_time_start = Time.now

                share_source_code_progress_bar = start_share_source_code_progress_bar(hardware_specs, msg)

                client.puts({ msg: msg }.to_json)
              end
            end

            if msg == 'get_source_code_fail'
              stop_share_source_code_progress_bar(hardware_specs, share_source_code_progress_bar)

              client.puts({ msg: 'finish_agent' }.to_json)
              client.close
              break
            end

            # Primera ejecucion de pruebas
            if msg == 'get_tests_files'
              stop_share_source_code_progress_bar(hardware_specs, share_source_code_progress_bar)

              share_source_code_time_end = Time.now - share_source_code_time_start

              Liri.logger.info("Running unit tests. Agent: #{agent_ip_address}. Wait... ", false)

              start_tests_running_progress_bar
              run_tests_batch_time_start = Time.now
              update_working_agents(agent_ip_address)
              tests_batch = tests_batch(agent_ip_address, hardware_specs, share_source_code_time_end)

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

              tests_batch = tests_batch(agent_ip_address, hardware_specs, 0)
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

    def build_tests_batches(all_tests)
      while all_tests.any?
        @batch_num += 1 # Se numera cada lote
        samples = all_tests.sample!(Manager.test_files_by_runner) # Se obtiene algunos tests
        samples_keys = samples.keys # Se obtiene la clave asignada a los tests
        files_count = samples.size
        status = "pending"
        @tests_files_count += files_count
        # Se construye el lote a enviar
        tests_batch = {
          batch_num: @batch_num,
          tests_batch_keys: samples_keys,
          msg: "process_tests",
          files_count: files_count,
          status: status,
          files_status: "#{files_count} #{status}",
          agent_ip_address: "",
          examples: 0,
          passed: 0,
          failures: 0,
          pending: 0,
          failed_files: "",
          files_load: 0,
          finish_in: 0,
          batch_run: 0,
          share_source_code: 0,
          tests_runtime: 0,
          hardware_specs: ""
        }
        @tests_batches[@batch_num] = tests_batch
      end

      @unfinished_tests_batches = @batch_num
    end

    def tests_batch(agent_ip_address, hardware_specs, share_source_code_time_end)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        return {} if @unfinished_tests_batches.zero?

        tests_batch = {}
        pending_tests_batch = {}
        sent_tests_batch = {}

        @tests_batches.each_value do |batch|
          if batch[:status] == "pending"
            pending_tests_batch = batch
            break
          elsif batch[:status] == "sent"
            sent_tests_batch = batch # Es importante que este no tenga un break para guardar el ultimo enviado
            # el cual tiene menos probabilidades de terminar de ejecutarse rapido
          end
        end

        # Es importante setear el status y el hardware_spec solo si los hashes no estan vacios
        # Porque si estan vacios significa que ya no hay tests que ejecutar, y si seteamos algun valor en el hash
        # estando este vacio entonces se tratara de ejecutar algo sin los datos suficientes y fallara
        if pending_tests_batch.any?
          tests_batch = pending_tests_batch
          tests_batch[:status] = "sent"
          tests_batch[:agent_ip_address] = agent_ip_address
          tests_batch[:hardware_specs] = hardware_specs
        elsif sent_tests_batch.any?
          tests_batch = sent_tests_batch
          tests_batch[:status] = "resent"
          tests_batch[:agent_ip_address] = agent_ip_address
          tests_batch[:hardware_specs] = hardware_specs
        end

        return {} if tests_batch.empty?

        tests_batch[:agent_ip_address] = agent_ip_address
        tests_batch[:share_source_code] = share_source_code_time_end

        Liri.logger.debug("Tests batches sent to Agent #{agent_ip_address}: #{tests_batch}")
        # se devuelve el hash con los datos que se enviarán al agente, por eso, primero se remueven los datos innecesarios
        tests_batch.remove(:files_count, :status, :files_status, :agent_ip_address, :examples, :passed, :failures,
                           :pending, :failed_files, :files_load, :finish_in, :batch_run, :share_source_code,
                           :tests_runtime, :hardware_specs)
      end
    end

    def process_tests_result(agent_ip_address, hardware_specs, tests_result, run_tests_batch_time_start)
      # Se inicia un semáforo para evitar que varios hilos actualicen variables compartidas
      @semaphore.synchronize do
        batch_num = tests_result['batch_num']
        tests_result_file_name = tests_result['tests_result_file_name']
        status = "processed"
        # Sólo se procesan las pruebas en estado sent o resent, caso contrario no se avanza con el procesamiento
        return if (["pending", status]).include?(@tests_batches[batch_num][:status])

        tests_result = @tests_result.process(tests_result_file_name)
        return if tests_result.empty?

        @unfinished_tests_batches -= 1

        files_count = @tests_batches[batch_num][:files_count]
        @files_processed += files_count

        batch_runtime = Time.now - run_tests_batch_time_start

        @tests_running_progress_bar.advance(files_count)
        @tests_result_bar.advance(1, examples: @tests_result.examples.to_s, passed: @tests_result.passed.to_s, failures: @tests_result.failures.to_s)
        @tests_running_progress_bar.stop if @unfinished_tests_batches.zero?

        @tests_batches[batch_num][:status] = status
        @tests_batches[batch_num][:files_status] = "#{files_count} #{status}"
        @tests_batches[batch_num][:agent_ip_address] = agent_ip_address
        @tests_batches[batch_num][:examples] = tests_result[:examples]
        @tests_batches[batch_num][:passed] = tests_result[:passed]
        @tests_batches[batch_num][:failures] = tests_result[:failures]
        @tests_batches[batch_num][:pending] = tests_result[:pending]
        @tests_batches[batch_num][:failed_files] = tests_result[:failed_files]
        @tests_batches[batch_num][:files_load] = tests_result[:files_load]
        @tests_batches[batch_num][:finish_in] = tests_result[:finish_in]
        @tests_batches[batch_num][:batch_run] = batch_runtime
        @tests_batches[batch_num][:tests_runtime] = @tests_batches[batch_num][:batch_run] + @tests_batches[batch_num][:share_source_code]
        @tests_batches[batch_num][:hardware_specs] = hardware_specs

        Liri.logger.info("Processed unit tests by Agent: #{agent_ip_address}: #{files_count}")
      end
    end

    def print_results
      @tests_processing_bar&.stop
      print_summary_table if Manager.print_summary_table
      print_detailed_table if Manager.print_detailed_table
      @tests_result.print_summary_failures if Manager.print_summary_failures
      @tests_result.print_detailed_failures if Manager.print_detailed_failures
    end

    def print_summary_table
      processed_tests_batches_by_agent = processed_tests_batches_by_agents
      rows = processed_tests_batches_by_agent.values.map do |value|
        value[:files_load] = to_duration(value[:files_load]) if value[:files_load]
        value[:finish_in] = to_duration(value[:finish_in]) if value[:finish_in]
        value[:batch_run] = to_duration(value[:batch_run]) if value[:batch_run]
        value[:share_source_code] = to_duration(value[:share_source_code]) if value[:share_source_code]
        value[:tests_runtime] = to_duration(value[:tests_runtime]) if value[:tests_runtime]
        value.values
      end

      rows << Array.new(rows.size) # Se agrega una linea vacia antes de mostrar los totales
      rows << summary_footer.remove(:batch_num).values
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
          tests_batches[key][:failed_files] += processed_test_batch[:failed_files] if Manager.show_failed_files_column
          tests_batches[key][:files_load] += processed_test_batch[:files_load] if Manager.show_files_load_column
          tests_batches[key][:finish_in] += processed_test_batch[:finish_in] if Manager.show_finish_in_column
          tests_batches[key][:batch_run] += processed_test_batch[:batch_run] if Manager.show_batch_run_column
          tests_batches[key][:share_source_code] += processed_test_batch[:share_source_code] if Manager.show_share_source_code_column
          tests_batches[key][:tests_runtime] += processed_test_batch[:tests_runtime]
        else
          files_count[key] = processed_test_batch[:files_count]

          _processed_test_batch = processed_test_batch.clone # Clone to change values in other hash
          _processed_test_batch.remove!(:batch_num, :tests_batch_keys, :msg, :files_count, :status, :agent_ip_address,
                                        :pending)

          _processed_test_batch.remove!(:failed_files) unless Manager.show_failed_files_column
          _processed_test_batch.remove!(:files_load) unless Manager.show_files_load_column
          _processed_test_batch.remove!(:finish_in) unless Manager.show_finish_in_column
          _processed_test_batch.remove!(:batch_run) unless Manager.show_batch_run_column
          _processed_test_batch.remove!(:share_source_code) unless Manager.show_share_source_code_column
          _processed_test_batch[:files_status] = "#{files_count[key]} #{status}"

          tests_batches[key] = _processed_test_batch
        end
      end
      tests_batches
    end

    def print_detailed_table
      rows = @tests_batches.values.map do |value|
        value.remove!(:tests_batch_keys, :msg, :files_count, :status, :agent_ip_address, :pending)

        value.remove!(:failed_files) unless Manager.show_failed_files_column
        value.remove!(:files_load) unless Manager.show_files_load_column
        value.remove!(:finish_in) unless Manager.show_finish_in_column
        value.remove!(:batch_run) unless Manager.show_batch_run_column
        value.remove!(:share_source_code) unless Manager.show_share_source_code_column

        value[:files_load] = to_duration(value[:files_load]) if value[:files_load]
        value[:finish_in] = to_duration(value[:finish_in]) if value[:finish_in]
        value[:batch_run] = to_duration(value[:batch_run]) if value[:batch_run]
        value[:share_source_code] = to_duration(value[:share_source_code]) if value[:share_source_code]
        value[:tests_runtime] = to_duration(value[:tests_runtime])
        value.values
      end

      rows << Array.new(rows.size) # Se agrega una linea vacia antes de mostrar los totales
      rows << summary_footer.values
      header = @tests_batches.values.first.keys

      table = Terminal::Table.new title: 'Detailed Summary', headings: header, rows: rows
      table.style = { padding_left: 3, border_x: '=', border_i: 'x' }

      Liri.logger.info("\n#{table}", true)
    end

    def summary_footer
      hash = {}
      hash[:batch_num] = ""
      hash[:files_status] = "#{@tests_files_count} in total"
      hash[:examples] = @tests_result.examples
      hash[:passed] = @tests_result.passed
      hash[:failures] = @tests_result.failures
      hash[:failed_files] = "" if Manager.show_failed_files_column
      hash[:files_load] = "" if Manager.show_files_load_column
      hash[:finish_in] = "" if Manager.show_finish_in_column
      hash[:batch_run] = "" if Manager.show_batch_run_column
      hash[:share_source_code] = "" if Manager.show_share_source_code_column
      hash[:tests_runtime] = ""
      hash[:hardware_specs] = ""
      hash
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

    def start_share_source_code_progress_bar(hardware_specs, msg)
      if msg == 'proceed_get_source_code' && Manager.show_share_source_code_progress_bar
        share_source_code_progress_bar = @tests_processing_bar.register("Sharing source code |:bar| :percent | Time: :time | Agent: [:agent ]", total: nil, width: 20, bar_format: :box)
        share_source_code_progress_bar.start
        share_source_code_progress_bar.use(Common::TtyProgressbar::TimeFormatter)
        Thread.new do
          animation_count = 0
          while !share_source_code_progress_bar.stopped?
            share_source_code_progress_bar.advance(1, agent: hardware_specs)

            share_source_code_progress_bar.update(unknown: Common::TtyProgressbar::ANIMATION2[animation_count])
            animation_count += 1
            animation_count = 0 if animation_count == 3

            sleep(0.1)
          end
        end
      end
      share_source_code_progress_bar
    end

    def stop_share_source_code_progress_bar(hardware_specs, share_source_code_progress_bar)
      if Manager.show_share_source_code_progress_bar
        share_source_code_progress_bar.update(total: 1, agent: hardware_specs)
        share_source_code_progress_bar.stop
      end
    end

    def start_tests_running_progress_bar
      @semaphore.synchronize do
        # Es importante hacer un reset acá osino va a contar desde que se instancia y no desde que se inicia la ejecución
        # del primer test. Solo se resetea si esta paused para evitar que al conectarse con cada Agent se vuelva a resetear
        @tests_running_progress_bar.reset if @tests_running_progress_bar.paused?
        Thread.new do
          while !@tests_running_progress_bar.stopped?
            @tests_running_progress_bar.advance(0)
            sleep(0.1) # Es importante que las otras barras tambien tengan el mismo sleep para que sean mas consistentes en sus resultados
          end
        end
      end
    end

    def to_duration(value)
      Common::Duration.humanize(value, times_round: Liri.times_round, times_round_type: Liri.times_round_type)
    end
  end
end
# frozen_string_literal: true

# Este modulo contiene datos del programa que son reutilizados en otras partes de la aplicacion
module Liri
  NAME = 'liri' # El gemspec requiere que el nombre este en minusculas
  VERSION = '0.4.1'

  class << self
    def set_setup(destination_folder_path, program, manager_tests_results_folder_time: nil)
      load_setup_manager(destination_folder_path, program, manager_tests_results_folder_time: manager_tests_results_folder_time)
    end

    # Carga las configuraciones en memoria desde un archivo de configuracion
    def setup
      @setup
    end

    def logger
      @logger ||= load_logger
    end

    def set_logger(folder_path, file_name)
      @logger = load_logger(folder_path, file_name)
    end

    def clear_setup
      if @setup
        @setup = nil
        true
      else
        false
      end
    end

    def clean_folder_content(folder_path)
      FileUtils.rm_rf(Dir.glob(folder_path + '/*')) if Dir.exist?(folder_path)
    end

    def reload_setup
      @setup = (@setup_manager ? @setup_manager.load : nil)
    end

    def delete_setup
      @setup_manager ? @setup_manager.delete_setup_folder : false
    end

    def init_exit(stop, threads)
      threads = threads.compact
      kill(threads) if stop

      # Con la siguiente línea se asegura que los hilos no mueran antes de que finalize el programa principal
      # Fuente: https://underc0de.org/foro/ruby/hilos-en-ruby/
      threads.each{|thread| thread.join}
    end

    def kill(threads)
      threads.each{ |thread| Thread.kill(thread) }
    end

    def current_host_ip_address
      addr = Socket.ip_address_list.select(&:ipv4?).detect{|addr| addr.ip_address != '127.0.0.1'}
      addr.ip_address
    end

    def compression_class
      "Liri::Common::Compressor::#{setup.general.library.compression}"
    end

    def unit_test_class
      "Liri::Common::UnitTest::#{setup.general.library.unit_test}"
    end

    def udp_port
      setup.general.ports.udp
    end

    def tcp_port
      setup.general.ports.tcp
    end

    def current_folder_ruby_and_gemset
      "#{File.read('.ruby-version').strip}@#{File.read('.ruby-gemset').strip}"
    end

    def ignored_folders_in_compress
      setup.general.ignored_folders_in_compress
    end

    def times_round
      setup.general.times_round
    end

    def times_round_type
      setup.general.times_round_type.to_sym
    end

    private

    # Inicializa el objeto que gestiona las configuraciones
    def load_setup_manager(destination_folder_path, program, manager_tests_results_folder_time: nil)
      @setup_manager = Liri::Common::Setup.new(destination_folder_path, program, manager_tests_results_folder_time: manager_tests_results_folder_time)
      @setup_manager.init
      @setup = @setup_manager.load
      @setup_manager
    end

    # Inicializa y configura la librería encargada de loguear
    def load_logger(folder_path = nil, file_name = nil)
      log = Liri::Common::Log.new('daily', folder_path: folder_path, file_name: file_name, stdout: setup.general.log.stdout.show)
      log
    end
  end

  # EXCEPTIONS
  class FileNotFoundError < StandardError
    def initialize(file_path)
      msg = "File not found #{file_path}"
      super(msg)
    end
  end

  class InxiCommandNotFoundError < StandardError
    def initialize
      msg = "Inxi command not found"
      super(msg)
    end
  end
end

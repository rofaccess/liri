# frozen_string_literal: true

# Este modulo contiene datos del programa que son reutilizados en otras partes de la aplicacion
module Liri
  NAME = 'liri' # El gemspec requiere que el nombre este en minusculas
  VERSION = '0.1.1'
  SETUP_FOLDER_NAME = 'liri'
  ROOT_PATH = Dir.pwd
  SETUP_FOLDER_PATH = ROOT_PATH
  LOGS_FOLDER_NAME = 'logs'
  MANAGER_LOGS_FOLDER_PATH = File.join(ROOT_PATH, '/', LOGS_FOLDER_NAME)
  AGENT_LOGS_FOLDER_PATH = File.expand_path("../#{LOGS_FOLDER_NAME}")
  AGENT_FOLDER_PATH = ROOT_PATH
  MANAGER_FOLDER_PATH = ROOT_PATH
  class << self
    def setup
      @setup ||= load_setup
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

    def create_folders(program)
      case program
      when 'manager'
        Dir.mkdir(SETUP_FOLDER_PATH) unless Dir.exist?(SETUP_FOLDER_PATH)
        Dir.mkdir(MANAGER_LOGS_FOLDER_PATH) unless Dir.exist?(MANAGER_LOGS_FOLDER_PATH)
      when 'agent'
        Dir.mkdir(AGENT_LOGS_FOLDER_PATH) unless Dir.exist?(AGENT_LOGS_FOLDER_PATH)
      end
    end

    def reload_setup
      @setup = load_setup
    end

    def delete_setup
      liri_setup = Liri::Manager::Setup.new(SETUP_FOLDER_PATH)
      liri_setup.delete
    end

    def init_exit(stop, threads, program)
      threads = threads.compact
      kill(threads) if stop

      # Con la siguiente línea se asegura que los hilos no mueran antes de que finalize el programa principal
      # Fuente: https://underc0de.org/foro/ruby/hilos-en-ruby/
      threads.each{|thread| thread.join}
      #rescue SignalException => e
      #puts "\nEjecución del #{program} terminada manualmente\n"
      #kill(threads)
    end

    def kill(threads)
      threads.each{|thread| Thread.kill(thread)}
    end

    def current_host_ip_address
      addr = Socket.ip_address_list.select(&:ipv4?).detect{|addr| addr.ip_address != '127.0.0.1'}
      addr.ip_address
    end

    def compression_class
      "Liri::Common::Compressor::#{setup.library.compression}"
    end

    def unit_test_class
      "Liri::Common::UnitTest::#{setup.library.unit_test}"
    end

    def udp_port
      setup.ports.udp
    end

    def tcp_port
      setup.ports.tcp
    end

    private

    # Carga las configuraciones en memoria desde un archivo de configuracion
    def load_setup
      liri_setup = Liri::Manager::Setup.new(SETUP_FOLDER_PATH)
      liri_setup.create unless File.exist?(liri_setup.path)
      liri_setup.load
    end

    # Inicializa y configura la librería encargada de loguear
    def load_logger(folder_path = nil, file_name = nil)
      log = Liri::Common::Log.new('daily', folder_path: folder_path, file_name: file_name, stdout: Liri.setup.show_stdout_log)
      log
    end
  end

  # EXCEPTIONS
  class FileNotFoundError < StandardError
    def initialize(file_path)
      msg = "No se encuentra el archivo #{file_path}"
      super(msg)
    end
  end
end

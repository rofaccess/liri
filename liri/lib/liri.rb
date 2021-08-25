# frozen_string_literal: true

# Este modulo contiene datos del programa que son reutilizados en otras partes de la aplicacion
module Liri
  NAME = 'liri' # El gemspec requiere que el nombre este en minusculas
  VERSION = '0.1.0'

  class << self
    def setup
      @setup ||= load_setup
    end

    def logger
      @logger ||= load_logger
    end

    def reset_setup
      if @setup
        @setup = nil
        true
      else
        false
      end
    end

    def delete_setup
      liri_setup = Liri::Manager::Setup.new
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

    private

    # Carga las configuraciones en memoria desde un archivo de configuracion
    def load_setup
      liri_setup = Liri::Manager::Setup.new
      liri_setup.create unless File.exist?(liri_setup.path)
      liri_setup.load
    end

    # Inicializa y configura la librería encargada de logear
    def load_logger
      log = Liri::Common::Log.new('daily', Liri.setup.show_stdout_log)
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

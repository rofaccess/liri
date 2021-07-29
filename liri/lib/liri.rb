# frozen_string_literal: true

# Este modulo contiene datos del programa que son reutilizados en otras partes de la aplicacion
module Liri
  NAME = 'liri' # El gemspec requiere que el nombre este en minusculas
  VERSION = '0.1.0'

  class << self
    def setup
      @setup ||= load_setup
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

    def init_exit(stop, threads)
      if stop
        kill(threads)
      else
        # Fuente: https://www.rubyguides.com/2019/10/ruby-chomp-gets/
        key = $stdin.gets
        if key.chomp == 's' || key.chomp == 'S'
          kill(threads)
        end
      end
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
  end

  # EXCEPTIONS
  class FileNotFoundError < StandardError
    def initialize(file_path)
      msg = "No se encuentra el archivo #{file_path}"
      super(msg)
    end
  end
end

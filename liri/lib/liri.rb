=begin
  Este modulo contiene datos del programa que son reutilizados en otras partes de la aplicación, como ser el nombre y la
  versión
=end

module Liri
  NAME = 'liri' # El nombre debe estar en minúsculas porque algunas partes de la aplicación lo utilizan como ser el gemspec
  VERSION = "0.1.0"

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
      _setup = Liri::Manager::Setup.new
      _setup.delete
    end

    private
    # Carga las configuraciones en memoria desde un archivo de configuración
    def load_setup
      _setup = Liri::Manager::Setup.new
      _setup.create unless File.exist?(_setup.path)
      _setup.load
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

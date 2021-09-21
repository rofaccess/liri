=begin
  Este modulo se encarga de manejar la configuración
=end
require 'yaml'
require 'json'

module Liri
  class Manager
    class Setup
      FOLDER_NAME = 'liri'
      FOLDER_PATH = File.join(Dir.pwd, '/', FOLDER_NAME)

      FILE_NAME = 'liri.yml'
      FILE_PATH = File.join(FOLDER_PATH, '/', FILE_NAME)

      TEMPLATE_PATH = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'template/liri.yml')

      def initialize
        # Crea la carpeta en donde se guardarán los datos relativos a liri, ya sean archivos comprimidos,
        # archivos descomprimidos, configuraciones, etc.
        Dir.mkdir(FOLDER_PATH) unless Dir.exist?(FOLDER_PATH)
      end

      # Crea un archivo de configuración en la raiz del proyecto desde un template
      def create
        if File.exist?(FILE_PATH)
          false
        else
          File.open(FILE_PATH, "w") do |output_file|
            File.foreach(TEMPLATE_PATH) do |input_line|
              output_file.write(input_line)
            end
          end
          true
        end
      end

      # Retorna los datos del archivo de configuración
      def load
        if File.exist?(FILE_PATH)
          data = YAML.load(File.read(FILE_PATH))
          JSON.parse(data.to_json, object_class: OpenStruct)
        else
          raise Liri::FileNotFoundError.new(FILE_PATH)
        end
      end

      # Borra el archivo de configuración
      def delete
        if File.exist?(FILE_PATH)
          File.delete(FILE_PATH)
          true
        else
          false
        end
      end

      def set(value, *keys)
        data = YAML.load(File.read(FILE_PATH))
        keys = keys.first
        aux = data
        keys.each_with_index do |key, index|
          if(keys[index + 1])
            aux = data[key]
          else
            aux[key] = value
          end
        end
        File.open(FILE_PATH, 'w') {|f| f.write data.to_yaml }
      end

      def path
        FILE_PATH
      end
    end
  end
end

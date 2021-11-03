=begin
  Este modulo se encarga de manejar la configuración
=end
require 'yaml'
require 'json'

module Liri
  class Manager
    class Setup
      FILE_NAME = 'liri-config.yml'
      TEMPLATE_PATH = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'template/liri-config.yml')

      def initialize(folder_path)
        @file_path = File.join(folder_path, '/', FILE_NAME)
      end

      # Crea un archivo de configuración en la raiz del proyecto desde un template
      def create
        File.open(@file_path, "w") do |output_file|
          File.foreach(TEMPLATE_PATH) do |input_line|
            output_file.write(input_line)
          end
        end
        true
      end

      # Retorna los datos del archivo de configuración
      def load
        if File.exist?(@file_path)
          data = YAML.load(File.read(@file_path))
          JSON.parse(data.to_json, object_class: OpenStruct)
        else
          raise Liri::FileNotFoundError.new(@file_path)
        end
      end

      # Borra el archivo de configuración
      def delete
        if File.exist?(@file_path)
          File.delete(@file_path)
          true
        else
          false
        end
      end

      def set(value, *keys)
        data = YAML.load(File.read(@file_path))
        keys = keys.first
        aux = data
        keys.each_with_index do |key, index|
          if (keys[index + 1])
            aux = data[key]
          else
            aux[key] = value
          end
        end
        File.open(@file_path, 'w') { |f| f.write data.to_yaml }
      end

      def path
        @file_path
      end
    end
  end
end

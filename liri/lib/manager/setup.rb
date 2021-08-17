=begin
  Este modulo se encarga de manejar la configuración
=end
require 'yaml'
require 'json'

module Liri
  class Manager
    class Setup
      FILE_NAME = 'liri.yml'
      FOLDER_NAME = 'temp'
      FILE_PATH = File.join(Dir.pwd, '/', FILE_NAME)
      TEMP_PATH = File.join(Dir.pwd, '/', FOLDER_NAME)
      TEMPLATE_PATH = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'template/liri.yml')

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

      def create_temp_folder
        directory_name = TEMP_PATH
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
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

      def update_value_two_level(key, key2, value)
        if File.exist?(FILE_PATH)
          data = YAML.load(File.read(FILE_PATH))
          data[key][key2] = value
          File.open(FILE_PATH, 'w') {|f| f.write data.to_yaml }
        else
          raise Liri::FileNotFoundError.new(FILE_PATH)
        end
      end


      def update_value_one_level(key, value)
        if File.exist?(FILE_PATH)
          data = YAML.load(File.read(FILE_PATH))
          data[key] = value
          File.open(FILE_PATH, 'w') {|f| f.write data.to_yaml }
        else
          raise Liri::FileNotFoundError.new(FILE_PATH)
        end
      end

      def path
        FILE_PATH
      end
      def temp_path
        TEMP_PATH
      end
    end
  end
end

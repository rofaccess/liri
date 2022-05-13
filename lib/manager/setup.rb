=begin
  Este modulo se encarga de manejar la configuración
=end
require 'yaml'
require 'json'

module Liri
  class Manager
    class Setup
      FOLDER_NAME = 'liri'
      FILE_NAME = 'liri-config.yml'
      TEMPLATE_PATH = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'template/liri-config.yml')

      attr_reader :folder_path, :file_path

      def initialize(destination_folder_path)
        @folder_path = File.join(destination_folder_path, '/', FOLDER_NAME)
        @file_path = File.join(@folder_path, '/', FILE_NAME)
      end

      def init
        create_folder
        create_file
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

      def create_folder
        # Crea la carpeta en donde se guardarán los datos relativos a liri, ya sean archivos comprimidos,
        # archivos descomprimidos, configuraciones, etc.
        Dir.mkdir(@folder_path) unless Dir.exist?(@folder_path)
        Dir.exist?(@folder_path) ? true : false
      end

      def delete_folder
        if Dir.exist?(@folder_path)
          FileUtils.rm_rf(@folder_path)
          Dir.exist?(@folder_path) ? false : true
        else
          false
        end
      end

      # Crea un archivo de configuración en la raiz del proyecto desde un template
      def create_file
        File.open(@file_path, 'w') do |output_file|
          File.foreach(TEMPLATE_PATH) do |input_line|
            output_file.write(input_line)
          end
        end

        File.exist?(@file_path) ? true : false
      end

      # Borra el archivo de configuración
      def delete_file
        if File.exist?(@file_path)
          File.delete(@file_path)
          File.exist?(@file_path) ? false : true
        else
          false
        end
      end
    end
  end
end

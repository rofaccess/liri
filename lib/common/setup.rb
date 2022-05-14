=begin
  Este modulo se encarga de manejar la configuración
=end
require 'yaml'
require 'json'

module Liri
  module Common
    class Setup
      SETUP_FOLDER_NAME = 'liri'
      SETUP_FILE_NAME = 'liri-config.yml'
      TEMPLATE_PATH = File.join(File.dirname(File.dirname(File.dirname(__FILE__))), 'template/liri-config.yml')
      LOGS_FOLDER_NAME = 'logs'
      MANAGER_FOLDER_NAME = 'manager'
      AGENT_FOLDER_NAME = 'agent'

      attr_reader :setup_folder_path, :setup_file_path, :logs_folder_path, :manager_folder_path, :agent_folder_path

      def initialize(destination_folder_path)
        @setup_folder_path = File.join(destination_folder_path, '/', SETUP_FOLDER_NAME)
        @setup_file_path = File.join(@setup_folder_path, '/', SETUP_FILE_NAME)
        @logs_folder_path = File.join(@setup_folder_path, '/', LOGS_FOLDER_NAME)
        @manager_folder_path = File.join(@setup_folder_path, '/', MANAGER_FOLDER_NAME)
        @agent_folder_path = File.join(@setup_folder_path, '/', AGENT_FOLDER_NAME)
      end

      def init
        create_folder(@setup_folder_path)
        create_folder(@logs_folder_path)
        create_folder(@manager_folder_path)
        create_folder(@agent_folder_path)
        create_setup_file
      end

      # Retorna los datos del archivo de configuración
      def load
        if File.exist?(@setup_file_path)
          data = YAML.load(File.read(@setup_file_path))
          JSON.parse(data.to_json, object_class: OpenStruct)
        else
          raise Liri::FileNotFoundError.new(@setup_file_path)
        end
      end

      def set(value, *keys)
        data = YAML.load(File.read(@setup_file_path))
        keys = keys.first
        aux = data
        keys.each_with_index do |key, index|
          if (keys[index + 1])
            aux = data[key]
          else
            aux[key] = value
          end
        end
        File.open(@setup_file_path, 'w') { |f| f.write data.to_yaml }
      end

      def create_folder(folder_path)
        if Dir.exist?(folder_path)
          false
        else
          Dir.mkdir(folder_path)
          Dir.exist?(folder_path) ? true : false
        end
      end

      def delete_setup_folder
        if Dir.exist?(@setup_folder_path)
          FileUtils.rm_rf(@setup_folder_path)
          Dir.exist?(@setup_folder_path) ? false : true
        else
          false
        end
      end

      # Crea un archivo de configuración en la raiz del proyecto desde un template
      def create_setup_file
        if File.exist?(@setup_file_path)
          false
        else
          File.open(@setup_file_path, 'w') do |output_file|
            File.foreach(TEMPLATE_PATH) do |input_line|
              output_file.write(input_line)
            end
          end

          File.exist?(@setup_file_path) ? true : false
        end
      end

      # Borra el archivo de configuración
      def delete_setup_file
        if File.exist?(@setup_file_path)
          File.delete(@setup_file_path)
          File.exist?(@setup_file_path) ? false : true
        else
          false
        end
      end
    end
  end
end

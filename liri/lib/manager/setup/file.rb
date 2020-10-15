require 'yaml'
require 'json'
require 'manager/setup/setup'

module Liri
  module Manager
    class Setup::File
      SETUP_FILE_NAME = 'liri.yml'
      TEMPLATE_PATH = File.join(File.dirname(File.dirname(File.dirname(File.dirname(__FILE__)))), 'template/liri.yml')

      attr_reader :path

      def initialize
        @name = SETUP_FILE_NAME
        @path = File.join(Dir.pwd, '/', @name)
      end

      def create
        if File.exist?(@path)
          false
        else
          File.open(@path, "w") do |output_file|
            File.foreach(TEMPLATE_PATH) do |input_line|
              output_file.write(input_line)
            end
          end
          true
        end
      end

      def load
        if File.exist?(@path)
          data = YAML.load(File.read(@path))
          JSON.parse(data.to_json, object_class: OpenStruct)
        else
          raise Liri::Manager::Setup::FileNotFoundError.new(self)
        end
      end

      def delete
        if File.exist?(@path)
          File.delete(@path)
          true
        else
          raise Liri::Manager::Setup::FileNotFoundError.new(self)
        end
      end
    end
  end
end
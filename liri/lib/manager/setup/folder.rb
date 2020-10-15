require 'manager/setup/setup'
require 'manager/setup/file'

module Liri
  module Manager
    class Setup::Folder
      attr_reader :path

      def initialize
        @name = Liri.config.setup.folder_name
        @path = File.join(Dir.pwd, '/', @name)
      end

      def create
        if Dir.exist?(@path)
          false
        else
          Dir.mkdir(@path)
          true
        end
      end

      def delete
        if Dir.exist?(@path)
          FileUtils.rm_rf(@path)
          true
        else
          raise Liri::Manager::Setup::FolderNotFoundError.new(self)
        end
      end
    end
  end
end
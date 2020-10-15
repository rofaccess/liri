require 'manager/source_code/source_code'
require 'manager/source_code/folder'
require 'manager/setup/folder'
require 'common/compressor/zip'

module Liri
  module Manager
    class SourceCode::CompressedFile
      attr_reader :path, :target_folder_path

      def initialize(source_code_folder_path, target_folder_path)
        @name = Liri.config.source_code.compressed_file_name
        @source_code_folder_path = source_code_folder_path
        @target_folder_path = target_folder_path
        @path = File.join(@target_folder_path, '/', @name)
      end

      def create
        if Dir.exist?(@target_folder_path)
          if File.exist?(@path)
            false
          else
            compressor_class = "Liri::Common::Compressor::#{Liri.config.implementation.compressor}"
            compressor = Object.const_get(compressor_class).new(@source_code_folder_path, @path)
            compressor.compress
          end
        else
          raise Liri::Manager::SourceCode::CompressedFileTargetFolderNotFoundError.new(self)
        end
      end

      def delete
        if File.exist?(@path)
          File.delete(@path)
          true
        else
          raise Liri::Manager::SourceCode::CompressedFileNotFoundError.new(self)
        end
      end
    end
  end
end
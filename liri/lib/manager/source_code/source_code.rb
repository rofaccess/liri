# Use this file to use SourceCode::CompressedFile and SourceCode::Folder format in CompressedFile and Folder module definition
module Liri
  module Manager
    module SourceCode
      class CompressedFileNotFoundError < StandardError
        def initialize(compressed_file_object)
          msg = "No such file #{compressed_file_object.path}"
          super(msg)
        end
      end

      class CompressedFileTargetFolderNotFoundError < StandardError
        def initialize(compressed_file_object)
          msg = "No such folder #{compressed_file_object.target_folder_path}"
          super(msg)
        end
      end
    end
  end
end

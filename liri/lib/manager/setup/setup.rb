# Use this file to use Setup::File and Setup::Folder format in File and Folder module definition
module Liri
  module Manager
    module Setup
      class FolderNotFoundError < StandardError
        def initialize(setup_folder_object)
          msg = "No such folder #{setup_folder_object.path}"
          super(msg)
        end
      end

      class FileNotFoundError < StandardError
        def initialize(setup_file_object)
          msg = "No such file #{setup_file_object.path}"
          super(msg)
        end
      end
    end
  end
end

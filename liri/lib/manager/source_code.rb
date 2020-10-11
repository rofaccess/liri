require 'manager/folder'
require 'common/compressor/zip'

module Liri
  module Manager
    # This module have all methods to manage source code to test
    module SourceCode
      DIR = Dir.pwd
      DIR_NAME = DIR.split('/').last

      COMPRESSED_FILE_NAME = "#{DIR_NAME}_source_code.zip"
      COMPRESSED_FILE = File.join(Liri::Manager::Folder::DIR, '/', COMPRESSED_FILE_NAME)

      class << self
        # TODO Warning: The source code can be contains logs files and temporal files that
        # are unnecessary for testing process and will increase the compressed file size
        # In future will be necessary ignore some folders before compress source file
        def compress
          compressor = Liri::Common::Compressor::Zip.new(DIR, COMPRESSED_FILE)
          compressor.compress
        end

        def delete
          File.delete(COMPRESSED_FILE) if File.exist?(COMPRESSED_FILE)
        end
      end
    end
  end
end
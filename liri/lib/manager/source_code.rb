=begin
  Este clase se encarga de manejar todo lo relativo al código fuente
=end

module Liri
  class Manager
    class SourceCode
      FOLDER_PATH = Dir.pwd
      FOLDER_NAME = FOLDER_PATH.split('/').last
      COMPRESSED_FILE_PATH = File.join(FOLDER_PATH, '/', "#{FOLDER_NAME}.zip")

      def initialize(compression_class, unit_test_class)
        # Inicializa un compresor acorde a compression_class, la siguiente línea en realidad hace lo siguiente:
        # @compressor = Liri::Common::Compressor::Zip.new(input_dir, output_file)
        # compression_class en este caso es Zip pero podría ser otro si existiera la implementación, por ejemplo Rar
        @compressor = Object.const_get(compression_class).new(FOLDER_PATH, COMPRESSED_FILE_PATH)
        # Inicializa un ejecutor de pruebas acorde a unit_test_class, la siguiente línea en realidad hace lo siguiente:
        # @unit_test = Liri::Common::UnitTest::Rspec.new(source_code_folder_path)
        # unit_test_class en este caso es Rspec pero podría ser otro si existiera la implementación, por ejemplo UnitTest
        @unit_test = Object.const_get(unit_test_class).new(FOLDER_PATH)
      end

      def compress_folder
        @compressor.compress
      end

      def delete_compressed_folder
        if File.exist?(COMPRESSED_FILE_PATH)
          File.delete(COMPRESSED_FILE_PATH)
          true
        else
          false
        end
      end

      def all_tests
        @unit_test.all_tests
      end

      def compressed_file_path
        COMPRESSED_FILE_PATH
      end
    end
  end
end

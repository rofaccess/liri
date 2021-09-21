=begin
  Este clase se encarga de manejar todo lo relativo al código fuente
=end

module Liri
  module Common
    class SourceCode
      FOLDER_PATH = Dir.pwd
      FOLDER_NAME = FOLDER_PATH.split('/').last
      attr_reader :compressed_file_folder_path, :compressed_file_path, :decompressed_file_folder_path

      def initialize(compressed_file_folder_path, compression_class, unit_test_class)
        @compressed_file_folder_path = compressed_file_folder_path
        @decompressed_file_folder_path = File.join(@compressed_file_folder_path, '/', "decompressed_#{FOLDER_NAME}")
        @compressed_file_path = File.join(@compressed_file_folder_path, '/', "#{FOLDER_NAME}.zip")
        # Inicializa un compresor acorde a compression_class, la siguiente línea en realidad hace lo siguiente:
        # @compressor = Liri::Common::Compressor::Zip.new(input_dir, output_file)
        # compression_class en este caso es Zip pero podría ser otro si existiera la implementación, por ejemplo Rar
        @compressor = Object.const_get(compression_class).new(FOLDER_PATH, @compressed_file_path)
        # Inicializa un ejecutor de pruebas acorde a unit_test_class, la siguiente línea en realidad hace lo siguiente:
        # @unit_test = Liri::Common::UnitTest::Rspec.new(source_code_folder_path)
        # unit_test_class en este caso es Rspec pero podría ser otro si existiera la implementación, por ejemplo UnitTest
        @unit_test = Object.const_get(unit_test_class).new(FOLDER_PATH)
      end

      def compress_folder
        @compressor.compress
      end

      def decompress_file
        @compressor.decompress(@compressed_file_path, @decompressed_file_folder_path)
      end

      def delete_compressed_file
        if File.exist?(@compressed_file_path)
          File.delete(@compressed_file_path)
          true
        else
          false
        end
      end

      def all_tests
        @unit_test.all_tests
      end
    end
  end
end

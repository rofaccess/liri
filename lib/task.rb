=begin
  Este módulo ejecuta tareas de apoyo
=end

module Liri
  module Task
    class << self
      def tests_files(source_code_folder_path)
        source_code = Liri::Common::SourceCode.new(source_code_folder_path,"", "", Liri.compression_class, Liri.unit_test_class)
        source_code.all_tests
      end

      def tests_count(source_code_folder_path)
        tests_files(source_code_folder_path).size
      end
    end
  end
end


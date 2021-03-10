# Es necesario usar el siguiente require para que el formato class UnitTest::Rspec funcione
require 'manager/unit_test/unit_test'

module Liri
  module Manager
    class UnitTest::Rspec
      TEST_FOLDER_NAME = 'spec'

      def initialize(source_code_folder_path)
        @path = File.join(source_code_folder_path, TEST_FOLDER_NAME)
      end

      def all_tests

      end
    end
  end
end
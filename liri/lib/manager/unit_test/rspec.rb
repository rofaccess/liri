module Liri
  module Manager
    module UnitTest
      class Rspec
        TESTS_FOLDER_NAME = 'spec'
        attr_reader :tests_folder_path

        def initialize(source_code_folder_path)
          @tests_folder_path = File.join(source_code_folder_path, TESTS_FOLDER_NAME)
        end

        def all_tests
          test_files.each do |test_file|
            puts test_file
          end
        end

        private
        def test_files
          Dir[@tests_folder_path + "/**/*spec.rb"]
        end
      end
    end
  end
end
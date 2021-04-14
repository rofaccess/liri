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
          tests_count = 1
          tests_hash = {}
          test_files.each do |test_file|
            File.open(test_file) do |file|
              file.each_with_index do |line, index|
                if line.strip.start_with?('it')
                  test_line = file.to_path + ":#{index + 1}"
                  tests_hash[tests_count] = test_line
                  tests_count += 1
                end
              end
            end
          end
          tests_hash
        end

        private
        def test_files
          Dir[@tests_folder_path + "/**/*spec.rb"]
        end
      end
    end
  end
end
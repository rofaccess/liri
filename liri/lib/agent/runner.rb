=begin
  Esta clase se encarga de ejecutar las pruebas unitarias recibidas del Manager
=end

module Liri
  class Agent
    class Runner
      def initialize(unit_test_class, source_code_folder_path)
        @unit_test = Object.const_get(unit_test_class).new(source_code_folder_path)
      end

      def run_tests(tests)
        result_hash = @unit_test.run_tests(tests.values)
        result_hash[:test_keys] = tests.keys
        result_hash
      end
    end
  end
end
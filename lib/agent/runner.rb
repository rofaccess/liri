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
        @unit_test.run_tests(tests)
      end
    end
  end
end
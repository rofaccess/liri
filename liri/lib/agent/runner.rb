=begin
  Esta clase se encarga de ejecutar las pruebas unitarias recibidas del Manager
=end

module Liri
  module Agent
    class Runner
      def initialize(unit_test_class)
        @unit_test = Object.const_get(unit_test_class).new
      end

      def run_tests(tests)
        result_hash = @unit_test.run_tests(tests.values)
        result_hash[:test_keys] = tests.keys
        result_hash
      end
    end
  end
end
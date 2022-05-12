# Procesa el resultado de las pruebas unitarias
module Liri
  class Manager
    class TestResult
      def initialize
        @example_quantity = 0
        @failure_quantity = 0
        @passed_quantity = 0
      end

      def update(test_result)
        @example_quantity += test_result['example_quantity']
        @failure_quantity += test_result['failure_quantity']
        @passed_quantity += (@example_quantity - @failure_quantity)
      end

      def print_process(test_result)
        passed_quantity = test_result['example_quantity'] - test_result['failure_quantity']
        passed_quantity.times do
          print '.'
        end

        test_result['failure_quantity'].times do
          print 'F'
        end
      end

      def print_summary
        print_examples_and_failures
      end

      private

      def print_examples_and_failures
        puts "#{@example_quantity} examples, #{@failure_quantity} failures\n\n"
      end
    end
  end
end

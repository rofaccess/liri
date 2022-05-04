# Procesa el resultado de las pruebas unitarias
module Liri
  class Manager
    class TestResult
      def initialize
        @result = ''
        @failures = ''
        @example_quantity = 0
        @failure_quantity = 0
        @passed_quantity = 0
        @failed_examples = ''
      end
      def update(test_result)
        @result << test_result['result']
        @failures << test_result['failures'] if test_result['failures']
        @example_quantity += test_result['example_quantity']
        @failure_quantity += test_result['failure_quantity']
        @passed_quantity += test_result['passed_quantity']
        @failed_examples += test_result['failed_examples'] if test_result['failed_examples']
      end

      def print_process(test_result)
        test_result['passed_quantity'].times do
          print '.'
        end

        test_result['failure_quantity'].times do
          print 'F'
        end
      end

      def print_summary
        print_failures unless @failures.empty?
        print_examples_and_failures
        print_failed_examples unless @failed_examples.empty?
      end

      private

      def print_failures
        puts "\n\nFailures:\n"

        puts @failures
      end

      def print_examples_and_failures
        puts "#{@example_quantity} examples, #{@failure_quantity} failures\n\n"
      end

      def print_failed_examples
        puts "Failed examples:\n"

        puts @failed_examples
      end
    end
  end
end
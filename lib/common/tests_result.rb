# = tests_result.rb
#
# @author Rodrigo Fernández
#
# == Clase TestsResult

module Liri
  module Common
    # Esta clase se encarga de guardar y procesar el archivo de resultados
    class TestsResult
      attr_reader :examples, :failures, :pending, :passed

      def initialize(folder_path)
        @folder_path = folder_path
        @examples = 0
        @failures = 0
        @pending = 0
        @passed = 0
        @finish_in = 0
        @files_load = 0
        @failures_list = ''
        @failed_examples = ''
        @failed_files = ''
      end

      def save(file_name, raw_tests_result)
        file_path = File.join(@folder_path, '/', file_name)
        File.write(file_path, raw_tests_result)
        file_path
      end

      def build_file_name(agent_ip_address, batch_num)
        "batch_#{batch_num}_agent_#{agent_ip_address}_tests_results"
      end

      # Procesa el resultado crudo de las pruebas unitarias y lo devuelve en formato hash manejable
      # Ejemplo del hash retornado:
      # { examples: 0, failures: 0, pending: 0, passed: 0, finish_in: 0, files_load: 0,
      #   failures_list: '', failed_examples: '' }
      def process(tests_result_file_name)
        file_path = File.join(@folder_path, '/', tests_result_file_name)
        # A veces no se encuentra el archivo de resultados, la siguiente condicional es para evitar errores relativos a esto
        return {} unless File.exist?(file_path)

        result_hash = process_tests_result_file(file_path)
        update_partial_result(result_hash)
        result_hash
      end

      def print_summary
        Liri.logger.info("\n#{@examples} examples, #{@passed} passed, #{@failures} failures\n", true)
      end

      def print_detailed_failures
        Liri.logger.info("\nFailures: ", true) unless @failures_list.empty?
        Liri.logger.info(@failures_list, true)
      end

      def print_summary_failures
        Liri.logger.info("\nFailed examples: ", true) unless @failed_examples.empty?
        Liri.logger.info(@failed_examples, true)
      end

      private

      # Recibe el resultado crudo de las pruebas unitarias
      # Procesa el archivo con los resultados crudos y lo devuelve en formato hash manejable
      # Ejemplo del hash retornado:
      # {result: '.F', failures: '', examples: 2, failures: 1, failed_examples: ''}
      def process_tests_result_file(file_path)
        result_hash = { examples: 0, failures: 0, pending: 0, passed: 0, finish_in: 0, files_load: 0,
                        failures_list: '', failed_examples: '', failed_files: '' }
        flag = ''
        @failures_lists_count = @failures
        File.foreach(file_path) do |line|
          if flag == '' && line.strip.start_with?('Randomized')
            flag = 'Randomized'
            next
          end

          if ['Randomized', ''].include?(flag) && line.strip.start_with?('Failures')
            flag = 'Failures'
            next
          end

          if ['Randomized', 'Failures', ''].include?(flag) && line.strip.start_with?('Finished')
            values = finish_in_values(line)
            result_hash[:finish_in] = values[:finish_in]
            result_hash[:files_load] = values[:files_load]
            flag = 'Finished'
            next
          end

          if ['Finished', ''].include?(flag) && line.strip.start_with?('Failed')
            flag = 'Failed'
            next
          end

          case flag
          when 'Failures'
            line = fix_failure_number(line)
            result_hash[:failures_list] << line
          when 'Finished'
            values = finished_summary_values(line)
            result_hash[:examples] = values[:examples]
            result_hash[:failures] = values[:failures]
            result_hash[:passed] = result_hash[:examples] - result_hash[:failures]
            result_hash[:pending] = values[:pending]
            flag = ''
          when 'Failed'
            if line.strip.start_with?('rspec')
              result_hash[:failed_examples] << line
              result_hash[:failed_files] << "#{failed_example(line)}\n"
            end
          end
        end

        result_hash
      end

      def update_partial_result(hash_result)
        @examples += hash_result[:examples]
        @failures += hash_result[:failures]
        @pending += hash_result[:pending]
        @passed += hash_result[:passed]
        @failures_list << hash_result[:failures_list]
        @failed_examples << hash_result[:failed_examples]
        @failed_files << hash_result[:failed_files]
      end

      def finish_in_values(line)
        UnitTest::RspecResultParser.finish_in_values(line)
      end

      def finished_summary_values(line)
        UnitTest::RspecResultParser.finished_summary_values(line)
      end

      def failed_example(line)
        # get string like this "/spec/failed_spec.rb:4"
        failed_example = UnitTest::RspecResultParser.failed_example(line)
        # return "failed_spec.rb:4"
        failed_example.split("/").last
      end

      def fix_failure_number(line)
        line_number_regex = /(\d+\))/
        if line.strip.start_with?(line_number_regex)
          @failures_lists_count += 1
          line.gsub!(line_number_regex, "#{@failures_lists_count})")
        end
        line
      end
    end
  end
end

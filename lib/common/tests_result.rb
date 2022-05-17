# = tests_result.rb
#
# @author Rodrigo Fernández
#
# == Clase TestsResult

module Liri
  module Common
    # Esta clase se encarga de guardar y procesar el archivo de resultados
    class TestsResult
      def initialize(folder_path)
        @folder_path = folder_path
        @examples = 0
        @failures = 0
        @pending = 0
        @passed = 0
        @finished_in = 0
        @files_took_to_load = 0
        @tests_files_processed_count = 0
        @batch_run_finished_in = 0
        @failures_list = ''
        @failed_examples = ''
      end

      def save(file_name, raw_tests_result)
        file_path = File.join(@folder_path, '/', file_name)
        File.write(file_path, raw_tests_result)
        file_path
      end

      def build_file_name(agent_ip_address, tests_batch_number)
        "batch_#{tests_batch_number}_agent_#{agent_ip_address}_tests_results"
      end

      # Procesa el resultado crudo de las pruebas unitarias y lo devuelve en formato hash manejable
      # Ejemplo del hash retornado:
      # { examples: 0, failures: 0, pending: 0, passed: 0, finished_in: 0, files_took_to_load: 0,
      #   failures_list: '', failed_examples: '' }
      def process(tests_result_file_name, tests_files_processed_count, batch_run_finished_in)
        file_path = File.join(@folder_path, '/', tests_result_file_name)
        result_hash = process_tests_result_file(file_path)
        result_hash[:tests_files_processed_count] = tests_files_processed_count
        result_hash[:batch_run_finished_in] = batch_run_finished_in
        update_partial_result(result_hash)
        result_hash
      end

      def print_summary
        puts "\n#{@examples} examples, #{@failures} failures, #{@pending} pending\n\n"
      end

      def print_failures_list
        puts "\nFailures: " unless @failures_list.empty?
        puts @failures_list
      end

      def print_failed_examples
        puts "\nFailed examples: " unless @failed_examples.empty?
        puts @failed_examples
      end

      def to_humanized_hash
        { examples: @examples, failures: @failures, pending: @pending, passed: @passed,
          finished_in: @finished_in.to_duration, files_took_to_load: @files_took_to_load.to_duration,
          tests_files_processed_count: @tests_files_processed_count,
          batch_run_finished_in: @batch_run_finished_in.to_duration }
      end

      private

      # Recibe el resultado crudo de las pruebas unitarias
      # Procesa el archivo con los resultados crudos y lo devuelve en formato hash manejable
      # Ejemplo del hash retornado:
      # {result: '.F', failures: '', examples: 2, failures: 1, failed_examples: ''}
      def process_tests_result_file(file_path)
        result_hash = { examples: 0, failures: 0, pending: 0, passed: 0, finished_in: 0, files_took_to_load: 0,
                        failures_list: '', failed_examples: '' }
        flag = ''
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
            values = finished_in_values(line)
            result_hash[:finished_in] = values[:finished_in]
            result_hash[:files_took_to_load] = values[:files_took_to_load]
            flag = 'Finished'
            next
          end

          if ['Finished', ''].include?(flag) && line.strip.start_with?('Failed')
            flag = 'Failed'
            next
          end

          case flag
          when 'Failures'
            result_hash[:failures_list] << line
          when 'Finished'
            values = finished_summary_values(line)
            result_hash[:examples] = values[:examples]
            result_hash[:failures] = values[:failures]
            result_hash[:passed] = result_hash[:examples] - result_hash[:failures]
            result_hash[:pending] = values[:pending]
            flag = ''
          when 'Failed'
            result_hash[:failed_examples] << line
          end
        end

        result_hash
      end

      def update_partial_result(hash_result)
        @examples += hash_result[:examples]
        @failures += hash_result[:failures]
        @pending += hash_result[:pending]
        @passed += hash_result[:passed]
        @finished_in += hash_result[:finished_in]
        @files_took_to_load += hash_result[:files_took_to_load]
        @tests_files_processed_count += hash_result[:tests_files_processed_count]
        @batch_run_finished_in += hash_result[:batch_run_finished_in]
        @failures_list << hash_result[:failures_list]
        @failed_examples << hash_result[:failed_examples]
      end

      def finished_in_values(line)
        UnitTest::RspecResultParser.finished_in_values(line)
      end

      def finished_summary_values(line)
        UnitTest::RspecResultParser.finished_summary_values(line)
      end
    end
  end
end

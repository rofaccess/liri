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
        @example_quantity = 0
        @failure_quantity = 0
        @passed_quantity = 0
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
      # {example_quantity: 2, failure_quantity: 1}
      def process(tests_result_file_name)
        file_path = File.join(@folder_path, '/', tests_result_file_name)
        result_hash = process_tests_result_file(file_path)
        update_partial_result(result_hash)
        print_partial_result(result_hash)
      end

      def print_summary
        puts "#{@example_quantity} examples, #{@failure_quantity} failures\n\n"
      end

      private

      # Recibe el resultado crudo de las pruebas unitarias
      # Procesa el archivo con los resultados crudos y lo devuelve en formato hash manejable
      # Ejemplo del hash retornado:
      # {result: '.F', failures: '', example_quantity: 2, failure_quantity: 1, failed_examples: ''}
      def process_tests_result_file(file_path)
        result_hash = {result: '', failures: '', example_quantity: 0, failure_quantity: 0, passed_quantity: 0, failed_examples: ''}
        flag = ''
        File.foreach(file_path) do |line|
          if flag == '' && line.strip.start_with?('Randomized')
            flag = 'Randomized'
            next
          end

          if flag == 'Randomized' && line.strip.start_with?('Failures')
            flag = 'Failures'
            next
          end

          if ['Randomized', 'Failures'].include?(flag) && line.strip.start_with?('Finished')
            flag = 'Finished'
            next
          end

          if ['Finished', ''].include?(flag) && line.strip.start_with?('Failed')
            flag = 'Failed'
            next
          end

          case flag
          when 'Randomized'
            result_hash[:result] << line.strip
          when 'Failures'
            result_hash[:failures] << line
          when 'Finished'
            values = line.to_s.match(/([\d]+) example.?, ([\d]+) failure.?/)
            result_hash[:example_quantity] = values[1].to_i
            result_hash[:failure_quantity] = values[2].to_i
            result_hash[:passed_quantity] = result_hash[:example_quantity] - result_hash[:failure_quantity]
            flag = ''
          when 'Failed'
            result_hash[:failed_examples] << line
          end
        end

        result_hash
      end

      def update_partial_result(hash_result)
        @example_quantity += hash_result[:example_quantity]
        @failure_quantity += hash_result[:failure_quantity]
        @passed_quantity += hash_result[:passed_quantity]
      end

      def print_partial_result(result_hash)
        result_hash[:passed_quantity].times do
          print '.'
        end

        result_hash[:failure_quantity].times do
          print 'F'
        end
      end

    end
  end
end

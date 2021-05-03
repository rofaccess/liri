module Liri
  class Agent
    module UnitTest
      class Rspec
        # Recibe un arreglo de rutas a las pruebas unitarias
        # Ejecuta las pruebas unitarias y retorna el resultado como un hash
        def run_tests(tests)
          tests_paths = tests.join(' ') # convierte ["spec/manager/setup_spec.rb:59", "spec/agent/agent_spec.rb:2"] a "spec/manager/setup_spec.rb:59 spec/agent/agent_spec.rb:2"
          # Se puede ejecutar comandos en líneas de comandos usando system(cli_command) o %x|cli_command|
          # system devuelve true, false o nil, %x devuelve la salida del comando ejecutado
          # From:
          #      https://www.rubyguides.com/2018/12/ruby-system/

          #system("bundle exec rspec #{tests_paths} --format progress --out rspec_result.txt --no-color")
          raw_tests_result = %x|bundle exec rspec #{tests_paths} --format progress|
          process_tests_result(raw_tests_result)
        end

        private
        # Recibe el resultado crudo de las pruebas unitarias
        # Procesa el resultado y lo devuelve en formato hash manejable
        # Ejemplo del hash retornado:
        # {result: '.F', failures: '', example_quantity: 2, failure_quantity: 1, passed_quantity: 0, failed_examples: ''}
        def process_tests_result(raw_test_results)
          result_hash = {result: '', failures: '', example_quantity: 0, failure_quantity: 0, passed_quantity: 0, failed_examples: ''}
          flag = ''
          raw_test_results.each_line do |line|
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
      end
    end
  end
end

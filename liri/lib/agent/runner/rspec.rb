module Liri
  module Agent
    module Runner
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

        end
      end
    end
  end
end

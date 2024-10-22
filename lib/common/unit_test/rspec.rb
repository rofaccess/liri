module Liri
  module Common
    module UnitTest
      class Rspec
        TESTS_FOLDER_NAME = 'spec'
        attr_reader :tests_folder_path

        def initialize(source_code_folder_path)
          @source_code_folder_path = source_code_folder_path
          @tests_folder_path = File.join(source_code_folder_path, TESTS_FOLDER_NAME)
        end

        # Retorna un hash con todos los tests. Ex.: {1=>"spec/hash_spec.rb:2", 2=>"spec/hash_spec.rb:13", 3=>"spec/hash_spec.rb:24", ..., 29=>"spec/liri_spec.rb:62"}
        def all_tests
          tests_count = 1
          tests_hash = {}
          sorted_test_files = test_files.sort
          sorted_test_files.each do |test_file|
            tests_hash[tests_count] = test_file.sub(@source_code_folder_path + '/', '')
            tests_count += 1
          end
          tests_hash
        end

        # Recibe un arreglo de rutas a las pruebas unitarias
        # Ejecuta las pruebas unitarias y retorna el resultado como un hash
        def run_tests(tests)
          # Se puede ejecutar comandos en líneas de comandos usando system(cli_command) o %x|cli_command|
          # system devuelve true, false o nil, %x devuelve la salida del comando ejecutado
          # From:
          #      https://www.rubyguides.com/2018/12/ruby-system/

          #system("bundle exec rspec #{tests_paths} --format progress --out rspec_result.txt --no-color")
          # El comando chdir hace que el directorio de trabajo se mueva a la carpeta en donde se descomprimió el código fuente para poder ejecutar las pruebas
          Dir.chdir(@source_code_folder_path) do
            # Descomentar para la depuración en entorno de desarrollo (Creo que aún así no se puede depurar)
            # raw_tests_result = %x|bundle exec rspec #{tests.join(' ')} --format progress|
            # Descomentar para el entorno de producción
            raw_tests_result = ''
            Liri::Common::Benchmarking.start(start_msg: "Running tests batch. Wait... ") do
              raw_tests_result = %x|bash -lc 'rvm use #{Liri.current_folder_ruby_and_gemset}; rspec #{tests.join(' ')}'|
            end

            return raw_tests_result
          end
        end

        private

        def test_files
          Dir[@tests_folder_path + "/**/*spec.rb"]
        end
      end
    end
  end
end
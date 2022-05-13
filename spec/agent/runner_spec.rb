RSpec.describe Liri::Agent::Runner, '#run_tests' do
  before(:all) do
    Liri.create_folders('test')
    @unit_test = Liri::Common::UnitTest::Rspec.new(source_code_folder_path)
    @runner = Liri::Agent::Runner.new(Liri.unit_test_class, source_code_folder_path)
    @tests_result = Liri::Common::TestsResult.new(setup_folder_path)
  end

  # TODO El runner en realidad devuelve sólo un String con el resultado crudo de los tests, pero,
  # acá se está procesando los resultados y comprobándolos, estas comprobaciones se deben hacer en sus
  # respectivos Tests. Esto nos dice que estos tests requieren refactorización
  it 'ejecuta 1 prueba unitaria' do
    all_tests = @unit_test.all_tests
    tests = {}
    all_tests.keys[0..0].each { |key| tests[key] = all_tests[key] } # Seleccionar el primer test del hash devuelto por all_tests
    test_results_file_path, tests_result = run_tests(tests)

    expect(tests_result).to be_a(Hash)
    expect(tests_result[:failures]).to be_empty
    expect(tests_result[:example_quantity]).to eq(1)
    expect(tests_result[:failure_quantity]).to eq(0)
    expect(tests_result[:passed_quantity]).to eq(1)
    expect(tests_result[:failed_examples]).to be_empty
    delete_file(test_results_file_path)
  end

  it 'ejecuta 2 pruebas unitarias' do
    all_tests = @unit_test.all_tests
    tests = {}
    all_tests.keys[0..1].each {|key| tests[key]=all_tests[key]} # Seleccionar los primeros dos test del hash devuelto por all_tests
    test_results_file_path, tests_result = run_tests(tests)

    expect(tests_result).to be_a(Hash)
    expect(tests_result[:failures]).to be_empty
    expect(tests_result[:example_quantity]).to eq(2)
    expect(tests_result[:failure_quantity]).to eq(0)
    expect(tests_result[:passed_quantity]).to eq(2)
    expect(tests_result[:failed_examples]).to be_empty
    delete_file(test_results_file_path)
  end

  after(:all) do
    Liri.delete_setup_folder
  end
end

def run_tests(tests)
  raw_tests_result = @runner.run_tests(tests.values)
  tests_result_file_name = @tests_result.build_file_name('0.0.0.0', 1)
  tests_result_file_path = @tests_result.save(tests_result_file_name, raw_tests_result)
  tests_result = @tests_result.process(tests_result_file_name)
  [tests_result_file_path, tests_result]
end

def delete_file(file_path)
  File.delete(file_path) if File.exist?(file_path)
end

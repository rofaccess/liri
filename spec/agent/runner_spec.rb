# Atención: Estos tests ejecutan los tests de dummy-app, es muy importante que en el archivo .ruby-gemset de dummy-app
# se especifique liri, porque si se especifica otro gemset, entonces, la ejecución de estos tests falla.
RSpec.describe Liri::Agent::Runner, '#run_tests' do
  before(:all) do
    Liri.set_setup(dummy_app_folder_path, :none)
    @unit_test = Liri::Common::UnitTest::Rspec.new(dummy_app_folder_path)
    @runner = Liri::Agent::Runner.new(unit_test_class, dummy_app_folder_path)
    @tests_result = Liri::Common::TestsResult.new(dummy_app_folder_path)
  end

  # TODO El runner en realidad devuelve sólo un String con el resultado crudo de los tests, pero,
  # acá se está procesando los resultados y comprobándolos, estas comprobaciones se deben hacer en sus
  # respectivos Tests. Esto nos dice que estos tests requieren refactorización
  it 'ejecuta 1 prueba unitaria' do
    all_tests = @unit_test.all_tests
    test_files = {}
    all_tests.keys[0..0].each { |key| test_files[key] = all_tests[key] } # Seleccionar el primer test del hash devuelto por all_tests
    test_results_file_path, tests_result = run_tests(test_files)

    expect(tests_result).to be_a(Hash)
    expect(tests_result[:examples]).to eq(2)
    expect(tests_result[:failures]).to eq(1)
    expect(tests_result[:pending]).to eq(0)
    expect(tests_result[:passed]).to eq(1)
    expect(tests_result[:finish_in]).to be > 0
    expect(tests_result[:files_load]).to be > 0
    expect(tests_result[:failures_list]).not_to be_empty
    expect(tests_result[:failed_examples]).not_to be_empty
    delete_file(test_results_file_path)
  end

  it 'ejecuta 2 pruebas unitarias' do
    all_tests = @unit_test.all_tests
    test_files = {}
    all_tests.keys[0..1].each { |key| test_files[key] = all_tests[key] } # Seleccionar los primeros dos test del hash devuelto por all_tests
    test_results_file_path, tests_result = run_tests(test_files)

    expect(tests_result).to be_a(Hash)
    expect(tests_result[:examples]).to eq(4)
    expect(tests_result[:failures]).to eq(2)
    expect(tests_result[:pending]).to eq(0)
    expect(tests_result[:passed]).to eq(2)
    expect(tests_result[:finish_in]).to be > 0
    expect(tests_result[:files_load]).to be > 0
    expect(tests_result[:failures_list]).not_to be_empty
    expect(tests_result[:failed_examples]).not_to be_empty
    delete_file(test_results_file_path)
  end

  after(:all) do
    Liri.clear_setup
    Liri.delete_setup
  end
end

def run_tests(test_files)
  raw_tests_result = @runner.run_tests(test_files.values)
  tests_result_file_name = @tests_result.build_file_name('0.0.0.0', 1)
  tests_result_file_path = @tests_result.save(tests_result_file_name, raw_tests_result)
  tests_result = @tests_result.process(tests_result_file_name)
  [tests_result_file_path, tests_result]
end

def delete_file(file_path)
  File.delete(file_path) if File.exist?(file_path)
end

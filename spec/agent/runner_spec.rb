RSpec.describe Liri::Agent::Runner, '#run_tests' do
  before(:all) do
    @unit_test = Liri::Common::UnitTest::Rspec.new(source_code_folder_path)
    @runner = Liri::Agent::Runner.new(Liri.unit_test_class, source_code_folder_path)
  end

  it 'ejecuta 1 prueba unitaria' do
    all_tests = @unit_test.all_tests
    tests = {}
    all_tests.keys[0..0].each{|key| tests[key]=all_tests[key]} # Seleccionar el primer test del hash devuelto por all_tests
    tests_result = @runner.run_tests(tests)
    expect(tests_result).to be_a(Hash)
    expect(tests_result[:result]).to eq('.')
    expect(tests_result[:failures]).to be_nil
    expect(tests_result[:example_quantity]).to eq(1)
    expect(tests_result[:failure_quantity]).to eq(0)
    expect(tests_result[:passed_quantity]).to eq(1)
    expect(tests_result[:failed_examples]).to be_nil
    expect(tests_result[:test_keys]).to eq(tests.keys)
  end

  it 'ejecuta 2 pruebas unitarias' do
    all_tests = @unit_test.all_tests
    tests = {}
    all_tests.keys[0..1].each{|key| tests[key]=all_tests[key]} # Seleccionar los primeros dos test del hash devuelto por all_tests
    tests_result = @runner.run_tests(tests)
    expect(tests_result).to be_a(Hash)
    expect(tests_result[:result]).to eq('..')
    expect(tests_result[:failures]).to be_nil
    expect(tests_result[:example_quantity]).to eq(2)
    expect(tests_result[:failure_quantity]).to eq(0)
    expect(tests_result[:passed_quantity]).to eq(2)
    expect(tests_result[:failed_examples]).to be_nil
    expect(tests_result[:test_keys]).to eq(tests.keys)
  end
end

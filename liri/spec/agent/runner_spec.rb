RSpec.describe Liri::Agent::Runner, '#run_tests' do
  before(:all) do
    @manager_unit_test = Liri::Manager::UnitTest::Rspec.new(source_code_folder_path)
    @runner = Liri::Agent::Runner.new(agent_unit_test_class)
  end

  it 'ejecuta 1 prueba unitaria' do
    tests = @manager_unit_test.all_tests.sample(1)
    tests_result = @runner.run_tests(tests)
    expect(tests_result).to be_a(Hash)
    expect(tests_result[:result]).to eq('.')
    expect(tests_result[:failures]).to eq('')
    expect(tests_result[:example_quantity]).to eq(1)
    expect(tests_result[:failure_quantity]).to eq(0)
    expect(tests_result[:passed_quantity]).to eq(1)
    expect(tests_result[:failed_examples]).to eq('')
    expect(tests_result[:test_keys]).to eq(tests.keys)
  end

  it 'ejecuta 2 pruebas unitarias' do
    tests = @manager_unit_test.all_tests.sample(2)
    tests_result = @runner.run_tests(tests)
    expect(tests_result).to be_a(Hash)
    expect(tests_result[:result]).to eq('..')
    expect(tests_result[:failures]).to eq('')
    expect(tests_result[:example_quantity]).to eq(2)
    expect(tests_result[:failure_quantity]).to eq(0)
    expect(tests_result[:passed_quantity]).to eq(2)
    expect(tests_result[:failed_examples]).to eq('')
    expect(tests_result[:test_keys]).to eq(tests.keys)
  end
end

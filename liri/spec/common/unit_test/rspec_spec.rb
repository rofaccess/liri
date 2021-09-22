RSpec.describe Liri::Common::UnitTest::Rspec, '#run_tests' do
  before(:all) do
    @unit_test = Liri::Common::UnitTest::Rspec.new(source_code_folder_path)
  end

  it 'ejecuta 1 prueba unitaria' do
    tests_result = @unit_test.run_tests(@unit_test.all_tests.sample(1).values)
    expect(tests_result).to be_a(Hash)
    expect(tests_result[:result]).to eq('.')
    expect(tests_result[:failures]).to eq('')
    expect(tests_result[:example_quantity]).to eq(1)
    expect(tests_result[:failure_quantity]).to eq(0)
    expect(tests_result[:passed_quantity]).to eq(1)
    expect(tests_result[:failed_examples]).to eq('')
  end

  it 'ejecuta 2 pruebas unitarias' do
    tests_result = @unit_test.run_tests(@unit_test.all_tests.sample(2).values)
    expect(tests_result).to be_a(Hash)
    expect(tests_result[:result]).to eq('..')
    expect(tests_result[:failures]).to eq('')
    expect(tests_result[:example_quantity]).to eq(2)
    expect(tests_result[:failure_quantity]).to eq(0)
    expect(tests_result[:passed_quantity]).to eq(2)
    expect(tests_result[:failed_examples]).to eq('')
  end
end

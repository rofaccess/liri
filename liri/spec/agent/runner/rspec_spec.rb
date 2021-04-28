RSpec.describe Liri::Agent::Runner::Rspec, '#run_tests' do
  before(:all) do
    @unit_test = Liri::Manager::UnitTest::Rspec.new(source_code_folder_path)
  end

  it 'ejecuta 1 prueba unitaria' do
    unit_test = Liri::Agent::Runner::Rspec.new
    tests_result = unit_test.run_tests(@unit_test.all_tests.sample(1).values)
    expect(tests_result).to be_a(Hash)
  end

  it 'ejecuta 2 pruebas unitarias' do
    unit_test = Liri::Agent::Runner::Rspec.new
    tests_result = unit_test.run_tests(@unit_test.all_tests.sample(2).values)
    expect(tests_result).to be_a(Hash)
  end
end

def source_code_folder_path
  Liri::Manager::SourceCode::FOLDER_PATH
end

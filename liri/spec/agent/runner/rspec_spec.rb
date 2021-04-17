RSpec.describe Liri::Agent::Runner::Rspec, '#run_tests' do
  before(:all) do
    @unit_test = Liri::Manager::UnitTest::Rspec.new(source_code_folder_path)
  end

  it 'ejecuta 1 prueba unitaria' do
    unit_test = Liri::Agent::Runner::Rspec.new
    unit_test.run_tests(@unit_test.all_tests.sample(1).values)
  end

  it 'ejecuta 2 pruebas unitarias' do
    unit_test = Liri::Agent::Runner::Rspec.new
    unit_test.run_tests(@unit_test.all_tests.sample(2).values)
  end
end

def source_code_folder_path
  Liri::Manager::SourceCode::FOLDER_PATH
end

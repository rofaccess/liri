RSpec.describe Liri::Manager::UnitTest::Rspec, '#all_tests' do
  it 'retorna un arreglo con las direcciones de los tests unitarios' do
    unit_test = Liri::Manager::UnitTest::Rspec.new(source_code_folder_path)
    unit_test.all_tests
  end
end

def source_code_folder_path
  Liri::Manager::SourceCode::FOLDER_PATH
end

RSpec.describe Liri::Manager::UnitTest::Rspec, '#all_tests' do
  it 'retorna un arreglo con las direcciones de los tests unitarios' do
    unit_test = Liri::Manager::UnitTest::Rspec.new(source_code_folder_path)
    expect(unit_test.all_tests).to be_a(Hash)
  end
end

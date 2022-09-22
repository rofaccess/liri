RSpec.describe Liri::Task do
  describe '#tests_count' do
    it 'get tests count' do
      Liri.set_setup(dummy_app_folder_path, :none)
      expect(Liri::Task.tests_count(dummy_app_folder_path)).to eq(2)
      Liri.clear_setup
      Liri.delete_setup
    end
  end

  describe '#tests_files' do
    it 'get tests files' do
      Liri.set_setup(dummy_app_folder_path, :none)
      tests_files = Liri::Task.tests_files(dummy_app_folder_path)
      expect(tests_files).to eq({ 1 => "spec/dummy/app_spec.rb", 2 => "spec/dummy/dummy_spec.rb" })
      Liri.clear_setup
      Liri.delete_setup
    end
  end
end

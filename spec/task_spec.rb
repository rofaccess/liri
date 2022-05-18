RSpec.describe Liri::Task, '#tests_count' do
  it 'get tests count' do
    Liri.set_setup(dummy_app_folder_path, :none)
    expect(Liri::Task.tests_count(dummy_app_folder_path)).to eq(2)
    Liri.clear_setup
    Liri.delete_setup
  end
end
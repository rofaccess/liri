RSpec.describe Liri::Task, '#tests_count' do
  it 'get tests count' do
    expect(Liri::Task.tests_count(dummy_app_folder_path)).to eq(2)
  end

  after(:all) do
    Liri.delete_setup_folder
  end
end
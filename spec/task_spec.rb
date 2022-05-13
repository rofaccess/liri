RSpec.describe Liri::Task, '#tests_count' do
  it 'get tests count' do
    expect(Liri::Task.tests_count).to eq(31)
  end

  after(:all) do
    Liri.delete_setup_folder
  end
end
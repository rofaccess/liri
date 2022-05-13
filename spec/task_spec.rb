RSpec.describe Liri::Task, '#tests_count' do
  it 'get tests count' do
    expect(Liri::Task.tests_count).to eq(31)
  end
end
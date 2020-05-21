require 'runner/rspec'

RSpec.describe Runner::Rspec, '#run' do
  it 'return true' do
    runner = Runner::Rspec.new
    expect(runner.run).to be true
  end
end
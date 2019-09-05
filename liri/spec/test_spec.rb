require 'test'

RSpec.describe "Test" do
  it "return executing" do
    expect(Liri::Test.run).to eq 'executing...'
  end

end
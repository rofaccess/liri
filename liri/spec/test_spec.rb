require 'test'

RSpec.describe "Test" do
  it "return true" do
    expect(Liri::Test.run('spec/liri_spec.rb')).to eq true
  end

end
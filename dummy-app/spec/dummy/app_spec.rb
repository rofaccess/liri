# frozen_string_literal: true

RSpec.describe Dummy::App do
  it "has a version number" do
    expect(Dummy::App::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end

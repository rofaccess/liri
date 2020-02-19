require 'config'

RSpec.describe Liri::Config, '#load' do
  it 'return true' do
    expect(Liri::Config.load(config_file_path)).to be true
  end
end

RSpec.describe Liri::Config, '#get' do
  context 'compressor' do
    it 'return Compressor class name' do
      expect(Liri::Config.get(:compressor)).to eq 'First'
    end
  end

  context 'runner' do
    it 'return Runner class name' do
      expect(Liri::Config.get(:runner)).to eq 'Second'
    end
  end

  context 'test_framework' do
    it 'return test framework name' do
      expect(Liri::Config.get(:test_framework)).to eq 'RSpec'
    end
  end
end

def config_file_path
  File.join(File.dirname(__FILE__), '/config.yml')
end
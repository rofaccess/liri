require 'config'

RSpec.describe Config, '#get' do
  context 'compressor' do
    it 'return Compressor class name from default config file path' do
      expect(Config.get(:compressor)).to eq 'First'
    end

    it 'return Compressor class name from custom config file path' do
      expect(Config.current(config_file_path).get(:compressor)).to eq 'First'
    end
  end

  context 'runner' do
    it 'return Runner class name from default config file path' do
      expect(Config.get(:runner)).to eq 'Second'
    end

    it 'return Compressor class name from custom config file path' do
      expect(Config.current(config_file_path).get(:runner)).to eq 'Second'
    end
  end

  context 'test_framework' do
    it 'return test framework name from default config file path' do
      expect(Config.get(:test_framework)).to eq 'RSpec'
    end

    it 'return Compressor class name from custom config file path' do
      expect(Config.current(config_file_path).get(:test_framework)).to eq 'RSpec'
    end
  end
end

def config_file_path
  File.join(File.dirname(__FILE__), '/config.yml')
end
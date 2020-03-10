require 'config'

RSpec.describe Config, '#get' do
  context 'compressor' do
    it 'return Compressor class name from default config file path' do
      expect(Config.get(:compressor, :class)).to eq 'First'
    end

    it 'return Compressor class name from custom config file path' do
      expect(Config.current(file_path: config_file_path).get(:compressor, :class)).to eq 'First'
    end

    it 'return Compressor type from default config file path' do
      expect(Config.get(:compressor, :type)).to eq 'Zip'
    end

    it 'return Compressor type from custom config file path' do
      expect(Config.current(file_path: config_file_path).get(:compressor, :type)).to eq 'Zip'
    end
  end

  context 'runner' do
    it 'return Runner class name from default config file path' do
      expect(Config.get(:runner, :class)).to eq 'Second'
    end

    it 'return Runner class name from custom config file path' do
      expect(Config.current(file_path: config_file_path).get(:runner, :class)).to eq 'Second'
    end

    it 'return Runner type from default config file path' do
      expect(Config.get(:runner, :type)).to eq 'Rspec'
    end

    it 'return Runner type from custom config file path' do
      expect(Config.current(file_path: config_file_path).get(:runner, :type)).to eq 'Rspec'
    end
  end
end

def config_file_path
  File.join(File.dirname(__FILE__), '/config.yml')
end
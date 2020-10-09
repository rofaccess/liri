require 'compressor/zip'
require 'config'

RSpec.describe Zip, '#compress' do
  it 'return true' do
    compressor = Compressor::Zip.new(input_dir, output_file)
    compressor.compress
    expect(File.exist?(Config::COMPRESSED_FILE)).to be true

    Config.remove_config_dir
    expect(Dir.exist?(Config::CONFIG_DIR)).to be false
  end
end

def input_dir
  Config::SOURCE_CODE_DIR
end

def output_file
  Config::COMPRESSED_FILE
end

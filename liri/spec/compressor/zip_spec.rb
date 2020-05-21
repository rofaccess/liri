require 'compressor/zip'
require 'config'

RSpec.describe Zip, '#compress' do
  it 'return true' do
    compressor = Compressor::Zip.new(input_dir, output_file)
    compressor.compress
    expect(File.exist?(output_file)).to be true
  end
end

def input_dir
  File.dirname(__dir__)
end

def output_file
  File.join(root_code_folder, Config::COMPRESSED_SOURCE_CODE_TARGET_FOLDER, "#{root_code_folder_name}.zip")
end

def root_code_folder
  File.dirname(File.dirname(File.dirname(__FILE__)))
end

def root_code_folder_name
  root_code_folder.split('/').last
end
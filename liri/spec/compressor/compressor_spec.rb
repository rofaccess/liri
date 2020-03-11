require 'compressor/compressor'

RSpec.describe Compressor, '#compress' do
  it 'return true' do
    root_code_folder = File.dirname(File.dirname(File.dirname(__FILE__)))
    output_file = File.join(root_code_folder, '/', Config::CONFIG_FOLDER_NAME)
    expect(Compressor.current(input_dir: root_code_folder, output_file: output_file).write).to be true
  end
end
require 'compressor/compressor'

RSpec.describe Compressor, '#compress' do
  it 'return true' do
    root_code_folder = File.dirname(File.dirname(File.dirname(__FILE__)))
    root_code_folder_name = root_code_folder.split('/').last
    output_file = File.join(root_code_folder, Config::CONFIG_FOLDER_NAME, "#{root_code_folder_name}.zip")
    Compressor.current(input_dir: root_code_folder, output_file: output_file).write
    file_exist = File.exist?(output_file)
    expect(file_exist).to be true
    File.delete(output_file) if file_exist
  end
end
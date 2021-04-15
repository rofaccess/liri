RSpec.describe Zip, '#compress' do
  it 'crea el archivo comprimido' do
    compressor = Liri::Common::Compressor::Zip.new(input_dir, output_file)
    compressor.compress
    expect(File.exist?(output_file)).to be true

    File.delete(output_file)
    expect(File.exist?(output_file)).to be false
  end
end

# Get current test folder ../liri/spec/common/compressor
def input_dir
  File.dirname(__FILE__)
end

# Get path for compressed file name ../liri/spec/common/compressor/compressor.zip
def output_file
  File.join(input_dir, "#{input_dir.split('/').last}.zip")
end

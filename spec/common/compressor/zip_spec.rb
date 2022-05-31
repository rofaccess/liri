RSpec.describe Zip, '#compress' do
  it 'crea el archivo comprimido' do
    compressor = Liri::Common::Compressor::Zip.new(input_dir, output_file, "")
    compressor.compress

    expect(File.exist?(output_file)).to be true

    File.delete(output_file)
    expect(File.exist?(output_file)).to be false
  end
end

RSpec.describe Zip, '#descompress' do
  it 'descomprime un archivo zip' do
    dest= output_file.split('.zip').first
    zip_file = Liri::Common::Compressor::Zip.new(input_dir, output_file, "")
    zip_file.compress # genero el zip primero
    zip_file.decompress(output_file, dest)
    expect(Dir.exist?(dest)).to be true

    File.delete(output_file)
    expect(File.exist?(output_file)).to be false

    FileUtils.rm_rf(dest)
    expect(Dir.exist?(dest)).to be false

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

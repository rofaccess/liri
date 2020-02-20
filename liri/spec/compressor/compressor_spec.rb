require 'compressor/compressor'

RSpec.describe Compressor, '#compress' do
  it 'return true' do
    directory_to_zip = "/home/lesliie/Documentos/TecnicoLopez"
    output_file = "/home/lesliie/Documentos/TecnicoLopez.zip"
    expect(Compressor.current(:First, directory_to_zip, output_file).write).to be true
  end
end
RSpec.describe Liri::Common::SourceCode do
  context 'cuando el codigo fuente comprimido no existe' do
    before(:all) do
      @source_code = Liri::Common::SourceCode.new(source_code_folder_path, compression_class, unit_test_class)
      @source_code.delete_compressed_file
    end

    describe '#compress_folder' do
      it 'crea el archivo comprimido' do
        expect(@source_code.compress_folder).to be true
        expect(File.exist?(@source_code.compressed_file_path)).to be true
      end

      after(:all) do
        @source_code.delete_compressed_file
      end
    end

    describe '#decompress_file' do
      it 'Lanza FileNotFoundError' do
        expect { @source_code.decompress_file }.to raise_error(Liri::FileNotFoundError)
      end
    end

    describe '#delete_compressed_file' do
      it 'no borra nada' do
        expect(@source_code.delete_compressed_file).to be false
        expect(File.exist?(@source_code.compressed_file_path)).to be false
      end
    end

    describe '#delete_decompressed_file_folder_path' do
      it 'no borra nada' do
        expect(@source_code.delete_decompressed_file_folder_path).to be false
        expect(Dir.exist?(@source_code.decompressed_file_folder_path)).to be false
      end
    end
  end

  context 'cuando el codigo fuente comprimido ya existe' do
    before(:all) do
      @source_code = Liri::Common::SourceCode.new(source_code_folder_path, compression_class, unit_test_class)
      @source_code.compress_folder
    end

    describe '#compress_folder' do
      it 'sobreescribe el archivo comprimido' do
        expect(@source_code.compress_folder).to be true
        expect(File.exist?(@source_code.compressed_file_path)).to be true
      end
    end

    describe '#decompress_file' do
      it 'descomprime el archivo comprimido' do
        @source_code.compress_folder
        expect(@source_code.decompress_file).to be true
      end

      after(:all) do
        @source_code.delete_compressed_file
        @source_code.delete_decompressed_file_folder_path
      end
    end

    describe '#delete_compressed_file' do
      it 'borra el archivo comprimido' do
        @source_code.compress_folder
        expect(@source_code.delete_compressed_file).to be true
        expect(File.exist?(@source_code.compressed_file_path)).to be false
      end
    end

    describe '#delete_decompressed_file_folder_path' do
      it 'borra la carpeta' do
        Dir.mkdir(@source_code.decompressed_file_folder_path) unless Dir.exist?(@source_code.decompressed_file_folder_path)
        expect(@source_code.delete_decompressed_file_folder_path).to be true
        expect(Dir.exist?(@source_code.decompressed_file_folder_path)).to be false
      end
    end

    after(:all) do
      @source_code.delete_compressed_file
    end
  end

  after(:all) do
    Liri.delete_setup_folder
  end
end
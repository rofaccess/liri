RSpec.describe Liri::Common::SourceCode do
  context 'cuando el codigo fuente comprimido no existe' do
    before(:all) do
      @source_code = Liri::Common::SourceCode.new(compression_class, manager_unit_test_class)
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

    describe '#delete_compressed_file' do
      it 'no borra nada' do
        expect(@source_code.delete_compressed_file).to be false
        expect(File.exist?(@source_code.compressed_file_path)).to be false
      end
    end
  end

  context 'cuando el codigo fuente comprimido ya existe' do
    before(:all) do
      @source_code = Liri::Common::SourceCode.new(compression_class, manager_unit_test_class)
      @source_code.compress_folder
    end

    describe '#compress_folder' do
      it 'sobreescribe el archivo comprimido' do
        expect(@source_code.compress_folder).to be true
        expect(File.exist?(@source_code.compressed_file_path)).to be true
      end
    end

    describe '#delete_compressed_file' do
      it 'borra el archivo comprimido' do
        expect(@source_code.delete_compressed_file).to be true
        expect(File.exist?(@source_code.compressed_file_path)).to be false
      end
    end

    after(:all) do
      @source_code.delete_compressed_file
    end
  end
end
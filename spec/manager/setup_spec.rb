RSpec.describe Liri::Manager::Setup do
  context 'cuando el archivo de configuración no existe' do
    before(:all) do
      @setup = Liri::Manager::Setup.new(dummy_app_folder_path)
      @setup.delete_folder
    end

    describe '#init' do
      it 'crea la carpeta y el archivo de configuración' do
        expect(@setup.init).to be true
        expect(Dir.exist?(@setup.folder_path)).to be true
        expect(File.exist?(@setup.file_path)).to be true
      end

      after(:all) do
        @setup.delete_folder
      end
    end

    describe '#load' do
      it 'lanza Liri::FileNotFoundError' do
        expect { @setup.load }.to raise_error(Liri::FileNotFoundError)
        expect(File.exist?(@setup.file_path)).to be false
      end
    end

    describe '#delete_folder' do
      it 'no borra nada' do
        expect(@setup.delete_folder).to be false
        expect(Dir.exist?(@setup.folder_path)).to be false
      end
    end

    describe '#delete_file' do
      it 'no borra nada' do
        expect(@setup.delete_file).to be false
        expect(File.exist?(@setup.file_path)).to be false
      end
    end
  end

  context 'cuando el archivo de configuración ya existe' do
    before(:all) do
      @setup = Liri::Manager::Setup.new(dummy_app_folder_path)
      @setup.init
    end

    describe '#create' do
      it 'no crea el archivo de configuración' do
        expect(@setup.init).to be true
        expect(Dir.exist?(@setup.folder_path)).to be true
        expect(File.exist?(@setup.file_path)).to be true
      end
    end

    describe '#load' do
      it 'retorna los datos del archivo de configuración' do
        setup = @setup.load
        expect(setup).to be_an_instance_of(OpenStruct)
        expect(setup.library.compression).to eq('Zip')
        expect(setup.library.unit_test).to eq('Rspec')
        expect(setup.compressed_file_name).to eq('compressed_source_code')
      end
    end

    describe '#delete_folder' do
      it 'borra la carpeta de configuración' do
        expect(@setup.delete_folder).to be true
        expect(Dir.exist?(@setup.folder_path)).to be false
      end
    end

    describe '#delete_file' do
      it 'borra el archivo de configuración' do
        expect(@setup.delete_file).to be true
        expect(File.exist?(@setup.file_path)).to be false
      end
    end

    after(:all) do
      @setup.delete_folder
    end
  end
end


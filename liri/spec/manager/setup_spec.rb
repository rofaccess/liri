RSpec.describe Liri::Manager::Setup do
  context 'cuando el archivo de configuración no existe' do
    before(:all) do
      @setup = Liri::Manager::Setup.new(Liri::SETUP_FOLDER_PATH)
      @setup.delete if File.exist?(@setup.path)
    end

    describe '#create' do
      it 'crea el archivo de configuración' do
        expect(@setup.create).to be true
        expect(File.exist?(@setup.path)).to be true
      end

      after(:all) do
        @setup.delete
      end
    end

    describe '#load' do
      it 'lanza Liri::FileNotFoundError' do
        expect { @setup.load }.to raise_error(Liri::FileNotFoundError)
        expect(File.exist?(@setup.path)).to be false
      end
    end

    describe '#delete' do
      it 'no borra nada' do
        expect(@setup.delete).to be false
        expect(File.exist?(@setup.path)).to be false
      end
    end
  end

  context 'cuando el archivo de configuración ya existe' do
    before(:all) do
      @setup = Liri::Manager::Setup.new(Liri::SETUP_FOLDER_PATH)
      @setup.create
    end

    describe '#create' do
      it 'no crea el archivo de configuración' do
        expect(@setup.create).to be true
        expect(File.exist?(@setup.path)).to be true
      end
    end

    describe '#load' do
      it 'retorna los datos del archivo de configuración' do
        setup = @setup.load
        expect(setup).to be_an_instance_of(OpenStruct)
        expect(setup.library.compression).to eq('Zip')
        expect(setup.library.unit_test).to eq('Rspec')
        expect(setup.compressed_file_name).to eq('compressed_source_code')
        expect(File.exist?(@setup.path)).to be true
      end
    end

    describe '#delete' do
      it 'borra el archivo de configuración' do
        expect(@setup.delete).to be true
        expect(File.exist?(@setup.path)).to be false
      end

      after(:all) do
        @setup = Liri::Manager::Setup.new(Liri::SETUP_FOLDER_PATH)
        @setup.create
      end
    end

    after(:all) do
      @setup.delete if File.exist?(@setup.path)
    end
  end
end


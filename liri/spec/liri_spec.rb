# frozen_string_literal: true

RSpec.describe Liri do
  context 'cuando el archivo de configuración no existe' do
    before(:all) do
      Liri.delete_setup
      Liri.reset_setup
    end

    describe '#setup' do
      it 'carga los datos del archivo de configuración' do
        expect(Liri.setup).to be_an_instance_of(OpenStruct)
        expect(Liri.setup.library.compression).to eq('Zip')
        expect(Liri.setup.library.unit_test).to eq('Rspec')
        expect(Liri.setup.compressed_file_name).to eq('compressed_source_code')
      end

      after(:all) do
        Liri.delete_setup
        Liri.reset_setup
      end
    end

    describe '#delete_setup' do
      it 'no hace nada' do
        expect(Liri.delete_setup).to be false
      end
    end

    describe '#reset_setup' do
      it 'no hace nada' do
        expect(Liri.reset_setup).to be false
      end
    end
  end

  context 'cuando el archivo de configuración ya existe' do
    before(:all) do
      Liri.setup
    end

    describe '#setup' do
      it 'carga los datos del archivo de configuración' do
        expect(Liri.setup.library.compression).to eq('Zip')
        expect(Liri.setup.library.unit_test).to eq('Rspec')
        expect(Liri.setup.compressed_file_name).to eq('compressed_source_code')
      end
    end

    describe '#delete_setup' do
      it 'borra la configuración' do
        Liri.setup # al parecer los tests que ejecutan tests a veces borran el archivo de configuración
                   # por eso se se llama a Liri.setup para crear el archivo de configuración
        expect(Liri.delete_setup).to be true
      end
    end

    describe '#reset_setup' do
      it 'nulifica los datos de configuración' do
        expect(Liri.reset_setup).to be true
      end
    end

    after(:all) do
      Liri.delete_setup
      Liri.reset_setup
    end
  end
end

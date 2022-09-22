# frozen_string_literal: true

RSpec.describe Liri do
  context 'cuando no se inició el gestor de configuración' do
    describe '#setup' do
      it 'devuelve nil' do
        expect(Liri.setup).to be_nil
      end
    end

    describe '#delete_setup' do
      it 'no hace nada' do
        expect(Liri.delete_setup).to be false
      end
    end

    describe '#clear_setup' do
      it 'no hace nada' do
        expect(Liri.clear_setup).to be false
      end
    end
  end

  context 'cuando el gestor de condiguración está inciado' do
    before(:all) do
      Liri.set_setup(dummy_app_folder_path, :none)
    end

    describe '#setup' do
      it 'carga los datos del archivo de configuración' do
        expect(Liri.setup.general.library.compression).to eq('Zip')
        expect(Liri.setup.general.library.unit_test).to eq('Rspec')
        expect(Liri.setup.general.compressed_file_name).to eq('compressed_source_code')
      end
    end

    describe '#delete_setup' do
      it 'borra la carpeta y archivo de configuración' do
        expect(Liri.delete_setup).to be true
        # Crea de vuelta lo que borró para que otros tests no salgan afectados
        Liri.set_setup(dummy_app_folder_path, :none)
      end
    end

    describe '#clear_setup' do
      it 'nulifica los datos de configuración' do
        expect(Liri.clear_setup).to be true
        Liri.reload_setup
      end
    end

    after(:all) do
      Liri.clear_setup
      Liri.delete_setup
    end
  end
end

# How to test
#   https://code.tutsplus.com/es/articles/rspec-testing-for-beginners-part-1--cms-26716
#   https://code.tutsplus.com/es/articles/rspec-testing-for-beginners-02--cms-26720
#   https://code.tutsplus.com/articles/rspec-testing-for-beginners-03--cms-26728
#   https://www.betterspecs.org/
require 'manager/setup/file'

RSpec.describe Liri::Manager::Setup::File do
  context 'when setup file no exist' do
    before(:all) do
      @setup_file = Liri::Manager::Setup::File.new
      @setup_file.delete if File.exist?(@setup_file.path)
    end

    describe '#create' do
      it 'create liri setup file' do
        expect(@setup_file.create).to be true
        expect(File.exist?(@setup_file.path)).to be true
      end

      after(:all) do
        @setup_file.delete
      end
    end

    describe '#load' do
      it 'raises a Setup::FileNotFoundError' do
        expect { @setup_file.load }.to raise_error(Liri::Manager::Setup::FileNotFoundError)
        expect(File.exist?(@setup_file.path)).to be false
      end
    end

    describe '#delete' do
      it 'raises a Setup::FileNotFoundError' do
        expect { @setup_file.delete }.to raise_error(Liri::Manager::Setup::FileNotFoundError)
        expect(File.exist?(@setup_file.path)).to be false
      end
    end
  end

  context 'when setup file already exist' do
    before(:all) do
      @setup_file = Liri::Manager::Setup::File.new
      @setup_file.create
    end

    describe '#create' do
      it 'not create liri setup file' do
        expect(@setup_file.create).to be false
        expect(File.exist?(@setup_file.path)).to be true
      end
    end

    describe '#load' do
      it 'load liri setup file' do
        expect(@setup_file.load).to be_an_instance_of(OpenStruct)
        expect(Liri.config.implementation.compressor).to eq('Zip')
        expect(Liri.config.implementation.runner).to eq('Rspec')
        expect(Liri.config.setup.folder_name).to eq('.liri')
        expect(Liri.config.source_code.compressed_file_name).to eq('compressed_source_code')
        expect(File.exist?(@setup_file.path)).to be true
      end
    end

    describe '#delete' do
      it 'delete liri setup file' do
        expect(@setup_file.delete).to be true
        expect(File.exist?(@setup_file.path)).to be false
      end
    end

    after(:all) do
      @setup_file.delete if File.exist?(@setup_file.path)
    end
  end
end


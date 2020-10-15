require 'manager/setup/folder'

RSpec.describe Liri::Manager::Setup::Folder do
  context 'when setup folder no exist' do
    before(:all) do
      @setup_folder = Liri::Manager::Setup::Folder.new
      @setup_folder.delete if Dir.exist?(@setup_folder.path)
    end

    describe '#create' do
      it 'create liri setup folder' do
        expect(@setup_folder.create).to be true
        expect(Dir.exist?(@setup_folder.path)).to be true
      end

      after(:all) do
        @setup_folder.delete
        Liri.delete_config
      end
    end

    describe '#delete' do
      it 'raises a Setup::FolderNotFoundError' do
        expect { @setup_folder.delete }.to raise_error(Liri::Manager::Setup::FolderNotFoundError)
        expect(Dir.exist?(@setup_folder.path)).to be false
      end
    end
  end

  context 'when setup folder already exist' do
    before(:all) do
      @setup_folder = Liri::Manager::Setup::Folder.new
      @setup_folder.create
    end

    describe '#create' do
      it 'not create liri setup folder' do
        expect(@setup_folder.create).to be false
        expect(Dir.exist?(@setup_folder.path)).to be true
      end
    end

    describe '#delete' do
      it 'delete liri setup folder' do
        expect(@setup_folder.delete).to be true
        expect(Dir.exist?(@setup_folder.path)).to be false
      end
    end

    after(:all) do
      @setup_folder.delete if Dir.exist?(@setup_folder.path)
    end
  end
end

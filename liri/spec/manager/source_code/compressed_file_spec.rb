require 'manager/source_code/compressed_file'

RSpec.describe Liri::Manager::SourceCode::CompressedFile do
  context 'when setup folder exist' do
    before(:all) do
      @setup_folder = Liri::Manager::Setup::Folder.new
      @setup_folder.create
      @source_code_folder = Liri::Manager::SourceCode::Folder.new
    end

    context 'when compressed file already exist' do
      before(:all) do
        @source_code_compressed_file = Liri::Manager::SourceCode::CompressedFile.new(@source_code_folder.path, @setup_folder.path)
        @source_code_compressed_file.create
      end

      describe '#create' do
        it 'create compressed file' do
          expect(@source_code_compressed_file.create).to be false
          expect(File.exist?(@source_code_compressed_file.path)).to be true
        end
      end

      describe '#delete' do
        it 'delete compressed file' do
          expect(@source_code_compressed_file.delete).to be true
          expect(File.exist?(@source_code_compressed_file.path)).to be false
        end
      end
    end

    context 'when compressed file no exist' do
      before(:all) do
        @source_code_compressed_file = Liri::Manager::SourceCode::CompressedFile.new(@source_code_folder.path, @setup_folder.path)
        @source_code_compressed_file.delete if File.exist?(@source_code_compressed_file.path)
      end

      describe '#create' do
        it 'create compressed file' do
          expect(@source_code_compressed_file.create).to be true
          expect(File.exist?(@source_code_compressed_file.path)).to be true
        end

        after(:all) do
          @source_code_compressed_file.delete
        end
      end

      describe '#delete' do
        it 'raises a SourceCode::CompressedFileNotFoundError' do
          expect { @source_code_compressed_file.delete }.to raise_error(Liri::Manager::SourceCode::CompressedFileNotFoundError)
          expect(File.exist?(@source_code_compressed_file.path)).to be false
        end
      end
    end

    after(:all) do
      @setup_folder.delete
      Liri.delete_config
    end
  end

  context 'when setup folder no exist' do
    before(:all) do
      @setup_folder = Liri::Manager::Setup::Folder.new
      @setup_folder.delete if Dir.exist?(@setup_folder.path)
      @source_code_folder = Liri::Manager::SourceCode::Folder.new
      @source_code_compressed_file = Liri::Manager::SourceCode::CompressedFile.new(@source_code_folder.path, @setup_folder.path)
    end

    describe '#create' do
      it 'raises a SourceCode::CompressedFileTargetFolderNotFoundError' do
        expect { @source_code_compressed_file.create }.to raise_error(Liri::Manager::SourceCode::CompressedFileTargetFolderNotFoundError)
        expect(File.exist?(@source_code_compressed_file.path)).to be false
      end
    end

    describe '#delete' do
      it 'raises a SourceCode::CompressedFileNotFoundError' do
        expect { @source_code_compressed_file.delete }.to raise_error(Liri::Manager::SourceCode::CompressedFileNotFoundError)
        expect(File.exist?(@source_code_compressed_file.path)).to be false
      end
    end
  end
end

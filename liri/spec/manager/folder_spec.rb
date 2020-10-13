require 'manager/folder'

RSpec.describe Liri::Manager::Folder do
  context '#create' do
    it 'Create .liri folder' do
      Liri::Manager::Folder.create
      expect(Dir.exist?(liri_folder)).to be true
    end
  end

  context 'delete' do
    it 'Delete .liri folder' do
      Liri::Manager::Folder.delete
      expect(Dir.exist?(liri_folder)).to be false
    end
  end
end

def liri_folder
  Liri::Manager::Folder::DIR
end

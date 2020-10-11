require 'manager/source_code'

RSpec.describe Liri::Manager::SourceCode do
  context '#compress' do
    it 'Create compressed file' do
      Liri::Manager::SourceCode.compress
      expect(File.exist?(compressed_file)).to be true
    end
  end

  context '#delete' do
    it 'Delete compressed file' do
      Liri::Manager::SourceCode.delete
      expect(Dir.exist?(compressed_file)).to be false
    end
  end
end

def compressed_file
  Liri::Manager::SourceCode::COMPRESSED_FILE
end

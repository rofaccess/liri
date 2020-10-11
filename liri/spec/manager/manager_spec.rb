require 'manager/manager'

RSpec.describe Liri::Manager, '#run' do
  Liri::Manager.run

  it 'Create .liri folder' do
    expect(Dir.exist?(Liri::Manager::Folder::DIR)).to be true
  end

  it 'Create compressed source code' do
    expect(File.exist?(Liri::Manager::SourceCode::COMPRESSED_FILE)).to be true
  end
end
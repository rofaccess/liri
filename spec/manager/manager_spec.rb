RSpec.describe Liri::Manager, '#run' do
  it 'run tests' do
    allow(Liri::Manager).to receive(:get_credentials).and_return(['user', 'password'])

    Liri::Manager.run(dummy_app_folder_path, true)

    Liri.clear_setup
    Liri.delete_setup
  end
end
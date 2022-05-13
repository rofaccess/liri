RSpec.describe Liri::Agent, '#run' do
  it 'run tests' do
    Liri::Agent.run(dummy_app_folder_path, true)

    Liri.clear_setup
    Liri.delete_setup
  end
end
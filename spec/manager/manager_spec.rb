RSpec.describe Liri::Manager, '#run' do
  it 'run tests' do
    allow(Liri::Manager).to receive(:get_credentials).and_return(['user', 'password'])

    #Liri::Manager.run(true)
  end

  after(:all) do
    #Liri.delete_setup_folder
  end
end
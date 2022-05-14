RSpec.describe Liri::Manager, '#run' do
  it 'run tests' do
    allow(Liri::Manager).to receive(:get_credentials).and_return(spec_credentials)

    @threads = []

    @threads << Thread.new do
      Liri::Agent.run(dummy_app_folder_path)
    end

    # Se espera un poco antes de iniciar el Manager, porque ambos van a tratar de crear las mismas carpetas
    # y chocan entre sí
    sleep(1)

    @threads << Thread.new do
      Liri::Manager.run(dummy_app_folder_path)
      @manager_process_finished = true
    end

    # Con este hilo se chequea constantemente si el manager ya terminó su proceso
    # cuando se considera terminado, entonces se terminan los hilos de procesos del Agent y del Manager
    @threads << Thread.new do
      until @manager_process_finished
        next unless @manager_process_finished
      end

      Liri.kill(@threads)
      Liri.set_setup(dummy_app_folder_path)
      Liri.clear_setup
      Liri.delete_setup
    end

    @threads.each(&:join)
  end
end



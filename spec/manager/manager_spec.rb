# Atención: Es recomendable comentar estos tests cuando se va a ejecutar los tests de Liri usando
# Liri desde la línea de comandos. Esto porque la ejecución de estos tests no funciona usando Liri en línea de comandos,
# tal vez por el uso de hilos.

RSpec.describe Liri::Manager, '#run' do
  # Cuidado: Al usar liri m dentro del proyecto Liri, el siguiente tests causa confusión en los resultados obtenidos
  # porque es un test que ejecuta tests.
  # No conviene usar este test en algun agente porque este test requiere usuario y contraseña que esta en un archivo yml
  # pero este usuario y contraseña no necesariamente coincidirá con otros agentes.
=begin
  it 'run tests with agent' do
    allow(Liri::Manager).to receive(:get_credentials).and_return(spec_credentials)
    allow(Liri).to receive(:udp_port).and_return(2001)
    allow(Liri).to receive(:tcp_port).and_return(2501)

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
      #Liri.set_setup(dummy_app_folder_path)
      Liri.clear_setup
      Liri.delete_setup
    end

    @threads.each(&:join)
  end
=end
  # El siguiente bloque es útil para debuguear
=begin
  it 'run tests' do
    allow(Liri::Manager).to receive(:get_credentials).and_return(spec_credentials)
    # Comentar las siguientes 3 lineas cuando se va a debugear junto el ejecutable liri a
    allow(Liri).to receive(:udp_port).and_return(2001)
    allow(Liri).to receive(:tcp_port).and_return(2501)
    Liri::Manager.run(dummy_app_folder_path, false) # Poner parametro a false para debugear con agent_spec

    #Liri::Manager.run(liri_folder_path, false)

    Liri.clear_setup
    Liri.delete_setup
  end
=end

end




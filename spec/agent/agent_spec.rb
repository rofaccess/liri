# Atención: Si hay algún error que diga que la contraseña es incorrecta cuando es correcta, podría ser por haber hecho
# varios intentos fallidos, entonces la contraseña se bloquea por 10 minutos en Manjaro.
RSpec.describe Liri::Agent, '#run' do
  it 'run tests' do
    # Comentar las siguientes tres lineas cuando se va a debugear junto al ejecutable liri m
    allow(Liri).to receive(:udp_port).and_return(2001)
    allow(Liri).to receive(:tcp_port).and_return(2501)
    Liri::Agent.run(dummy_app_folder_path, true)

    #Liri::Agent.run(liri_folder_path, false)

    Liri.clear_setup
    Liri.delete_setup
  end
end
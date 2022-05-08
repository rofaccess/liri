require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

# Define la tarea por defecto, esto hace que se ejecute el comando 'rake install' cuando se ejecuta 'rake' en linea de comandos
# De:
# - https://medium.com/@stephenagrice/making-a-command-line-ruby-gem-write-build-and-push-aec24c6c49eb
task :default => :install

Rake::Task["build"].clear # Borra la implementación por defecto de build
# Compila la gema
# > rake build
task :build do
  system "gem build " + Liri::NAME + ".gemspec"
end

# El instalador del agente se encuentra en la carpeta /installers/liriagent
# Esta tarea copia la gema compilada dentro de la carpeta liriagent/lib
task :update_agent_installer do
  # Obtiene la ubicación en donde se enviará la gema compilada
  liriagent_lib_path =  File.expand_path("./installers/liriagent/lib")
  # Escribe un archivo con la versión actual de Liri, la versión indicada en este archivo se usará para instalar y actualizar el agente
  system("echo '#{Liri::VERSION}' > ./installers/liriagent/bin/.liri-version")
  # Obtiene la dirección de la gema compilada
  compiled_gem_file_path = File.join(Dir.pwd,"/#{Liri::NAME}-#{Liri::VERSION}.gem")
  # Se copia la gema compilada a la ubicación deseada
  system "cp #{compiled_gem_file_path} #{liriagent_lib_path}"
end

# El instalador del agente se encuentra en una carpeta llamada liriagent que está en la carpeta que contiene a la carpeta actual del proyecto
# Esta tarea comprime la carpeta liriagent en un archivo zip
task :compress_agent_installer do
  # Define el nombre del archivo comprimido
  zip_name = 'liriagent.zip'
  agent_installer_compressed_path = File.expand_path("./installers")
  Dir.chdir(agent_installer_compressed_path) do
    system "zip -r #{zip_name} liriagent/"
  end
end

Rake::Task["install"].clear # Borra la implementación por defecto de install
# Instala la gema después de compilar
# > rake install
# Esta tarea compila la gema, copia la gema en el instalador del agente y crea un nuevo comprimido zip del instalador del agente
task :install => [:build, :update_agent_installer, :compress_agent_installer] do
  system "gem install " + Liri::NAME + "-" + Liri::VERSION + ".gem"
end

# Publica la gema después de compilar.
# > rake publish
task :publish => :build do
  system 'gem push ' + Liri::NAME + "-" + Liri::VERSION + ".gem"
end

Rake::Task["clean"].clear # Borra la implementación por defecto de clean
# Borra la gema compilada
# > rake clean
task :clean do
  system "rm *.gem"
end
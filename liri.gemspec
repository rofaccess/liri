require_relative 'lib/liri.rb'

Gem::Specification.new do |spec|
  spec.name          = Liri::NAME
  spec.version       = Liri::VERSION
  spec.authors       = ["Rodrigo Fernández", "Leslie López"]
  spec.email         = ["rofaccess@gmail.com", "leslyee.05@gmail.com"]

  spec.summary       = "TFG Project"
  spec.description   = "Test distributor executor"
  spec.homepage      = "https://github.com/rofaccess/tfg"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rofaccess/tfg/liri"
  spec.metadata["changelog_uri"] = "https://github.com/rofaccess/tfg/blob/master/liri/README.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    # La siguiente línea debe comentarse al momento de ejecutar liri m dentro del proyecto Liri cuando porque al tratar de ejecutar pruebas de este código fuente
    # con agentes ejecutandose en distribuciones Linux y Ubuntu, por algún motivo ocurre el siguiente error:
    #
    # Esta línea es crítica, debe estar si o sí habilitada al compilar la gema
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Rubyzip is a ruby library for reading and writing zip files. https://github.com/rubyzip/rubyzip
  # Se usa para comprimir el código fuente en el Manager y descomprimir el código fuente recibido en el Agent
  spec.add_runtime_dependency('rubyzip', '~> 2')

  # The complete solution for Ruby command-line executables. https://github.com/commander-rb/commander
  # Se usa para pasar comandos a la gema Liri
  spec.add_runtime_dependency('commander', '~> 4')

  # HighLine was designed to ease the tedious tasks of doing console input and output with low-level methods like gets and puts. https://github.com/JEG2/highline
  # Se usa para pedir password en el Manager
  spec.add_runtime_dependency('highline', '~> 2')

  # Net::SCP is a pure-Ruby implementation of the SCP protocol. This operates over SSH (and requires the Net::SSH library), and allows files and directory trees to be copied to and from a remote server. https://github.com/net-ssh/net-scp
  # Se usa para obtener el código fuente del Manager desde el Agent
  spec.add_runtime_dependency('net-scp', '~> 3')

  # A Ruby gem for converting seconds into human-readable format. https://github.com/digaev/to_duration
  # Se usa para convertir un tiempo en segundos a un formato más legible
  spec.add_runtime_dependency('to_duration', '~> 1')

  # Ruby internationalization and localization (i18n) solution. https://github.com/ruby-i18n/i18n
  # Este es un requerimiento de la gema to_duration
  spec.add_runtime_dependency('i18n', '~> 1')
end
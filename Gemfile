# frozen_string_literal: true

# Obs.: Al agregar nuevas gemas, el formato debe ser el siguiente:
# gem 'rake', '~> 13'
# De este modo se asegura que la versión instalada es igua o mayor que 13.0.0 y menor a 14.0.0
# Se usa este formato porque cuando la versión cambia de 13 a 14, en teoría la compatibilidad se pierde
# Más info: https://blog.makeitreal.camp/manejo-de-dependencias-en-ruby-con-bundler/

source 'https://rubygems.org'

# Specify your gem's dependencies in liri.gemspec
gemspec

# Rake is a Make-like program implemented in Ruby. Tasks and dependencies are specified in standard Ruby syntax. https://github.com/ruby/rake
# Se usa para compilar la gema Liri
gem 'rake', '~> 13'

# Behaviour Driven Development for Ruby. https://github.com/rspec/rspec
# Se usa para testear la gema Liri
gem 'rspec', '~> 3.10.0'

# Fast and easy syntax highlighting for selected languages, written in Ruby. https://github.com/rubychan/coderay
# Usado por rspec para mostrar los resultados resaltados cuando se guarda el resultado de la ejecución de las pruebas en un archivo html
gem 'coderay', '~>1'

group :development do
  # Ruby static code analyzer and formatter, based on the community Ruby style guide. https://github.com/rubocop-hq/rubocop
  gem 'rubocop', '~>1', require: false

  # A Ruby Documentation Tool. https://github.com/lsegal/yard
  gem 'yard', '~>0'
end

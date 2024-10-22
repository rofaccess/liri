# frozen_string_literal: true

require 'simplecov'
SimpleCov.start 'liri'

require 'bundler/setup'
require 'all_libraries'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def dummy_app_name
  'dummy-app'
end

def dummy_app_folder_path
  File.join(File.expand_path("./"), '/', dummy_app_name)
end

def test_files_by_runner
  1
end

# En vez de crear este metodo para pasarle las carpetas a ignorar a las clases SourceCode o Zip, se pudo usar un Stub
# sobre Liri.ignored_folders_in_compress, y llamar Liri.ignored_folders_in_compress directamente en la clase Zip
# pero es mejora pasar como parámetro, así Zip se mantiene independiente y se puede reutilizar sin depender del módulo Liri
def ignored_folders_in_compress
  ".git,some_folder"
end

def spec_credentials_file_path
  File.expand_path('./spec_credentials.yml')
end

def liri_folder_path
  File.expand_path('./')
end

def spec_credentials
  data = YAML.load(File.read(spec_credentials_file_path))
  [data['user'], data['password']]
end

def unit_test_class
  "Liri::Common::UnitTest::Rspec"
end

def compression_class
  "Liri::Common::Compressor::Zip"
end


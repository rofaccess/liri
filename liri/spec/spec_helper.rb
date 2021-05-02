# frozen_string_literal: true

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

def source_code_folder_path
  Liri::Manager::SourceCode::FOLDER_PATH
end

def test_samples_by_runner
  Liri.setup.test_samples_by_runner
end

def agent_unit_test_class
  "Liri::Agent::UnitTest::#{Liri.setup.library.unit_test}"
end

def manager_unit_test_class
  "Liri::Manager::UnitTest::#{Liri.setup.library.unit_test}"
end

def compression_class
  "Liri::Common::Compressor::#{Liri.setup.library.compression}"
end


# This module contains some generic program data like name and version

module Liri
  NAME = 'liri' # Using downcase because some action like found gemspec depend with this
  VERSION = "0.1.0"

  class << self
    attr_accessor :config

    def config
      @config ||= load_config
    end

    def load_config
      @setup_file = Liri::Manager::Setup::File.new
      @setup_file.create unless File.exist?(@setup_file.path)
      @setup_file.load
    end

    def reset_config
      @config = nil
    end

    def delete_config
      @setup_file.delete if File.exist?(@setup_file.path)
    end
  end
end

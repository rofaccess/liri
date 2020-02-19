require 'yaml'
require 'mixin/singleton'

class Config
    extend Mixin::Singleton

  CONFIG_FOLDER_NAME = '.liri'
  CONFIG_FILE_NAME = 'config.yml'

  class << self
    def get(class_type)
      current.get(class_type)
    end
  end

  def initialize(args)
    config_file_path = args.first || default_config_file_path
    @conf_data = YAML.load(File.read(config_file_path))
  end

  def load_instance
    self
  end

  def get(class_type)
    @conf_data[class_type.to_s]
  end

  private

  def default_config_file_path
    File.join(default_config_folder_path, CONFIG_FILE_NAME)
  end

  def default_config_folder_path
    File.join(File.dirname(current_folder_path), '/', CONFIG_FOLDER_NAME)
  end

  def current_folder_path
    File.dirname(__FILE__)
  end
end
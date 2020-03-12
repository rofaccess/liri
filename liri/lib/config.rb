require 'yaml'
require 'mixin/singleton'

class Config
  extend Mixin::Singleton
  init_singleton

  CONFIG_FOLDER_NAME = '.liri'
  CONFIG_FILE_NAME = 'config.yml'
  CONFIG_INPUT_FILE_NAME = File.dirname(__dir__) #cambiar por otro método para obtener nombre del projecto que ejecutará la gema
  CONFIG_OUTPUT_FILE_NAME = File.join(CONFIG_INPUT_FILE_NAME, CONFIG_FOLDER_NAME, "#{CONFIG_INPUT_FILE_NAME.split('/').last}.zip")  #cambiar por otro método para obtener nombre del projecto que ejecutará la gema

  class << self
    def get(*config)
      current.get(config)
    end
  end

  def load_instance
    self
  end

  def get(*config)
    conf = config.flatten
    conf_data[conf[0].to_s][conf[1].to_s]
  end

  private

  def conf_data
    @_conf_data ||= YAML.load(File.read(config_file_path))
  end

  def config_file_path
    @file_path || default_config_file_path
  end

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
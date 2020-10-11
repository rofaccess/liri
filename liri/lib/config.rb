require 'fileutils'

module Config
  SOURCE_CODE_DIR = Dir.pwd
  SOURCE_CODE_DIR_NAME = SOURCE_CODE_DIR.split('/').last
  CONFIG_DIR_NAME = '.liri'
  CONFIG_DIR = File.join(SOURCE_CODE_DIR, '/', CONFIG_DIR_NAME)
  COMPRESSED_FILE_NAME = "#{SOURCE_CODE_DIR_NAME}_source_code.zip"


  def self.config_dir
    Dir.mkdir(CONFIG_DIR) unless Dir.exist?(CONFIG_DIR)
    CONFIG_DIR
  end

  COMPRESSED_FILE = File.join(config_dir, '/', COMPRESSED_FILE_NAME)

  def self.remove_config_dir
    FileUtils.rm_rf(config_dir) if Dir.exist?(CONFIG_DIR)
  end
end
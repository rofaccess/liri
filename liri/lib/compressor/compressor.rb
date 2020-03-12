require 'config'
require 'mixin/singleton'
require 'compressor/zip/first'

class Compressor
  extend Mixin::Singleton
  init_singleton

  class << self
    def compress

      Compressor.current(input_dir: Config::CONFIG_INPUT_FILE_NAME, output_file: Config::CONFIG_OUTPUT_FILE_NAME).write
    end
  end

  def load_instance
    compressor = @compressor || Config.get(:compressor, :class)
    type = @type || Config.get(:compressor, :type)
    input_dir = @input_dir || Config.get(:compressor, :input_dir)
    output_file = @output_file || Config.get(:compressor, :output_file)
    file_exist = File.exist?(output_file)
    File.delete(output_file) if file_exist
    Object.const_get("#{self.class}::#{type}::#{compressor}").new(input_dir, output_file)
  end
end
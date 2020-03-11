require 'config'
require 'mixin/singleton'
require 'compressor/zip/first'

class Compressor
  extend Mixin::Singleton
  init_singleton

  class << self
    def compress
      current.compress
    end
  end

  def load_instance
    compressor = @compressor || Config.get(:compressor, :class)
    type = @type || Config.get(:compressor, :type)
    input_dir = @input_dir || Config.get(:compressor, :input_dir)
    output_file = @output_file || Config.get(:compressor, :output_file)
    Object.const_get("#{self.class}::#{type}::#{compressor}").new(input_dir, output_file)
  end
end
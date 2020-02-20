require 'config'
require 'mixin/singleton'
require 'compressor/first'

class Compressor
  extend Mixin::Singleton

  class << self
    def compress
      current.compress
    end
  end

  def initialize(args)
    @compressor_class_name = "#{self.class}::#{args.first || Config.get(:compressor)}"
    @input_dir = args[1]
    @output_file = args[2]
  end

  def load_instance
    Object.const_get(@compressor_class_name).new(@input_dir, @output_file)
  end
end
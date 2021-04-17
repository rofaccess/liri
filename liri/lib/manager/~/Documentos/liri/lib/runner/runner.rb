require 'config'
require 'mixin/singleton'
require 'runner/first'
require 'runner/second'

class Runner
  extend Mixin::Singleton

  class << self
    def run
      current.run
    end
  end

  def initialize(args)
    @runner_class_name = "#{self.class}::#{args.first || Config.get(:runner)}"
  end

  def load_instance
    Object.const_get(@runner_class_name).new
  end
end
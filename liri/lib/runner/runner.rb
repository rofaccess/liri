require 'config'
require 'mixin/singleton'
require 'runner/rspec/first'
require 'runner/rspec/second'

class Runner
  extend Mixin::Singleton
  init_singleton

  class << self
    def run
      current.run
    end
  end

  def load_instance
    runner = @runner || Config.get(:runner, :class)
    type = @type || Config.get(:runner, :type)
    Object.const_get("#{self.class}::#{type}::#{runner}").new
  end
end
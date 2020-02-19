require 'config'

module Liri
  class << self
    def start
      load_config
      load_runner
      #start_runner
    end

    private
    def load_config
      Liri::Config.load
    end

    def load_runner
      runner_class_name = Liri::Config.get(:runner)
      Liri::Runner.load(runner_class_name)
    end

    def start_runner
      Liri::Runner.start
    end
  end
end

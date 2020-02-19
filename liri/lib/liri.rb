module Liri
  class << self
    def run
      load_conf
      #run_tests
    end

    private

    def load_conf
      Liri::Config.load
    end

    def run_tests
      Liri::Runner.load(Liri::Config.get(:runner))
      Liri::Runner.run
    end
  end
end

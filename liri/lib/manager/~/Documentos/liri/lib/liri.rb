require 'runner/runner'

module Liri
  class << self
    def run
      #Compressor.compress
      #Sender.send
      Runner.run
    end
  end
end

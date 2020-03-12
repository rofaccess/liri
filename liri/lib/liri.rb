require 'runner/runner'
require 'compressor/compressor'

module Liri
  class << self
    def run
      Compressor.compress
      #Sender.send

      #Runner.run

    end
      Liri.run
  end
end

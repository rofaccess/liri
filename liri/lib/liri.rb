require 'runner/runner'
require 'compressor/compressor'

module Liri
  class << self
    def run
      puts "Starting Testing Process"
      Compressor.compress
      #Sender.send

      #Runner.run
      puts "Finished Testing Process"
    end
  end
end

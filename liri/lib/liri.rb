require "liri/version"

module Liri
  class Error < StandardError; end

  class Greet
    def self.hello
      return "Hello!!!"
    end
  end
end

require 'bundler/setup'

module Liri
  class Test
    def self.run(path)
      system("bundle exec rspec #{path}")
    end
  end
end

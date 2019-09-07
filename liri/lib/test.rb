require 'bundler/setup'

module Liri
  class Test
    def self.run(path)
      system("bundle exec rspec #{path} --format progress --out rspec_result.txt --no-color")
    end
  end
end
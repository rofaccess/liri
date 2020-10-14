# This module contains some generic program data like name and version

module Liri
  NAME = 'liri' # Using downcase because some action like found gemspec depend with this
  VERSION = "0.1.0"

  # Configuration
  # From:
  #   http://lizabinante.com/blog/creating-a-configurable-ruby-gem/
  #   https://www.skcript.com/svr/the-easiest-configuration-block-for-your-ruby-gems/
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def reset
      self.configuration = Configuration.new
    end
  end
end

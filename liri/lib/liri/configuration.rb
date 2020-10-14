# From:
#   http://lizabinante.com/blog/creating-a-configurable-ruby-gem/
#   https://www.skcript.com/svr/the-easiest-configuration-block-for-your-ruby-gems/

module Liri
  class Configuration
    attr_accessor :compressor, :runner, :connection

    def initialize
      @compressor = nil
      @runner = nil
      @connection = nil
    end
  end
end
module Liri
  module Module
    module Loadable
      # next class variable is to use singleton pattern
      @@instance = nil

      def load(*args)
        self.current = Config.new(args)
        true
      rescue StandardError => e
        # TODO Print log
        raise e
        false
      end
      private

      def current
        @@instance
      end

      def current=(instance)
        @@instance = instance
      end
    end
  end
end
module Mixin
  module Singleton
    # next class variable is to use singleton pattern
    @@instance = nil

    def current(*args)
      @@instance ||= load_instance(args)
    end

    private
    def load_instance(args)
      self.current = self.new(args).load_instance
    rescue StandardError => e
      # TODO Print log instead raise exception
      raise e
      nil
    end

    def current=(instance)
      @@instance = instance
    end
  end
end
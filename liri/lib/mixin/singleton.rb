module Mixin
  module Singleton
    # next class variable is to use singleton pattern
    @@instance = nil

    def init_singleton
      include InstanceMethods
    end

    def current(instance_params={})
      @@instance ||= load_instance(instance_params)
    end

    private
    def load_instance(instance_params)
      current = self.new
      current.set_instance_variables(instance_params)
      self.current = current.load_instance
    rescue StandardError => e
      # TODO Print log instead raise exception
      raise e
      nil
    end

    def current=(instance)
      @@instance = instance
    end

    module InstanceMethods
      def set_instance_variables(instance_params)
        instance_params.each do |key, value|
          self.instance_variable_set("@#{key}", value)
        end
      end
    end
  end
end
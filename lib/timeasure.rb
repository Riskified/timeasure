require 'timeasure/version'

module Timeasure
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def included(base_class)
      base_class.extend ClassMethods

      instance_interceptor = const_set(instance_interceptor_name_for(base_class), interceptor_module_for(base_class))
      class_interceptor = const_set(class_interceptor_name_for(base_class), interceptor_module_for(base_class))

      # TODO: needs to be solved, perhaps a #timeasure_enabled? method is needed, maybe an extra configuration proc
      # return if Rails.env.test? && disable_testing?

      base_class.prepend instance_interceptor
      base_class.singleton_class.prepend class_interceptor
    end

    private

    def instance_interceptor_name_for(base_class)
      "#{base_class.timeasure_name}InstanceInterceptor"
    end

    def class_interceptor_name_for(base_class)
      "#{base_class.timeasure_name}ClassInterceptor"
    end

    def interceptor_module_for(base_class)
      Module.new do
        @base_class = base_class

        def self.base_class
          @base_class
        end
      end
    end

    # def disable_testing?
    #   true
    # end
  end
end

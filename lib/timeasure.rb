require_relative 'timeasure/version'
require_relative 'timeasure/configuration'
require_relative 'timeasure/class_methods'
require_relative 'timeasure/measurement'
require_relative 'timeasure/profiling/manager'

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

      return unless timeasure_enabled?

      base_class.prepend instance_interceptor
      base_class.singleton_class.prepend class_interceptor
    end

    def measure(klass_name: nil, method_name: nil, segment: nil, metadata: nil)
      t0 = Time.now.utc
      block_return_value = yield if block_given?
      t1 = Time.now.utc

      begin
        measurement = Timeasure::Measurement.new(klass_name: klass_name.to_s, method_name: method_name.to_s,
                                                 segment: segment, metadata: metadata, t0: t0, t1: t1)
        Timeasure.configuration.post_measuring_proc.call(measurement)
      rescue => e
        Timeasure.configuration.rescue_proc.call(e, klass_name)
      end

      block_return_value
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
        @klass_name = base_class

        def self.klass_name
          @klass_name
        end
      end
    end

    def timeasure_enabled?
      configuration.enable_timeasure_proc.call
    end
  end
end

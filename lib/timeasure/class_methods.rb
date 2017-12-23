module Timeasure
  module ClassMethods
    def tracked_instance_methods(*method_names)
      method_names.each do |method_name|
        instance_interceptor = const_get("#{timeasure_name}InstanceInterceptor")
        add_method_to_interceptor(instance_interceptor, method_name)
      end
    end

    def tracked_class_methods(*method_names)
      method_names.each do |method_name|
        class_interceptor = const_get("#{timeasure_name}ClassInterceptor")
        add_method_to_interceptor(class_interceptor, method_name)
      end
    end

    def timeasure_name
      name.gsub('::', '_')
    end

    private

    def add_method_to_interceptor(interceptor, method_name)
      interceptor.class_eval do
        define_method method_name do |*args, &block|
          t0 = Time.now.utc
          method_return_value = super(*args, &block)
          t1 = Time.now.utc

          begin
            Timeasure.configuration.post_measuring_proc.call(interceptor.base_class.to_s, method_name.to_s, t0, t1)
          rescue => e
            Timeasure.configuration.rescue_proc.call(e, interceptor.base_class)
          end

          method_return_value
        end
      end
    end
  end
end

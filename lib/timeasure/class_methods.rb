module Timeasure
  module ClassMethods
    def tracked_instance_methods(*method_names)
      method_names.each do |method_name|
        add_method_to_interceptor(interceptor: instance_interceptor, method_name: method_name)
      end
    end

    def tracked_class_methods(*method_names)
      method_names.each do |method_name|
        add_method_to_interceptor(interceptor: class_interceptor, method_name: method_name)
      end
    end

    def timeasure_name
      name.gsub('::', '_')
    end

    private

    def add_method_to_interceptor(interceptor:, method_name:, private_method: false)
      interceptor.class_eval do
        define_method method_name do |*args, &block|
          Timeasure.measure(klass_name: interceptor.klass_name.to_s, method_name: method_name.to_s) do
            super(*args, &block)
          end
        end

        private method_name if private_method
      end
    end

    def instance_interceptor
      const_get("#{timeasure_name}InstanceInterceptor")
    end

    def class_interceptor
      const_get("#{timeasure_name}ClassInterceptor")
    end
  end
end

module Timeasure
  module ClassMethods
    def tracked_instance_methods(*method_names)
      method_names.each do |method_name|
        add_method_to_interceptor(instance_interceptor, method_name)
      end
    end

    def tracked_class_methods(*method_names)
      method_names.each do |method_name|
        add_method_to_interceptor(class_interceptor, method_name)
      end
    end

    def tracked_private_instance_methods(*method_names)
      tracked_instance_methods(*method_names)
      method_names.each { |method_name| privatize_interceptor_method(instance_interceptor, method_name) }
    end

    def tracked_private_class_methods(*method_names)
      tracked_class_methods(*method_names)
      method_names.each { |method_name| privatize_interceptor_method(class_interceptor, method_name) }
    end

    def timeasure_name
      name.gsub('::', '_')
    end

    private

    def add_method_to_interceptor(interceptor, method_name)
      interceptor.class_eval do
        define_method method_name do |*args, &block|
          Timeasure.measure(klass_name: interceptor.klass_name.to_s, method_name: method_name.to_s) do
            super(*args, &block)
          end
        end
      end
    end

    def privatize_interceptor_method(interceptor, method_name)
      interceptor.class_eval { private method_name }
    end

    def instance_interceptor
      const_get("#{timeasure_name}InstanceInterceptor")
    end

    def class_interceptor
      const_get("#{timeasure_name}ClassInterceptor")
    end
  end
end

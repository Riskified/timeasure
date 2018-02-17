module Timeasure
  module Profiling
    class ReportedMethod
      attr_reader :klass_name, :method_name, :segment, :metadata, :runtime_sum, :call_count

      def initialize(measurement)
        @klass_name = measurement.klass_name
        @method_name = measurement.method_name
        @segment = measurement.segment
        @metadata = measurement.metadata

        @runtime_sum = 0
        @call_count = 0
      end

      def increment_runtime_sum(runtime)
        @runtime_sum += runtime
      end

      def increment_call_count
        @call_count += 1
      end

      def full_path
        @segment.nil? ? method_path : "#{method_path}:#{@segment}"
      end

      def method_path
        "#{@klass_name}##{@method_name}"
      end
    end
  end
end

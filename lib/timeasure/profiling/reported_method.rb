module Timeasure
  module Profiling
    class ReportedMethod
      attr_reader :klass_name, :method_name, :segment, :metadata, :full_path, :method_path, :runtime_sum, :call_count

      def initialize(measurement)
        @klass_name = measurement.klass_name
        @method_name = measurement.method_name
        @segment = measurement.segment
        @metadata = measurement.metadata
        @full_path = measurement.full_path
        @method_path = measurement.method_path

        @runtime_sum = 0
        @call_count = 0
      end

      def increment_runtime_sum(runtime)
        @runtime_sum += runtime
      end

      def increment_call_count
        @call_count += 1
      end
    end
  end
end

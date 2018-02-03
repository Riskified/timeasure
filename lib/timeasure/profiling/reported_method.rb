module Timeasure
  module Profiling
    class ReportedMethod
      attr_reader :klass_name, :method_name, :segment, :metadata, :runtime_sum, :call_count

      def initialize(klass_name:, method_name:, segment:, metadata:)
        @klass_name = klass_name
        @method_name = method_name
        @segment = segment
        @metadata = metadata

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

module Timeasure
  module Profiling
    class ReportedMethodsHandler
      def initialize
        @reported_methods = {}
      end

      def report(measurement)
        initialize_path_for(measurement) if path_uninitialized_for(measurement)

        @reported_methods[measurement.full_path].increment_runtime_sum(measurement.runtime_in_milliseconds)
        @reported_methods[measurement.full_path].increment_call_count
      end

      def export
        @reported_methods.values
      end

      private

      def path_uninitialized_for(measurement)
        @reported_methods[measurement.full_path].nil?
      end

      def initialize_path_for(measurement)
        @reported_methods[measurement.full_path] = ReportedMethod.new(measurement)
      end
    end
  end
end

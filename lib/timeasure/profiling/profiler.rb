require_relative 'reported_methods_handler'
require_relative 'reported_method'

module Timeasure
  module Profiling
    class Profiler
      class << self
        def prepare
          Timeasure.configuration.reported_methods_handler_ref_set_proc.call(ReportedMethodsHandler.new)
        end

        def report(measurement)
          reported_methods_handler&.report(measurement)
        end

        def export
          reported_methods_handler&.reported_methods&.values || []
        end

        private

        def reported_methods_handler
          Timeasure.configuration.reported_methods_handler_ref_get_proc.call
        end
      end
    end
  end
end

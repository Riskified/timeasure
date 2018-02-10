require 'logger'
require_relative 'reported_methods_handler'
require_relative 'reported_method'

module Timeasure
  module Profiling
    class Manager
      class << self
        def prepare
          Timeasure.configuration.reported_methods_handler_set_proc.call(ReportedMethodsHandler.new)
        end

        def report(measurement)
          handler = reported_methods_handler
          warn_unprepared_handler if handler.nil?
          handler.report(measurement)
        end

        def export
          handler = reported_methods_handler
          warn_unprepared_handler if handler.nil?
          handler.reported_methods.values || []
        end

        private

        def reported_methods_handler
          Timeasure.configuration.reported_methods_handler_get_proc.call
        end

        def warn_unprepared_handler
          logger.warn("#{self} is not prepared. Call Timeasure::Profiling::Manager.prepare before trying to report measurements or export reported methods.")
        end

        def logger
          @logger ||= Logger.new(STDOUT)
        end
      end
    end
  end
end

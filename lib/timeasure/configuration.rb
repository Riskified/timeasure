module Timeasure
  class Configuration
    attr_accessor :post_measuring_proc, :rescue_proc, :enable_timeasure_proc,
                  :reported_methods_handler_set_proc, :reported_methods_handler_get_proc

    def initialize
      @post_measuring_proc = lambda do |measurement|
        # Enables the configuration of what to do with each method runtime measurement.
        # By default it reports to Timeasure's Profiling Manager.

        Timeasure::Profiling::Manager.report(measurement)
      end

      @rescue_proc = lambda do |e, klass|
        # Enabled the configuration of post_measuring_proc rescue.
      end

      @enable_timeasure_proc = lambda do
        # Enables toggling Timeasure's activation (e.g. for disabling Timeasure for RSpec).

        true
      end

      @reported_methods_handler_set_proc = lambda do |reported_methods_handler|
        # Enables configuring where to store the ReportedMethodsHandler instance.
        # This proc will be called by Timeasure::Profiling::Manager.prepare.
        # By default it stores the handler as a class instance variable (in Timeasure::Profiling::Manager)

        @reported_methods_handler = reported_methods_handler
      end

      @reported_methods_handler_get_proc = lambda do
        # Enables configuring where to fetch the ReportedMethodsHandler instance.
        # This proc will be called by Timeasure::Profiling::Manager.report and Timeasure::Profiling::Manager.export.
        # By default it fetches the handler from the class instance variable
        # (see @reported_methods_handler_set_proc).

        @reported_methods_handler
      end
    end
  end
end

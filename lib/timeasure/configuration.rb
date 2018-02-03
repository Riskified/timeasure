module Timeasure
  class Configuration
    attr_accessor :post_measuring_proc, :rescue_proc, :enable_timeasure_proc

    def initialize
      @post_measuring_proc = lambda { |measurement| }
      @rescue_proc = lambda { |e, klass| }
      @enable_timeasure_proc = lambda { true }
    end
  end
end

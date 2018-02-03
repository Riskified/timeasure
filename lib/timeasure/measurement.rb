module Timeasure
  class Measurement
    attr_reader :klass_name, :method_name, :segment, :metadata, :t0, :t1

    def initialize(klass_name:, method_name:, t0:, t1:, segment: nil, metadata: nil)
      @klass_name = klass_name
      @method_name = method_name
      @t0 = t0
      @t1 = t1
      @segment = segment
      @metadata = metadata
    end

    def runtime_in_milliseconds
      (@t1 - @t0) * 1000
    end

    def full_path
      @segment.nil? ? method_path : "#{method_path}:#{@segment}"
    end

    def method_path
      "#{@klass_name}##{@method_name}"
    end
  end
end

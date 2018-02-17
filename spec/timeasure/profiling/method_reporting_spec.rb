require 'timeasure'

# This spec serves for both Timeasure::Profiling::ReportedMethodsHandler
# and Timeasure::Profiling::ReportedMethod as they represent one unit

RSpec.describe 'Timeasure::Profiling - Method Reporting' do
  let(:reported_methods_handler) { Timeasure::Profiling::ReportedMethodsHandler.new }

  let(:foo_measurement1) do
    double(:measurement, runtime_in_milliseconds: 10, full_path: foo_full_path, klass_name: anything,
           method_name: anything, segment: anything, metadata: anything, method_path: anything)
  end

  let(:foo_measurement2) do
    double(:measurement, runtime_in_milliseconds: 20, full_path: foo_full_path, klass_name: anything,
           method_name: anything, segment: anything, metadata: anything, method_path: anything)
  end

  let(:bar_measurement) do
    double(:measurement, runtime_in_milliseconds: 15, full_path: bar_full_path, klass_name: anything,
           method_name: anything, segment: anything, metadata: anything, method_path: anything)
  end

  let(:foo_full_path) { 'Foo#baz' }
  let(:bar_full_path) { 'Bar#baz' }

  let(:all_measurements) { [foo_measurement1, foo_measurement2, bar_measurement] }

  describe '#export' do
    let(:export) { reported_methods_handler.export }

    before { all_measurements.each { |measurement| reported_methods_handler.report(measurement) } }

    context 'return value type' do
      it 'returns an array of ReportedMethod objects' do
        expect(export).to all(be_a Timeasure::Profiling::ReportedMethod)
      end
    end

    context 'singularity by full path' do
      it 'holds a single ReportedMethod objects per Measurement#full_path' do
        expect(export.map(&:full_path)).to contain_exactly(*all_measurements.map(&:full_path).uniq)
      end
    end

    context 'aggregated values' do
      let(:foo_reported_method) { export.find { |reported_method| reported_method.full_path == foo_full_path } }
      let(:bar_reported_method) { export.find { |reported_method| reported_method.full_path == bar_full_path } }

      it 'aggregates runtime_sum per ReportedMethod' do
        expect(foo_reported_method.runtime_sum).to eq(foo_measurement1.runtime_in_milliseconds +
                                                          foo_measurement2.runtime_in_milliseconds)
        expect(bar_reported_method.runtime_sum).to eq(bar_measurement.runtime_in_milliseconds)
      end

      it 'aggregates call_count per ReportedMethod' do
        expect(foo_reported_method.call_count).to eq 2
        expect(bar_reported_method.call_count).to eq 1
      end
    end
  end
end

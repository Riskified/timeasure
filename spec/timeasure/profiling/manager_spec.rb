require 'timeasure'

RSpec.describe Timeasure::Profiling::Manager do
  before do
    # this emulates 'unpreparing' the Profiling Manager. This way tests are independent regarding their running order.
    Timeasure.configuration.reported_methods_handler_set_proc.call(nil)
  end

  describe '.report' do
    let(:report) { described_class.report(measurement) }
    let(:measurement) { double(:measurement) }

    context 'profiling manager is not prepared' do
      it 'logs a warning' do
        expect_any_instance_of(Logger).to receive(:warn)
        report
      end

      it 'does not call #report on reported_methods_handler' do
        expect_any_instance_of(Timeasure::Profiling::ReportedMethodsHandler).not_to receive(:report)
        report
      end
    end

    context 'profiling manager is prepared' do
      before do
        described_class.prepare
      end

      it 'calls #report on reported_methods_handler with measurement as argument' do
        expect_any_instance_of(Timeasure::Profiling::ReportedMethodsHandler).to receive(:report).with(measurement)
        report
      end
    end
  end

  describe '.export' do
    let(:export) { described_class.export }

    context 'profiling manager is not prepared' do
      it 'logs a warning' do
        expect_any_instance_of(Logger).to receive(:warn)
        export
      end

      it 'does not call #export on reported_methods_handler' do
        expect_any_instance_of(Timeasure::Profiling::ReportedMethodsHandler).not_to receive(:export)
        export
      end
    end

    context 'profiling manager is prepared' do
      before do
        described_class.prepare
      end

      it 'calls #export on reported_methods_handler with measurement as argument' do
        expect_any_instance_of(Timeasure::Profiling::ReportedMethodsHandler).to receive(:export)
        export
      end
    end
  end
end

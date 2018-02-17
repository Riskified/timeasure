require 'timeasure'

RSpec.describe Timeasure do
  before(:each) { Timeasure::Profiling::Manager.prepare }

  context 'direct interface' do
    describe '.measure' do
      let(:klass_name) { double }
      let(:method_name) { double }
      let(:segment) { double }
      let(:metadata) { double }

      context 'proper calls' do
        let(:measure) do
          described_class.measure(klass_name: klass_name, method_name: method_name,
                                  segment: segment, metadata: metadata) { :some_return_value }
        end

        it 'returns the return value of the code block' do
          expect(measure).to eq :some_return_value
        end

        it 'calls post_measuring_proc' do
          expect(Timeasure.configuration.post_measuring_proc).to receive(:call)
          measure
        end
      end

      context 'error handling' do
        context 'in the code block itself' do
          it 'raises an error normally' do
            expect { described_class.measure { raise 'some error in the code block!' } }.to raise_error(RuntimeError)
          end
        end

        context 'in the post_measuring_proc' do
          before do
            Timeasure.configure do |configuration|
              configuration.post_measuring_proc = lambda do |measurement|
                raise RuntimeError
              end
            end
          end

          it 'calls the rescue proc' do
            expect(Timeasure.configuration.rescue_proc).to receive(:call)
            described_class.measure { :some_return_value }
          end

          it 'does not interfere with block return value' do
            expect(described_class.measure { :some_return_value }).to eq :some_return_value
          end

          after do
            Timeasure.configure do |configuration|
              configuration.post_measuring_proc = lambda do |measurement|
                Timeasure::Profiling::Manager.report(measurement)
              end
            end
          end
        end
      end
    end
  end


  context 'DSL interface' do
    before do
      # The next section emulates the creation of a new class that includes Timeasure.
      # Since using the `Class.new` syntax is obligatory in test environment,
      # it has to be assigned to a constant first in order to have a name.

      FirstClass ||= Class.new
      unless FirstClass.ancestors.include? Timeasure
        FirstClass.class_eval do
          include Timeasure
          tracked_instance_methods :a_method, :a_method_with_args, :a_method_with_a_block
          tracked_class_methods :a_class_method

          def a_method
            true
          end

          def a_method_with_args(arg)
            arg
          end

          def a_method_with_a_block(&block)
            yield
          end

          def an_untracked_method
            'untracked method'
          end

          def self.a_class_method
            false
          end

          def self.an_untracked_class_method
            'untracked class method'
          end
        end
      end
    end

    let(:instance) { FirstClass.new }

    context 'methods return value' do
      it 'returns methods return values transparently' do
        expect(instance.a_method).to eq true
        expect(instance.a_method_with_args('arg')).to eq 'arg'
        expect(instance.a_method_with_a_block { true ? 8 : 0 }).to eq 8
        expect(FirstClass.a_class_method).to eq false
      end
    end
  end

  context 'profiler' do
    context 'reporting' do
      it 'reports each call trough Timeasure::Profiling::Manager.report' do
        expect(Timeasure::Profiling::Manager).to receive(:report).exactly(7).times

        2.times do
          Timeasure.measure(klass_name: 'Foo', method_name: 'bar') { :some_return_value }
        end

        5.times do
          Timeasure.measure(klass_name: 'Baz', method_name: 'qux') { :some_other_return_value }
        end
      end
    end

    context 'exporting' do
      before do
        3.times do
          Timeasure.measure(klass_name: 'Foo', method_name: 'bar') { :some_return_value }
        end

        4.times do
          Timeasure.measure(klass_name: 'Baz', method_name: 'qux') { :some_other_return_value }
        end
      end

      let(:export) { Timeasure::Profiling::Manager.export }

      it 'exports all calls in an aggregated manner' do
        expect(export.count).to eq 2
      end
    end
  end
end

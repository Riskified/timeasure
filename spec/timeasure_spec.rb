require 'timeasure'

RSpec.describe Timeasure do
  context 'direct interface' do
    describe '.measure' do
      let(:klass_name) { double }
      let(:method_name) { double }
      let(:segment) { double }
      let(:metadata) { double }

      context 'proper calls' do
        it 'returns the return value of the code block' do
          measure = described_class.measure(klass_name: klass_name,
                                            method_name: method_name,
                                            segment: segment,
                                            metadata: metadata) { :some_return_value }
          expect(measure).to eq :some_return_value
        end

        it 'calls post_measuring_proc' do
          expect(Timeasure.configuration.post_measuring_proc).to receive(:call)
          described_class.measure(klass_name: klass_name,
                                  method_name: method_name,
                                  segment: segment,
                                  metadata: metadata) { :some_return_value }
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

              configuration.rescue_proc = lambda do |e, klass_name|
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
        end
      end
    end
  end


  context 'DSL interface' do
    # Firstly, the setup emulates the configuration of Timeasure as if it was defined upon initalization.
    # The simplest form of handling measured methods timing is to report them to some global array.

    before do
      @timeasure_results = []
      Timeasure.configure do |configuration|
        configuration.post_measuring_proc = lambda do |measurement|
          @timeasure_results << { klass_name: measurement.klass_name,
                                  method_name: measurement.method_name,
                                  t0: measurement.t0,
                                  t1: measurement.t1 }
        end
      end

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
            yield(block)
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

          def self.an_erroneous_method
            raise RuntimeError
          end
        end
      end
    end

    context 'ancestor chain' do
      let(:ancestors_chain) { timeasured_class.ancestors }

      context 'non-namespaced class' do
        let(:timeasured_class) { FirstClass }

        context 'interceptors' do
          context 'tracked instance methods' do
            it 'is placed up first in the ancestors chain' do
              expect(ancestors_chain.first).to eq Timeasure::FirstClassInstanceInterceptor
            end

            it "has the base_class' specified instance tracked methods as instance methods" do
              expect(ancestors_chain.first.instance_methods(false)).to contain_exactly(:a_method, :a_method_with_args,
                                                                                       :a_method_with_a_block)
            end
          end

          context 'tracked class methods' do
            let(:singleton_ancestors_chain) { FirstClass.singleton_class.ancestors }

            it 'is placed up first in the ancestors chain' do
              expect(singleton_ancestors_chain.first).to eq Timeasure::FirstClassClassInterceptor
            end

            it "has the base_class' specified class tracked methods as class methods" do
              expect(singleton_ancestors_chain.first.instance_methods(false)).to contain_exactly(:a_class_method)
            end
          end
        end

        context 'calling class' do
          it 'is placed second in the ancestors chain' do
            expect(ancestors_chain[1]).to eq FirstClass
          end
        end
      end

      context 'namespaced class' do
        # This setup block helps in emulating the creation of a namespaced class.

        before do
          Namespace = Module.new
          concrete_class = Class.new
          Namespace.const_set 'Concrete', concrete_class
          Namespace::Concrete.class_eval { include Timeasure }
        end

        let(:timeasured_class) { Namespace::Concrete }

        it 'supports usage under namespace' do
          expect(ancestors_chain.first).to eq Timeasure::Namespace_ConcreteInstanceInterceptor
        end
      end
    end

    context 'method calling' do
      let!(:instance) { FirstClass.new }
      let!(:a_method_return_value) { instance.a_method }
      let!(:a_method_with_args_return_value) { instance.a_method_with_args('arg') }
      let!(:a_method_with_a_block_return_value) { instance.a_method_with_a_block { true ? 8 : 0 } }

      it 'returns methods return values transparently' do
        expect(a_method_return_value).to eq true
        expect(a_method_with_args_return_value).to eq 'arg'
        expect(a_method_with_a_block_return_value).to eq 8
      end

      it 'executes the post_measuring_proc lambda from Timeausre.configuration' do
        expect(@timeasure_results.count).to eq 3
        expect(@timeasure_results).to all(be_a Hash)
      end
    end
  end
end

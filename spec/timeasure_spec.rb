require 'timeasure'

RSpec.describe Timeasure do
  # Firstly, the setup emulates the configuration of Timeasure as if it was defined upon initalization.
  # The simplest form of handling measured methods timing is to report them to some global array.

  before do
    @timeasure_results = []

    Timeasure.configure do |configuration|
      configuration.post_measuring_proc = lambda do |base_class_name, method_name, t0, t1|
        @timeasure_results << { base_class_name: base_class_name, method_name: method_name, t0: t0, t1: t1 }
      end
    end
  end

  # The next section emulates the creation of a new class that includes Timeasure.
  # Since using the `Class.new` syntax is obligatory in test environment,
  # it has to be assigned to a constant first in order to have a name.

  before :all do
    FirstClass = Class.new
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

      context 'actual class' do
        it 'is placed second in the ancestors chain' do
          expect(ancestors_chain[1]).to eq FirstClass
        end
      end
    end

    context 'namespaced class' do
      # This setup block helps in emulating the creation of a namespaced class.

      before :all do
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
    let(:instance) { FirstClass.new }

    context 'without errors' do
      let(:a_method_return_value) { instance.a_method }
      let(:a_method_with_args_return_value) { instance.a_method_with_args('arg') }
      let(:a_method_with_a_block_return_value) { instance.a_method_with_a_block { true ? 8 : 0 } }

      it 'returns methods return values transparently' do
        expect(a_method_return_value).to eq true
        expect(a_method_with_args_return_value).to eq 'arg'
        expect(a_method_with_a_block_return_value).to eq 8
      end

      it 'executes the post_measuring_proc lambda from Timeausre.configuration' do
        a_method_return_value
        a_method_with_args_return_value
        a_method_with_a_block_return_value

        expect(@timeasure_results.count).to eq 3
        expect(@timeasure_results).to all be_a(Hash)
      end
    end

    context 'with errors' do
      context 'in the tracked method' do
        it 'raises an error normally' do
          expect { FirstClass.an_erroneous_method }.to raise_error(RuntimeError)
        end
      end

      context 'in the post_measuring_proc' do
        # This setup block emulates a case in which the configuration.post_measuring_proc
        # encounters an error.

        before do
          Timeasure.configure do |configuration|
            configuration.post_measuring_proc = lambda do |base_class_name, method_name, t0, t1|
              raise RuntimeError
            end
          end
        end

        it 'calls the rescue proc' do
          expect(Timeasure.configuration.rescue_proc).to receive(:call)
          instance.a_method
        end

        it 'does not interfere with method return value' do
          expect(instance.a_method).to eq true
        end
      end
    end
  end
end

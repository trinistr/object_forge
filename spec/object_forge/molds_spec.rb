# frozen_string_literal: true

module ObjectForge
  RSpec.describe Molds do
    describe ".mold_for" do
      subject(:mold) { described_class.mold_for(klass) }

      let(:built_object) { mold.call(forged: klass, attributes: { a: 1, b: 2 }) }

      context "when called with a Struct subclass" do
        let(:klass) { Struct.new(:a, :b) }

        it "returns StructMold" do
          expect(mold).to be_a described_class::StructMold
        end

        specify "returned mold is appropriate" do
          expect(built_object).to eq klass.new(1, 2)
        end
      end

      context "when called with a Data subclass",
              skip: !defined?(Data) && "Data is not available" do
        let(:klass) { Data.define(:a, :b) }

        it "returns KeywordsMold" do
          expect(mold).to be_a described_class::KeywordsMold
        end

        specify "returned mold is appropriate" do
          expect(built_object).to eq klass.new(a: 1, b: 2)
        end
      end

      context "when called with Hash" do
        let(:klass) { Hash }

        it "returns HashMold" do
          expect(mold).to be_a described_class::HashMold
        end

        specify "returned mold is appropriate" do
          expect(built_object).to be_a Hash
          expect(built_object).to eq({ a: 1, b: 2 })
        end

        context "when called with a subclass of Hash" do
          let(:klass) { Class.new(Hash) }

          it "returns HashMold" do
            expect(mold).to be_a described_class::HashMold
          end

          specify "returned mold is appropriate" do
            expect(built_object).to be_a klass
            expect(built_object).to eq({ a: 1, b: 2 })
          end
        end
      end

      context "when called with any other class" do
        let(:klass) { Class.new }

        it "returns SingleArgumentMold" do
          expect(mold).to be_a described_class::SingleArgumentMold
        end
      end

      context "when called with any other object" do
        let(:klass) { Object.new }

        it "returns SingleArgumentMold" do
          expect(mold).to be_a described_class::SingleArgumentMold
        end
      end
    end

    describe ".wrap_mold" do
      subject(:wrapped_mold) { described_class.wrap_mold(mold) }

      context "with nil" do
        let(:mold) { nil }

        it "returns nil" do
          expect(wrapped_mold).to be nil
        end
      end

      context "with a proc" do
        let(:mold) { ->(attributes:, **) { attributes } }

        it "returns it as the mold" do
          expect(wrapped_mold).to be mold
        end
      end

      context "with a callable object" do
        let(:mold) { Molds::HashMold.new }

        it "returns it as the mold" do
          expect(wrapped_mold).to be mold
        end
      end

      context "with a Class with #call" do
        let(:mold) { Proc }

        it "wraps the class in WrappedMold" do
          expect(wrapped_mold).to be_a described_class::WrappedMold
          expect(wrapped_mold.wrapped_mold).to be Proc
        end
      end

      context "with a Class without #call" do
        let(:mold) { Object }

        it "raises MoldError" do
          expect { wrapped_mold }.to raise_error(
            MoldError, "mold must respond to or implement #call"
          )
        end
      end

      context "with an object without #call" do
        let(:mold) { Object.new }

        it "raises MoldError" do
          expect { wrapped_mold }.to raise_error(
            MoldError, "mold must respond to or implement #call"
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

module ObjectForge
  RSpec.describe Crucible do
    subject(:crucible) { described_class.new(attributes) }

    let(:attributes) { { foo: -> { 1 }, bar: 2, baz: -> { foo + bar } } }

    describe "#resolve!" do
      it "resolves all attributes by calling their procs" do
        expect(crucible.resolve!).to eq({ foo: 1, bar: 2, baz: 3 })
      end

      it "modifies initial attributes" do
        expect { crucible.resolve! }.to change(attributes, :itself).to({ foo: 1, bar: 2, baz: 3 })
      end

      it "is idempotent for resolved attributes" do
        expect { crucible.resolve! }.to change(attributes, :itself)
        expect { crucible.resolve! }.not_to change(attributes, :itself)
      end

      context "if an attribute can not be resolved" do
        let(:attributes) { { foo: -> { 1 }, bar: 2, baz: -> { foo + bard } } }

        it "raises NameError" do
          expect { crucible.resolve! }.to raise_error(
            NameError,
            # Ruby 3.4 changed initial quote from "`" to "'" in error messages.
            /\Aundefined local variable or method ['`]bard'/
          )
        end
      end

      context "if attributes conflict with Object (but not BasicObject) methods" do
        let(:attributes) { dsl.attributes.dup }
        let(:dsl) do
          ForgeDSL.new do |f|
            f.display { "My String" }
            f.long_display { "#{display} +L +fell off" }
          end
        end

        it "resolves attributes correctly" do
          expect(dsl.attributes).to match({ display: Proc, long_display: Proc })
          expect(crucible.resolve!).to eq(
            display: "My String",
            long_display: "My String +L +fell off"
          )
        end
      end

      context "if attributes conflict with existing methods" do
        let(:attributes) { dsl.attributes.dup }
        let(:dsl) do
          ForgeDSL.new do |f|
            f.attribute(:resolve!) { "My Resolve!" }
            f.attribute(:[]) { "#{self[:resolve!]} It's Strong!" }
          end
        end

        it "resolves attributes correctly when accessed through #[]" do
          expect(dsl.attributes).to match({ resolve!: Proc, "[]": Proc })
          expect(crucible.resolve!).to eq(resolve!: "My Resolve!", "[]": "My Resolve! It's Strong!")
        end
      end

      context "when `rand` is used in attribute definitions" do
        let(:attributes) { dsl.attributes.dup }
        let(:dsl) do
          ForgeDSL.new do |f|
            f.attribute(:foo) { rand(100) }
            f.attribute(:bar) { rand(100) }
            f.attribute(:baz) { foo + bar }
          end
        end

        it "resolves attributes correctly" do
          expect(crucible.resolve!).to match({ foo: Integer, bar: Integer, baz: Integer })
        end
      end
    end

    describe "#respond_to?" do
      it "returns true if a corresponding key exists" do
        key = attributes.keys.sample
        expect(crucible).to respond_to key
        expect(crucible.__send__(key)).to be attributes[key]
      end

      it "returns false if a corresponding key does not exist" do
        expect(crucible).not_to respond_to :qux
      end
    end
  end
end

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
          expect { crucible.resolve! }.to raise_error NameError, "undefined local variable or method 'bard' for an instance of ObjectForge::Crucible"
        end
      end
    end

    describe "#respond_to?" do
      it "returns true if a corresponding key exists" do
        key = attributes.keys.sample
        expect(crucible).to respond_to key
        expect(crucible.public_send(key)).to be attributes[key]
      end

      it "returns false if a corresponding key does not exist" do
        expect(crucible).not_to respond_to :qux
      end
    end
  end
end

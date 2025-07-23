# frozen_string_literal: true

module ObjectForge
  RSpec.describe Crucible do
    subject(:crucible) { described_class.new(attributes) }

    let(:attributes) { { foo: -> { 1 }, bar: 2, baz: -> { foo + bar } } }

    it "responds to missing methods corresponding to keys" do
      key = attributes.keys.sample
      expect(crucible).to respond_to key
      expect(crucible.public_send(key)).to be attributes[key]
    end

    it "does not respond to methods not corresponding to keys" do
      expect(crucible).not_to respond_to :qux
    end

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
    end
  end
end

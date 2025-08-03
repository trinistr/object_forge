# frozen_string_literal: true

require "object_forge/molds/hash_mold"

RSpec.describe ObjectForge::Molds::HashMold do
  subject(:mold) { described_class.new }

  let(:forged_object) do
    Class.new { def [](attributes) = attributes.dup }.new
  end

  describe "#default" do
    context "when default value is not set" do
      it "returns nil" do
        expect(mold.default).to be nil
      end
    end

    context "when default value is set" do
      subject(:mold) { described_class.new(default_value) }

      let(:default_value) { Object.new }

      it "returns default value" do
        expect(mold.default).to be default_value
      end
    end
  end

  describe "#default_proc" do
    context "when default proc is not set" do
      it "returns nil" do
        expect(mold.default_proc).to be nil
      end
    end

    context "when default proc is set" do
      subject(:mold) { described_class.new(&default_proc) }

      let(:default_proc) { ->(_hash, key) { key } }

      it "returns default proc" do
        expect(mold.default_proc).to be default_proc
      end
    end
  end

  describe "#call" do
    it "calls +[]+ on the forged object with the attributes hash" do
      expect(mold.call(forged: forged_object, attributes: { a: 1, b: 2 })).to eq(a: 1, b: 2)
    end

    context "when default value is set" do
      subject(:mold) { described_class.new(37) }

      it "assigns default value to the produced hash" do
        hash = mold.call(forged: forged_object, attributes: { a: 1, b: 2 })
        expect(hash).to eq(a: 1, b: 2)
        expect(hash.default).to eq 37
        expect(hash[:c]).to eq 37
      end
    end

    context "when default proc is set" do
      subject(:mold) { described_class.new(&default_proc) }

      let(:default_proc) { ->(_hash, key) { key } }

      it "assigns default value to the produced hash" do
        hash = mold.call(forged: forged_object, attributes: { a: 1, b: 2 })
        expect(hash).to eq(a: 1, b: 2)
        expect(hash.default_proc).to be default_proc
        expect(hash[:c]).to eq :c
      end
    end

    context "with a custom Hash class" do
      require "concurrent/hash"

      it "builds an instance of the specified class correctly" do
        hash = mold.call(forged: Concurrent::Hash, attributes: { a: 1, b: 2 })
        expect(hash).to be_a Concurrent::Hash
        expect(hash).to eq(a: 1, b: 2)
      end
    end

    it "can be called with arbitrary extra arguments" do
      expect(mold.call(forged: forged_object, attributes: { b: 12, d: 21 }, extra: 3))
        .to eq(b: 12, d: 21)
    end
  end
end

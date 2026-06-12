# frozen_string_literal: true

require "object_forge/molds/array_mold"

RSpec.describe ObjectForge::Molds::ArrayMold do
  subject(:mold) { described_class.new }

  let(:forged_object) do
    Class.new { def new(array) = array.dup }.new
  end

  describe "#call" do
    before { allow(forged_object).to receive(:new).and_call_original }

    it "calls +new+ on the forged object with the array of attribute values" do
      expect(mold.call(forge_target: forged_object, attributes: { b: 1, a: 2 })).to eq([1, 2])
      expect(forged_object).to have_received(:new).with([1, 2])
    end

    context "with core Array class" do
      let(:forged_object) { Array }

      it "skips calling `.new`, returning `values` directly" do
        array = mold.call(forge_target: forged_object, attributes: { a: 4, b: 3 })
        expect(array).to be_a forged_object
        expect(array).to eq([4, 3])
        expect(forged_object).not_to have_received(:new)
      end
    end

    context "with a custom Array class" do
      let(:forged_object) { Class.new(Array) }

      it "builds an instance of the specified class correctly" do
        array = mold.call(forge_target: forged_object, attributes: { "[]": "array", "{}": "hash" })
        expect(array).to be_a forged_object
        expect(array).to eq(%w[array hash])
        expect(forged_object).to have_received(:new)
      end
    end

    it "can be called with arbitrary extra arguments" do
      expect(mold.call(forge_target: forged_object, attributes: { b: 12, d: 21 }, extra: 3))
        .to eq([12, 21])
    end
  end
end

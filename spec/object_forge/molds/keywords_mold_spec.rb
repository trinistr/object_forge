# frozen_string_literal: true

require "object_forge/molds/keywords_mold"

RSpec.describe ObjectForge::Molds::KeywordsMold do
  subject(:mold) { described_class.new }

  let(:forged_object) do
    Class.new { def new(**attributes) = attributes.slice(:a, :c) }.new
  end

  describe "#call" do
    it "calls +new+ on the forged object with attributes keywords" do
      expect(mold.call(forged: forged_object, attributes: { a: 1, b: 2 })).to eq(a: 1)
    end

    it "can be called as many times as needed" do
      expect(mold.call(forged: forged_object, attributes: { a: 1, b: 2 })).to eq(a: 1)
      expect(mold.call(forged: forged_object, attributes: { a: "s", c: "c" })).to eq(a: "s", c: "c")
    end

    it "can be called with arbitrary extra arguments" do
      expect(mold.call(forged: forged_object, attributes: { a: 1, b: 2 }, extra: 3)).to eq(a: 1)
    end
  end
end

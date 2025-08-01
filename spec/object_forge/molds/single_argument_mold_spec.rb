# frozen_string_literal: true

require "object_forge/molds/single_argument_mold"

RSpec.describe ObjectForge::Molds::SingleArgumentMold do
  subject(:mold) { described_class.new }

  let(:forged_object) do
    klass = Class.new do
      def new(attributes)
        attributes.slice(:a, :c)
      end
    end

    klass.new
  end

  describe "#call" do
    it "calls +new+ on the forged object with the attributes hash" do
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

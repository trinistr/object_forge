# frozen_string_literal: true

require "object_forge/molds/mold_mold"

RSpec.describe ObjectForge::Molds::MoldMold do
  subject(:mold) { described_class.new(mold_class) }

  let(:mold_class) do
    Class.new do
      attr_reader :kwargs

      def call(**kwargs)
        @kwargs = kwargs unless defined?(@kwargs)
      end
    end
  end

  describe "example mold class" do
    subject(:example_mold) { mold_class.new }

    it "modifies its state on call" do
      expect(example_mold.kwargs).to be nil
      example_mold.call(a: 1, b: 2)
      expect(example_mold.kwargs).to eq(a: 1, b: 2)
    end

    it "can't be called multiple times meaningfully" do
      expect { example_mold.call(a: rand, b: rand) }.to change(example_mold, :kwargs)
      expect { example_mold.call(a: rand, b: rand) }.not_to change(example_mold, :kwargs)
    end
  end

  describe "#wrapped_mold" do
    it "returns class to be instantiated" do
      expect(mold.wrapped_mold).to be mold_class
    end
  end

  describe "#call" do
    it "instantiates wrapped mold and calls it" do
      expect(mold.call(forged: 1, attributes: 2)).to eq(forged: 1, attributes: 2)
    end

    it "can be called as many times as needed" do
      expect(mold.call(forged: 1, attributes: 2)).to eq(forged: 1, attributes: 2)
      expect(mold.call(forged: "s", attributes: "c")).to eq(forged: "s", attributes: "c")
    end

    it "can be called with arbitrary extra arguments" do
      expect(mold.call(forged: 1, attributes: 2, extra: 3)).to eq(forged: 1, attributes: 2, extra: 3)
    end
  end
end

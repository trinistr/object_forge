# frozen_string_literal: true

require "object_forge/molds/mold_mold"

RSpec.describe ObjectForge::Molds::MoldMold do
  subject(:mold) { described_class.new.call(forged: klass) }

  let(:built_object) { mold.call(forged: klass, attributes: { a: 1, b: 2 }) }

  context "when called with a Struct subclass" do
    let(:klass) { Struct.new(:a, :b) }

    it "returns StructMold" do
      expect(mold).to be_a ObjectForge::Molds::StructMold
    end

    specify "returned mold is appropriate" do
      expect(built_object).to eq klass.new(1, 2)
    end
  end

  if defined?(Data)
    context "when called with a Data subclass" do
      let(:klass) { Data.define(:a, :b) }

      it "returns KeywordsMold" do
        expect(mold).to be_a ObjectForge::Molds::KeywordsMold
      end

      specify "returned mold is appropriate" do
        expect(built_object).to eq klass.new(a: 1, b: 2)
      end
    end
  end

  context "when called with Hash" do
    let(:klass) { Hash }

    it "returns HashMold" do
      expect(mold).to be_a ObjectForge::Molds::HashMold
    end

    specify "returned mold is appropriate" do
      expect(built_object).to be_a Hash
      expect(built_object).to eq({ a: 1, b: 2 })
    end

    context "when called with a subclass of Hash" do
      let(:klass) { Class.new(Hash) }

      it "returns HashMold" do
        expect(mold).to be_a ObjectForge::Molds::HashMold
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
      expect(mold).to be_a ObjectForge::Molds::SingleArgumentMold
    end
  end

  context "when called with any other object" do
    subject(:mold) { described_class.new.call(forged: Object.new) }

    it "returns SingleArgumentMold" do
      expect(mold).to be_a ObjectForge::Molds::SingleArgumentMold
    end
  end
end

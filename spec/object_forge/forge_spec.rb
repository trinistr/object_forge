# frozen_string_literal: true

module ObjectForge
  RSpec.describe Forge do
    subject(:forge) { described_class.new(forged_class, parameters, name: name) }

    let(:forged_class) { Struct.new(:foo, :bar) }
    let(:name) { "ASDFg" }
    let(:parameters) { described_class::Parameters.new }

    describe "#forged" do
      it "returns the class to forge" do
        expect(forge.forged).to be forged_class
      end
    end

    describe "#name" do
      it "returns the name of the forge" do
        expect(forge.name).to eq name
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe ObjectForge do
  it "has a valid version number" do
    expect(described_class::VERSION).not_to be nil
    expect { Gem::Version.new(described_class::VERSION) }.not_to raise_error
  end

  it "has a global default forgeyard" do
    expect(described_class::DEFAULT_YARD).to be_a described_class::Forgeyard
  end

  describe ".sequence" do
    subject(:sequence) { described_class.sequence(137) }

    it "creates a sequence" do
      expect(sequence).to be_a described_class::Sequence
      expect(sequence.next).to eq 137
    end
  end

  describe ".define" do
    subject(:definition) { described_class.define(:foo, test_struct) { |f| f.attr { 13 } } }

    let(:test_struct) { Struct.new(:attr, keyword_init: true) }

    after { described_class::DEFAULT_YARD.forges.clear }

    it "defines a forge on default forgeyard" do
      expect { definition }.to change(described_class::DEFAULT_YARD.forges, :size).by(1)
      expect(described_class::DEFAULT_YARD.forges[:foo]).to be_a described_class::Forge
    end
  end

  describe ".forge" do
    subject(:forged_instance) { described_class.forge(:foo) }

    let(:test_struct) { Struct.new(:attr, keyword_init: true) }

    before { described_class.define(:foo, test_struct) { |f| f.attr { 13 } } }
    after { described_class::DEFAULT_YARD.forges.clear }

    it "builds an instance using a forge from default forgeyard" do
      expect(forged_instance).to be_a test_struct
      expect(forged_instance).to have_attributes(attr: 13)
    end
  end

  describe described_class.singleton_class do
    include_examples "has an alias", :build, :forge
    include_examples "has an alias", :[], :forge
  end
end

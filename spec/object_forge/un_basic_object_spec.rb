# frozen_string_literal: true

RSpec.describe ObjectForge::UnBasicObject do
  subject(:instance) { classy.new }

  let(:classy) do
    Class.new(described_class) do
      def error
        raise "error"
      end

      def blocky
        block_given?
      end

      def change
        @changed = true
      end
    end
  end

  describe "#class" do
    it "returns the class of the instance" do
      expect(instance.class).to be classy
    end
  end

  describe "#eql?" do
    it "returns false if other is not the same object" do
      expect(instance.eql?(Object.new)).to be false
    end

    it "returns true if other is the same object" do
      expect(instance.eql?(instance)).to be true
    end
  end

  describe "#freeze" do
    it "freezes the instance, preventing change" do
      expect { instance.freeze.change }.to raise_error FrozenError
    end
  end

  describe "#frozen?" do
    it "returns false if instance is not frozen" do
      expect(instance.frozen?).to be false
    end

    it "returns true if the instance is frozen" do
      expect(instance.freeze.frozen?).to be true
    end
  end

  describe "#hash" do
    let(:hash) { instance.hash }

    it "returns an Integer" do
      expect(hash).to be_an Integer
    end

    it "returns the same hash for the same instance" do
      expect(hash).to eq instance.hash
    end
  end

  describe "#inspect" do
    it "returns a human-readable representation of the instance" do
      expect(instance.inspect).to be_an String
    end
  end

  describe "#is_a?" do
    it "returns true if the given class is the instance's ancestor" do
      expect(instance.is_a?(BasicObject)).to be true
      expect(instance.is_a?(described_class)).to be true
      expect(instance.is_a?(classy)).to be true
    end

    it "returns false if the instance is not an instance of the given class" do
      expect(instance.is_a?(Object)).to be false
    end
  end

  include_examples "has an alias", :kind_of?, :is_a?

  describe "#respond_to?" do
    it "returns true if a corresponding method exists" do
      expect(instance).to respond_to :inspect
    end

    it "returns false if a corresponding method does not exist" do
      expect(instance).not_to respond_to :nonexistent
    end
  end

  describe "#to_s" do
    it "returns a string representation of the instance" do
      expect(instance.to_s).to be_an String
    end
  end

  # -- pretty print --

  describe "#pretty_print" do
    require "pp"

    it "pretty prints the instance" do
      instance.change
      expect { pp instance }.to output.to_stdout
    end
  end

  # -- private methods --

  describe "#block_given?" do
    it "is private" do
      expect { instance.block_given? }.to raise_error NoMethodError
    end

    it "returns false if no block is given to a method" do
      expect(instance.blocky).to be false
    end

    it "returns true if a block is given to a method" do
      expect(instance.blocky { nil }).to be true
    end
  end

  describe "#raise" do
    it "is private" do
      expect { instance.raise }.to raise_error NoMethodError
    end

    it "raises an error" do
      expect { instance.error }.to raise_error RuntimeError, "error"
    end
  end
end

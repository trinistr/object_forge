# frozen_string_literal: true

module ObjectForge
  RSpec.describe Forge do
    subject(:forge) { described_class.new(forged_class, parameters, name: name) }

    let(:forged_class) { Struct.new(:foo, :bar, keyword_init: true) }
    let(:name) { "ASDFg" }
    let(:parameters) do
      described_class::Parameters.new(
        attributes: { foo: -> { 1 }, bar: -> { 2 } },
        traits: {
          barfoo: { bar: -> { foo } }, foofoo: { foo: -> { :foo } }, bazoo: { foo: -> { :baz } },
        }
      )
    end

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

    describe "#forge" do
      context "without parameters" do
        it "builds an instance of the forged class with default attributes" do
          expect(forge.forge).to eq forged_class.new(foo: 1, bar: 2)
        end
      end

      context "with traits" do
        it "builds an instance of the forged class, applying traits in order" do
          expect(forge.forge(:barfoo, :bazoo, :foofoo)).to eq forged_class.new(foo: :foo, bar: :foo)
        end
      end

      context "with overrides" do
        it "builds an instance of the forged class, applying overrides" do
          expect(forge.forge(foo: 3)).to eq forged_class.new(foo: 3, bar: 2)
        end
      end

      context "with traits and overrides" do
        it "builds an instance of the forged class, applying traits and overrides in order" do
          expect(forge.forge(:barfoo, :bazoo, foo: 3)).to eq forged_class.new(foo: 3, bar: 3)
        end

        context "if traits and overrides are passed as two positional parameters" do
          it "works the same" do
            expect(forge.forge(%i[barfoo bazoo], { foo: 3 })).to eq forged_class.new(foo: 3, bar: 3)
          end
        end

        context "if only two traits are passed" do
          it "does not try to parse them as traits and overrides" do
            expect(forge.forge(:barfoo, :bazoo)).to eq forged_class.new(foo: :baz, bar: :baz)
          end
        end
      end

      context "with a block" do
        it "allows tapping into the object" do
          expect(forge.forge { _1.foo = 33 }).to eq forged_class.new(foo: 33, bar: 2)
        end

        it "runs the block after forging the object with resolved attributes" do
          expect(forge.forge(:barfoo, :foofoo) { _1.foo = 33 })
            .to eq forged_class.new(foo: 33, bar: :foo)
        end

        context "if the forged class does not implement #tap" do
          let(:forged_class) do
            Class.new(BasicObject) do
              attr_accessor :foo, :bar

              def initialize(attributes)
                @foo = attributes[:foo]
                @bar = attributes[:bar]
              end
            end
          end

          it "works correctly" do
            instance = forge.forge { _1.foo = 33 }
            expect(forged_class === instance).to be true
            expect(instance.foo).to eq 33
            expect(instance.bar).to eq 2
          end
        end
      end
    end

    include_examples "has an alias", :build, :forge
    include_examples "has an alias", :[], :forge
  end
end

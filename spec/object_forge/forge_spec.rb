# frozen_string_literal: true

module ObjectForge
  RSpec.describe Forge do
    subject(:forge) { described_class.new(forged_class, parameters, name: name) }

    let(:forged_class) { Struct.new(:foo, :bar, keyword_init: true) }
    let(:name) { "ASDFg" }
    let(:parameters) do
      described_class::Parameters.new(
        options: options,
        attributes: { foo: -> { 1 }, bar: -> { 2 } },
        traits: {
          barfoo: { bar: -> { foo } }, foofoo: { foo: -> { :foo } }, bazoo: { foo: -> { :baz } },
        }
      )
    end
    let(:options) { {} }

    describe "#forge_target" do
      it "returns the class to forge" do
        expect(forge.forge_target).to be forged_class
      end
    end

    include_examples "has an alias", :target, :forge_target

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

        context "when some trait names are unknown" do
          context "and forge is named" do
            it "raises ArgumentError with unknown trait names and forge name" do
              expect { forge.forge(:bafoo, :bazoo, :foofo) }.to raise_error(
                ArgumentError, "unknown traits for forge ASDFg: bafoo, foofo"
              )
            end
          end

          context "and forge is unnamed" do
            let(:name) { nil }

            it "raises ArgumentError with unknown trait names" do
              expect { forge.forge(:bafoo, :bazoo, :foofo) }.to raise_error(
                ArgumentError, "unknown traits for forge: bafoo, foofo"
              )
            end
          end
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

          it "yields object correctly" do
            instance = forge.forge { _1.foo = 33 }
            expect(forged_class === instance).to be true
            expect(instance.foo).to eq 33
            expect(instance.bar).to eq 2
          end
        end
      end
    end

    include_examples "has an alias", :build, :forge
    include_examples "has an alias", :call, :forge

    describe "forge options" do
      describe ":mold" do
        before do
          allow(Molds).to receive(:mold_for).and_call_original
          allow(Molds).to receive(:wrap_mold).and_call_original
        end

        context "with a non-nil object" do
          let(:options) { { mold: ->(**) { 123 } } }

          it "calls Molds.wrap_mold with it" do
            expect(Molds).to receive(:wrap_mold).with(options[:mold])
            expect(Molds).not_to receive(:mold_for)
            expect(forge.forge).to eq 123
          end
        end

        context "with nil" do
          let(:options) { { mold: nil } }

          it "calls Molds.mold_for to determine mold" do
            expect(Molds).to receive(:mold_for).with(forged_class)
            expect(forge.forge).to be_an_instance_of forged_class
          end
        end
      end

      describe ":crucible" do
        context "with a non-nil object" do
          let(:options) { { crucible: ->(attributes) { attributes.transform_values(&:inspect) } } }

          it "uses the object to resolve attributes" do
            expect(forge.forge).to have_attributes(foo: /Proc/, bar: /Proc/)
          end
        end

        context "with nil" do
          let(:options) { { crucible: nil } }

          it "uses Crucible for attribute resolution" do
            expect(forge.forge).to have_attributes(foo: 1, bar: 2)
          end
        end
      end

      describe ":after_forge/:after_build" do
        let(:hook) { ->(object) { object.foo = 100 } }

        context "with non-nil :after_forge" do
          let(:options) { { after_forge: hook } }

          it "uses the hook to act on built object after building it" do
            expect(forge.forge(:barfoo)).to have_attributes(foo: 100, bar: 1)
          end
        end

        context "with non-nil :after_build" do
          let(:options) { { after_build: hook } }

          it "uses the hook to act on built object after building it" do
            expect(forge.forge(:barfoo)).to have_attributes(foo: 100, bar: 1)
          end
        end

        context "if both options are specified" do
          let(:options) { { after_forge: hook, after_build: ->(o) { o.bar = 5 } } }

          specify ":after_forge wins" do
            expect(forge.forge).to have_attributes(foo: 100, bar: 2)
          end
        end

        context "when block is also used" do
          let(:options) { { after_forge: hook } }

          specify "hook runs before the block" do
            expect(forge.forge(:barfoo) { _1.foo = 3 }).to have_attributes(foo: 3, bar: 1)
          end
        end
      end
    end
  end
end

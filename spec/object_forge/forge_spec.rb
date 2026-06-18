# frozen_string_literal: true

module ObjectForge
  RSpec.describe Forge do
    subject(:forge) { described_class.new(forged_class, parameters, name: name, yard: yard) }

    let(:forged_class) { Struct.new(:foo, :bar, keyword_init: true) }
    let(:name) { "ASDFg" }
    let(:yard) { { bar: 3 } }
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

    describe "#name" do
      it "returns the specified name of the forge" do
        expect(forge.name).to eq name
      end

      context "when name is nil" do
        let(:name) { nil }

        it "returns nil" do
          expect(forge.name).to be nil
        end
      end
    end

    describe "#yard" do
      let(:yard) { instance_double(Forgeyard) }

      it "returns the specified yard of the forge" do
        expect(forge.yard).to be yard
      end

      context "when yard is nil" do
        let(:yard) { nil }

        it "returns nil" do
          expect(forge.yard).to be nil
        end
      end
    end

    describe "#forge_target" do
      it "returns the class to forge" do
        expect(forge.forge_target).to be forged_class
      end
    end

    # This isn't an alias test due to a bug with `original_name` on JRuby.
    describe "#target" do
      it "returns the class to forge" do
        expect(forge.target).to be forged_class
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

    describe "forge options", :aggregate_failures do
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

        context "with invalid value" do
          let(:options) { { mold: "invalid" } }

          it "raises ObjectInterfaceError" do
            expect { forge.forge }.to raise_error(ObjectInterfaceError)
          end
        end
      end

      describe ":crucible" do
        context "with a non-nil object taking only attributes" do
          let(:options) do
            { crucible: ->(attributes) { attributes.transform_values(&:inspect) } }
          end

          it "uses the object to resolve attributes" do
            expect(forge.forge).to have_attributes(foo: /Proc/, bar: /Proc/)
          end
        end

        context "with a non-nil object taking attributes and :yard keyword parameter" do
          let(:crucible) do
            Class.new do
              def call(attributes, yard: {})
                attributes.to_h { |k, v| [k, yard[k] || v.inspect] }
              end
            end
          end
          let(:options) { { crucible: crucible.new } }

          it "uses the object to resolve attributes" do
            expect(forge.forge).to have_attributes(foo: /Proc/, bar: 3)
          end

          context "if crucible takes :yard in keyrest parameters" do
            let(:options) do
              { crucible: ->(attributes, **kwargs) {
                attributes.to_h { |k, v| [k, kwargs[:yard][k] || v.inspect] }
              } }
            end

            it "detects that and supplies the yard" do
              expect(forge.forge).to have_attributes(foo: /Proc/, bar: 3)
            end
          end
        end

        context "with nil" do
          let(:options) { { crucible: nil } }

          it "uses Crucible for attribute resolution" do
            expect(forge.forge).to have_attributes(foo: 1, bar: 2)
          end
        end

        context "with invalid value" do
          let(:options) { { crucible: "invalid" } }

          it "raises ObjectInterfaceError" do
            expect { forge.forge }.to raise_error(ObjectInterfaceError)
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

        context "with invalid value" do
          let(:options) { { after_forge: "invalid" } }

          it "raises ObjectInterfaceError" do
            expect { forge.forge }.to raise_error(ObjectInterfaceError)
          end
        end
      end

      describe ":attribute_list" do
        context "when an attribute list is specified" do
          let(:options) { { attribute_list: [:foo] } }

          it "limits final attributes to those in the list but resolves using all attributes" do
            expect(forge.forge).to eq forged_class.new(foo: 1)
            expect(forge.forge(bar: 5)).to eq forged_class.new(foo: 1)
            expect(forge.forge(foo: -> { bar + 3 }, bar: 5)).to eq forged_class.new(foo: 8)
          end
        end

        context "when attribute list includes extra attributes" do
          let(:options) { { attribute_list: %i[foo baz] } }

          it "ignores the extra attributes" do
            expect(forge.forge).to eq forged_class.new(foo: 1)
          end
        end

        context "when attribute list reorders attributes" do
          let(:options) do
            { attribute_list: %i[bar foo], mold: ->(attributes:, **) { attributes.keys } }
          end

          it "passes attributes in the order specified to the mold" do
            expect(forge.forge).to eq %i[bar foo]
          end
        end

        context "when attribute list is empty" do
          let(:options) { { attribute_list: [] } }

          it "uses no attributes for forging" do
            expect(forge.forge).to eq forged_class.new
          end
        end

        context "when attribute list is nil" do
          let(:options) { { attribute_list: nil } }

          it "behaves as if no attribute list was specified" do
            expect(forge.forge).to eq forged_class.new(foo: 1, bar: 2)
          end
        end

        context "with invalid non-Array value" do
          let(:options) { { attribute_list: "invalid" } }

          it "raises TypeError" do
            expect { forge.forge }.to raise_error(TypeError)
          end
        end

        context "with invalid Array containing non-Symbol elements" do
          let(:options) { { attribute_list: [:foo, "bar"] } }

          it "raises TypeError" do
            expect { forge.forge }.to raise_error(TypeError)
          end
        end
      end
    end
  end
end

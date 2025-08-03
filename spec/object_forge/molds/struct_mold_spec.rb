# frozen_string_literal: true

require "object_forge/molds/struct_mold"

RSpec.describe ObjectForge::Molds::StructMold do
  subject(:mold) { described_class.new(lax: lax) }

  let(:lax) { false }

  let(:struct_keyword_init) { Struct.new(:a, :b, keyword_init: true) }
  let(:struct_positional_init) { Struct.new(:a, :b, keyword_init: false) }
  let(:struct_unspecified_init) { Struct.new(:a, :b) }

  describe "RUBY_FEATURE_AUTO_KEYWORDS" do
    it "is true on Ruby >= 3.2" do
      expect(described_class::RUBY_FEATURE_AUTO_KEYWORDS).to eq !RUBY_VERSION.start_with?("3.1.")
    end
  end

  describe "#lax" do
    it "is false by default" do
      expect(described_class.new.lax).to be false
    end

    it "is set on initialization" do
      expect(described_class.new(lax: false).lax).to be false
      expect(described_class.new(lax: true).lax).to be true
    end
  end

  include_examples "has an alias", :lax?, :lax

  describe "#call" do
    context "when lax is false" do
      context "when extra attributes are not present" do
        it "can instantiate structs with keyword_init: true" do
          expect(mold.call(forged: struct_keyword_init, attributes: { a: 1, b: 2 }))
            .to have_attributes(a: 1, b: 2)
        end

        it "can instantiate structs with keyword_init: false" do
          expect(mold.call(forged: struct_positional_init, attributes: { a: 1, b: 2 }))
            .to have_attributes(a: 1, b: 2)
        end

        it "can instantiate structs with unspecified keyword_init" do
          expect(mold.call(forged: struct_unspecified_init, attributes: { a: 1, b: 2 }))
            .to have_attributes(a: 1, b: 2)
        end
      end

      context "when extra attributes are present" do
        it "fails to instantiate structs with keyword_init: true" do
          expect { mold.call(forged: struct_keyword_init, attributes: { a: 1, b: 2, c: 3 }) }
            .to raise_error ArgumentError
        end

        it "can instantiate structs with keyword_init: false" do
          expect(mold.call(forged: struct_positional_init, attributes: { a: 1, b: 2, c: 3 }))
            .to have_attributes(a: 1, b: 2)
        end

        if described_class::RUBY_FEATURE_AUTO_KEYWORDS
          it "fails to instantiate structs with unspecified keyword_init" do
            expect { mold.call(forged: struct_unspecified_init, attributes: { a: 1, b: 2, c: 3 }) }
              .to raise_error ArgumentError
          end
        else
          # :nocov:
          it "can instantiate structs with unspecified keyword_init" do
            expect(mold.call(forged: struct_unspecified_init, attributes: { a: 1, b: 2, c: 3 }))
              .to have_attributes(a: 1, b: 2)
          end
          # :nocov:
        end
      end
    end

    context "when lax is true" do
      let(:lax) { true }

      context "when extra attributes are not present" do
        it "can instantiate structs with keyword_init: true" do
          expect(mold.call(forged: struct_keyword_init, attributes: { a: 1, b: 2 }))
            .to have_attributes(a: 1, b: 2)
        end

        it "can instantiate structs with keyword_init: false" do
          expect(mold.call(forged: struct_positional_init, attributes: { a: 1, b: 2 }))
            .to have_attributes(a: 1, b: 2)
        end

        it "can instantiate structs with unspecified keyword_init" do
          expect(mold.call(forged: struct_unspecified_init, attributes: { a: 1, b: 2 }))
            .to have_attributes(a: 1, b: 2)
        end
      end

      context "when extra attributes are present" do
        it "can instantiate structs with keyword_init: true" do
          expect(mold.call(forged: struct_keyword_init, attributes: { a: 1, b: 2, c: 3 }))
            .to have_attributes(a: 1, b: 2)
        end

        it "can instantiate structs with keyword_init: false" do
          expect(mold.call(forged: struct_positional_init, attributes: { a: 1, b: 2, c: 3 }))
            .to have_attributes(a: 1, b: 2)
        end

        it "can instantiate structs with unspecified keyword_init" do
          expect(mold.call(forged: struct_unspecified_init, attributes: { a: 1, b: 2, c: 3 }))
            .to have_attributes(a: 1, b: 2)
        end
      end
    end

    it "can be called with arbitrary extra arguments" do
      expect(mold.call(forged: struct_keyword_init, attributes: { a: 1, b: 2 }, extra: 3))
        .to have_attributes(a: 1, b: 2)
    end
  end
end

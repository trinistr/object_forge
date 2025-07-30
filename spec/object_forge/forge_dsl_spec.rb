# frozen_string_literal: true

module ObjectForge
  RSpec.describe ForgeDSL do
    subject(:forge_dsl) { described_class.new(&definition) }

    let(:attribute_context) do
      Object.new.tap do |o|
        o.instance_variable_set(:@attributes, forge_dsl.attributes)
        # rubocop:disable RSpec/InstanceVariable, ThreadSafety/ClassInstanceVariable
        def o.method_missing(name) = @attributes[name].call
        def o.respond_to_missing?(_name, _include_private = false) = true
        # rubocop:enable RSpec/InstanceVariable, ThreadSafety/ClassInstanceVariable
      end
    end

    def evaluate(proc)
      attribute_context.instance_exec(&proc)
    end

    describe "full example" do
      let(:definition) do
        proc do |f|
          f.attribute(:name) { "Name" }
          f[:description] { name.upcase }
          f.duration { rand(1000) }

          f.sequence(:id, 100_000)
          f.sequence(:external, Sequence.new(35))
          f.sequence(:dated, Date.today) { |d| "#{d}/#{id}" }

          f.trait :special do
            f.name { "Special Name" }
            f[:id] { "~~~ SpEcIaL ~~~" }
          end

          f.trait :useless do
            f.useless { "Useless" }
            f.sequence(:useless_id) { "Useless #{id}" }
          end
        end
      end

      it "is frozen" do
        expect(forge_dsl).to be_frozen
      end

      it "contains only frozen data" do
        expect(forge_dsl.attributes).to be_frozen
        expect(forge_dsl.sequences).to be_frozen
        expect(forge_dsl.traits).to be_frozen
        expect(forge_dsl.traits.values).to all be_frozen
      end

      it "contains root attributes, including sequenced ones" do
        expect(forge_dsl.attributes.keys).to contain_exactly(
          :name, :description, :duration, :id, :external, :dated
        )
        expect(forge_dsl.attributes.values).to all be_a Proc
      end

      specify "normal attributes resolve to expected values" do
        expect(evaluate(forge_dsl.attributes[:name])).to eq "Name"
        expect(evaluate(forge_dsl.attributes[:description])).to eq "NAME"
        expect(evaluate(forge_dsl.attributes[:duration])).to be_a Integer
      end

      it "contains all sequences" do
        expect(forge_dsl.sequences.keys).to contain_exactly(:id, :external, :dated, :useless_id)
        expect(forge_dsl.sequences.values).to all be_a Sequence
      end

      specify "all sequences use expected initial values" do
        expect(forge_dsl.sequences[:id].initial).to eq 100_000
        expect(forge_dsl.sequences[:external].initial).to eq 35
        expect(forge_dsl.sequences[:dated].initial).to eq Date.today
        expect(forge_dsl.sequences[:useless_id].initial).to eq 1
      end

      specify "sequenced attributes resolve to expected values" do
        expect(evaluate(forge_dsl.attributes[:id])).to eq 100_000
        expect(evaluate(forge_dsl.attributes[:external])).to eq 35
        expect(evaluate(forge_dsl.attributes[:dated])).to eq "#{Date.today}/100001"
      end

      it "contains traits with their attributes" do
        expect(forge_dsl.traits.keys).to contain_exactly(:special, :useless)

        expect(forge_dsl.traits[:special].keys).to contain_exactly(:name, :id)
        expect(forge_dsl.traits[:special].values).to all be_a Proc

        expect(forge_dsl.traits[:useless].keys).to contain_exactly(:useless, :useless_id)
        expect(forge_dsl.traits[:useless].values).to all be_a Proc
      end

      it "overrides attributes in traits" do
        expect(evaluate(forge_dsl.traits[:special][:id])).to eq "~~~ SpEcIaL ~~~"
        expect(evaluate(forge_dsl.traits[:special][:name])).to eq "Special Name"

        expect(evaluate(forge_dsl.traits[:useless][:useless])).to eq "Useless"
        expect(evaluate(forge_dsl.traits[:useless][:useless_id])).to eq "Useless 100000"
      end

      context "if an outside method is called in definition" do
        let(:definition) do
          proc do |f|
            f.attr { "Name" }
            puts f.attributes[:attr].call
          end
        end

        it "calls the method successfully" do
          expect { forge_dsl }.to output("Name\n").to_stdout
        end
      end
    end

    describe "definition without block parameter" do
      let(:definition) do
        proc do
          attr_1 { "Name" }
          sequence(:attr_2) { "#{attr_1} #{_1}" }
          trait :unnamed do
            attr_1 { nil }
            sequence(:attr_2) { "<unnamed> #{_1}" }
          end
        end
      end

      it "defines forge attributes, sequences and traits, changing `self` for the block" do
        expect(forge_dsl.attributes[:attr_1]).to be_a Proc
        expect(forge_dsl.attributes[:attr_2]).to be_a Proc
        expect(forge_dsl.sequences[:attr_2]).to be_a Sequence
        expect(forge_dsl.traits[:unnamed]).to be_a Hash
      end

      context "if an outside method is called in definition" do
        let(:definition) do
          proc do
            attr { "Name" }
            puts attributes[:attr].call
          end
        end

        it "fails, probably with ArgumentError" do
          expect { forge_dsl }.to raise_error(ArgumentError, /wrong number of arguments/)
        end
      end
    end

    describe "#attribute" do
      context "with valid attribute definition" do
        let(:definition) { proc { |f| f.attribute(:attr_1) { "Name" } } }

        it "defines an attribute Proc" do
          expect(forge_dsl.attributes[:attr_1]).to be_a Proc

          expect(forge_dsl.attributes[:attr_1].call).to eq "Name"
          # Does not change between calls
          expect(forge_dsl.attributes[:attr_1].call).to eq "Name"
        end

        context "with a reserved name" do
          let(:definition) do
            proc do |f|
              f.attribute(:attr?) { "Name?" }
              f.attribute(:attr!) { "Name!" }
              f.attribute(:attr=) { "Name=" }
              f.attribute(:`) { "`Name`" }
            end
          end

          it "defines an attribute successfully" do
            expect(forge_dsl.attributes[:attr?].call).to eq "Name?"
            expect(forge_dsl.attributes[:attr!].call).to eq "Name!"
            expect(forge_dsl.attributes[:attr=].call).to eq "Name="
            expect(forge_dsl.attributes[:`].call).to eq "`Name`"
          end
        end
      end

      context "when attribute name is not a Symbol" do
        let(:definition) { proc { |f| f.attribute("attr_string") { "Name" } } }

        it "raises ArgumentError on definition" do
          expect { forge_dsl }.to raise_error(
            ArgumentError,
            "attribute name must be a Symbol, String given (in \"attr_string\")"
          )
        end
      end

      context "when no block is given" do
        let(:definition) { proc { |f| f.attribute(:attr_invalid) } }

        it "raises DSLError on definition" do
          expect { forge_dsl }.to raise_error(
            DSLError,
            "attribute definition requires a block (in :attr_invalid)"
          )
        end
      end
    end

    include_examples "has an alias", :[], :attribute

    describe "#sequence" do
      context "with valid, plain sequence definition" do
        let(:definition) { proc { |f| f.sequence(:seq_1) } }

        it "defines a sequence and an attribute" do
          expect(forge_dsl.sequences[:seq_1]).to be_a Sequence
          expect(forge_dsl.attributes[:seq_1]).to be_a Proc

          expect(forge_dsl.attributes[:seq_1].call).to eq 1
          expect(forge_dsl.attributes[:seq_1].call).to eq 2
        end
      end

      context "with an initial value" do
        let(:definition) { proc { |f| f.sequence(:seq_2, "a") } }

        it "defines a sequence and an attribute with a custom value" do
          expect(forge_dsl.sequences[:seq_2]).to be_a Sequence
          expect(forge_dsl.attributes[:seq_2]).to be_a Proc

          expect(forge_dsl.attributes[:seq_2].call).to eq "a"
          expect(forge_dsl.attributes[:seq_2].call).to eq "b"
        end

        context "with a Sequence as initial value" do
          let(:definition) { proc { |f| f.sequence(:seq_2a, sequence) } }
          let(:sequence) { Sequence.new("a") }

          before { sequence.next }

          it "defines a sequence and an attribute with an externally sequenced value" do
            expect(forge_dsl.sequences[:seq_2a]).to be_a Sequence
            expect(forge_dsl.attributes[:seq_2a]).to be_a Proc

            expect(forge_dsl.attributes[:seq_2a].call).to eq "b"
            sequence.next
            expect(forge_dsl.attributes[:seq_2a].call).to eq "d"
          end
        end
      end

      context "with a block" do
        let(:definition) { proc { |f| f.sequence(:seq_3) { |n| n.to_s } } }

        it "defines a sequence and an attribute with a transformed value" do
          expect(forge_dsl.sequences[:seq_3]).to be_a Sequence
          expect(forge_dsl.attributes[:seq_3]).to be_a Proc

          expect(forge_dsl.attributes[:seq_3].call).to eq "1"
          expect(forge_dsl.attributes[:seq_3].call).to eq "2"
        end
      end

      context "when attribute name is not a Symbol" do
        let(:definition) { proc { |f| f.sequence(15) } }

        it "raises ArgumentError on definition" do
          expect { forge_dsl }.to raise_error(
            ArgumentError,
            "sequence name must be a Symbol, Integer given (in 15)"
          )
        end
      end

      context "when initial value is not a Sequence and does not respond to #succ" do
        let(:definition) { proc { |f| f.sequence(:seq_invalid, -> { "a" }) } }

        it "raises ArgumentError on definition (proxied from Sequence)" do
          expect { forge_dsl }.to raise_error(
            ArgumentError,
            "initial value must respond to #succ, Proc given"
          )
        end
      end
    end

    describe "#trait" do
      context "with valid trait definition" do
        let(:definition) do
          proc do |f|
            f.attribute(:attr_1) { "Name" }
            f.trait(:trait_1) { |ft| ft.attribute(:attr_1) { f.equal?(ft) } }
          end
        end

        it "yields self to the block, with block defining overridden attributes" do
          expect(forge_dsl.attributes[:attr_1].call).to eq "Name"
          expect(forge_dsl.traits[:trait_1]).to be_a Hash
          expect(forge_dsl.traits[:trait_1][:attr_1].call).to be true
        end

        context "when trait is defined outside of DSL" do
          let(:definition) do
            trait = ->(ft) { ft.attr_1 { "Enam" } }
            proc do |f|
              f.attribute(:attr_1) { "Name" }
              f.trait(:trait_1, &trait)
            end
          end

          it "accepts such a block" do
            expect(forge_dsl.attributes[:attr_1].call).to eq "Name"
            expect(forge_dsl.traits[:trait_1]).to be_a Hash
            expect(forge_dsl.traits[:trait_1][:attr_1].call).to eq "Enam"
          end
        end
      end

      context "when trait name is not a Symbol" do
        let(:definition) { proc { |f| f.trait("trait_string") } }

        it "raises ArgumentError on definition" do
          expect { forge_dsl }.to raise_error(
            ArgumentError,
            "trait name must be a Symbol, String given (in \"trait_string\")"
          )
        end
      end

      context "when called inside of another trait" do
        let(:definition) do
          proc do |f|
            f.trait(:trait_1) { f.trait(:trait_2) { f.attribute(:attr_unreachable) { "Name" } } }
          end
        end

        it "raises DSLError on definition" do
          expect { forge_dsl }.to raise_error(
            DSLError,
            "can not define trait inside of another trait (in :trait_2)"
          )
        end
      end

      context "when no block is given" do
        let(:definition) { proc { |f| f.trait(:trait_invalid) } }

        it "raises DSLError on definition" do
          expect { forge_dsl }.to raise_error(
            DSLError,
            "trait definition requires a block (in :trait_invalid)"
          )
        end
      end
    end

    describe "#method_missing" do
      context "when called with a non-reserved not-defined name" do
        let(:definition) { proc { |f| f.non_reserved_name { "nAME" } } }

        it "defines corresponding attribute" do
          expect(forge_dsl.attributes[:non_reserved_name].call).to eq "nAME"
        end
      end

      context "when called with a reserved name" do
        %i[
          name? name! name= ` []= + - * / % ** +@ -@ & | ^ ~ << >> < > <= >= === !== =~ !~ rand
        ].each do |reserved_name|
          describe "##{reserved_name}" do
            let(:definition) { proc { |f| f.__send__(reserved_name) { "Name?" } } }

            it "raises DSLError on definition" do
              expect { forge_dsl }.to raise_error(
                DSLError,
                "#{reserved_name.inspect} is a reserved name (in #{reserved_name.inspect})"
              )
            end
          end
        end
      end

      context "when called with a conflicting name" do
        let(:definition) { proc { |f| f.eql? { "Name!!!" } } }

        it "behaves in an undefined manner" do
          expect { forge_dsl }.to raise_error ArgumentError
        end
      end

      context "if called after DSL definition" do
        let(:definition) { proc { |f| f.non_reserved_name { "nAME" } } }

        it "raises NoMethodError" do
          expect { forge_dsl.non_reserved_name }.to raise_error NoMethodError
        end
      end
    end

    describe "#respond_to?" do
      let(:definition) { proc { |f| f.__send__(name) { "Name" } if f.respond_to?(name) } }
      let(:name) { :nnasd_kjbksadk }

      it "returns true if the method is defined" do
        expect(forge_dsl.respond_to?(:attribute)).to be true
      end

      context "if called during DSL definition" do
        it "returns true for non-reserved names" do
          expect(forge_dsl.attributes[name]).to be_a Proc
        end

        context "when called with a reserved name" do
          %i[
            name? name! name= ` []= + - * / % ** +@ -@ & | ^ ~ << >> < > <= >= === !== =~ !~ rand
          ].each do |reserved_name|
            describe "##{reserved_name}" do
              let(:name) { reserved_name }

              it "returns false" do
                expect(forge_dsl.attributes[reserved_name]).to be nil
              end
            end
          end
        end
      end

      context "if called after DSL definition" do
        it "returns false for non-defined names" do
          expect(forge_dsl.respond_to?(name)).to be false
        end
      end
    end

    describe "#inspect" do
      subject(:inspect) { forge_dsl.inspect }

      let(:definition) do
        proc do |f|
          f.attribute(:name) { "Name" }
          f.sequence(:id, 100_000)

          f.trait :special do
            f.name { "Special Name" }
            f[:id] { "~~~ SpEcIaL ~~~" }
          end

          f.trait :useless do
            f.useless { "Useless" }
          end
        end
      end

      it "returns a string containing a human-readable representation of the definition" do
        expect(inspect).to eq(
          "#<#{described_class.name}:#{forge_dsl.__id__} " \
          "attributes=[:name, :id] " \
          "sequences=[:id] " \
          "traits={:special=[:name, :id], :useless=[:useless]}>"
        )
      end
    end
  end
end

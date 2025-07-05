# frozen_string_literal: true

module ObjectForge
  RSpec.describe ForgeDSL do
    subject(:forge_dsl) { described_class.new(&definition) }

    let(:attribute_context) do
      Object.new.tap do |o|
        o.instance_variable_set(:@attributes, forge_dsl.attributes)
        o.instance_variable_set(:@sequences, forge_dsl.sequences)
        # rubocop:disable RSpec/InstanceVariable, ThreadSafety/ClassInstanceVariable
        def o.method_missing(name) = @attributes[name].call
        def o.respond_to_missing?(_name, _include_private = false) = true
        # rubocop:enable RSpec/InstanceVariable, ThreadSafety/ClassInstanceVariable
      end
    end

    def evaluate(proc)
      attribute_context.instance_eval(&proc)
    end

    describe "full example" do
      let(:definition) do
        proc do |f|
          f.attribute(:name) { "Name" }
          f[:description] { name.upcase }
          f.duration { rand(1000) }

          f.sequence(:id, 100_000)
          f.sequence(:reused, Sequence.new(35))
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
          :name, :description, :duration, :id, :reused, :dated
        )
        expect(forge_dsl.attributes.values).to all be_a Proc
      end

      specify "normal attributes resolve to expected values" do
        expect(evaluate(forge_dsl.attributes[:name])).to eq "Name"
        expect(evaluate(forge_dsl.attributes[:description])).to eq "NAME"
        expect(evaluate(forge_dsl.attributes[:duration])).to be_a Integer
      end

      it "contains all sequences" do
        expect(forge_dsl.sequences.keys).to contain_exactly(:id, :reused, :dated, :useless_id)
        expect(forge_dsl.sequences.values).to all be_a Sequence
      end

      specify "all sequences use expected initial values" do
        expect(forge_dsl.sequences[:id].initial).to eq 100_000
        expect(forge_dsl.sequences[:reused].initial).to eq 35
        expect(forge_dsl.sequences[:dated].initial).to eq Date.today
        expect(forge_dsl.sequences[:useless_id].initial).to eq 1
      end

      specify "sequenced attributes resolve to expected values" do
        expect(evaluate(forge_dsl.attributes[:id])).to eq 100_000
        expect(evaluate(forge_dsl.attributes[:reused])).to eq 35
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
    end
  end
end

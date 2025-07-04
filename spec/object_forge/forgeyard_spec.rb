# frozen_string_literal: true

module ObjectForge
  RSpec.describe Forgeyard do
    subject(:forgeyard) { described_class.new }

    let(:forge) { instance_double(Forge, "Forge", "[]": instance) }
    let(:instance) { Object.new }

    describe "#register" do
      let(:another_forge) { instance_double(Forge, "Another forge") }

      it "registers the forge under a specified name, returning it" do
        expect(forgeyard.register(:test, forge)).to be forge
      end

      it "returns an existing forge if one was already registered" do
        expect(forgeyard.register(:test, forge)).to be forge
        expect(forgeyard.register(:test, another_forge)).to be forge
      end

      context "when running in a threaded environment" do
        let(:sleepy_thread) do
          Thread.new do
            sleep 0.001
            forgeyard.register(:test, another_forge)
          end
        end

        before { sleepy_thread }

        it "registers the forge thread-safely, returning first registered forge" do
          expect(forgeyard.register(:test, forge)).to be forge
          expect(sleepy_thread.join.value).to be forge
        end
      end
    end

    include_examples "has an alias", :[]=, :register

    describe "#forge" do
      before { forgeyard.register(:test, forge) }

      context "with a single argument" do
        it "returns a forge by name" do
          expect(forgeyard.forge(:test)).to be forge
        end

        context "when name is not registered" do
          it "raises KeyError" do
            expect { forgeyard.forge(:nonexistent) }.to raise_error KeyError
          end
        end
      end

      context "with multiple arguments" do
        it "builds an instance using the forge" do
          expect(forgeyard.forge(:test, :trait, attribute: 2)).to be instance
          expect(forge).to have_received(:[]).with([:trait], { attribute: 2 })
        end

        context "when name is not registered" do
          it "raises KeyError" do
            expect { forgeyard.forge(:nonexistent, :trait, attribute: 2) }.to raise_error KeyError
          end
        end
      end
    end

    include_examples "has an alias", :[], :forge
  end
end

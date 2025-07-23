# frozen_string_literal: true

module ObjectForge
  RSpec.describe Sequence do
    subject(:sequence) { described_class.new(initial) }

    let(:initial) { rand(1000) }

    describe ".new" do
      it "returns a new sequence" do
        expect(sequence).to be_a described_class
      end

      it "returns the same sequence if it's already a sequence" do
        expect(described_class.new(sequence)).to be sequence
      end

      context "when initial value does not respond to #succ" do
        let(:initial) { [1] }

        it "raises ArgumentError" do
          expect { described_class.new(initial) }.to raise_error(
            ArgumentError,
            "initial value must respond to #succ, Array given"
          )
        end
      end
    end

    describe "#initial" do
      it "returns the initial value" do
        sequence.next
        expect(sequence.next).to eq initial + 1
        expect(sequence.initial).to eq initial
      end
    end

    describe "#next" do
      it "returns the next value, starting with initial" do
        expect(sequence.next).to eq initial
        expect(sequence.next).to eq initial + 1
        expect(sequence.next).to eq initial + 2
      end

      context "with a string initial value" do
        let(:initial) { "aaa" }

        it "returns the next value, starting with initial" do
          expect(sequence.next).to eq "aaa"
          expect(sequence.next).to eq "aab"
          expect(sequence.next).to eq "aac"
        end
      end

      context "when running in a threaded environment" do
        let(:initial) { 1 }
        let(:threads) { Array.new(10) { Thread.new { Array.new(10) { sequence.next } } } }

        # Sadly, this test doesn't really prove anything, as the quantum of processing time
        # is larger than the time it takes to run each thread (I think).
        # However, if Sequence#next is modified to call Thread.pass, this test will fail
        # on naive implementation, but not on the synchronized one.
        it "synchronizes access to the sequence, returning unique values" do
          values = threads.each(&:join).map(&:value).flatten!.sort!

          expect(values).to eq (1..(10 * 10)).to_a
        end
      end
    end

    describe "#reset" do
      it "resets the sequence to its initial value" do
        sequence.next
        expect(sequence.reset).to eq initial + 1
        expect(sequence.next).to eq initial
      end
    end

    include_examples "has an alias", :rewind, :reset
  end
end

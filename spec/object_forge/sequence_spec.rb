# frozen_string_literal: true

module ObjectForge
  RSpec.describe Sequence do
    subject(:sequence) { described_class.new(initial) }

    let(:initial) { rand(1000) }

    describe "#initial" do
      it "returns the initial value" do
        sequence.succ
        expect(sequence.succ).to eq initial + 1
        expect(sequence.initial).to eq initial
      end
    end

    describe "#succ" do
      it "returns the next value, starting with initial" do
        expect(sequence.succ).to eq initial
        expect(sequence.succ).to eq initial + 1
        expect(sequence.succ).to eq initial + 2
      end

      context "with a string initial value" do
        let(:initial) { "aaa" }

        it "returns the next value, starting with initial" do
          expect(sequence.succ).to eq "aaa"
          expect(sequence.succ).to eq "aab"
          expect(sequence.succ).to eq "aac"
        end
      end

      context "when running in a threaded environment" do
        let(:initial) { 1 }
        let(:threads) { Array.new(10) { Thread.new { Array.new(10) { sequence.succ } } } }

        # Sadly, this test doesn't really prove anything, as the quantum of processing time
        # is larger than the time it takes to run each thread (I think).
        # However, if Sequence#succ is modified to call Thread.pass, this test will fail
        # on naive implementation, but not on the synchronized one.
        it "synchronizes access to the sequence, returning unique values" do
          values = threads.each(&:join).map(&:value).flatten!.sort!

          expect(values).to eq (1..(10 * 10)).to_a
        end
      end
    end

    include_examples "has an alias", :next, :succ

    describe "#reset" do
      it "resets the sequence to its initial value" do
        sequence.succ
        expect(sequence.reset).to eq initial + 1
        expect(sequence.succ).to eq initial
      end
    end

    include_examples "has an alias", :rewind, :reset
  end
end

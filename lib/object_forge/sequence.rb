# frozen_string_literal: true

require "concurrent/mvar"

module ObjectForge
  # A thread-safe container for sequences.
  #
  # @since 0.1.0
  class Sequence
    # @return [#succ] initial value for the sequence
    attr_reader :initial

    # @note Initial value must not be modified after the sequence is created,
    #   or the results will be unpredicatable. Consider always passing a frozen value.
    #
    # @param initial [#succ] initial value for the sequence
    def initialize(initial)
      @initial = initial
      @container = Concurrent::MVar.new(initial)
    end

    # Get the next value in the sequence, starting with the initial value.
    #
    # @thread_safety Sequence traversal is synchronized,
    #   so no duplicate values will be returned.
    #
    # @return [#succ] next value
    def succ
      @container.modify(&:succ)
    end

    alias next succ

    # Reset the sequence to its {#initial} value.
    #
    # @thread_safety Reset is synchronized with {#succ}.
    #
    # @return [#succ] whatever value would be returned by {#succ} before reset
    def reset
      @container.modify { @initial }
    end

    alias rewind reset
  end
end

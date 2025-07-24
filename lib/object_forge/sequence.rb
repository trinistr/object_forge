# frozen_string_literal: true

require "concurrent/mvar"

module ObjectForge
  # A thread-safe container for sequences.
  #
  # @since 0.1.0
  class Sequence
    # Return a new sequence, or +initial+ if it's already a sequence.
    #
    # @param initial [#succ, Sequence]
    # @return [Sequence]
    def self.new(initial, ...)
      return initial if initial.is_a?(Sequence)

      super
    end

    # @return [#succ] initial value for the sequence
    attr_reader :initial

    # @note Initial value must not be modified after the sequence is created,
    #   or the results will be unpredicatable. Consider always passing a frozen value.
    #
    # @param initial [#succ] initial value for the sequence
    #
    # @raise [ArgumentError] if +initial+ does not respond to #succ
    def initialize(initial)
      unless initial.respond_to?(:succ)
        raise ArgumentError, "initial value must respond to #succ, #{initial.class} given"
      end

      @initial = initial
      @container = Concurrent::MVar.new(initial)
    end

    # Get the next value in the sequence, starting with the initial value.
    #
    # @thread_safety Sequence traversal is synchronized,
    #   so no duplicate values will be returned.
    #
    # @return [#succ] next value
    def next
      @container.modify(&:succ)
    end

    # Reset the sequence to its {#initial} value.
    #
    # @thread_safety Reset is synchronized with {#next}.
    #
    # @return [#succ] whatever value would be returned by {#next} before reset
    def reset
      @container.modify { @initial }
    end

    alias rewind reset
  end
end

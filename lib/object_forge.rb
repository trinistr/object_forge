# frozen_string_literal: true

Dir["#{__dir__}/object_forge/**/*.rb"].each { require _1 }

# A simple all-purpose factory library with minimal assumptions.
module ObjectForge
  # Base error class for ObjectForge.
  # @since 0.1.0
  class Error < StandardError; end
  # Error raised when a mistake is made in using DSL.
  # @since 0.1.0
  class DSLError < Error; end

  # @!macro default_forgeyard
  #   @note
  #     Default forgeyard is intended to be useful for non-shareable code,
  #     like simple application tests and specs.
  #     It should not be used in application code, and never in gems.

  # Default {Forgeyard} that is used by {.define} and {.forge}.
  #
  # @since 0.1.0
  DEFAULT_YARD = Forgeyard.new

  # @overload sequence(initial)
  # Create a sequence.
  #
  # @see Sequence.new
  # @since 0.1.0
  #
  # @param initial [#succ, Sequence]
  # @return [Sequence]
  #
  def self.sequence(...)
    Sequence.new(...)
  end

  # @overload define(forged, name: nil) { |f| ...}
  # Define and create a forge in {DEFAULT_YARD}.
  #
  # @!macro default_forgeyard
  # @see Forgeyard#define
  # @since 0.1.0
  #
  # @param forged [Class] class to forge
  # @param name [Symbol, nil] forge name
  # @yieldparam f [ForgeDSL]
  # @yieldreturn [void]
  # @return [Forge] forge
  def self.define(...)
    DEFAULT_YARD.define(...)
  end

  # @overload forge(name, *traits, **overrides)
  # Build an instance using a forge from {DEFAULT_YARD}.
  #
  # @!macro default_forgeyard
  # @see Forgeyard#define
  # @since 0.1.0
  #
  # @param name [Symbol] name of the forge
  # @param traits [Array<Symbol>] traits to apply
  # @param overrides [Hash{Symbol => Any}] attribute overrides
  # @return [Any] built instance
  def self.forge(...)
    DEFAULT_YARD.forge(...)
  end
end

# frozen_string_literal: true

Dir["#{__dir__}/object_forge/**/*.rb"].each { require _1 }

# A simple all-purpose factory library with minimal assumptions.
#
# These are the main classes you should be aware of:
# - {Forgeyard} is a registry of named related Forges.
#   A Forgeyard allows to {Forgeyard#define} a Forge,
#   and {Forgeyard#forge} a new object using a defined Forge.
# - {Forge} is a factory for objects.
#   Usually created through {Forgeyard#define}/{Forge.define} in a manner similar to FactoryBot,
#   Forges can be used standalone, or as a part of a Forgeyard.
# - {Sequence} is a representation of a sequence of values.
#   They are usually used implicitly through {ForgeDSL#sequence},
#   but can be created explicitly to be shared (or used outside of ObjectForge).
#
# Additionally, successful use may depend on understanding these:
# - {ForgeDSL} is a block-based DSL inspired by FactoryBot and ROM::Factory.
#   It allows defining arbitrary attributes (possibly using sequences),
#   with support for traits (collections of attributes with non-default values).
# - {Crucible} is used to resolve attributes.
module ObjectForge
  # Base error class for ObjectForge.
  # @since 0.1.0
  class Error < StandardError; end
  # Error raised when a mistake is made in using DSL.
  # @since 0.1.0
  class DSLError < Error; end

  # Default {Forgeyard} that is used by {.define} and {.forge}.
  #
  # @!macro default_forgeyard
  #   @note
  #     Default forgeyard is intended to be useful for non-shareable code,
  #     like simple application tests and specs.
  #     It should not be used in application code, and never in gems.
  # @since 0.1.0
  DEFAULT_YARD = Forgeyard.new

  # @overload sequence(initial)
  # Create a sequence, to be used wherever it needs to be.
  #
  # @see Sequence.new
  # @since 0.1.0
  #
  # @param initial [#succ, Sequence]
  # @return [Sequence]
  def self.sequence(...)
    Sequence.new(...)
  end

  # @overload define(name, forged, &)
  # Define and create a forge in {DEFAULT_YARD}.
  #
  # @!macro default_forgeyard
  # @see Forgeyard#define
  # @since 0.1.0
  #
  # @param name [Symbol] forge name
  # @param forged [Class] class to forge
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

  class << self
    # @since 0.1.0
    alias build forge
    # @since 0.1.0
    alias [] forge
  end
end

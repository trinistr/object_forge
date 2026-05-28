# frozen_string_literal: true

require_relative "object_forge/forgeyard"
require_relative "object_forge/sequence"
require_relative "object_forge/version"

# A small factory library for Ruby objects with minimal assumptions about framework, persistence,
# or runtime environment.
#
# These are the main classes you should be aware of:
# - {Forge} is a factory for objects.
#   Usually created through {Forgeyard#define} or {Forge.define}
#   using a DSL similar to FactoryBot, Forges can be used standalone,
#   or as a part of a Forgeyard.
# - {Forgeyard} is a registry of named related Forges.
#   A Forgeyard allows to {Forgeyard#define} a Forge,
#   and {Forgeyard#forge} a new object using a defined Forge.
# - {Molds} are object constructors used by {Forge}s.
#   Several common molds are shipped with ObjectForge, but you
#   will probably find it useful to create your own.
#
# Successful use may also depend on understanding these:
# - {ForgeDSL} is a block-based DSL inspired by FactoryBot and ROM::Factory.
#   It allows defining arbitrary attributes (possibly using sequences),
#   with support for traits (collections of attributes with non-default values).
# - {Sequence} is a representation of a sequence of values.
#   They are usually used implicitly through {ForgeDSL#sequence},
#   but can be created explicitly to be shared (or used outside of ObjectForge).
# - {Crucible} is used to resolve attributes.
#
# *ObjectForge* itself provides a top-level convenience API for working with a singular
# {DEFAULT_YARD} when you expect to never need more than one Forgeyard, such as in test suites.
#
# @example Quick example
#   Frobinator = Struct.new(:frob, :inator, keyword_init: true)
#
#   # Forge's name and target class are completely independent.
#   ObjectForge.define(:frobber, Frobinator) do |f|
#     f.frob { "Frob" + inator.call }
#     f.inator { -> { "inator" } }
#
#     f.trait :static do |tf|
#       tf.frob { "Static" }
#     end
#   end
#
#   # These methods are aliases:
#   ObjectForge.forge(:frobber)
#     # => #<struct Frobinator frob="Frobinator", inator=#<Proc:...>>
#   ObjectForge.build(:frobber, frob: -> { "Frob" + inator }, inator: "orn")
#     # => #<struct Frobinator frob="Froborn", inator="orn">
#   ObjectForge.call(:frobber, :static, inator: "Value")
#     # => #<struct Frobinator frob="Static", inator="Value">
#
# @example A more involved example
#   require "logger"
#
#   # A custom mold is needed for Logger because it has positional and keyword parameters.
#   logger_mold = ->(forge_target:, attributes:, **) {
#     forge_target.new(
#       attributes[:file],
#       *attributes[:rotation],
#       **attributes.slice(:level, :progname, :formatter)
#     )
#   }
#
#   # This is a one-off, universal factory, so using a Forgeyard is not needed.
#   $logger_factory = ObjectForge::Forge.define(Logger) do |f|
#     f.mold = logger_mold
#     # Default crucible is almost always good enough, but let's use a simpler and faster resolver.
#     f.crucible = ->(attributes) { attributes.transform_values { _1.is_a?(Proc) ? _1.call : _1 } }
#
#     f.file { $stderr }
#
#     f.trait :stdout do |tf|
#       tf.file { $stdout }
#     end
#
#     f.trait :logfiles do |tf|
#       require "date"
#       tf.file { "log-#{Date.today}.log" }
#       tf.rotation { "daily" }
#     end
#   end
#
#   class MyClass
#     def initialize
#       @logger = $logger_factory.build(:stdout, progname: self.class)
#     end
#
#     def call
#       @logger.info("called!")
#     end
#   end
#
#   MyClass.new.call
#     # outputs "I, [2026-05-25T13:56:33.533669 #206330]  INFO -- MyClass: called!" to $stdout
module ObjectForge
  # Base domain error class for ObjectForge.
  # @since 0.1.0
  class Error < StandardError; end
  # Error raised when a mistake is made in using DSL.
  # @since 0.1.0
  class DSLError < Error; end
  # Error raised when attribute resolution surfaces a circular dependency.
  # @since 0.4.0
  class CircularAttributeDependencyError < Error; end

  # Error raised when object does not conform to expected interface,
  # most commonly lacking +#call+.
  # @note This class inherits from +TypeError+, not {Error}.
  # @since 0.4.0
  class ObjectInterfaceError < ::TypeError; end

  # Default {Forgeyard} that is used by {.define} and {.forge}.
  #
  # @!macro default_forgeyard
  #   @note
  #     Default forgeyard is intended to be useful for non-shareable code,
  #     like simple application tests and specs.
  #     It should not be used in application code, especially in gems.
  # @since 0.1.0
  DEFAULT_YARD = Forgeyard.new

  # Create a sequence, to be used wherever it needs to be.
  #
  # @see Sequence.new
  # @since 0.1.0
  #
  # @overload sequence(initial)
  #   @param initial [#succ, Sequence]
  #   @return [Sequence]
  def self.sequence(...)
    Sequence.new(...)
  end

  # Define and create a forge in {DEFAULT_YARD}.
  #
  # @!macro default_forgeyard
  # @see Forgeyard#define
  # @since 0.1.0
  #
  # @overload define(name, forge_target)
  #   @param name [Symbol] name to register forge under
  #   @param forge_target [Class, Any] class or object to forge
  #   @yieldparam dsl [ForgeDSL]
  #   @yieldreturn [void]
  #   @return [Forge] forge
  def self.define(...)
    DEFAULT_YARD.define(...)
  end

  # Build an instance using a forge from {DEFAULT_YARD}.
  #
  # @!macro default_forgeyard
  # @see Forgeyard#forge
  # @since 0.1.0
  #
  # @overload forge(name, *traits, **overrides)
  #   @param name [Symbol] name of the forge
  #   @param traits [Array<Symbol>] traits to apply
  #   @param overrides [Hash{Symbol => Any}] attribute overrides
  #   @yieldparam object [Any] forged instance
  #   @yieldreturn [void]
  #   @return [Any] forged instance
  #   @raise [ArgumentError] if a trait name is unknown
  #   @raise [KeyError] if forge with the specified name is not registered
  def self.forge(...)
    DEFAULT_YARD.forge(...)
  end

  class << self
    alias build forge
    alias call forge
  end
end

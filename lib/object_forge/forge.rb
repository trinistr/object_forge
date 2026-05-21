# frozen_string_literal: true

require_relative "crucible"
require_relative "forge_dsl"
require_relative "molds"

module ObjectForge
  # Object instantitation forge.
  #
  # @since 0.1.0
  class Forge
    # Interface for forge parameters.
    # It is not used internally, but can be useful for defining forges
    # through means other than {ForgeDSL}.
    #
    # @!attribute [r] attributes
    #   Non-trait values of the attributes.
    #   @return [Hash{Symbol => Any}]
    #
    # @!attribute [r] traits
    #   Attributes belonging to traits.
    #   @return [Hash{Symbol => Hash{Symbol => Any}}]
    #
    # @!attribute [r] options
    #   A forge's options.
    #   Known options:
    #   - +:mold+ — an object that knows how to build the instance
    #     with a +call+ method taking a class and a hash of attributes.
    #   - +:crucible+ — an object that knows how to resolve attributes
    #     with a +call+ method taking a hash of initial attributes.
    #   @since 0.3.0
    #   @return [Hash{Symbol => Any}]
    Parameters = Struct.new(:attributes, :traits, :options, keyword_init: true)

    # Define (and create) a forge using DSL.
    #
    # @see ForgeDSL
    # @thread_safety Thread-safe if DSL definition is thread-safe.
    #
    # @param forge_target [Class, Any] class or object to forge
    # @param name [Symbol, nil] forge name
    # @yieldparam dsl [ForgeDSL]
    # @yieldreturn [void]
    # @return [Forge] forge
    def self.define(forge_target, name: nil, &)
      new(forge_target, ForgeDSL.new(&), name:)
    end

    # @return [Symbol, nil] forge name
    attr_reader :name

    # @return [Class, Any] class or object to forge
    # @since <<next>>
    attr_reader :forge_target
    alias target forge_target

    # @return [Parameters, ForgeDSL] forge parameters
    attr_reader :parameters

    # @param forge_target [Class, Any] class or object to forge
    # @param parameters [Parameters, ForgeDSL] forge parameters
    # @param name [Symbol, nil] forge name;
    #   only used for identification purposes
    def initialize(forge_target, parameters, name: nil)
      @name = name
      @forge_target = forge_target
      @parameters = parameters
      @mold = determine_mold(forge_target, parameters.options[:mold])
      @crucible = determine_crucible(parameters.options[:crucible])
    end

    # Forge a new instance.
    #
    # Positional arguments are taken as trait names, keyword arguments as attribute overrides.
    #
    # All traits and overrides are applied in argument order,
    # with overrides always applied after traits.
    #
    # If a block is given, forged instance is yielded to it after being built.
    #
    # @thread_safety Forging is thread-safe if {#parameters},
    #   +traits+ and +overrides+ are thread-safe.
    #
    # @param traits [Array<Symbol>] traits to apply
    # @param overrides [Hash{Symbol => Any}] attribute overrides
    # @yieldparam object [Any] forged instance
    # @yieldreturn [void]
    # @return [Any] built instance
    #
    # @raise [ArgumentError] if a trait name is unknown
    def forge(*traits, **overrides)
      resolved_attributes = resolve_attributes(traits, overrides)
      instance = @mold.call(forge_target: @forge_target, attributes: resolved_attributes)
      yield instance if block_given?
      instance
    end

    alias build forge
    alias call forge

    private

    # Get appropriate mold based on parameters.
    #
    # If +mold+ is already set, it will be used directly, or,
    # if it is Class, it will be wrapped in {Molds::WrappedMold} if posssible.
    # If +nil+, a mold will be selected based on +forge_target+ class.
    #
    # @param forge_target [Class, Any]
    # @param mold [#call, Class, nil]
    # @return [#call]
    #
    # @raise [MoldError]
    #
    # @since 0.3.0
    def determine_mold(forge_target, mold)
      Molds.wrap_mold(mold) || Molds.mold_for(forge_target)
    end

    # Get a crucible object based on parameters.
    #
    # It's either the object provided in options, or {Crucible}.
    #
    # @param crucible [#call, nil]
    # @return [#call]
    #
    # @since <<next>>
    def determine_crucible(crucible)
      crucible || Crucible
    end

    # Resolve attributes using default attributes, specified traits and overrides.
    #
    # @param traits [Array<Symbol>]
    # @param overrides [Hash{Symbol => Any}]
    # @return [Hash{Symbol => Any}]
    #
    # @raise [ArgumentError]
    def resolve_attributes(traits, overrides)
      unless (unknown_traits = traits.difference(@parameters.traits.keys)).empty?
        raise ArgumentError,
              "unknown traits for forge#{" #{name}" if name}: #{unknown_traits.join(", ")}"
      end

      attributes = @parameters.attributes.merge(*@parameters.traits.values_at(*traits), overrides)
      @crucible.call(attributes)
    end
  end
end

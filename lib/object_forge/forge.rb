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
    #   Must include a +:mold+ key, containing an object that knows how to build the instance
    #   with a +call+ method that takes a class and a hash of attributes.
    #   @since 0.3.0
    #   @return [Hash{Symbol => Any}]
    Parameters = Struct.new(:attributes, :traits, :options, keyword_init: true)

    # Define (and create) a forge using DSL.
    #
    # @see ForgeDSL
    # @thread_safety Thread-safe if DSL definition is thread-safe.
    #
    # @param forged [Class, Any] class or object to forge
    # @param name [Symbol, nil] forge name
    # @yieldparam f [ForgeDSL]
    # @yieldreturn [void]
    # @return [Forge] forge
    def self.define(forged, name: nil, &)
      new(forged, ForgeDSL.new(&), name:)
    end

    # @return [Symbol, nil] forge name
    attr_reader :name

    # @return [Class, Any] class or object to forge
    attr_reader :forged

    # @return [Parameters, ForgeDSL] forge parameters
    attr_reader :parameters

    # @param forged [Class, Any] class or object to forge
    # @param parameters [Parameters, ForgeDSL] forge parameters
    # @param name [Symbol, nil] forge name;
    #   only used for identification purposes
    def initialize(forged, parameters, name: nil)
      @name = name
      @forged = forged
      @parameters = parameters
      @mold = determine_mold(forged, parameters.options[:mold])
    end

    # Forge a new instance.
    #
    # @overload forge(*traits, **overrides, &)
    # @overload forge(traits, overrides, &)
    #
    # Positional arguments are taken as trait names, keyword arguments as attribute overrides,
    # unless there are exactly two positional arguments: an array and a hash.
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
    def forge(*traits, **overrides)
      resolved_attributes = resolve_attributes(traits, overrides)
      instance = @mold.call(forged: @forged, attributes: resolved_attributes)
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
    # If +nil+, a mold will be selected based on +forged+ class.
    #
    # @param forged [Class, Any]
    # @param mold [#call, Class, nil]
    # @return [#call]
    #
    # @raise [MoldError]
    #
    # @since 0.3.0
    def determine_mold(forged, mold)
      Molds.wrap_mold(mold) || Molds.mold_for(forged)
    end

    # Resolve attributes using default attributes, specified traits and overrides.
    #
    # @param traits [Array<Symbol>]
    # @param overrides [Hash{Symbol => Any}]
    # @return [Hash{Symbol => Any}]
    def resolve_attributes(traits, overrides)
      attributes = @parameters.attributes.merge(*@parameters.traits.values_at(*traits), overrides)
      Crucible.new(attributes).resolve!
    end
  end
end

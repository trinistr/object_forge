# frozen_string_literal: true

require_relative "crucible"
require_relative "forge_dsl"
require_relative "molds"

module ObjectForge
  # Object building forge.
  #
  # Usually created through {.define} or {Forgeyard#define} using {ForgeDSL}.
  # Alternatively, can be directly initalized with {Parameters} if you prefer not using the DSL.
  #
  # Then, {#forge} can be called to build instances of {#forge_target}.
  #
  # @since 0.1.0
  class Forge
    # Interface for forge parameters.
    # It is not used internally, but can be useful for defining forges
    # through means other than {ForgeDSL}.
    #
    # @!attribute [r] attributes
    #   Default values of the attributes.
    #   @return [Hash{Symbol => Proc, Any}]
    #
    # @!attribute [r] traits
    #   Attributes belonging to traits.
    #   @return [Hash{Symbol => Hash{Symbol => Proc, Any}}]
    #
    # @!attribute [r] options
    #   A forge's options.
    #   Known options:
    #   - +:mold+ — a +call+able object that knows how to build the instance,
    #     taking a class and a hash of attributes.
    #   - +:crucible+ — a +call+able object that knows how to resolve attributes,
    #     taking a hash of initial attributes.
    #   - +:after_forge+/+:after_build+ — a +call+able object that is passed
    #     the forged instance and can do anything with it.
    #   @since 0.3.0
    #   @return [Hash{Symbol => Any}]
    Parameters = Struct.new(:attributes, :traits, :options, keyword_init: true)

    # Define (and initialize) a forge using DSL.
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

    # @return [Symbol, nil] forge name, only used for identification purposes
    attr_reader :name

    # @return [Class, Any] class or object to forge
    # @since 0.4.0
    attr_reader :forge_target
    alias target forge_target

    # @return [Parameters, ForgeDSL] forge parameters
    attr_reader :parameters

    # @param forge_target [Class, Any] class or object to forge,
    #   will be passed to mold as +forge_target+ argument
    # @param parameters [Parameters, ForgeDSL] forge parameters
    # @param name [Symbol, nil] forge name
    #
    # @raise [ObjectInterfaceError] if forge options do not have expected interface;
    #   see {Parameters#options} for details
    def initialize(forge_target, parameters, name: nil)
      @name = name
      @forge_target = forge_target
      @parameters = parameters

      options = @parameters.options
      @crucible = determine_crucible(options)
      @mold = determine_mold(forge_target, options)
      @after_forge_hook = determine_after_forge_hook(options)
    end

    # Forge a new instance, applying attributes to forge target.
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
    # @param overrides [Hash{Symbol => Proc, Any}] attribute overrides
    # @yieldparam object [Any] forged instance
    # @yieldreturn [void]
    # @return [Any] forged instance
    #
    # @raise [ArgumentError] if a trait name is unknown
    def forge(*traits, **overrides)
      resolved_attributes = resolve_attributes(traits, overrides)
      instance = @mold.call(forge_target: @forge_target, attributes: resolved_attributes)
      @after_forge_hook&.call(instance)
      yield instance if block_given?
      instance
    end

    alias build forge
    alias call forge

    private

    # Get a crucible object based on parameters.
    #
    # It's either the object provided in options, or {Crucible}.
    #
    # @param options [Hash]
    # @option options [#call, nil] :crucible
    # @return [#call]
    #
    # @raise [ObjectInterfaceError]
    #
    # @since 0.4.0
    def determine_crucible(options)
      crucible = options[:crucible] || Crucible

      unless crucible.respond_to?(:call)
        raise ObjectInterfaceError, "crucible must respond to #call"
      end

      crucible
    end

    # Get appropriate mold based on parameters.
    #
    # If +mold+ is already set, it will be used directly, or,
    # if it is Class, it will be wrapped in {Molds::WrappedMold} if posssible.
    # If +nil+, a mold will be selected based on +forge_target+ class.
    #
    # @param forge_target [Class, Any]
    # @param options [Hash]
    # @option options [#call, Class, nil] :mold
    # @return [#call]
    #
    # @raise [ObjectInterfaceError]
    #
    # @since 0.3.0
    def determine_mold(forge_target, options)
      Molds.wrap_mold(options[:mold]) || Molds.mold_for(forge_target)
    end

    # Get after-forge hook if specified.
    #
    # Both +:after_forge+ and +:after_build+ are accepted, but +:after_forge+
    # wins if both are present.
    #
    # @param options [Hash]
    # @option options [#call, nil] :after_forge
    # @option options [#call, nil] :after_build
    # @return [#call, nil]
    #
    # @raise [ObjectInterfaceError]
    #
    # @since 0.4.0
    def determine_after_forge_hook(options)
      hook = options[:after_forge] || options[:after_build] || nil

      unless hook.nil? || hook.respond_to?(:call)
        raise ObjectInterfaceError, "after-forge hook must respond to #call"
      end

      hook
    end

    # Resolve attributes using default attributes, specified traits and overrides.
    #
    # @param traits [Array<Symbol>]
    # @param overrides [Hash{Symbol => Proc, Any}]
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

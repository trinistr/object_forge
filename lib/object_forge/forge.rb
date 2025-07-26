# frozen_string_literal: true

require_relative "crucible"
require_relative "forge_dsl"

module ObjectForge
  # Object instantitation forge.
  #
  # @since 0.1.0
  class Forge
    # @!attribute [r] attributes
    #   @return [Hash{Symbol => Any}] non-trait values of the attributes
    #
    # @!attribute [r] traits
    #   @return [Hash{Symbol => Hash{Symbol => Any}}] attributes belonging to traits
    Parameters = Struct.new(:attributes, :traits)

    # Define (and create) a forge using DSL.
    #
    # @see ForgeDSL
    #
    # @param forged [Class] class to forge
    # @param name [Symbol, nil] forge name
    # @yieldparam f [ForgeDSL]
    # @yieldreturn [void]
    # @return [Forge] forge
    def self.define(forged, name: nil, &)
      new(forged, ForgeDSL.new(&), name: name)
    end

    # @return [Class] class to forge
    attr_reader :forged

    # @return [Parameters, ForgeDSL] forge parameters
    attr_reader :parameters

    # @return [Symbol, nil] forge name
    attr_reader :name

    # @param forged [Class] class to forge
    # @param parameters [Parameters, ForgeDSL] forge parameters
    # @param name [Symbol, nil] forge name
    def initialize(forged, parameters, name: nil)
      @forged = forged
      @parameters = parameters
      @name = name
    end

    # Forge a new instance.
    #
    # @overload forge(*traits, **overrides)
    # @overload forge(traits, overrides)
    #
    # @thread_safety Forging is thread-safe if {#parameters},
    #    +traits+ and +overrides+ are thread-safe.
    #
    # @param traits [Array<Symbol>] traits to apply
    # @param overrides [Hash{Symbol => Any}] attribute overrides
    # @return [Any] built instance
    def forge(*traits, **overrides)
      traits, overrides = check_traits_and_overrides(traits, overrides)
      attributes = @parameters.attributes.merge(*@parameters.traits.values_at(*traits), overrides)
      attributes = Crucible.new(attributes).resolve!

      forged.new(attributes)
    end

    alias build forge
    alias [] forge

    private

    def check_traits_and_overrides(traits, overrides)
      return [traits, overrides] unless overrides.empty?

      case traits
      in [Array => real_traits, Hash => real_overrides]
        [real_traits, real_overrides]
      else
        [traits, overrides]
      end
    end
  end
end

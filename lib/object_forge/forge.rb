# frozen_string_literal: true

require_relative "crucible"
require_relative "forge_dsl"

module ObjectForge
  # Object instantitation forge.
  #
  # @since 0.1.0
  class Forge
    # @return [Class] class to forge
    attr_reader :forged

    # @return [Symbol, name] forge name
    attr_reader :name

    # @param forged [Class] class to forge
    # @param name [Symbol, nil] forge name
    # @yieldparam f [ForgeDSL] forge DSL
    # @yieldreturn [void]
    def initialize(forged, name: nil, &)
      @forged = forged
      @name = name
      @parameters = ForgeDSL.new(&)
    end

    # Forge a new instance.
    #
    # @overload forge(*traits, **overrides)
    # @overload forge(traits, overrides)
    #
    # @param traits [Array<Symbol>] traits to apply
    # @param overrides [Hash{Symbol => Any}] attribute overrides
    # @return [Any] built instance
    def forge(*traits, **overrides)
      traits, overrides = check_traits_and_overrides(traits, overrides)
      attributes = @parameters.attributes.merge(*@parameters.traits.values_at(*traits), overrides)
      attributes = Crucible.new(attributes, @parameters.sequences).resolve!
      
      forged.new(attributes)
    end

    alias [] forge

    private

    def check_traits_and_overrides(traits, overrides)
      case [traits, overrides]
      in [[Array => real_traits, Hash => real_overrides], {}]
        traits = real_traits
        overrides = real_overrides
      else
        # already good
      end

      [traits, overrides]
    end
  end
end

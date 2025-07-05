# frozen_string_literal: true

require_relative "forge_dsl"

module ObjectForge
  # Object instantitation forge.
  #
  # @since 0.1.0
  class Forge
    # @return [Symbol] forge name
    attr_reader :name

    # @return [Class] class to forge
    attr_reader :forged

    # @param forged [Class] class to forge
    # @param name [Symbol] forge name
    # @yieldparam f [ForgeDSL] forge DSL
    # @yieldreturn [void]
    def initialize(forged, name: nil, &)
      @forged = forged
      @name = name
      @parameters = ForgeDSL.new(&)
    end

    # Forge a new instance.
    #
    # @param traits [Array<Symbol>] traits to apply
    # @param overrides [Hash{Symbol => Any}] attribute overrides
    # @return [Any] built instance
    def forge(*traits, **overrides)
      raise NotImplementedError
    end

    alias [] forge
  end
end

# frozen_string_literal: true

module ObjectForge
  class Forge
    def initialize(forged, attributes, sequences, traits)
      @forged = forged
      @attributes = attributes
      @sequences = sequences
      @traits = traits
    end

    def forge(*traits, **overrides)
      forged.new(@attributes.merge(*@traits.values_at(*traits), overrides))
    end

    alias [] forge
  end
end

# frozen_string_literal: true

module ObjectForge
  # Melting pot for the forged object's attributes.
  #
  # @since 0.1.0
  class Crucible
    # @param attributes [Hash{Symbol => Proc}]
    #   initial attributes; will be modified directly
    def initialize(attributes)
      @attributes = attributes
    end

    # Resolve all attributes by calling their procs,
    # using +self+ as the evaluation context.
    #
    # @return [Hash{Symbol => Any}]
    def resolve!
      @attributes.each_key { |name| method_missing(name) }
      @attributes
    end

    private

    # Get the value of the attribute +name+.
    #
    # @param name [Symbol]
    # @return [Any]
    def method_missing(name)
      if @attributes.key?(name)
        if @attributes[name].is_a?(Proc)
          @attributes[name] = instance_eval(&@attributes[name])
        else
          @attributes[name]
        end
      else
        super
      end
    end

    def respond_to_missing?(name, _include_all)
      @attributes.key?(name) || super
    end
  end
end

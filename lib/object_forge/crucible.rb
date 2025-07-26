# frozen_string_literal: true

require_relative "un_basic_object"

module ObjectForge
  # Melting pot for the forged object's attributes.
  #
  # @since 0.1.0
  class Crucible < UnBasicObject
    # @param attributes [Hash{Symbol => Proc, Any}] initial attributes
    def initialize(attributes)
      super()
      @attributes = attributes
    end

    # Resolve all attributes by calling their +Proc+s,
    # using +self+ as the evaluation context.
    #
    # @note This method destructively modifies initial attributes.
    #
    # @thread_safety Resolving attributes modifies instance variables,
    #   therefore making it unsafe to use in a concurrent environment.
    #
    # @return [Hash{Symbol => Any}] resolved attributes
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
        if @attributes[name].is_a?(::Proc)
          @attributes[name] = instance_exec(&@attributes[name])
        else
          @attributes[name]
        end
      else
        super
      end
    end

    def respond_to_missing?(name, _include_all)
      @attributes.key?(name)
    end
  end
end

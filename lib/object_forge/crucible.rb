# frozen_string_literal: true

require_relative "un_basic_object"

module ObjectForge
  # Melting pot for the forged object's attributes.
  #
  # @since 0.1.0
  class Crucible < UnBasicObject
    # @!group Instance methods copied from Object
    # @!method rand(max = 0)
    #   @see Kernel#rand
    #   @return [Float, Integer]
    %i[rand].each { |m| private define_method(m, ::Object.instance_method(m)) }
    # @!endgroup

    # @param attributes [Hash{Symbol => Proc, Any}] initial attributes
    def initialize(attributes)
      super()
      @attributes = attributes
      @resolved_attributes = ::Set.new
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
        if @resolved_attributes.include?(name) || !(::Proc === @attributes[name])
          @attributes[name]
        else
          @resolved_attributes << name
          @attributes[name] = instance_exec(&@attributes[name])
        end
      else
        super
      end
    end

    alias [] method_missing

    def respond_to_missing?(name, _include_all)
      @attributes.key?(name)
    end
  end
end

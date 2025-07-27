# frozen_string_literal: true

require "set"

require_relative "un_basic_object"

module ObjectForge
  # Melting pot for the forged object's attributes.
  #
  # @note This class is not intended to be used directly,
  #   but it's not a private API.
  #
  # @thread_safety Attribute resolution is idempotent,
  #   but modifies instance variables, making it unsafe to share the Crucible
  #
  # @since 0.1.0
  class Crucible < UnBasicObject
    %i[rand].each { |m| private define_method(m, ::Object.instance_method(m)) }

    # @param attributes [Hash{Symbol => Proc, Any}] initial attributes
    def initialize(attributes)
      super()
      @attributes = attributes
      @resolved_attributes = ::Set.new
    end

    # Resolve all attributes by calling their +Proc+s,
    # using +self+ as the evaluation context.
    #
    # Attributes can freely refer to each other inside +Proc+s
    # through bareword names or +#[]+.
    # However, make sure to avoid cyclic dependencies:
    # they aren't specially detected or handled, and will cause +SystemStackError+.
    #
    # @note This method destructively modifies initial attributes.
    #
    # @return [Hash{Symbol => Any}] resolved attributes
    def resolve!
      @attributes.each_key { |name| method_missing(name) }
      @attributes
    end

    private

    # Get the value of the attribute +name+.
    #
    # To prevent problems with calling methods which may be defined,
    # +#[]+ can be used instead.
    #
    # @example
    #   attrs = {
    #     name: -> { "Name" },
    #     description: -> { name.downcase },
    #     duration: -> { rand(1000) }
    #   }
    #   Crucible.new(attrs).resolve!
    #   # => { name: "Name", description: "name", duration: 123 }
    # @example using conflicting and reserved names
    #   attrs = {
    #     "[]": -> { "Brackets" },
    #     "[]=": -> { "#{self[:[]]} are brackets" },
    #     "!": -> { "#{self[:[]=]}!" }
    #   }
    #   Crucible.new(attrs).resolve!
    #   # => { "[]": "Brackets", "[]=": "Brackets are brackets", "!": "Brackets are brackets!" }
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

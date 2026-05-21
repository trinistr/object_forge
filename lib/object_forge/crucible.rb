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
  #   and using {.resolve} is thread-safe
  # @since 0.1.0
  class Crucible < UnBasicObject
    class << self
      # Resolve all attributes by calling their +Proc+s,
      # using a new instance as evaluation context.
      #
      # @note This method destructively modifies initial attributes.
      # @see #resolve!
      #
      # @param attributes [Hash{Symbol => Proc, Any}] initial attributes
      # @return [Hash{Symbol => Any}] resolved attributes
      def call(attributes)
        new(attributes).resolve!
      end

      alias resolve call
    end

    %i[rand].each { |m| private define_method(m, ::Kernel.instance_method(m)) }

    # @param attributes [Hash{Symbol => Proc, Any}] initial attributes
    def initialize(attributes)
      super()
      @attributes = attributes
      @resolved_attributes = ::Set.new
      @resolving_attributes = []
    end

    # Resolve all attributes by calling their +Proc+s,
    # using +self+ as the evaluation context.
    #
    # Attributes can freely refer to each other inside +Proc+s
    # through bareword names or +#[]+.
    # However, make sure to avoid cyclic dependencies:
    # they can't be resolved and will raise {CircularAttributeDependencyError}.
    #
    # @note This method destructively modifies initial attributes.
    #
    # @return [Hash{Symbol => Any}] resolved attributes
    #
    # @raise [CircularAttributeDependencyError] if a dependency cycle is detected
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
    #   Crucible.call(attrs)
    #   # => { name: "Name", description: "name", duration: 123 }
    # @example using conflicting and reserved names
    #   attrs = {
    #     "[]": -> { "Brackets" },
    #     "[]=": -> { "#{self[:[]]} are brackets" },
    #     "!": -> { "#{self[:[]=]}!" }
    #   }
    #   Crucible.resolve(attrs)
    #   # => { "[]": "Brackets", "[]=": "Brackets are brackets", "!": "Brackets are brackets!" }
    #
    # @param name [Symbol]
    # @return [Any]
    #
    # @raise [CircularAttributeDependencyError] if a dependency cycle is detected
    def method_missing(name) # rubocop:disable Metrics/MethodLength
      if @attributes.key?(name)
        if @resolving_attributes.include?(name)
          raise_circular_dependency_error!(name)
        elsif !@resolved_attributes.include?(name) && (::Proc === @attributes[name])
          begin
            @resolving_attributes << name
            @attributes[name] = instance_exec(&@attributes[name])
            @resolved_attributes << name
          ensure
            @resolving_attributes.pop
          end
        end
        @attributes[name]
      else
        super
      end
    end

    alias [] method_missing

    def respond_to_missing?(name, _include_all)
      @attributes.key?(name)
    end

    def raise_circular_dependency_error!(name)
      loop_start = @resolving_attributes.index(name)
      loop = @resolving_attributes[loop_start..] # : Array[Symbol]
      raise CircularAttributeDependencyError,
            "attribute depends on itself: #{loop.join(" -> ")} -> #{name}"
    end
  end
end

# frozen_string_literal: true

require_relative "sequence"

module ObjectForge
  # DSL for defining a forge.
  #
  # @note This class is not intended to be used directly.
  #
  # @since 0.1.0
  class ForgeDSL
    # @api private
    # @return [Hash{Symbol => Proc}] frozen hash
    attr_reader :attributes

    # @api private
    # @return [Hash{Symbol => Sequence}] frozen hash
    attr_reader :sequences

    # @api private
    # @return [Hash{Symbol => Hash{Symbol => Proc}}] frozen hash of frozen hashes
    attr_reader :traits

    # Define forge's parameters through DSL.
    #
    # @thread_safety DSL is not thread-safe.
    #   Take care not to introduce side effects in the block.
    #   However, the instance is frozen after initialization,
    #   so it should be safe to use.
    #
    # @yieldparam f [ForgeDSL] self
    # @yieldreturn [void]
    def initialize
      @attributes = {}
      @sequences = {}
      @traits = {}
      @current_trait = nil

      yield self

      freeze
    end

    # Freezes the instance, including +attributes+ and +traits+.
    #
    # Called automatically in {#initialize}.
    #
    # @return [self]
    def freeze
      @attributes.freeze
      @sequences.freeze
      @traits.freeze
      super
    end

    # Define an attribute, possibly transient.
    #
    # You can refer to any other attribute inside the attribute definition block.
    # It is also possible to define attributes using {#method_missing} shortcut,
    # except for conflicting or reserved names.
    #
    # @example
    #   f.attribute(:name) { "Name" }
    #   f[:description] { name.downcase }
    #   f.duration { rand(1000) }
    # @example using external sequence
    #   seq = Sequence.new(1)
    #   f.sequence(:global_id, seq)
    #
    # @param name [Symbol] attribute name
    # @yieldreturn [Any] attribute value
    # @return [Symbol] attribute name
    # @raise [ArgumentError] if +name+ is not a Symbol
    # @raise [ArgumentError] if no block is given
    def attribute(name, &definition)
      raise ArgumentError, "attribute name must be a Symbol" unless name.is_a?(Symbol)
      raise ArgumentError, "attribute definition requires a block" unless block_given?

      if @current_trait
        @traits[@current_trait][name] = definition
      else
        @attributes[name] = definition
      end

      name
    end

    alias [] attribute

    # Define an attribute, using a sequence.
    #
    # +name+ is used for both attribute and sequence, for the whole forge.
    # If the name was used for a sequence previously, it will not be redefined in traits.
    #
    # @example
    #   f.sequence(:date, Date.today)
    #   f.sequence(:id) { _1.to_s }
    #   f.sequence(:dated_id, 10) { |n| "#{Date.today}/#{n}-#{id}" }
    #
    # @param name [Symbol] attribute name
    # @param initial [Sequence, #succ] existing sequence, or initial value for a new sequence
    # @yieldparam value [#succ] current value of the sequence to calculate attribute value
    # @yieldreturn [Any] attribute value
    # @return [Symbol] attribute name
    # @raise [ArgumentError] if +name+ is not a Symbol
    # @raise [DSLError] if +initial+ does not respond to #succ and is not a {Sequence}
    def sequence(name, initial = 1, **nil, &)
      raise ArgumentError, "sequence name must be a Symbol" unless name.is_a?(Symbol)
      raise DSLError, "initial value must respond to #succ" unless initial.respond_to?(:succ)

      seq = @sequences[name] ||= initial.is_a?(Sequence) ? initial : Sequence.new(initial)

      if block_given?
        attribute(name) { instance_exec(seq.next, &) }
      else
        attribute(name) { seq.next }
      end

      name
    end

    # Define a trait — a group of attributes with non-default values.
    #
    # @example
    #   f.trait :special do
    #     f.name { "***xXxSPECIALxXx***" }
    #     f.sequence(:special_id) { "~~~ SpEcIaL #{_1} ~~~" }
    #   end
    #
    # @note Traits can not be defined inside of traits.
    #
    # @param name [Symbol] trait name
    # @yield block for trait definition
    # @return [Symbol] trait name
    # @raise [ArgumentError] if +name+ is not a Symbol
    # @raise [DSLError] if called inside of another trait definition
    def trait(name, **nil)
      raise ArgumentError, "trait name must be a Symbol" unless name.is_a?(Symbol)
      raise DSLError, "can not define trait inside of another trait" if @current_trait

      @current_trait = name
      @traits[name] = {}
      yield self
      @traits[name].freeze
      @current_trait = nil

      name
    end

    private

    # Define an attribute using a shorthand.
    #
    # Does not allow to define attributes with names ending with +?+, +!+ or +=+,
    # use {#attribute} or {#[]} instead.
    #
    # @param name [Symbol] attribute name
    # @yieldreturn [Any] attribute value
    # @return [Symbol] attribute name
    # @raise [DSLError] if a reserved +name+ is used
    def method_missing(name, **nil, &)
      return attribute(name, &) if respond_to_missing?(name, false)

      raise DSLError, "#{name} is a reserved name"
    end

    def respond_to_missing?(name, _include_all)
      if name.end_with?("?", "!", "=")
        super
      else
        true
      end
    end
  end
end

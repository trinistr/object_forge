# frozen_string_literal: true

require_relative "sequence"

module ObjectForge
  # DSL for defining a forge.
  #
  # @note This class is not intended to be used directly,
  #   but it's not a private API.
  #
  # @since 0.1.0
  class ForgeDSL < ::BasicObject
    %i[raise block_given? eql? frozen? is_a? respond_to? class hash inspect to_s].each do |m|
      define_method(m, ::Object.instance_method(m))
    end

    # @return [Hash{Symbol => Proc}] frozen hash
    attr_reader :attributes

    # @return [Hash{Symbol => Sequence}] frozen hash
    attr_reader :sequences

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
      @attributes = {}.compare_by_identity
      @sequences = {}.compare_by_identity
      @traits = {}.compare_by_identity

      yield self

      freeze
    end

    # Freezes the instance, including +attributes+, +sequences+ and +traits+.
    # Prevents further responses through +#method_missing+.
    #
    # @note Called automatically in {#initialize}.
    #
    # @return [self]
    def freeze
      ::Object.instance_method(:freeze).bind_call(self)
      @attributes.freeze
      @sequences.freeze
      @traits.freeze
      self
    end

    # Define an attribute, possibly transient.
    #
    # It is also possible to define attributes using +method_missing+ shortcut,
    # except for conflicting or reserved names.
    #
    # You can refer to any other attribute inside the attribute definition block.
    #
    # @example
    #   f.attribute(:name) { "Name" }
    #   f[:description] { name.downcase }
    #   f.duration { rand(1000) }
    #
    # @param name [Symbol] attribute name
    # @yieldreturn [Any] attribute value
    # @return [Symbol] attribute name
    #
    # @raise [ArgumentError] if +name+ is not a Symbol
    # @raise [DSLError] if no block is given
    def attribute(name, &definition)
      unless ::Symbol === name
        raise ::ArgumentError,
              "attribute name must be a Symbol, #{name.class} given (in #{name.inspect})"
      end
      unless block_given?
        raise DSLError, "attribute definition requires a block (in #{name.inspect})"
      end

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
    # If the name was used for a sequence previously,
    # the sequence will not be redefined on subsequent calls.
    #
    # @example
    #   f.sequence(:date, Date.today)
    #   f.sequence(:id) { _1.to_s }
    #   f.sequence(:dated_id, 10) { |n| "#{Date.today}/#{n}-#{id}" }
    # @example using external sequence
    #   seq = Sequence.new(1)
    #   f.sequence(:global_id, seq)
    # @example sequence reuse
    #   f.sequence(:id, "a") # => "a", "b", ...
    #   f.trait :new_id do
    #     f.sequence(:id) { |n| n * 2 } # => "aa", "bb", ...
    #   end
    #
    # @param name [Symbol] attribute name
    # @param initial [Sequence, #succ] existing sequence, or initial value for a new sequence
    # @yieldparam value [#succ] current value of the sequence to calculate attribute value
    # @yieldreturn [Any] attribute value
    # @return [Symbol] attribute name
    #
    # @raise [ArgumentError] if +name+ is not a Symbol
    # @raise [DSLError] if +initial+ does not respond to #succ and is not a {Sequence}
    def sequence(name, initial = 1, **nil, &)
      unless ::Symbol === name
        raise ::ArgumentError,
              "sequence name must be a Symbol, #{name.class} given (in #{name.inspect})"
      end

      seq = @sequences[name] ||= Sequence.new(initial)

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
    #
    # @raise [ArgumentError] if +name+ is not a Symbol
    # @raise [DSLError] if no block is given
    # @raise [DSLError] if called inside of another trait definition
    def trait(name, **nil)
      unless ::Symbol === name
        raise ::ArgumentError,
              "trait name must be a Symbol, #{name.class} given (in #{name.inspect})"
      end
      if @current_trait
        raise DSLError, "can not define trait inside of another trait (in #{name.inspect})"
      end
      raise DSLError, "trait definition requires a block (in #{name.inspect})" unless block_given?

      @current_trait = name
      @traits[name] = {}.compare_by_identity
      yield self
      @traits[name].freeze
      @current_trait = nil

      name
    end

    # Return a string containing a human-readable representation of the definition.
    #
    # @return [String]
    def inspect
      "#<#{self.class.name}:#{__id__} " \
        "attributes=#{@attributes.keys.inspect} " \
        "sequences=#{@sequences.keys.inspect} " \
        "traits=#{@traits.transform_values(&:keys).inspect}>"
    end

    private

    # Define an attribute using a shorthand.
    #
    # Can not be used to define attributes with reserved names.
    # Trying to use a conflicting name will lead to usual issues
    # with calling random methods.
    # When in doubt, use {#attribute} or {#[]} instead.
    #
    # Reserved names are:
    # - all names ending in +?+, +!+ or +=+
    # - all names starting with a non-word ASCII character
    #   (operators, +`+, +[]+, +[]=+)
    #
    # @param name [Symbol] attribute name
    # @yieldreturn [Any] attribute value
    # @return [Symbol] attribute name
    #
    # @raise [DSLError] if a reserved +name+ is used
    def method_missing(name, **nil, &)
      return super if frozen?
      return attribute(name, &) if respond_to_missing?(name, false)

      raise DSLError, "#{name.inspect} is a reserved name (in #{name.inspect})"
    end

    def respond_to_missing?(name, _include_all)
      return false if frozen?

      !name.end_with?("?", "!", "=") && !name.match?(/\A(?=\p{ASCII})\P{Word}/)
    end
  end
end

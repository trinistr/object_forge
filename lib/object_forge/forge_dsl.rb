# frozen_string_literal: true

require_relative "sequence"
require_relative "un_basic_object"

require_relative "molds/wrapped_mold"

module ObjectForge
  # DSL for defining a forge.
  #
  # @note This class is not intended to be used directly,
  #   but it's not a private API.
  #
  # @thread_safety DSL is not thread-safe.
  #   Take care not to introduce side effects,
  #   especially in attribute definitions.
  #   The instance itself is frozen after initialization,
  #   so it should be safe to share.
  # @since 0.1.0
  class ForgeDSL < UnBasicObject
    # @return [Hash{Symbol => Proc}] attribute definitions
    attr_reader :attributes

    # @return [Hash{Symbol => Sequence}] used sequences
    attr_reader :sequences

    # @return [Hash{Symbol => Hash{Symbol => Proc}}] trait definitions
    attr_reader :traits

    # @return [#call, nil] forge mold
    attr_reader :mold

    # Define forge's parameters through DSL.
    #
    # If the block has a parameter, an object will be yielded,
    # and +self+ context will be preserved.
    # Otherwise, DSL will change +self+ context inside the block,
    # without ability to call methods available outside.
    #
    # @example with block parameter
    #   ForgeDSL.new do |f|
    #     f.attribute(:name) { "Name" }
    #     f[:description] { name.upcase }
    #     f.duration { rand(1000) }
    #   end
    #
    # @example without block parameter
    #   ForgeDSL.new do
    #     attribute(:name) { "Name" }
    #     self[:description] { name.upcase }
    #     duration { rand(1000) }
    #   end
    #
    # @yieldparam f [ForgeDSL] self
    # @yieldreturn [void]
    def initialize(&dsl)
      super
      @attributes = {}
      @sequences = {}
      @traits = {}

      dsl.arity.zero? ? instance_exec(&dsl) : yield(self)

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
      @mold.freeze
      self
    end

    # Set the forge mold.
    #
    # Mold is an object that knows how to take a hash of attributes
    # and create an object from them.
    # It can also be a class with +#call+, in which case a new mold will be instantiated
    # automatically for each build. If a single instance is enough,
    # please call +.new+ yourself once.
    #
    # @param mold [Class, #call, nil]
    # @return [Class, #call, nil]
    #
    # @raise [DSLError] if +mold+ does not respond to or implement +#call+
    def mold=(mold)
      if nil == mold || mold.respond_to?(:call) # rubocop:disable Style/YodaCondition
        @mold = mold
      elsif ::Class === mold && mold.public_method_defined?(:call)
        @mold = Molds::WrappedMold.new(mold)
      else
        raise DSLError, "mold must respond to or implement #call"
      end
    end

    # Define an attribute, possibly transient.
    #
    # DSL does not know or care what attributes the forged class has,
    # so the only difference between "real" and "transient" attributes
    # is how the class itself treats them.
    #
    # It is also possible to define attributes using +method_missing+ shortcut,
    # except for conflicting or reserved names.
    #
    # You can refer to any other attribute inside the attribute definition block.
    # +self[:name]+ can be used to refer to an attribute with a conflicting or reserved name.
    #
    # @example
    #   f.attribute(:name) { "Name" }
    #   f[:description] { name.downcase }
    #   f.duration { rand(1000) }
    # @example using conflicting and reserved names
    #   f.attribute(:[]) { "Brackets" }
    #   f.attribute(:[]=) { "#{self[:[]]} are brackets" }
    #   f.attribute(:!) { "#{self[:[]=]}!" }
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
    # DSL yields itself to the block, in case you need to refer to it.
    # This can be used to define traits using a block coming from outside of DSL.
    #
    # @example
    #   f.trait :special do
    #     f.name { "***xXxSPECIALxXx***" }
    #     f.sequence(:special_id) { "~~~ SpEcIaL #{_1} ~~~" }
    #   end
    # @example externally defined trait
    #   # Variable defined outside of DSL:
    #   success_trait = ->(ft) do
    #     ft.status { :success }
    #     ft.error_code { 0 }
    #   end
    #   # Inside the DSL:
    #   f.trait(:success, &success_trait)
    #
    # @note Traits can not be defined inside of traits.
    #
    # @param name [Symbol] trait name
    # @yield block for trait definition
    # @yieldparam f [ForgeDSL] self
    # @yieldreturn [void]
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
      @traits[name] = {}
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
        "traits={#{@traits.map { |k, v| "#{k.inspect}=#{v.keys.inspect}" }.join(", ")}}>"
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
    # - +rand+
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

      !name.end_with?("?", "!", "=") && !name.match?(/\A(?=\p{ASCII})\P{Word}/) && name != :rand
    end
  end
end

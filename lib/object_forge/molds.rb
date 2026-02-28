# frozen_string_literal: true

module ObjectForge
  # This module provides a collection of predefined molds to be used in common cases.
  #
  # Mold is an object that knows how to take a hash of attributes
  # and create an object from them. Molds are +#call+able objects
  # responsible for actually building objects produced by factories
  # (or doing other, interesting things with them (truly, only the code review is the limit!)).
  # They are supposed to be immutable, shareable, and persistent:
  # initialize once, use for the whole runtime.
  #
  # A simple mold can easily be just a +Proc+.
  # All molds must have the following +#call+ signature: +call(forged:, attributes:, **)+.
  # The extra keywords are ignored for possibility of future extensions.
  #
  # @example A very basic FactoryBot replacement
  #   creator = ->(forged:, attributes:, **) do
  #     instance = forged.new
  #     attributes.each_pair { instance.public_send(:"#{_1}=", _2) }
  #     instance.save!
  #   end
  #   creator.call(forged: User, attributes: { name: "John", age: 30 })
  #     # => <User name="John" age=30>
  # @example Using a mold to serialize collection of objects (contrivedly)
  #   dumpy = ->(forged:, attributes:, **) do
  #     Enumerator.new(attributes.size) do |y|
  #       attributes.each_pair { y << forged.dump(_1 => _2) }
  #     end
  #   end
  #   dumpy.call(forged: JSON, attributes: {a:1, b:2}).to_a
  #     # => ["{\"a\":1}", "{\"b\":2}"]
  #   dumpy.call(forged: YAML, attributes: {a:1, b:2}).to_a
  #     # => ["---\n:a: 1\n", "---\n:b: 2\n"]
  # @example Abstract factory pattern (kind of)
  #   class FurnitureFactory
  #     def call(forged:, attributes:, **)
  #       concrete_factory = concrete_factory(forged)
  #       attributes[:pieces].map do |piece|
  #         concrete_factory.public_send(piece, attributes.dig(:color, piece))
  #       end
  #     end
  #     private def concrete_factory(style)
  #       case style
  #       when :hitech
  #         HiTechFactory.new
  #       when :retro
  #         RetroFactory.new
  #       end
  #     end
  #   end
  #   FurnitureFactory.new.call(forged: :hitech, attributes: {
  #     pieces: [:chair, :table], color: { chair: :black, table: :white }
  #   })
  #     # => [<#HiTech::Chair color=:black>, <#HiTech::Table color=:white>]
  # @example Abusing molds
  #   printer = ->(forged:, attributes:, **) { PP.pp(attributes, forged) }
  #   printer.call(forged: $stderr, attributes: {a:1, b:2})
  #     # outputs "{:a=>1, :b=>2}" to $stderr
  #
  # @since 0.2.0
  module Molds
    Dir["#{__dir__}/molds/*.rb"].each { require_relative _1 }

    # Get maybe appropriate mold for the given +forged+ class or object.
    #
    # Currently provides specific recognition for:
    # - subclasses of +Struct+ ({StructMold}),
    # - subclasses of +Data+ ({KeywordsMold}),
    # - +Hash+ and subclasses ({HashMold}).
    # Other objects just get {SingleArgumentMold}.
    #
    # @param forged [Class, Any]
    # @return [#call] an instance of a mold
    #
    # @thread_safety Thread-safe.
    # @since 0.3.0
    def self.mold_for(forged)
      if ::Class === forged
        if forged < ::Struct
          StructMold.new
        elsif defined?(::Data) && forged < ::Data
          KeywordsMold.new
        elsif forged <= ::Hash
          HashMold.new
        else
          SingleArgumentMold.new
        end
      else
        SingleArgumentMold.new
      end
    end

    # Wrap mold if needed.
    #
    # If +mold+ is +nil+ or a +call+able object, returns it.
    # If it is a Class with +#call+, wraps it in {WrappedMold}.
    # Otherwise, raises an error.
    #
    # @since 0.3.0
    #
    # @param mold [Class, #call, nil]
    # @return [#call, nil]
    #
    # @raise [DSLError] if +mold+ does not respond to or implement +#call+
    #
    # @thread_safety Thread-safe.
    # @since 0.3.0
    def self.wrap_mold(mold)
      if mold.nil? || mold.respond_to?(:call)
        mold # : ObjectForge::mold?
      elsif ::Class === mold && mold.public_method_defined?(:call)
        WrappedMold.new(mold)
      else
        raise MoldError, "mold must respond to or implement #call"
      end
    end
  end
end

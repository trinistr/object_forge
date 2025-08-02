# frozen_string_literal: true

module ObjectForge
  # This module provides a collection of predefined molds to be used in common cases.
  #
  # Molds are +#call+able objects responsible for actually building objects produced by factories
  # (or doing other, interesting things with them (truly, only the code review is the limit!)).
  # They are supposed to be immutable, shareable, and persistent:
  # initialize once, use for the whole runtime.
  #
  # A simple mold can easily be just a +Proc+.
  # All molds must have the following +#call+ signature: +call(forged:, attributes:, **)+.
  # The extra keywords are for future extensions.
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
  # @since 0.1.1
  module Molds
    Dir["#{__dir__}/molds/*.rb"].each { require_relative _1 }
  end
end

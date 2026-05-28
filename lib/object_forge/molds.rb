# frozen_string_literal: true

module ObjectForge
  # This module provides a collection of predefined molds to be used in common cases.
  #
  # Mold is an object that knows how to take a hash of attributes
  # and create an object from them. Molds are +call+able objects
  # responsible for actually building objects produced by factories
  # (or doing other, interesting things with them (truly, only the code review is the limit!)).
  # They are supposed to be immutable, shareable, and persistent:
  # initialize once, use for the whole runtime.
  #
  # A simple mold can easily be just a +Proc+.
  # All molds must have the following +#call+ signature: +call(forge_target:, attributes:, **)+.
  # The extra keywords are ignored for possibility of future extensions.
  #
  # @example A very basic FactoryBot replacement
  #   creator = ->(forge_target:, attributes:, **) do
  #     instance = forge_target.new
  #     attributes.each_pair { instance.public_send(:"#{_1}=", _2) }
  #     instance.save!
  #   end
  #
  #   creator.call(forge_target: User, attributes: { name: "John", age: 30 })
  #     # => <User name="John" age=30>
  #
  # @example Using a mold to serialize collection of objects (contrivedly)
  #   dumpy = ->(forge_target:, attributes:, **) do
  #     Enumerator.new(attributes.size) do |y|
  #       attributes.each_pair { y << forge_target.dump(_1 => _2) }
  #     end
  #   end
  #
  #   dumpy.call(forge_target: JSON, attributes: {a:1, b:2}).to_a
  #     # => ["{\"a\":1}", "{\"b\":2}"]
  #   dumpy.call(forge_target: YAML, attributes: {a:1, b:2}).to_a
  #     # => ["---\n:a: 1\n", "---\n:b: 2\n"]
  #
  # @example Abstract factory pattern (kind of)
  #   class FurnitureFactory
  #     def call(forge_target:, attributes:, **)
  #       concrete_factory = concrete_factory(forge_target)
  #       attributes[:pieces].map do |piece|
  #         concrete_factory.public_send(piece, attributes.dig(:color, piece))
  #       end
  #     end
  #
  #     private def concrete_factory(style)
  #       case style
  #       when :hitech
  #         HiTechFactory.new
  #       when :retro
  #         RetroFactory.new
  #       end
  #     end
  #   end
  #
  #   FurnitureFactory.new.call(forge_target: :hitech, attributes: {
  #     pieces: [:chair, :table], color: { chair: :black, table: :white }
  #   })
  #     # => [<#HiTech::Chair color=:black>, <#HiTech::Table color=:white>]
  #
  # @example Abusing molds
  #   printer = ->(forge_target:, attributes:, **) { PP.pp(attributes, forge_target) }
  #   printer.call(forge_target: $stderr, attributes: {a:1, b:2})
  #     # outputs "{:a=>1, :b=>2}" to $stderr
  #
  # @example Abuse above is just not enough, we need something even better
  #   class Character
  #     attr_reader :hp
  #
  #     def initialize(hp)
  #       @hp = hp
  #       @damage_factory = ObjectForge::Forge.new(self, DamageParameters.new)
  #     end
  #
  #     def hit(damage)
  #       if damage <= 0
  #         @damage_factory.call(:shielded, apply: ->(damage) { @hp -= damage })
  #       else
  #         @damage_factory.call(amount: damage, apply: ->(damage) { @hp -= damage })
  #       end
  #     end
  #
  #     def heal(amount)
  #       @damage_factory.call(amount: amount, apply: ->(amount) { @hp += amount }) if amount >= 0
  #     end
  #
  #     def die!
  #       puts "Character died!"
  #     end
  #   end
  #
  #   class DamageParameters
  #     def attributes = {}
  #     def traits = { shielded: { amount: 1 } }
  #     def options
  #       {
  #         crucible: lambda(&:itself),
  #         mold: ->(forge_target:, attributes:, **) {
  #           attributes[:apply].call(attributes[:amount])
  #           forge_target
  #         },
  #         after_build: ->(forge_target) { forge_target.die! if forge_target.hp <= 0 }
  #       }
  #     end
  #   end
  #
  #   mc = Character.new(100)
  #   mc.hit(50)
  #   mc.heal(25)
  #   mc.hit(-10)
  #   mc.hit(75)
  #     # outputs "Character died!"
  #
  # @since 0.2.0
  module Molds
    Dir["#{__dir__}/molds/*.rb"].each { require_relative _1 }

    # Get maybe appropriate mold for the given forge target.
    #
    # Currently provides specific recognition for:
    # - subclasses of +Struct+ ({StructMold}),
    # - subclasses of +Data+ ({KeywordsMold}),
    # - +Hash+ and subclasses ({HashMold}).
    # Other objects just get {SingleArgumentMold}.
    #
    # @param forge_target [Class, Any]
    # @return [#call] an instance of a mold
    #
    # @thread_safety Thread-safe.
    # @since 0.3.0
    def self.mold_for(forge_target)
      if ::Class === forge_target
        if forge_target < ::Struct
          StructMold.new
        elsif defined?(::Data) && forge_target < ::Data
          KeywordsMold.new
        elsif forge_target <= ::Hash
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
    # @param mold [Class, #call, nil]
    # @return [#call, nil]
    #
    # @raise [ObjectInterfaceError] if +mold+ does not respond to or implement +#call+
    #
    # @thread_safety Thread-safe.
    # @since 0.3.0
    def self.wrap_mold(mold)
      if mold.nil? || mold.respond_to?(:call)
        mold # : ObjectForge::mold?
      elsif ::Class === mold && mold.public_method_defined?(:call)
        WrappedMold.new(mold)
      else
        raise ObjectInterfaceError, "mold must respond to or implement #call"
      end
    end
  end
end

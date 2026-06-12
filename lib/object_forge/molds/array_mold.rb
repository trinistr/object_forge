# frozen_string_literal: true

module ObjectForge
  module Molds
    # Mold for constructing Arrays.
    #
    # @thread_safety Thread-safe.
    # @since <<next>>
    class ArrayMold
      # Build a new array from attributes' values.
      #
      # If +forge_target+ is +Array+, result is built directly by calling +attributes.values+.
      # If it is a different class, its +.new+ method is called with the values array.
      #
      # @see Array.new
      #
      # @param forge_target [Class] Array or a subclass of Array
      # @param attributes [Hash{Symbol => Any}]
      # @return [Array]
      def call(forge_target:, attributes:, **_)
        return attributes.values if Array == forge_target # rubocop:disable Style/YodaCondition

        forge_target.new(attributes.values)
      end
    end
  end
end

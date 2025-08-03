# frozen_string_literal: true

module ObjectForge
  module Molds
    # Basic mold which calls +forged.new(attributes)+.
    #
    # @thread_safety Thread-safe.
    # @since 0.2.0
    class SingleArgumentMold
      # Instantiate +forged+ with a hash of attributes.
      #
      # @param forged [Class, #new]
      # @param attributes [Hash{Symbol => Any}]
      # @return [Any]
      def call(forged:, attributes:, **_)
        forged.new(attributes)
      end
    end
  end
end

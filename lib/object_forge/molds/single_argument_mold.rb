# frozen_string_literal: true

module ObjectForge
  module Molds
    # Basic mold which calls +forge_target.new(attributes)+.
    #
    # @thread_safety Thread-safe.
    # @since 0.2.0
    class SingleArgumentMold
      # Instantiate forge target with a hash of attributes.
      #
      # @param forge_target [Class, #new]
      # @param attributes [Hash{Symbol => Any}]
      # @return [Any]
      def call(forge_target:, attributes:, **_)
        forge_target.new(attributes)
      end
    end
  end
end

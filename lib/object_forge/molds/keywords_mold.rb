# frozen_string_literal: true

module ObjectForge
  module Molds
    # Basic mold which calls +forged.new(**attributes)+.
    #
    # Can be used instead of {SingleArgumentMold}
    # due to how keyword arguments are treated in Ruby,
    # but performance is about 1.5 times worse.
    #
    # @thread_safety Thread-safe.
    # @since 0.2.0
    class KeywordsMold
      # Instantiate +forged+ with a hash of attributes.
      #
      # @param forged [Class, #new]
      # @param attributes [Hash{Symbol => Any}]
      # @return [Any]
      def call(forged:, attributes:, **_)
        forged.new(**attributes)
      end
    end
  end
end

# frozen_string_literal: true

module ObjectForge
  module Molds
    # Basic mold which calls +forge_target.new(**attributes)+.
    #
    # Can be used instead of {SingleArgumentMold}
    # due to how keyword arguments are treated in Ruby,
    # but performance is about 1.5 times worse.
    #
    # @thread_safety Thread-safe.
    # @since 0.2.0
    class KeywordsMold
      # Instantiate forge target with a hash of attributes.
      #
      # @param forge_target [Class, #new]
      # @param attributes [Hash{Symbol => Any}]
      # @return [Any]
      def call(forge_target:, attributes:, **_)
        forge_target.new(**attributes)
      end
    end
  end
end

# frozen_string_literal: true

module ObjectForge
  module Molds
    # Mold that wraps a mold class.
    #
    # Wrapping a mold class is useful when its +#call+ is stateful,
    # making it unsafe to use multiple times or in shared environments.
    #
    # @thread_safety Thread-safe if {wrapped_mold} does not use global state.
    # @since 0.1.1
    class WrappedMold
      # @return [Class] wrapped mold class
      attr_reader :wrapped_mold

      # @param wrapped_mold [Class] class with +#call+ method
      def initialize(wrapped_mold)
        @wrapped_mold = wrapped_mold
      end

      # @overload call(...)
      # Instantiate {wrapped_mold} and call it.
      #
      # @return [Any] result of +wrapped_mold.new.call(...)+
      def call(...)
        wrapped_mold.new.call(...)
      end
    end
  end
end

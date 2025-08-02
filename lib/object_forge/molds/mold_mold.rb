# frozen_string_literal: true

module ObjectForge
  module Molds
    # Special "mold" that returns appropriate mold for the given forged object.
    # Probably not the best fit though.
    #
    # Currently provides specific recognition for:
    # - subclasses of +Struct+ ({StructMold}),
    # - subclasses of +Data+ ({KeywordsMold}),
    # - +Hash+ and subclasses ({HashMold}).
    # Other objects just get {SingleArgumentMold}.
    #
    # @thread_safety Thread-safe.
    # @since 0.1.1
    class MoldMold
      # Get maybe appropriate mold for the given forged object.
      #
      # @param forged [Class, Any]
      # @return [#call] an instance of a mold
      def call(forged:, **_)
        # rubocop:disable Style/YodaCondition
        if ::Class === forged
          if ::Struct > forged
            StructMold.new
          elsif defined?(::Data) && ::Data > forged
            KeywordsMold.new
          elsif ::Hash >= forged
            HashMold.new
          else
            SingleArgumentMold.new
          end
        else
          SingleArgumentMold.new
        end
        # rubocop:enable Style/YodaCondition
      end
    end
  end
end

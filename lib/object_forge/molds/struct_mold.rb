# frozen_string_literal: true

module ObjectForge
  module Molds
    # Mold for building Structs.
    #
    # Supports all variations of +keyword_init+.
    #
    # @thread_safety Thread-safe.
    # @since 0.1.1
    class StructMold
      # Does Struct automatically use keyword initialization
      # when +keyword_init+ is not specified / +nil+?
      #
      # @return [Boolean]
      RUBY_FEATURE_AUTO_KEYWORDS = (::Struct.new(:a, :b).new(a: 1, b: 2).a == 1)

      # Whether to work around argument hashes with extra keys.
      #
      # @return [Boolean]
      attr_reader :lax
      alias lax? lax

      # @param lax [Boolean]
      #   whether to work around argument hashes with extra keys
      #   (when keyword_init is false, workaround always happens for technical reasons)
      #   - if +true+, arguments can contain extra keys, but building is slower;
      #   - if +false+, building may raise an error if extra keys are present;
      def initialize(lax: false)
        @lax = lax
      end

      # Instantiate +forged+ struct with a hash of attributes.
      #
      # @param forged [Class] a subclass of Struct
      # @param attributes [Hash{Symbol => Any}]
      # @return [Struct]
      def call(forged:, attributes:, **_)
        if forged.keyword_init?
          lax ? forged.new(attributes.slice(*forged.members)) : forged.new(attributes)
        elsif forged.keyword_init? == false
          forged.new(*attributes.values_at(*forged.members))
        else
          build_struct_with_unspecified_keyword_init(forged, attributes)
        end
      end

      private

      if RUBY_FEATURE_AUTO_KEYWORDS
        # Build struct by using keywords to specify member values.
        def build_struct_with_unspecified_keyword_init(forged, attributes)
          if lax
            forged.new(**attributes.slice(*forged.members))
          else
            forged.new(**attributes)
          end
        end
      else
        # :nocov:
        # Build struct by using positional arguments to specify member values.
        def build_struct_with_unspecified_keyword_init(forged, attributes)
          forged.new(*attributes.values_at(*forged.members))
        end
        # :nocov:
      end
    end
  end
end

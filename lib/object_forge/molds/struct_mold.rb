# frozen_string_literal: true

module ObjectForge
  module Molds
    # Mold for building Structs.
    #
    # Supports all variations of +keyword_init+.
    #
    # @thread_safety Thread-safe.
    # @since 0.2.0
    class StructMold
      # Does Struct automatically use keyword initialization
      # when +keyword_init+ is not specified / +nil+?
      #
      # This should be true on Ruby 3.2.0 and later.
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
      def initialize(lax: true)
        @lax = lax
      end

      # Instantiate target struct with a hash of attributes.
      #
      # @param forge_target [Class] a subclass of Struct
      # @param attributes [Hash{Symbol => Any}]
      # @return [Struct]
      def call(forge_target:, attributes:, **_)
        if forge_target.keyword_init?
          if lax
            forge_target.new(attributes.slice(*forge_target.members))
          else
            forge_target.new(attributes)
          end
        elsif forge_target.keyword_init? == false
          forge_target.new(*attributes.values_at(*forge_target.members))
        else
          build_struct_with_unspecified_keyword_init(forge_target, attributes)
        end
      end

      private

      if RUBY_FEATURE_AUTO_KEYWORDS
        # Build struct by using keywords to specify member values.
        def build_struct_with_unspecified_keyword_init(forge_target, attributes)
          if lax
            forge_target.new(**attributes.slice(*forge_target.members))
          else
            forge_target.new(**attributes)
          end
        end
      else
        # :nocov:
        # Build struct by using positional arguments to specify member values.
        def build_struct_with_unspecified_keyword_init(forge_target, attributes)
          forge_target.new(*attributes.values_at(*forge_target.members))
        end
        # :nocov:
      end
    end
  end
end

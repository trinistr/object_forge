# frozen_string_literal: true

module ObjectForge
  module Molds
    # Mold for constructing Hashes.
    #
    # @thread_safety Thread-safe on its own,
    #   but using unshareable default value or block is not thread-safe.
    #
    # @since 0.2.0
    class HashMold
      # Default value to be assigned to each produced hash.
      # @return [Any, nil]
      attr_reader :default
      # Default proc to be assigned to each produced hash.
      # @return [Proc, nil]
      attr_reader :default_proc

      # Initialize new HashMold with default value or default proc
      # to be assigned to each produced hash.
      #
      # The same exact objects are used for each hash.
      # It is not advised to use mutable objects as default values.
      # Be aware that using a default proc with assignment
      # is inherently not safe, see this Ruby issue:
      # https://bugs.ruby-lang.org/issues/19237.
      #
      # @see Hash.new
      #
      # @param default_value [Any]
      # @yieldparam hash [Hash]
      # @yieldparam key [Any]
      # @yieldreturn [Any]
      def initialize(default_value = nil, &default_proc)
        @default = default_value
        @default_proc = default_proc
      end

      # Build a new hash using +forged.[]+.
      #
      # @see Hash.[]
      #
      # @param forged [Class] Hash or a subclass of Hash
      # @param attributes [Hash{Symbol => Any}]
      # @return [Hash]
      def call(forged:, attributes:, **_)
        hash = forged[attributes]
        hash.default = @default if @default
        hash.default_proc = @default_proc if @default_proc
        hash
      end
    end
  end
end

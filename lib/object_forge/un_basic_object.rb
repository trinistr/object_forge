# frozen_string_literal: true

module ObjectForge
  # BasicObject with a few common methods copied from Object.
  #
  # @api private
  #
  # @since 0.1.0
  class UnBasicObject < ::BasicObject
    # @!group Instance methods copied from Object
    # @!method raise(exception [, string [, array]], cause: $!)
    #   @return [void]
    # @!method block_given?
    #   @return [Boolean]
    # @!method eql?(other)
    #   @return [Boolean]
    # @!method frozen?
    #   @return [Boolean]
    # @!method respond_to?(symbol [, include_private])
    #   @return [Boolean]
    # @!method class
    #   @return [Class]
    # @!method hash
    #   @return [Integer]
    # @!method inspect
    #   @return [String]
    # @!method to_s
    #   @return [String]
    %i[
      class raise
      block_given? frozen? respond_to?
      eql? hash
      inspect to_s
    ].each do |m|
      define_method(m, ::Object.instance_method(m))
    end
    # @!endgroup

    # @!macro pp_support
    #   Support for +pp+ (and IRB).
    #
    #   @note This method dynamically calls UnboundMethod#bind_call, making it fairly slow.
    #
    #   @api public
    def pretty_print(...)
      # We have to do it this way, instead of defining methods,
      # because Object#pretty_print does not exist without requiring "pp".
      ::Object.instance_method(:pretty_print).bind_call(self, ...)
    end

    # @!macro pp_support
    def pretty_print_cycle(...)
      # See comment for #pretty_print.
      ::Object.instance_method(:pretty_print_cycle).bind_call(self, ...)
    end
  end
end

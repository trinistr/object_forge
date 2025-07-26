# frozen_string_literal: true

module ObjectForge
  # BasicObject with a few common methods copied from Object.
  #
  # @api private
  #
  # @since 0.1.0
  class UnBasicObject < ::BasicObject
    # @!group Instance methods copied from Object
    # @!method class
    #   @see Kernel#class
    #   @return [Class]
    # @!method eql?(other)
    #   @see Object#eql?
    #   @return [Boolean]
    # @!method freeze
    #   @see Kernel#freeze
    #   @return [self]
    # @!method frozen?
    #   @see Kernel#frozen?
    #   @return [Boolean]
    # @!method hash
    #   @see Object#hash
    #   @return [Integer]
    # @!method inspect
    #   @see Object#inspect
    #   @return [String]
    # @!method is_a?(class)
    #   @see Kernel#is_a?
    #   @return [Boolean]
    # @!method respond_to?(symbol [, include_private])
    #   @see Object#respond_to?
    #   @return [Boolean]
    # @!method to_s
    #   @see Object#to_s
    #   @return [String]
    %i[class eql? freeze frozen? hash inspect is_a? respond_to? to_s].each do |m|
      define_method(m, ::Object.instance_method(m))
    end
    alias kind_of? is_a?
    # @!endgroup

    %i[block_given? raise].each { |m| private define_method(m, ::Object.instance_method(m)) }

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
      # :nocov:
      ::Object.instance_method(:pretty_print_cycle).bind_call(self, ...)
      # :nocov:
    end
  end
end

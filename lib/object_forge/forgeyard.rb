# frozen_string_literal: true

require "concurrent/map"

module ObjectForge
  # A registry for forges, making them accessible by name.
  #
  # Forgeyard provides a thread-safe interface for adding and retrieving forges.
  #
  # @since 0.1.0
  class Forgeyard
    def initialize
      @forges = Concurrent::Map.new
    end

    # Add a forge under a specified name.
    #
    # @thread_safety If +name+ was already taken, new +forge+ will be ignored
    #   and existing forge will be returned.
    #
    # @param name [Symbol] name to register forge under
    # @param forge [Forge] forge to register
    # @return [Forge] actually registered forge
    #
    # @since 0.1.0
    def register(name, forge)
      @forges.put_if_absent(name, forge) || forge
    end

    alias []= register

    # @overload forge(name)
    #   Retrieve a forge by name.
    #   @param name [Symbol] name of the forge
    #   @return [Forge] registered forge
    #
    # @overload forge(name, *traits, **overrides)
    #   Build an instance using a forge.
    #   @param name [Symbol] name of the forge
    #   @param traits [Array<Symbol>] traits to apply
    #   @param overrides [Hash{Symbol => Any}] attribute overrides
    #   @return [Any] built instance
    #
    # @raise [KeyError] if forge with the specified name is not registered
    #
    # @since 0.1.0
    def forge(name, *traits, **overrides)
      forge = @forges.fetch(name)
      if traits.empty? && overrides.empty?
        forge
      else
        forge[traits, overrides]
      end
    end

    alias [] forge
  end
end

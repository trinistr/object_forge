# frozen_string_literal: true

require "concurrent/map"

require_relative "forge"

module ObjectForge
  # A registry for forges, making them accessible by name.
  #
  # @since 0.1.0
  class Forgeyard
    # @return [Concurrent::Map{Symbol => Forge}] registered forges
    attr_reader :forges

    def initialize
      @forges = Concurrent::Map.new
    end

    # Define and register a forge in one go.
    #
    # @see #register
    # @see Forge.define
    #
    # @param name [Symbol] name to register forge under
    # @param forged [Class, Any] class or object to forge
    # @yieldparam f [ForgeDSL]
    # @yieldreturn [void]
    # @return [Forge] forge
    def define(name, forged, &)
      register(name, Forge.define(forged, name: name, &))
    end

    # Add a forge under a specified name.
    #
    # If +name+ was already taken, new +forge+ will be ignored
    # and existing forge will be returned.
    #
    # @thread_safety Registration is thread-safe, i.e. first one always wins.
    #
    # @param name [Symbol] name to register forge under
    # @param forge [Forge] forge to register
    # @return [Forge] actually registered forge
    def register(name, forge)
      # `put_if_absent` returns `nil` if there was no previous value, hence the `||`.
      @forges.put_if_absent(name, forge) || forge
    end

    # Build an instance using a forge.
    #
    # @see Forge#forge
    #
    # @param name [Symbol] name of the forge
    # @param traits [Array<Symbol>] traits to apply
    # @param overrides [Hash{Symbol => Any}] attribute overrides
    # @yieldparam object [Any] forged instance
    # @yieldreturn [void]
    # @return [Any] built instance
    #
    # @raise [KeyError] if forge with the specified name is not registered
    def forge(name, *traits, **overrides, &)
      @forges.fetch(name)[*traits, **overrides, &]
    end

    alias build forge
    alias [] forge
  end
end

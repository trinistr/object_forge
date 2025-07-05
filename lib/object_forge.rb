# frozen_string_literal: true

Dir["#{__dir__}/object_forge/**/*.rb"].each { require _1 }

# A simple all-purpose factory library with minimal assumptions.
module ObjectForge
  # Base error class for ObjectForge.
  # @since 0.1.0
  class Error < StandardError; end
  # Error raised when a mistake is made in using DSL.
  # @since 0.1.0
  class DSLError < Error; end
end

# frozen_string_literal: true

Dir["#{__dir__}/object_forge/**/*.rb"].each { require _1 }

module ObjectForge
  class Error < StandardError; end
end

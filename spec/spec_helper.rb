# frozen_string_literal: true

require_relative "support/coverage_helper"

require "object_forge"

require_relative "support/negated_matchers"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
  Kernel.srand(config.seed)

  config.formatter = (config.files_to_run.size > 1) ? :progress : :documentation
end

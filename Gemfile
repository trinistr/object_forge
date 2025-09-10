# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# For running tasks
gem "rake", require: false

group :test do
  # Testing framework
  gem "rspec", require: false

  # Code coverage report
  gem "simplecov", require: false
  gem "simplecov_lcov_formatter", require: false
end

group :linting do
  # Linting
  gem "rubocop", "~> 1.72", require: false
  gem "rubocop-packaging", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-thread_safety", require: false

  # Checking type signatures
  gem "rbs", require: false
  # Checking types in code
  gem "steep", require: false
end

group :documentation do
  # Documentation
  gem "redcarpet", require: false
  gem "yard", require: false
end

group :development do
  # Version changes
  gem "bump", require: false

  # Benchmarking and profiling
  gem "benchmark", require: false
  gem "benchmark-ips", require: false
  gem "stackprof", require: false

  # Useful for manual testing
  gem "dry-struct", require: false
end

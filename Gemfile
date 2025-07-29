# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# For running checks
gem "rake"

group :linting do
  # Linting
  gem "rubocop", "~> 1.72"
  gem "rubocop-packaging"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-rspec"
  gem "rubocop-thread_safety"

  # Checking type signatures
  gem "rbs", require: false
end

group :development do
  # Type checking
  gem "steep", require: false

  # Documentation
  gem "yard", require: false

  # Language server for development
  gem "solargraph", require: false

  # Version changes
  gem "bump", require: false

  # Benchmarking and profiling
  gem "benchmark"
  gem "benchmark-ips"
  gem "stackprof"
end

group :test do
  # Testing framework
  gem "rspec"

  # Code coverage report
  gem "simplecov"
  gem "simplecov_lcov_formatter"
end

# frozen_string_literal: true

begin
  require "simplecov"
rescue LoadError
  warn "simplecov is not available, coverage report will not be generated!"
  return
end

SimpleCov.start do
  enable_coverage :branch
  enable_coverage_for_eval

  add_group "Lib", "lib"
  add_group "Tests", "spec"
end

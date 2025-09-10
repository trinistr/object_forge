# frozen_string_literal: true

require_relative "lib/object_forge/version"

Gem::Specification.new do |spec|
  spec.name = "object_forge"
  spec.version = ObjectForge::VERSION
  spec.authors = ["Alexandr Bulancov"]

  spec.homepage = "https://github.com/trinistr/#{spec.name}"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.3"
  spec.summary = "A simple factory for objects with minimal assumptions."
  spec.description = <<~TEXT
    ObjectForge provides a familiar way to build objects in any context
    with minimal assumptions about usage environment.
    It has no connection to any framework and, indeed, has nothing to do with a database.
    To use, just define some factories and call them wherever you need,
    be it in tests, console, or application code.
    If needed, almost any part of the process can be easily replaced with a custom solution.
  TEXT

  # Dependencies:
  spec.add_dependency "concurrent-ruby", "~> 1.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/#{spec.name}/#{spec.version}"
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/v#{spec.version}"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/v#{spec.version}/CHANGELOG.md"

  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["{lib,sig,exe}/**/*"].select { File.file?(_1) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { File.basename(_1) }

  spec.rdoc_options = ["--tag", "thread_safety:Thread safety", "--main", "README.md"]
  spec.extra_rdoc_files = ["README.md"]
end

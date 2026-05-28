# frozen_string_literal: true

require_relative "lib/object_forge/version"

Gem::Specification.new do |spec|
  spec.name = "object_forge"
  spec.version = ObjectForge::VERSION
  spec.authors = ["Alexander Bulancov"]

  spec.homepage = "https://github.com/trinistr/#{spec.name}"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.3"
  spec.summary =
    "A small, flexible factory library for plain Ruby objects, " \
    "hashes, structs and custom build flows."
  spec.description = <<~TEXT
    ObjectForge is a small factory library for Ruby objects with minimal assumptions
    about framework, persistence, or runtime environment.

    It is designed for cases where factory-style object construction is useful,
    but Rails-oriented or database-oriented tooling is a poor fit. ObjectForge
    works well with plain Ruby objects, hashes, structs, and custom build flows.

    The library focuses on explicit configuration, independent registries and factories,
    and replaceable components. It aims to provide a familiar workflow without
    coupling object generation to a framework or persistence layer.
  TEXT

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

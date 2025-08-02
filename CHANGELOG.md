# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Next]

**Added**
- `Forge#forge` (and all proxy methods) now accept an optional block, yielding the forged object to do user-defined post-processing.

**Changed**
- [Breaking] `Forge#forge` no longer accepts array of traits and hash of overrides as positional arguments.

[Compare v0.1.0...main](https://github.com/trinistr/object_forge/compare/v0.1.0...main)

## [v0.1.0]

Initital implementation.

**Added**
- `Forge`, a factory for objects, utilising FactoryBot-like DSL.
- `Forgeyard`, a container for named forges.
- `Sequence`, a thread-safe sequence generator.
- `ForgeDSL` and `Crucible` — implementation of DSL.

[Compare v0.0.0...v0.1.0](https://github.com/trinistr/object_forge/compare/v0.0.0...v0.1.0)

[Next]: https://github.com/trinistr/object_forge/tree/main
[v0.1.0]: https://github.com/trinistr/object_forge/tree/v0.1.0
[🚀 CI]: https://github.com/trinistr/object_forge/actions/workflows/CI.yaml

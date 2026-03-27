# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Next]

**Added**
- `:crucible` option (previously known as settings) in `Forge`, allowing to replace `Crucible` with any `call`-able object. May be useful to provide a faster attributes resolver.

**Changed**
- [Breaking] "Settings" added in last update were renamed to "options" due to unwieldy name. All methods and references were changed to reflect new name.

[Compare v0.3.0...main](https://github.com/trinistr/object_forge/compare/v0.3.0...main)

## [v0.3.0] — 2026-02-28

This update replaces previous hardcoded "mold" setting in DSL with a generic system for passing settings to a Forge,
useful for custom classes and future enhancements.
Other than that, `#[]` as an alias to `#forge` was removed, as it clashes with planned features.

**Added**
- `Forgeyard#[]` to retrieve a forge by name.
- `#call` alias to `#forge` in `Forge`, `Forgeyard`, and `ObjectForge` itself.
- `Molds.mold_for` and `Molds.wrap_mold`. These are helper methods replacing previous scattered functionality.
- Generic settings system in `ForgeDSL` through `#settings` reader, `#setting` method and `#setting_name=` shortcut.
  - This replaces previous "mold" setting.
- `:mold` setting for `Forge`, accessible via generic settings in DSL.

**Removed**
- [Breaking] `#[]` alias to `#forge` in `Forge`, `Forgeyard`, and `ObjectForge`.
- `Molds::MoldMold`, replaced by `Molds.mold_for`.
- `ForgeDSL#mold` and `#mold=`.

**Changed**
- [Breaking] `Forge::Parameters` interface now includes `#settings` and no longer includes `#mold`.
- `ForgeDSL` no longer checks or modifies set `mold`, this is now accomplished in `Forge`.

[Compare v0.2.0...v0.3.0](https://github.com/trinistr/object_forge/compare/v0.2.0...v0.3.0)

## [v0.2.0] — 2025-08-20

This update brings a huge and necessary enhancement: ability to change how objects are built.
This is achieved with the *mold* (builder) system. You can now precisely control the process,
making it possible to consume attributes in any way you want.

**Added**
- Add option to set mold for a Forge through the `ForgeDSL#mold=` method, using any object (or class) with a `#call` method.
- Add `Molds::SingleArgumentMold` as a default mold, mimicing previous behavior, and `Molds::KeywordsMold` as an alternative.
- Add `Molds::HashMold` and `Molds::StructMold` to support Hashes and Structs out-of-the-box.
- Add `Molds::WrappedMold` to support complex user-provided molds.

**Changed**
- [Breaking] `Forge::Parameters` interface now includes `#mold`.
- `Forge` will automatically use `Molds::MoldMold` to determine the mold if none is provided.

[Compare v0.1.1...v0.2.0](https://github.com/trinistr/object_forge/compare/v0.1.1...v0.2.0)

## [v0.1.1] — 2025-08-02

**Added**
- `Forge#forge` (and all proxy methods) now accept an optional block, yielding the forged object to do user-defined post-processing.

**Changed**
- [Breaking] `Forge#forge` no longer accepts array of traits and hash of overrides as positional arguments.

[Compare v0.1.0...v0.1.1](https://github.com/trinistr/object_forge/compare/v0.1.0...v0.1.1)

## [v0.1.0] — 2025-07-30

Initital implementation.

**Added**
- `Forge`, a factory for objects, utilising FactoryBot-like DSL.
- `Forgeyard`, a container for named forges.
- `Sequence`, a thread-safe sequence generator.
- `ForgeDSL` — implementation of DSL and `Crucible` — attribute resolver.

[Compare v0.0.0...v0.1.0](https://github.com/trinistr/object_forge/compare/v0.0.0...v0.1.0)

[Next]: https://github.com/trinistr/object_forge/tree/main
[v0.3.0]: https://github.com/trinistr/object_forge/tree/v0.3.0
[v0.2.0]: https://github.com/trinistr/object_forge/tree/v0.2.0
[v0.1.1]: https://github.com/trinistr/object_forge/tree/v0.1.1
[v0.1.0]: https://github.com/trinistr/object_forge/tree/v0.1.0

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- `Graph.Canonical` module with tests for changing from Graphs to Elixir structs and back.
- Helper functions in the `Universe` and `Conformance` modules
- Introduced transform driver `Paradigm.Transform/apply_class_transform/3` abstracting a common pattern
### Changed
- Relabeled built-in Paradigms as "Builtin" rather than "Canonical" to free up the term.
- Introduced explicit `Paradigm.Graph.Node.Ref` struct instead of using raw pointers.
### Fixed
- The MapGraph normalizes property keys to strings to avoid conformance issues.

## [0.2.0] - 2025-08-11

### Added
- Filesystem support with `Canonical.Filesystem` paradigm and `Graph.FilesystemGraph` adapter
- System model support with `Canonical.Universe` paradigm and `Transform.Propagate` transform.
### Changed
- Refactored Graphs to use protocols instead of behaviors.
### Fixed
- The MapGraph normalizes property keys to strings to avoid conformance issues.

## [0.1.0] - 2025-07-31

### Added
- Initial release of Paradigm modeling framework
- Core data structures: `Paradigm`, `Class`, `Property`, `Package`, `PrimitiveType`, `Enumeration`
- Graph abstraction with pluggable backends via `Paradigm.Graph` behavior
- Map-based graph implementation (`Paradigm.Graph.MapImpl`) for in-memory operations
- Abstraction operations for embedding/extracting paradigms to/from graph data
- Comprehensive conformance checking with detailed error reporting
- Transform behavior with identity transform implementation
- Canonical metamodel definition for self-modeling
- Complete documentation and examples
- Full test suite

### Features
- **Abstraction**: Convert between `Paradigm` structs and `Graph` representations
- **Conformance**: Validate graph data against paradigm definitions
- **Transforms**: Pluggable transformation system between different paradigms
- **Graph Backends**: Flexible graph storage with behavior-based implementations
- **Type Safety**: Comprehensive type specifications throughout

[Unreleased]: https://github.com/roriholm/paradigm/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/roriholm/paradigm/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/roriholm/paradigm/releases/tag/v0.1.0

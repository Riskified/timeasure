# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2018-03-12
### Added
- New class macros for tracking private methods in both inline and scoped visibility declaration.

### Changed
- Start using `Process.clock_gettime(Process::CLOCK_MONOTONIC)` instead of `Time.now` for time tracking
- Bumped up required Ruby version from 2.0 to 2.1

## [0.1.1] - 2018-02-24
### Added
- Specs for describing the proper way to track private methods. 

### Fixed
- Minor performance issue in class macros

## [0.1.0] - 2018-02-24
### Added
- Timeasure main code
- Timeasure profiler

[0.2.0]: https://github.com/Riskified/timeasure/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/Riskified/timeasure/compare/v0.1.0...v0.1.1

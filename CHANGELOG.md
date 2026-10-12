# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Install the hyai CLI from this flake, pinned at version 0.6.3. Available as
  `packages.<system>.hyai`, as `overlays.default`, and through `nix run` on
  x86_64-linux, aarch64-linux and aarch64-darwin.
- Node.js ships with the package, so `node` and `npm` are not needed on the
  host.
- `scripts/update.sh` bumps the pinned version from upstream's release manifest
  in one command, verifying the published sha256 and version against the
  downloaded artifact before writing anything.
- README documenting installation, that no coding agent is bundled, and how to
  update the pin.
- A CI workflow running `nix flake check` on every push and pull request, scoped
  to `x86_64-linux`, and a scheduled job that fails when the pin falls behind
  upstream.

### Changed

- `nix flake check` now builds the package and verifies that it reports the
  pinned version, replacing the placeholder coverage check from project setup.

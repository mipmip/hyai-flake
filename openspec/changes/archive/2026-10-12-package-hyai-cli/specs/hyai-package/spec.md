## Purpose

Makes the HostYourAI command line, `hyai`, installable from this flake as a
normal Nix package, so users get it from the store and a profile instead of a
`curl | sh` installer that writes outside both.

## ADDED Requirements

### Requirement: The flake exposes an installable hyai package

The flake SHALL expose the CLI as `packages.<system>.hyai` and as
`packages.<system>.default`, for `x86_64-linux`, `aarch64-linux` and
`aarch64-darwin`. `x86_64-darwin` is excluded because nixpkgs 26.11 dropped
support for it. It SHALL also expose an
`overlays.default` that adds the same package to a nixpkgs instance under the
attribute name `hyai`.

#### Scenario: Building the default package

- **WHEN** a user runs `nix build .#` on a supported system
- **THEN** the build succeeds
- **AND** `result/bin/hyai` exists and is executable

#### Scenario: Using the overlay

- **WHEN** a nixpkgs instance is created with `overlays = [ self.overlays.default ]`
- **THEN** `pkgs.hyai` resolves to the same derivation as `packages.<system>.hyai`

#### Scenario: Running without installing

- **WHEN** a user runs `nix run .# -- --version`
- **THEN** the CLI starts and reports its version

### Requirement: The packaged binary runs without a Node.js on the user's PATH

The package SHALL supply its own Node.js, satisfying the upstream requirement of
Node 20 or newer. The user SHALL NOT need `node` or `npm` installed for `hyai`
to start.

#### Scenario: No node on PATH

- **WHEN** `result/bin/hyai --version` is run in an environment whose PATH
  contains no `node`
- **THEN** the command succeeds and prints the version

### Requirement: The package reports the pinned version

The `hyai` binary in the built package SHALL report exactly the version recorded
in the pin. A pin whose recorded version disagrees with the version inside the
fetched tarball SHALL fail the build.

#### Scenario: Version matches the pin

- **WHEN** `hyai --version` is run from the built package
- **THEN** its output equals the `version` field of the pin

### Requirement: No coding agent is bundled

`hyai` launches a separate coding agent (OpenCode, Codex or Claude Code). The
package SHALL NOT place any such agent in its closure, and SHALL NOT set
`HYAI_AGENT_BIN`, so that the user's own agent is always the one that is used.

#### Scenario: Agent is absent

- **WHEN** the built package's closure is inspected
- **THEN** it contains no coding agent binary

#### Scenario: The user is told what is missing

- **WHEN** a user runs `hyai doctor` with no agent installed
- **THEN** `hyai` reports the agent as missing and names how to install it
- **AND** this is documented in the README as expected behaviour, not a defect

### Requirement: Installation is documented

The README SHALL document how to install the CLI as a flake input with the
overlay, as a one-off `nix run`, and into a profile. It SHALL state that a
coding agent is not included and must be installed separately.

#### Scenario: A reader can install it

- **WHEN** a reader follows the README
- **THEN** they reach a working `hyai --version` without consulting other sources

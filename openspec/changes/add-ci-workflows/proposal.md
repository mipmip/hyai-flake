## Why

Nothing verifies a pushed commit and nothing notices when the pinned hyai
version falls behind upstream. The pin and the build are only checked by hand, so
a broken tree can be merged and a stale pin can go unnoticed indefinitely.

## What Changes

- Add a continuous integration workflow that runs the flake's existing checks on
  every push and pull request, limited to `x86_64-linux`.
- Add a scheduled freshness workflow that runs `scripts/update.sh --check` and
  fails when upstream has published a version newer than the pinned one.
- Link this change to bean `hyai-flake-6axl` and move that bean to in-progress.

Out of scope: darwin CI runners, a binary cache (cachix), and automatic version
bump pull requests. The pin stays a manual `scripts/update.sh` run that a human
reviews and merges.

## Capabilities

### New Capabilities

- `continuous-integration`: how pushes and pull requests are validated, and how
  a stale version pin is surfaced on a schedule.

### Modified Capabilities

<!-- None. The version-pin spec already requires that the gate runs offline and
     that update.sh reports freshness; CI only invokes existing behaviour. -->

## Impact

- New `.github/workflows/` files.
- Bean `hyai-flake-6axl` (epic "CI and version bumps"), parent milestone
  `hyai-flake-463u`.
- No change to `flake.nix`, `pkgs/`, or `scripts/update.sh`; CI calls what is
  already there.
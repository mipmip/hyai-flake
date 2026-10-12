## Why

This repository exists to install the HostYourAI command line, `hyai`, but it
ships no package yet. Upstream distributes the CLI only as a tarball on their
own website, so Nix users currently have to run a `curl | sh` installer that
calls `npm install -g`, which puts files outside the store and outside any
profile.

Investigation of release 0.6.3 showed the packaging is nearly free: the tarball
is MIT, has zero runtime dependencies, is plain ESM, writes only to XDG
directories, and runs from a bare `node`. Upstream also publishes a manifest at
`https://hostyourai.com/cli/latest.json` that names a versioned URL and its
sha256, so the version can be pinned from their own data instead of by hand.

Beans: [hyai-flake-z45x](../../../.beans/hyai-flake-z45x--determine-how-hyai-is-distributed.md),
[hyai-flake-0671](../../../.beans/hyai-flake-0671--hyai-derivation.md)

## What Changes

- Add `pkgs/sources.json`, a committed pin generated from upstream's
  `latest.json`, holding `version`, `url`, `sha256` and `released`.
- Add `pkgs/hyai.nix`: a `stdenv.mkDerivation` that fetches the pinned tarball,
  installs `bin/` and `src/` into `$out/lib/hyai`, and wraps the entry point
  with `nodejs` on PATH. No build step, no `node_modules`.
- Expose the package as `packages.<system>.default` and `packages.<system>.hyai`,
  an `apps.<system>.default` for `nix run`, and an `overlays.default`, for
  `x86_64-linux`, `aarch64-linux` and `aarch64-darwin`.
- Add `scripts/update.sh`, which refreshes `pkgs/sources.json` from upstream's
  manifest in one command.
- Replace the placeholder `checks.coverage` with checks that can run in the Nix
  sandbox: the package builds, `hyai --version` prints exactly the pinned
  version, and `hyai help` exits 0.
- Document installation in `README.md` for flake and non-flake users, including
  that no coding agent is bundled.

Non-goals: bundling or wrapping a coding agent (OpenCode, Codex, Claude Code),
a NixOS or home-manager module, and submitting the package to nixpkgs.

## Capabilities

### New Capabilities

- `hyai-package`: the installable `hyai` derivation. What it contains, what it
  guarantees about the binary it exposes, and what it deliberately leaves to the
  user (the coding agent).
- `version-pin`: how the pinned version is sourced from upstream's manifest,
  what `pkgs/sources.json` must contain, and how a bump is performed and
  verified.

### Modified Capabilities

None. This is the project's first behaviour.

## Impact

- New files: `pkgs/sources.json`, `pkgs/hyai.nix`, `scripts/update.sh`.
- Modified: `flake.nix` (packages, apps, overlay, checks), `README.md`,
  `CHANGELOG.md`.
- The failing `checks.coverage` placeholder is removed, so `nix flake check`
  goes green and `/mip:ship` can complete for the first time.
- New dependency on upstream availability: the pinned URL must keep resolving.
  Versions back to 0.5.0 were confirmed still served, so this is a low risk, but
  it is a risk the flake cannot remove.
- Runtime dependency on `nodejs` (upstream requires >= 20; nixpkgs ships 24).

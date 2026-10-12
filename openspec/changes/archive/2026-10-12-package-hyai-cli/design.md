## Context

See proposal.md for motivation. The facts below come from inspecting release
0.6.3 of the upstream tarball and probing their site on 2026-10-12.

What upstream ships:

```
@hostyourai/code 0.6.3   MIT   "private": true   type: module   node >= 20
  bin/hyai.js  ->  src/cli.js
  dependencies: none
  files: bin/ src/ README CHANGELOG LICENSE THIRD_PARTY_NOTICES
  writes only to $XDG_CONFIG_HOME/hyai and $XDG_CACHE_HOME/hyai
  no self-update: "hyai doctor" prints a note, it never installs anything
```

Verified rather than assumed:

| Claim                                           | Result                       |
|-------------------------------------------------|------------------------------|
| `latest.json` names a versioned URL and a sha256 | yes                          |
| that URL serves the same bytes as `-latest.tgz`  | byte-identical               |
| the published sha256 is the real one             | matches                      |
| old versions stay served                         | 0.5.0 through 0.6.3 all 200  |
| the CLI runs from a bare `node`                  | yes, `--version` and `help`  |
| `hyai doctor` exits 0 without a key              | no, it exits 1               |

Two constraints follow from the last two rows. The package needs nothing but
Node, and `doctor` cannot be used as a build-time check.

`private: true` matters: the package is not on any npm registry, so the tarball
on their website is the only distribution channel.

## Goals / Non-Goals

**Goals:**

- A derivation small enough to read in one screen.
- The version number in the flake comes from upstream's data, never from a
  human typing it.
- `nix flake check` is meaningful and runs offline.

**Non-Goals:**

- Reproducing upstream's own test suite. The tarball's `files` list excludes
  `test/`, so the tests are not published and cannot be run from the artifact.
- Tracking `latest` automatically. A bump is a reviewed commit, not a silent
  moving target.

## Decisions

### Use `stdenv.mkDerivation`, not `buildNpmPackage`

`buildNpmPackage` is the reflex choice for a Node CLI and the wrong one here. It
wants a lockfile and a registry, and this package has neither. With zero runtime
dependencies there is nothing for it to resolve, so its entire value is unused
while its requirements still have to be worked around.

What is left is a fetch, a copy and a wrapper:

```
fetchurl { url, sha256 }  from the pin
  └─ unpack "package/"
      └─ cp -r bin src LICENSE *.md  ->  $out/lib/hyai
          └─ makeWrapper  $out/lib/hyai/bin/hyai.js  ->  $out/bin/hyai
                 --prefix PATH : ${nodejs}/bin
```

Both `patchShebangs` and the wrapper are needed, and they are not alternatives
to each other. `bin/hyai.js` starts with `#!/usr/bin/env node`, which resolves
only where `/usr/bin/env` exists. That is true on a normal machine and false in
the Nix sandbox, so a wrapper that merely puts Node on PATH builds fine and then
fails inside `nix flake check` with `bad interpreter`. `patchShebangs` rewrites
the interpreter to an absolute store path, which fixes that and also makes the
package work for a user with no Node at all. The wrapper is kept on top so Node
is on PATH for anything the CLI shells out to.

This was found by the gate rather than by reasoning: the first implementation
had the wrapper alone and passed every manual test, because every environment
tested by hand had `/usr/bin/env`.

### Pin through a committed `pkgs/sources.json`

A flake cannot read `latest.json` during evaluation: pure eval has no network,
and a value that changes under a fixed lock would break reproducibility. So
"use the remote version" is implemented as vendored-and-refreshed:

```
  hostyourai.com/cli/latest.json
            |
            |  scripts/update.sh      (run by hand, or by CI on a schedule)
            v
  pkgs/sources.json   <- committed, reviewed, this is what gets built
            |  builtins.fromJSON
            v
  pkgs/hyai.nix  ->  fetchurl { inherit (src) url sha256; }
```

Alternative considered: hardcoding `version` and `hash` in `flake.nix`. Simpler
to read, but it puts the version in two places (the `fetchurl` and the
derivation's `version` attribute) and makes milestone 03's one-command bump into
a hand edit. The JSON file costs one `fromJSON` call and removes both problems.

### Verify the hash instead of trusting the manifest

`scripts/update.sh` downloads the artifact and checks it against the sha256 the
manifest claims, before writing anything. The manifest and the artifact come
from the same host, so this is not a defence against that host. It is a defence
against a truncated download, a stale manifest, and a mismatch introduced
between publishing the two. Cheap, so worth doing.

### `--prefix` for Node, nothing at all for the agent

`findBinary` in the OpenCode adapter resolves `HYAI_AGENT_BIN` first, then PATH,
then the npm install directory. Setting `HYAI_AGENT_BIN` in the wrapper would
therefore override the user's own choice, and would be wrong by construction:
the variable names one agent binary, while `hyai run <agent>` can target
OpenCode, Codex or Claude Code. The package leaves it unset and adds no agent to
PATH.

This is also why no agent is bundled at all. nixpkgs carries all three, none at
a version hyai was tested against:

| agent       | hyai tested against | nixpkgs  |
|-------------|---------------------|----------|
| opencode    | 1.18.31 and 2.0.20  | 1.15.10  |
| claude-code | adapter present     | 2.1.223  |
| codex       | adapter present     | 0.133.0  |

The OpenCode gap is not theoretical: the 0.6.2 changelog entry is about parsing
OpenCode's version string. Shipping 1.15.10 as "the" agent would make this flake
responsible for a pairing upstream has not tested. The user brings their own.

### What the gate can actually check

The Nix sandbox has no network and no home directory, which rules out most of
what one would want to verify:

| check                                  | in sandbox | where it lives        |
|----------------------------------------|------------|-----------------------|
| the package builds                     | yes        | `checks.package`      |
| `hyai --version` equals the pin        | yes        | `checks.version`      |
| `hyai help` exits 0                    | yes        | `checks.version`      |
| `hyai doctor`                          | no         | nowhere (exits 1)     |
| pinned sha still matches served bytes  | no         | CI, scheduled         |

Drift between a pin's `version` and its `url` is caught earlier than the gate:
the derivation's install phase compares the tarball's own `package.json` version
against the pin and fails the build. `checks.version` then covers a different
failure, that the built package cannot report its version at all, which is what
a packaging mistake such as omitting `package.json` from the install produces.
`src/version.js` reads that file at runtime, so it has to be installed.

This replaces the placeholder `checks.coverage` written during project setup,
which fails on purpose and demands 70% coverage. That gate was written for a
project with its own source code. This repository has none: it is a pin, a
derivation and a shell script. Coverage of what, measured how, is not a question
with an answer here, so the check is removed rather than weakened to a number
that would be theatre.

### Supported systems

nixpkgs 26.11 dropped `x86_64-darwin`, and evaluating that system throws from
nixpkgs before any code in this flake runs. The flake therefore covers
`x86_64-linux`, `aarch64-linux` and `aarch64-darwin`.

Alternative considered: a second `nixpkgs-26.05` input used only for
`x86_64-darwin`. Rejected as disproportionate, a whole extra input and lock
entry to keep one fading platform alive. Listing the system without supporting
it was also rejected: it would make the spec claim a platform that
demonstrably throws.

## Risks / Trade-offs

- **Upstream removes an old tarball, and the pinned URL 404s.** Then the flake
  fails to build for anyone on that lock, including old revisions. Versions back
  to 0.5.0 are still served, so the observed policy is to keep them. Mitigation:
  nothing inside this flake can fix it. A scheduled CI job that fetches the
  pinned URL turns a silent breakage into a notification.
- **Upstream changes the manifest's shape or URL.** `scripts/update.sh` breaks
  rather than writing a wrong pin, because it reads named fields and verifies
  the hash. A loud failure is the intended outcome.
- **`hyai doctor` tells a Nix user to run `npm install -g ...`.** Wrong advice
  inside a profile, but only advice: nothing is executed. Patching the string
  means carrying a patch across every version bump for a cosmetic gain. Left
  alone, and documented in the README instead.
- **No agent means `hyai` alone does not start a session.** A first-time user
  reaches a `FAIL` line from `doctor`. This is a deliberate trade of
  out-of-the-box completeness for not pinning a pairing upstream has not tested.
  The README carries the weight here, so it has to be explicit.
- **`private: true` suggests upstream does not intend third-party
  redistribution,** even though the LICENSE is MIT and permits it. The licence
  governs. Worth knowing if upstream is ever asked about this flake.

## Migration Plan

Not applicable. The repository has no released package, so there is nothing to
migrate from and nothing to roll back to. The first build of this change is the
first version of the package.

## Open Questions

- Should a scheduled CI job verify that the pinned URL still resolves? It
  changes nothing about the specs, the derivation or the task breakdown, and
  belongs with the rest of the CI work in milestone 03
  (`hyai-flake-6axl`).

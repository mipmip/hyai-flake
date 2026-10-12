## Context

`flake.nix` exposes a `checks` output that already covers the package build, the
version assertion, `nixfmt`, and `shellcheck`. `scripts/update.sh` already has a
`--check` mode that reports freshness without writing, and its own comment marks
that mode as "Intended for CI". Neither is wired to anything. See proposal.md
for motivation.

The flake targets three systems (`x86_64-linux`, `aarch64-linux`,
`aarch64-darwin`) but GitHub only offers free `x86_64-linux` runners, and a bare
`nix flake check` would try to build the darwin slice and fail there.

## Goals / Non-Goals

**Goals:**

- A push/PR workflow that enforces the flake's checks on `x86_64-linux`.
- A scheduled workflow that fails when upstream is ahead of the pin.
- Reuse of existing flake checks and `update.sh --check`, not reimplementation.

**Non-Goals:**

- Building or testing `aarch64-darwin` / `aarch64-linux` in CI.
- A binary cache (cachix) or caching of the nix store beyond what the nix action
  does by default.
- Automatic bump pull requests; the pin stays a manual, reviewed change.
- Changing `flake.nix`, `pkgs/`, or `scripts/update.sh`.

## Decisions

### Decision: One workflow file with two jobs, `ci.yml`

A single `.github/workflows/ci.yml` holds a `check` job (push/PR trigger) and a
`freshness` job (schedule + manual trigger). Alternative: two files, giving two
distinct status badges. One file is simpler and the two jobs never overlap; a
combined run history is easy enough to read.

### Decision: Invoke the flake's checks, scoped to `x86_64-linux`

The check job runs `nix flake check --system x86_64-linux` (plus `-L` for logs on
failure) after installing Nix. This reuses `package`, `version`, `format`, and
`shellcheck` as-is. Alternative: list each check by attribute — rejected because
it drifts from the flake whenever a check is added.

### Decision: Freshness runs on a schedule, no writes

The freshness job runs `scripts/update.sh --check`. Exit 0 means current; exit 1
means a newer release exists, which fails the job. It needs only `curl`, `jq`,
and `sha256sum`, all present on `ubuntu-latest`. It authenticates nothing and
pushes nothing, so no token or permissions beyond `contents: read` are needed.

### Decision: Weekly schedule

A stale-pin alarm run more often than the release cadence only produces noise.
Weekly is the default; `workflow_dispatch` is added so it can be triggered by
hand after a release is known.

## Risks / Trade-offs

- **Upstream manifest unreachable or malformed** → the freshness job fails. That
  is acceptable: a failing freshness job is visible and does not block pushes,
  which run in a separate job. The failure message comes from `update.sh`, which
  already distinguishes a network error from a stale pin.
- **Flake input churn makes CI slow or flaky** → out of scope here; the flake has
  one input (`nixpkgs`). If it becomes a problem, caching is a later change.
- **`nix flake check` pulling `aarch64-*` anyway** → avoided by passing
  `--system x86_64-linux`; the check job must never use a bare invocation.
- **A green check job mistaken for darwin coverage** → the README notes CI covers
  `x86_64-linux` only; darwin is validated by users who build on it.

## Migration Plan

Additive: two workflow files, no existing file changes. Nothing to roll back
beyond deleting `.github/workflows/` if the approach is abandoned.

## Open Questions

None.
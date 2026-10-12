## 1. Continuous integration on push and pull request

- [x] 1.1 Write `.github/workflows/ci.yml` with a `check` job triggered on
      `push` and `pull_request`, checking out the repo and installing Nix, then
      running `nix flake check --system x86_64-linux -L`; verify `actionlint`
      (or a YAML parse) reports no errors and the job uses only
      `contents: read`
- [x] 1.2 Confirm the check job never uses a bare `nix flake check` and never
      names a darwin or aarch64 system; verify by reading the run command and
      the `--system` value

## 2. Scheduled pin freshness

- [x] 2.1 Add a `freshness` job to `.github/workflows/ci.yml` triggered on
      `schedule` (weekly cron) and `workflow_dispatch`, running
      `scripts/update.sh --check`; verify the exit code maps to job status
      (0 pass, 1 fail) and no write step exists
- [x] 2.2 Confirm the freshness job requires only `curl`, `jq` and `sha256sum`,
      all present on `ubuntu-latest`, and declares no permissions beyond
      `contents: read`; verify by reading the job's steps

## 3. Documentation

- [x] 3.1 Note in `README.md` that CI covers `x86_64-linux` only and that a
      scheduled job flags a stale pin, and add a `CHANGELOG.md` entry under
      `## [Unreleased] ### Added`; verify both files mention both workflows

## 4. Close the loop

- [x] 4.1 Move bean `hyai-flake-6axl` to `in-progress` and add
      `openspec-link: openspec/changes/add-ci-workflows` to its frontmatter;
      verify the frontmatter parses and the status changed
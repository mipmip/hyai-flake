## Purpose

Keeps every push and pull request validated by the flake's own checks, and
surfaces on a schedule when the pinned hyai version falls behind upstream.

## ADDED Requirements

### Requirement: Every push and pull request is validated

The repository SHALL run the flake's checks on every push and every pull
request. The run SHALL invoke the flake's existing `checks` output rather than
reimplementing them, so a check added to the flake is enforced without a second
edit. A failing check SHALL fail the run with a non-zero status.

#### Scenario: A broken push is rejected

- **WHEN** a commit that fails `nix flake check` is pushed or opened as a pull
  request
- **THEN** the workflow run fails

#### Scenario: Checked-in checks are what runs

- **WHEN** a new check is added to the flake's `checks` output
- **THEN** the workflow enforces it on the next run without the workflow itself
  being edited

### Requirement: Continuous integration is limited to x86_64-linux

The push and pull-request workflow SHALL evaluate only `x86_64-linux`. It SHALL
NOT attempt to build `aarch64-darwin` or `aarch64-linux` on that runner.

#### Scenario: Darwin is not built on Linux

- **WHEN** the push or pull-request workflow runs
- **THEN** it builds and checks only `x86_64-linux`
- **AND** it does not fail because a darwin target cannot build there

### Requirement: A stale pin is surfaced on a schedule

The repository SHALL run a scheduled job that invokes the update script's
freshness check and fails when upstream has published a version newer than the
pinned one. The job SHALL write nothing and SHALL NOT open a pull request; it
only reports.

#### Scenario: A newer release exists

- **WHEN** the scheduled job runs and upstream has published a newer version
- **THEN** the job fails
- **AND** the failure names the pinned version and the available version

#### Scenario: The pin is current

- **WHEN** the scheduled job runs and the pin names the newest release
- **THEN** the job succeeds

#### Scenario: The scheduled job stays out of the way

- **WHEN** the scheduled job runs
- **THEN** it leaves the repository unchanged
- **AND** it creates no pull request or commit
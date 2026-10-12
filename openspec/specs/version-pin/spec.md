# version-pin Specification

## Purpose
Keeps the packaged version of `hyai` traceable to what upstream published, by
pinning from their own release manifest rather than from a number typed by hand,
and by making a version bump a single reproducible command.

## Requirements

### Requirement: The pin is committed and complete

The repository SHALL hold the pin in a committed file. The pin SHALL record the
upstream `version`, the versioned tarball `url`, its `sha256`, and the `released`
date. The build SHALL read the version and the source location from that file
only, so no version string is written in more than one place.

#### Scenario: The pin is the single source of the version

- **WHEN** the pin is the only file changed in a version bump
- **THEN** the built package reports the new version
- **AND** no other file in the repository needed editing to achieve that

### Requirement: The pin names a versioned URL, not a moving one

The pinned `url` SHALL point at a version-specific artifact. A URL that serves
whichever release is newest SHALL NOT be used as the build source, because its
content changes under a fixed hash.

#### Scenario: Pinned URL stays fixed

- **WHEN** upstream publishes a newer release
- **THEN** the pinned URL still serves the same bytes
- **AND** the build continues to produce the previously pinned version

### Requirement: A bump is one command

The repository SHALL provide an update command that reads upstream's release
manifest and rewrites the pin from it. The command SHALL leave the working tree
either unchanged (already current) or holding exactly one modified file, ready to
review and commit.

#### Scenario: Already up to date

- **WHEN** the update command runs and the pin already names the newest release
- **THEN** it reports that nothing changed
- **AND** it leaves the pin byte-identical

#### Scenario: A newer release exists

- **WHEN** the update command runs and upstream has published a newer version
- **THEN** the pin is rewritten with the new version, url, sha256 and date
- **AND** the change is visible as a diff for review before committing

### Requirement: The recorded hash is verified, not trusted

The update command SHALL download the artifact and verify that its hash matches
the hash the manifest claims, before writing that hash into the pin. A mismatch
SHALL abort the update with a non-zero exit status and leave the pin untouched.

#### Scenario: Manifest hash disagrees with the artifact

- **WHEN** the downloaded artifact does not hash to the value in the manifest
- **THEN** the update command fails
- **AND** the pin is left as it was

### Requirement: The gate runs offline

Checks SHALL be runnable inside the Nix sandbox, which has no network access and
no home directory. Any verification that needs the network, a router key, or a
coding agent SHALL NOT be part of `nix flake check`.

#### Scenario: Gate on a machine with no network

- **WHEN** `nix flake check` runs with every input already in the store
- **THEN** it completes without network access
- **AND** it fails only on a genuine defect, not on a missing key or agent

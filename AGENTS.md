# hyai-flake

A Nix flake that installs the HostYourAI command line tool, `hyai`. The point of
the repository is distribution, not the tool itself: it pins a version of the
CLI, builds or unpacks it reproducibly, and exposes it as `packages.default`, an
overlay and a `nix run` app for every supported system.

How `hyai` ships is still open. It may be a prebuilt release artifact, a source
build, or a package on a public registry, and that answer decides which Nix
builder the derivation uses. Milestone 02 settles it before any derivation gets
written.

The flake also carries a dev shell and a `checks` attribute, so `nix flake check`
is the single gate that `/mip:ship` runs before anything is archived or
committed.

## Commands

```bash
nix flake check            # gate: build, tests, coverage
nix develop                # dev shell
nix run .                  # run the packaged hyai CLI (lands in milestone 02)
nix fmt                    # format the tree

beans list --ready         # what is ready to pick up
beans show <id>            # read one bean

openspec list              # active changes
scripts/ship-change.sh <change-name> [commit-subject]
```

## Beans

When I refer to issues like hyai-flake-rn3b checkout the task
in @.beans/hyai-flake-rn3b-*.md

In this project we will use these tasks as epics for making openspec proposals.

WHEN you create a proposal at a link to this task in the proposal.md.
WHEN a bean is used to create an proposal change the status to "in-progress"
WHEN a proposal is archived add the link to the archived proposal in the frontmatter of this task like this:

```
openspec-link: openspec/changes/archive/....
```

You are allowed to update these statuses in the task frontmatter:

- in-progress
- todo
- draft
- completed
- scrapped

When making changes you are allowed to update the date/time in `updated_at` in the task frontmatter

Besides updating status and openspec-link, you are NOT ALLOWED to modify the contents of the task file.

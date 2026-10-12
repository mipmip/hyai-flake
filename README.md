# hyai-flake

A Nix flake that installs [hyai](https://hostyourai.com/code/), the HostYourAI
command line: a coding agent in your terminal, on open-weights models served
from the EU.

Upstream ships the CLI as a tarball on their own website, installed with a
`curl | sh` script that calls `npm install -g`. This flake packages that same
tarball so it lands in the Nix store and in a profile instead.

Current version: **0.6.3**, pinned in [`pkgs/sources.json`](pkgs/sources.json).

## Install

Run it once, without installing anything:

```bash
nix run github:mipmip/hyai-flake -- --version
```

Install it into your profile:

```bash
nix profile add github:mipmip/hyai-flake#hyai
```

Use it as a flake input, with the overlay:

```nix
{
  inputs.hyai-flake.url = "github:mipmip/hyai-flake";

  outputs = { nixpkgs, hyai-flake, ... }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ hyai-flake.overlays.default ];
      };
    in
    {
      # pkgs.hyai is now available
    };
}
```

Or take the package directly, without the overlay:

```nix
environment.systemPackages = [ hyai-flake.packages.${system}.hyai ];
```

Supported systems: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`.
`x86_64-darwin` is not supported, because nixpkgs 26.11 dropped it.

Node.js comes with the package. You do not need `node` or `npm` installed.

## A coding agent is not included

`hyai` does not contain a coding agent. It configures one and launches it, so
you install the agent yourself. It works with OpenCode, Codex and Claude Code:

```bash
nix profile add nixpkgs#opencode      # or nixpkgs#codex, nixpkgs#claude-code
```

Until you do, `hyai doctor` reports the agent as missing and exits non-zero.
That is expected, not a defect in this flake. This is deliberate: upstream tests
against OpenCode 1.18.31 and 2.0.20, while nixpkgs currently carries 1.15.10, so
bundling a version would mean shipping a pairing nobody has tested. Yours is the
one that gets used.

Then point it at a router key and start it:

```bash
hyai login
cd your-project && hyai
```

One thing to ignore: when a newer release exists, `hyai doctor` suggests
`npm install -g https://hostyourai.com/cli/hyai-code-latest.tgz`. That is the
upstream instruction and it does not apply here. Update by updating this flake
input instead.

## Updating the pinned version

`scripts/update.sh` reads upstream's release manifest, downloads the artifact,
verifies its sha256 and the version inside it, and only then rewrites
`pkgs/sources.json`:

```bash
./scripts/update.sh           # refresh the pin, or report it is current
./scripts/update.sh --check   # exit non-zero if a newer release exists
```

Review the diff and commit it. Nothing is written when the hash or the version
disagrees with the manifest.

## Development

```bash
nix develop        # shell with nixfmt, shellcheck, jq, node
nix flake check    # build, version check, formatting, shellcheck
nix fmt            # format the nix files
```

## Licence

The packaged CLI is MIT, copyright HostYourAI B.V.; see
[their LICENSE](https://hostyourai.com/cli/hostyourai-code-0.6.3.tgz) inside the
tarball. The packaging in this repository is MIT as well, see [LICENSE](LICENSE).

## 1. Pin the release

- [x] 1.1 Create `pkgs/sources.json` holding `version`, `url`, `sha256` and
      `released` for hyai 0.6.3, taken from `https://hostyourai.com/cli/latest.json`,
      and verify `sha256sum` of the downloaded tarball matches the recorded value
- [x] 1.2 Write `scripts/update.sh` so it fetches the manifest, downloads the
      artifact, aborts non-zero on a hash mismatch, and otherwise rewrites
      `pkgs/sources.json`; verify by running it against the current release and
      confirming the file is left byte-identical
- [x] 1.3 Make `scripts/update.sh` executable and verify `shellcheck` passes on it

## 2. Build the derivation

- [x] 2.1 Write `pkgs/hyai.nix` as a `stdenv.mkDerivation` that fetches the
      pinned tarball with `fetchurl`, installs `bin/`, `src/`, `LICENSE` and the
      markdown files into `$out/lib/hyai`, and wraps `bin/hyai.js` as
      `$out/bin/hyai` with `--prefix PATH : ${nodejs}/bin`; verify
      `nix build -f . hyai` produces an executable `result/bin/hyai`
- [x] 2.2 Set `meta` with `description`, `homepage`, `license = licenses.mit`,
      `mainProgram = "hyai"` and `platforms`; verify
      `nix eval .#packages.x86_64-linux.hyai.meta.license.shortName` returns `mit`
- [x] 2.3 Set the derivation's `version` from the pin rather than a literal, and
      verify `nix eval --raw .#packages.x86_64-linux.hyai.version` prints `0.6.3`

## 3. Wire it into the flake

- [x] 3.1 Read `pkgs/sources.json` with `builtins.fromJSON` and expose
      `packages.<system>.hyai` and `packages.<system>.default` for the four
      supported systems; verify `nix flake show` lists both on each system
- [x] 3.2 Add `overlays.default` adding `hyai` to a nixpkgs instance, and verify
      with a `nix eval` expression that `pkgs.hyai` resolves to the same store path
      as `packages.<system>.hyai`
- [x] 3.3 Add `apps.<system>.default` pointing at the wrapper, and verify
      `nix run .# -- --version` prints `0.6.3`

## 4. Replace the gate

- [x] 4.1 Remove the placeholder `checks.coverage` and add `checks.package`
      building the derivation; verify the attribute builds
- [x] 4.2 Add `checks.version` asserting that `hyai --version` equals the pin's
      `version` and that `hyai help` exits 0, both with an empty PATH apart from
      the package; verify it fails when the pin's `version` is deliberately
      changed to a wrong value, then restore the pin
- [x] 4.3 Run `nix flake check` and verify it passes offline with all inputs
      already in the store

## 5. Document it

- [x] 5.1 Write the README install section covering the flake input with overlay,
      `nix run` for a one-off, and `nix profile install`; verify each command as
      written actually runs
- [x] 5.2 State in the README that no coding agent is bundled, that
      `hyai doctor` will report one missing until the user installs it, and that
      its `npm install -g` update hint does not apply to this installation
- [x] 5.3 Add the user-facing entries to `CHANGELOG.md` under `## [Unreleased]`

## 6. Close the loop

- [x] 6.1 Update beans `hyai-flake-z45x` and `hyai-flake-0671` to `completed`
      with the `openspec-link` frontmatter pointing at the archived change
- [x] 6.2 Verify `hyai --version`, `hyai help` and `hyai doctor` all behave as
      the specs describe when run from a profile-installed build, with `doctor`
      reporting the missing agent and exiting 1

{
  description = "Nix flake that installs the HostYourAI (hyai) CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      source = builtins.fromJSON (builtins.readFile ./pkgs/sources.json);
    in
    {
      overlays.default = final: _prev: {
        hyai = final.callPackage ./pkgs/hyai.nix { };
      };

      packages = forAllSystems (pkgs: rec {
        hyai = pkgs.callPackage ./pkgs/hyai.nix { };
        default = hyai;
      });

      apps = forAllSystems (pkgs: rec {
        hyai = {
          type = "app";
          program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.hyai}/bin/hyai";
        };
        default = hyai;
      });

      formatter = forAllSystems (
        pkgs:
        pkgs.writeShellApplication {
          name = "fmt";
          runtimeInputs = [
            pkgs.findutils
            pkgs.nixfmt
          ];
          text = ''
            find "''${1:-.}" -name '*.nix' -not -path '*/.git/*' -exec nixfmt {} +
          '';
        }
      );

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nixfmt
            pkgs.nix-prefetch
            pkgs.shellcheck
            pkgs.jq
            pkgs.nodejs
          ];
        };
      });

      checks = forAllSystems (
        pkgs:
        let
          hyai = self.packages.${pkgs.stdenv.hostPlatform.system}.hyai;
        in
        {
          package = hyai;

          version = pkgs.runCommand "check-hyai-version" { } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"

            reported="$(${hyai}/bin/hyai --version)"
            if [ "$reported" != "${source.version}" ]; then
              echo "hyai --version printed '$reported', the pin records '${source.version}'" >&2
              exit 1
            fi

            ${hyai}/bin/hyai help > /dev/null

            touch $out
          '';

          format = pkgs.runCommand "check-format" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            nixfmt --check ${./flake.nix} ${./pkgs/hyai.nix}
            touch $out
          '';

          shellcheck = pkgs.runCommand "check-shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
            shellcheck ${./scripts/ship-change.sh} ${./scripts/update.sh}
            touch $out
          '';
        }
      );
    };
}

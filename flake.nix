{
  description = "A small desktop shell for NixOS on X11, in QML for Quickshell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forEach = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # the shell, its theme file and the fragments for the apps, for home-manager
      homeModules.default = import ./nix/module.nix self;

      # i3 with the patch that the shell needs, see docs/i3.md: the room for its tabs, the gap inside them and the tabs that are not in front
      # unmapped. It applies to the i3 of the pkgs that it is used with, so use it as nixpkgs.overlays = [ nix-quickshell.overlays.i3 ]
      overlays.i3 = _final: prev: {
        i3 = prev.i3.overrideAttrs (old: {
          # the tests of i3 drag a tab with the pointer at the places of its default height, which the patch changes
          doCheck = false;
          patches = (old.patches or [ ]) ++ [ ./nix/apps/i3.patch ];
        });
      };

      devShells = forEach (pkgs: {
        default = pkgs.mkShell {
          name = "nix-quickshell";
          packages = with pkgs; [
            shellcheck
            actionlint
            jq
          ];
        };
      });

      # `nix flake check` builds the shell and the patched i3 (the patch must apply), and checks that the flavours are the same shape
      checks = forEach (pkgs: {
        inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) nshell i3;
        flavours =
          pkgs.runCommand "nix-quickshell-flavours" { nativeBuildInputs = [ pkgs.jq ]; }
            ''
              for f in ${./flavours}/*.json; do
                # a dark and a light palette with the same roles, each a color of six hex digits, or eight with the alpha first
                jq -e '(.dark | keys) == (.light | keys)
                  and ([.dark, .light] | all(.[]; to_entries | all(.value | test("^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"))))' "$f" > /dev/null \
                  || { echo "$f: the palettes are not the same shape, or a role is not a color"; exit 1; }
              done
              # the flavours have the same roles as each other
              test "$(jq -c '.dark | keys' ${./flavours}/*.json | sort -u | wc -l)" = 1
              touch $out
            '';
      });

      packages = forEach (pkgs: rec {
        nshell = pkgs.callPackage ./package.nix { };
        default = nshell;
        # the i3 of the pinned nixpkgs with the patch: `nix build .#i3` says if the patch still applies
        i3 = (pkgs.extend self.overlays.i3).i3;
      });
    };
}

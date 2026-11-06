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
      # unmapped. It applies to the i3 of the pkgs that it is used with, so use it as nixpkgs.overlays = [ nix-shell.overlays.i3 ]
      overlays.i3 = _final: prev: {
        i3 = prev.i3.overrideAttrs (old: {
          # the tests of i3 drag a tab with the pointer at the places of its default height, which the patch changes
          doCheck = false;
          patches = (old.patches or [ ]) ++ [ ./nix/patches/i3.patch ];
        });
      };

      packages = forEach (pkgs: rec {
        nshell = pkgs.callPackage ./package.nix { };
        default = nshell;
        # the i3 of the pinned nixpkgs with the patch: `nix build .#i3` says if the patch still applies
        i3 = (pkgs.extend self.overlays.i3).i3;
      });
    };
}

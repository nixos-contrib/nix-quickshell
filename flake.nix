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

      packages = forEach (pkgs: rec {
        nshell = pkgs.callPackage ./package.nix { };
        default = nshell;
      });
    };
}

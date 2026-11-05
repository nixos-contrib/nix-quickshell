# A home-manager module: the shell, its theme as the file that the shell reads, and the fragments for the apps that follow the
# theme. See the README
self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.nix-shell;
  inherit (lib) mkEnableOption mkOption mkIf types;

  variant = builtins.fromJSON (builtins.readFile ../themes/${cfg.theme.variant}.json);
  # The apps follow the mode when it is dark or light. When it is auto, the shell changes during the day and the apps do not,
  # so they have the dark palette
  mode = if cfg.theme.mode == "light" then "light" else "dark";
  palette = variant.${mode} // cfg.theme.${mode};
  files = import ./generators.nix palette;

  roles = mkOption {
    type = types.attrsOf types.str;
    default = { };
    example = {
      primary = "#7ebae4";
    };
    description = "Roles of the palette to change, by name, as in themes/*.json. A color is #rrggbb, or #aarrggbb with alpha.";
  };

  integration =
    description:
    mkOption {
      type = types.bool;
      default = false;
      inherit description;
    };
in
{
  options.programs.nix-shell = {
    enable = mkEnableOption "the nix-shell desktop shell";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = "the package of this flake";
      description = "The shell.";
    };

    theme = {
      variant = mkOption {
        type = types.enum [
          "navy"
          "graphite"
        ];
        default = "navy";
        description = "The theme of the package: navy is the blues of nixos.org, graphite is the same with greys.";
      };
      mode = mkOption {
        type = types.enum [
          "dark"
          "light"
          "auto"
        ];
        default = "dark";
        description = "dark, light, or auto, which follows the hours below. `nshell theme` changes it while the shell runs, and that choice lasts over this one.";
      };
      hours = {
        light = mkOption {
          type = types.ints.between 0 23;
          default = 7;
          description = "The hour auto turns light.";
        };
        dark = mkOption {
          type = types.ints.between 0 23;
          default = 19;
          description = "The hour auto turns dark.";
        };
      };
      font = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "SF Pro Text";
        description = "The family of the font. The default is Inter, which has to be installed: the shell carries no font.";
      };
      radius = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "The large radius, in pixels, of what floats. The medium and small ones follow it. The default is 16.";
      };
      dark = roles;
      light = roles;
    };

    integration = {
      gtk = integration "~/.config/nix-shell/gtk.css, the named colors of adw-gtk3 and libadwaita, for `@import url(\"../nix-shell/gtk.css\");` in gtk-3.0/gtk.css and gtk-4.0/gtk.css";
      xresources = integration "~/.config/nix-shell/Xresources, the colors of xterm, for `xrdb -merge`";
      zathura = integration "~/.config/nix-shell/zathurarc, the colors of zathura, for `include` in zathurarc";
      i3 = integration "~/.config/nix-shell/i3.conf, the colors of the tabs, for `include` in the config of i3";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "nix-shell/theme.json".text = builtins.toJSON (
        lib.filterAttrs (_: v: v != null && v != { }) {
          variant = cfg.theme.variant;
          mode = cfg.theme.mode;
          hours = cfg.theme.hours;
          inherit (cfg.theme) font radius dark light;
        }
      );
    }
    // lib.optionalAttrs cfg.integration.gtk { "nix-shell/gtk.css".text = files.gtk; }
    // lib.optionalAttrs cfg.integration.xresources { "nix-shell/Xresources".text = files.xresources; }
    // lib.optionalAttrs cfg.integration.zathura { "nix-shell/zathurarc".text = files.zathura; }
    // lib.optionalAttrs cfg.integration.i3 { "nix-shell/i3.conf".text = files.i3; };
  };
}

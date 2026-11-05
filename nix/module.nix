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
  # the colors are in a file of their own, which the apps that cannot be written by the module also import
  gtkCss = ''
    @import url("file://${config.xdg.configHome}/nix-shell/gtk.css");
${cfg.integration.gtk.extraCss}'';

  roles = mkOption {
    type = types.attrsOf types.str;
    default = { };
    example = {
      primary = "#7ebae4";
    };
    description = "Roles of the palette to change, by name, as in themes/*.json. A color is #rrggbb, or #aarrggbb with alpha.";
  };

  enableOption =
    description:
    mkOption {
      type = types.bool;
      default = false;
      inherit description;
    };

  font = if cfg.theme.font != null then cfg.theme.font else "Inter";
  fontSize = toString cfg.integration.fontSize;
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
      fontSize = mkOption {
        type = types.ints.positive;
        default = 11;
        description = "The size of the text of the GTK apps and of zathura, in points. The shell has its own sizes.";
      };

      gtk = {
        enable = enableOption ''
          The look of the GTK apps: the settings (adw-gtk3 in the mode of the theme, the icons, the font), and gtk-3.0/gtk.css and
          gtk-4.0/gtk.css with the named colors of the palette, which adw-gtk3 and libadwaita read. Owns those files
        '';
        iconTheme = {
          name = mkOption {
            type = types.str;
            default = "Papirus-Dark";
            description = "The name of the icon theme.";
          };
          package = mkOption {
            type = types.package;
            default = pkgs.papirus-icon-theme;
            defaultText = "pkgs.papirus-icon-theme";
            description = "The package of the icon theme, installed with the theme adw-gtk3.";
          };
        };
        extraCss = mkOption {
          type = types.lines;
          default = "";
          description = "Rules added to gtk.css after the colors: the layout of the apps. They can use the named colors, as @window_bg_color.";
        };
      };

      zathura = {
        enable = enableOption "zathura/zathurarc with the colors of the palette and the font. Owns that file";
        extraConfig = mkOption {
          type = types.lines;
          default = "";
          description = "Lines added to zathurarc.";
        };
      };

      xresources.enable = enableOption "~/.config/nix-shell/Xresources, the colors of xterm, for `xrdb -merge`";
      i3.enable = enableOption "~/.config/nix-shell/i3.conf, the colors of the tabs, for `include` in the config of i3";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      cfg.package
    ]
    ++ lib.optionals cfg.integration.gtk.enable [
      pkgs.adw-gtk3
      cfg.integration.gtk.iconTheme.package
    ];

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
    // lib.optionalAttrs cfg.integration.gtk.enable {
      "nix-shell/gtk.css".text = files.gtk;
      "gtk-3.0/gtk.css".text = gtkCss;
      "gtk-4.0/gtk.css".text = gtkCss;
      "gtk-3.0/settings.ini".text = ''
        [Settings]
        gtk-theme-name=${if mode == "light" then "adw-gtk3" else "adw-gtk3-dark"}
        gtk-icon-theme-name=${cfg.integration.gtk.iconTheme.name}
        gtk-font-name=${font} ${fontSize}
        gtk-application-prefer-dark-theme=${if mode == "light" then "0" else "1"}
      '';
    }
    // lib.optionalAttrs cfg.integration.xresources.enable { "nix-shell/Xresources".text = files.xresources; }
    // lib.optionalAttrs cfg.integration.zathura.enable {
      "zathura/zathurarc".text = ''
        ${files.zathura}
        set font "${font} ${fontSize}"
        ${cfg.integration.zathura.extraConfig}
      '';
    }
    // lib.optionalAttrs cfg.integration.i3.enable { "nix-shell/i3.conf".text = files.i3; };
  };
}

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
  modes = [
    "dark"
    "light"
  ];
  palettes = lib.genAttrs modes (m: variant.${m} // cfg.theme.${m});
  files = lib.mapAttrs (_: import ./generators.nix) palettes;
  # The mode the apps have until the shell says its own: the files that the shell copies when the mode changes, see `nshell apps`.
  # Dark, unless the theme is light
  startMode = if cfg.theme.mode == "light" then "light" else "dark";
  stateDir = "${config.xdg.stateHome}/nix-shell";

  gtkTheme = m: "nix-shell-${m}";
  # The same theme under another name. Brave (Chromium) reads the colors of the GTK theme when its name changes, before GTK has loaded it, and
  # so it shows the mode before: the apps are told the name of the theme, and a moment later the name of its twin, which is when Brave
  # reads the theme that was loaded. See `nshell apps`
  gtkTwin = m: "nix-shell-${m}-twin";
  iconName = m: if m == "light" then cfg.integration.gtk.iconTheme.lightName else cfg.integration.gtk.iconTheme.name;
  # The GTK theme of a mode: adw-gtk3 in that mode, with the named colors of the palette after it, which win over its own, and the
  # rules of the user
  gtkThemeCss = m: ''
    @import url("file://${pkgs.adw-gtk3}/share/themes/${if m == "light" then "adw-gtk3" else "adw-gtk3-dark"}/gtk-3.0/gtk.css");
    ${files.${m}.gtk}
    ${cfg.integration.gtk.extraCss}
  '';
  # What xsettingsd tells the GTK apps, which then draw themselves again: the theme of the mode, and the rest of the look
  xsettings = m: theme: ''
    Net/ThemeName "${theme}"
    Net/IconThemeName "${iconName m}"
    Gtk/FontName "${font} ${fontSize}"
    Gtk/ApplicationPreferDarkTheme ${if m == "light" then "0" else "1"}
    Gtk/MenuImages ${if cfg.integration.gtk.menuImages then "1" else "0"}
    ${lib.optionalString cursor.enable ''
      Gtk/CursorThemeName "${cursor.name}"
      Gtk/CursorThemeSize ${toString cursor.size}
    ''}${cfg.integration.gtk.xsettings}
  '';

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
  cursor = cfg.integration.cursor;
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
          gtk-4.0/gtk.css with the named colors of the palette, which adw-gtk3 and libadwaita read. Owns those files, and two GTK themes in ~/.local/share/themes: nix-shell-dark and nix-shell-light
        '';
        iconTheme = {
          name = mkOption {
            type = types.str;
            default = "Papirus-Dark";
            description = "The name of the icon theme in the dark mode.";
          };
          lightName = mkOption {
            type = types.str;
            default = "Papirus-Light";
            description = "The name of the icon theme in the light mode.";
          };
          package = mkOption {
            type = types.package;
            default = pkgs.papirus-icon-theme;
            defaultText = "pkgs.papirus-icon-theme";
            description = "The package of the icon theme, installed with the theme adw-gtk3.";
          };
        };
        menuImages = mkOption {
          type = types.bool;
          default = true;
          description = "Icons in the menus of the GTK apps, as in the context menu of Thunar. GTK 3 draws none unless it is told to.";
        };
        extraCss = mkOption {
          type = types.lines;
          default = "";
          description = "Rules added to the two GTK themes after the colors: the layout of the apps. They can use the named colors, as @window_bg_color.";
        };
        xsettings = mkOption {
          type = types.lines;
          default = "";
          example = ''Xft/DPI 196608'';
          description = "Lines added to what xsettingsd tells the GTK apps, as the dpi of the screen, see xsettingsd.conf(5).";
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

      cursor = {
        enable = enableOption ''
          The mouse cursor: the package, a default theme for X (icons/default/index.theme), the cursor of GTK, the cursor of Xresources,
          and nix-shell/session.sh, which the session sources for XCURSOR_THEME, XCURSOR_SIZE and XCURSOR_PATH. Xcursor on NixOS does
          not look into the profile of the user by itself
        '';
        name = mkOption {
          type = types.str;
          default = "capitaine-cursors";
          description = "The name of the cursor theme: capitaine-cursors is the arrow of macOS, black with a white edge, and capitaine-cursors-white is its white one.";
        };
        package = mkOption {
          type = types.package;
          default = pkgs.capitaine-cursors;
          defaultText = "pkgs.capitaine-cursors";
          description = "The package of the cursor theme.";
        };
        size = mkOption {
          type = types.ints.positive;
          default = 24;
          description = "The size in pixels. capitaine-cursors has 24, 30, 36, 48, 60 and 72, and a screen with twice the pixels needs twice the size.";
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
      pkgs.xsettingsd
      cfg.integration.gtk.iconTheme.package
    ]
    ++ lib.optional cursor.enable cursor.package;

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
    // lib.optionalAttrs cfg.integration.gtk.enable (
      {
        # for the GTK apps that do not ask xsettingsd, and the apps of GTK 4, which take no theme: the mode of the start
        "gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=${gtkTheme startMode}
          gtk-icon-theme-name=${iconName startMode}
          gtk-font-name=${font} ${fontSize}
          gtk-application-prefer-dark-theme=${if startMode == "light" then "0" else "1"}
          gtk-menu-images=${if cfg.integration.gtk.menuImages then "1" else "0"}
        ''
        + lib.optionalString cursor.enable ''
          gtk-cursor-theme-name=${cursor.name}
          gtk-cursor-theme-size=${toString cursor.size}
        '';
        "gtk-4.0/gtk.css".text = ''
          ${files.${startMode}.gtk}
          ${cfg.integration.gtk.extraCss}
        '';
      }
      // lib.listToAttrs (
        lib.concatMap (m: [
          (lib.nameValuePair "nix-shell/xsettings-${m}.conf" { text = xsettings m (gtkTheme m); })
          (lib.nameValuePair "nix-shell/xsettings-${m}-twin.conf" { text = xsettings m (gtkTwin m); })
        ]) modes
      )
    )
    // lib.optionalAttrs cfg.integration.xresources.enable (
      lib.listToAttrs (map (m: lib.nameValuePair "nix-shell/xresources-${m}" { text = files.${m}.xresources; }) modes)
    )
    // lib.optionalAttrs cursor.enable {
      # mode-free, for `xrdb -merge` once, and the session
      "nix-shell/Xresources".text = ''
        Xcursor.theme: ${cursor.name}
        Xcursor.size: ${toString cursor.size}
      '';
      "nix-shell/session.sh".text = ''
        export XCURSOR_THEME=${cursor.name}
        export XCURSOR_SIZE=${toString cursor.size}
        export XCURSOR_PATH=${config.home.profileDirectory}/share/icons:/run/current-system/sw/share/icons
      '';
    }
    // lib.optionalAttrs cfg.integration.zathura.enable (
      {
        "zathura/zathurarc".text = ''
          include ${stateDir}/zathurarc
          set font "${font} ${fontSize}"
          ${cfg.integration.zathura.extraConfig}
        '';
      }
      // lib.listToAttrs (map (m: lib.nameValuePair "nix-shell/zathurarc-${m}" { text = files.${m}.zathura; }) modes)
    )
    // lib.optionalAttrs cfg.integration.i3.enable (
      lib.listToAttrs (map (m: lib.nameValuePair "nix-shell/i3-${m}.conf" { text = files.${m}.i3; }) modes)
    );

    xdg.dataFile =
      lib.optionalAttrs cursor.enable {
        "icons/default/index.theme".text = ''
          [Icon Theme]
          Name=Default
          Comment=The default cursor theme
          Inherits=${cursor.name}
        '';
      }
      // lib.optionalAttrs cfg.integration.gtk.enable (
        lib.listToAttrs (
          lib.concatMap (
            m:
            lib.concatMap (name: [
              (lib.nameValuePair "themes/${name}/index.theme" {
                text = ''
                  [Desktop Entry]
                  Type=X-GNOME-Metatheme
                  Name=${name}
                  Comment=adw-gtk3 in the palette of nix-shell, ${m}

                  [X-GNOME-Metatheme]
                  GtkTheme=${name}
                '';
              })
              (lib.nameValuePair "themes/${name}/gtk-3.0/gtk.css" { text = gtkThemeCss m; })
            ]) [ (gtkTheme m) (gtkTwin m) ]
          ) modes
        )
      );
  };
}

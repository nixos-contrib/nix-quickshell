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
  cfg = config.programs.nix-quickshell;
  inherit (lib) mkEnableOption mkOption mkIf types;

  themeData = builtins.fromJSON (builtins.readFile ../themes/${cfg.theme.name}.json);
  modes = [
    "dark"
    "light"
  ];
  palettes = lib.genAttrs modes (m: themeData.${m} // cfg.theme.${m});
  gtkColors = lib.mapAttrs (_: import ./gtk.nix) palettes;
  # The apps that follow the theme: each file of apps/ is one, see there. Enabled when Home Manager has the program enabled, or when the user says so
  appDefs = lib.mapAttrs' (n: _: lib.nameValuePair (lib.removeSuffix ".nix" n) (import ./apps/${n})) (
    lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nix" n) (builtins.readDir ./apps)
  );
  enabledApps = lib.filterAttrs (n: _: cfg.targets.${n}.enable) appDefs;
  # The mode the apps have until the shell says its own: the files that the shell copies when the mode changes, see `nshell apps`.
  # Dark, unless the theme is light
  startMode = if cfg.theme.mode == "light" then "light" else "dark";
  stateDir = "${config.xdg.stateHome}/nix-quickshell";

  gtkTheme = m: "nix-quickshell-${m}";
  # The same theme under another name. Brave (Chromium) reads the colors of the GTK theme when its name changes, before GTK has loaded it, and
  # so it shows the mode before: the apps are told the name of the theme, and a moment later the name of its twin, which is when Brave
  # reads the theme that was loaded. See `nshell apps`
  gtkTwin = m: "nix-quickshell-${m}-twin";
  iconName = m: cfg.targets.gtk.iconTheme.${m};
  # The GTK theme of a mode: adw-gtk3 in that mode, with the named colors of the palette after it, which win over its own, and the
  # rules of the user
  gtkThemeCss = m: ''
    @import url("file://${pkgs.adw-gtk3}/share/themes/${if m == "light" then "adw-gtk3" else "adw-gtk3-dark"}/gtk-3.0/gtk.css");
    ${gtkColors.${m}}
    ${cfg.targets.gtk.extraCss}
  '';
  # What xsettingsd tells the GTK apps, which then draw themselves again: the theme of the mode, and the rest of the look
  xsettings = m: theme: ''
    Net/ThemeName "${theme}"
    Net/IconThemeName "${iconName m}"
    Gtk/FontName "${font} ${fontSize}"
    Gtk/ApplicationPreferDarkTheme ${if m == "light" then "0" else "1"}
    Gtk/MenuImages ${if cfg.targets.gtk.menuImages then "1" else "0"}
    ${lib.optionalString cursor.enable ''
      Gtk/CursorThemeName "${cursor.name}"
      Gtk/CursorThemeSize ${toString cursor.size}
    ''}${cfg.targets.gtk.xsettings}
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

  # The wallpaper of a mode: the surface color of the palette, a step off the bar so that the bar is seen as a strip, and the official logomark of NixOS in
  # the middle, the one with the gradient, the same on both modes, 12% of the height of the screen: it is the signature of an empty desktop, and does not draw the eye. 5120 x 2880: it is scaled to the
  # screen, and the logo stays in the middle. The bar has the flat white one: the blues of the gradient would not show on it
  logomarkFile = ../assets/nixos-logomark-default-gradient-recommended.svg;
  wallpaper =
    m:
    pkgs.runCommand "nix-quickshell-wallpaper-${m}.png" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
      # the drawing of the logomark, without its svg element: it is centered on 0, 0 and 1995 high, with its clear space around
      logo="$(sed -e 's/^<svg[^>]*>//' -e 's#</svg>$##' ${logomarkFile})"
      cat > wallpaper.svg <<SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="5120" height="2880" viewBox="0 0 5120 2880">
        <rect width="5120" height="2880" fill="${palettes.${m}.surface}"/>
        <g transform="translate(2560 1440) scale(0.17)">$logo</g>
      </svg>
      SVG
      rsvg-convert wallpaper.svg -o $out
    '';

  # the image of the user for a mode, or the generated one
  wallpaperOf =
    m:
    let
      image = cfg.targets.wallpaper.image;
      own = if image == null then null else if builtins.isAttrs image then image.${m} else image;
    in
    if own != null then own else wallpaper m;

  font = if cfg.theme.font != null then cfg.theme.font else "Route 159";
  fontSize = toString cfg.theme.fontSize;
  cursor = cfg.targets.cursor;
in
{
  options.programs.nix-quickshell = {
    enable = mkEnableOption "the nix-quickshell desktop shell";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = "the package of this flake";
      description = "The shell.";
    };

    theme = {
      name = mkOption {
        type = types.enum [
          "nixos-navy"
          "nixos-graphite"
        ];
        default = "nixos-navy";
        description = "The theme, a set of palettes of the package (themes/*.json): nixos-navy is the blues of nixos.org, nixos-graphite is the same with greys.";
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
        description = "The family of the font. The default is Route 159, the typeface of NixOS, which has to be installed (nixpkgs has it as route159): the shell carries no font.";
      };
      fontSize = mkOption {
        type = types.ints.positive;
        default = 11;
        description = "The size of the text of the apps that follow the theme, the GTK apps and zathura, in points. The shell has its own sizes.";
      };
      fallbackFont = mkOption {
        type = types.nullOr types.str;
        default = "Inter";
        example = "Noto Sans";
        description = ''
          The family that draws what the font has not: Route 159 has the Latin letters and little more, no Cyrillic, no Greek and no arrows. A
          fontconfig rule in ~/.config/fontconfig/conf.d adds it after the font, for the shell and the GTK apps. It has to be installed. null: no rule.
        '';
      };
      radius = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        description = "The large radius, in pixels, of what floats. The medium and small ones follow it. The default is 16.";
      };
      dark = roles;
      light = roles;
    };

    network = {
      interface = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "enp3s0";
        description = "The interface that the network item of the bar shows when NetworkManager is not there. None, which is the one of the default route when it is a card of the machine, and otherwise the first card with a cable: the interfaces of Tailscale, Docker and VPNs are not the connection.";
      };
    };

    session = {
      lock = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "i3lock";
        description = "What Lock in the menu of the session runs, `i3lock` or `xss-lock --transfer-sleep-lock -- i3lock`. None by default, and then the menu has no Lock: X11 has no lock screen for a shell to draw.";
      };
      logout = mkOption {
        type = types.str;
        default = "i3-msg exit";
        description = "What Log out runs.";
      };
      suspend = mkOption {
        type = types.str;
        default = "systemctl suspend";
        description = "What Suspend runs.";
      };
      reboot = mkOption {
        type = types.str;
        default = "systemctl reboot";
        description = "What Reboot runs, after the menu asks once more.";
      };
      poweroff = mkOption {
        type = types.str;
        default = "systemctl poweroff";
        description = "What Power off runs, after the menu asks once more.";
      };
    };

    calendar = {
      weekStart = mkOption {
        type = types.enum [
          "monday"
          "sunday"
        ];
        default = "monday";
        description = "The day the weeks of the calendar under the clock start on.";
      };
      weekNumbers = mkOption {
        type = types.bool;
        default = false;
        description = "The ISO number of the week, at the start of each row of the calendar.";
      };
    };

    targets = {
      autoEnable = mkOption {
        type = types.bool;
        default = true;
        description = "Turn on the apps below that Home Manager has enabled as programs.<app>.enable. An `enable` of a target says what it says, whatever this is.";
      };

      gtk = {
        enable = enableOption ''
          The look of the GTK apps: the settings (adw-gtk3 in the mode of the theme, the icons, the font), and gtk-3.0/gtk.css and
          gtk-4.0/gtk.css with the named colors of the palette, which adw-gtk3 and libadwaita read. Owns those files, and two GTK themes in ~/.local/share/themes: nix-quickshell-dark and nix-quickshell-light
        '';
        iconTheme = {
          dark = mkOption {
            type = types.str;
            default = "Papirus-Dark";
            description = "The name of the icon theme in the dark mode.";
          };
          light = mkOption {
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

      cursor = {
        enable = enableOption ''
          The mouse cursor: the package, a default theme for X (icons/default/index.theme), the cursor of GTK, the cursor of Xresources,
          and nix-quickshell/session.sh, which the session sources for XCURSOR_THEME, XCURSOR_SIZE and XCURSOR_PATH. Xcursor on NixOS does
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

      wallpaper = {
        enable = enableOption ''
          The wallpaper of the theme: ~/.config/nix-quickshell/wallpaper-<mode>.png, the surface color of the palette (not the one of the bar) with the logomark of NixOS in the
          middle, and `nshell apps` sets the one of the mode with feh, when the mode changes and at the start of the session
        '';
        image = mkOption {
          type = types.nullOr (
            types.either types.path (
              types.submodule {
                options = {
                  dark = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "The image of the dark mode: null is the generated wallpaper.";
                  };
                  light = mkOption {
                    type = types.nullOr types.path;
                    default = null;
                    description = "The image of the light mode: null is the generated wallpaper.";
                  };
                };
              }
            )
          );
          default = null;
          example = lib.literalExpression "{ dark = ./night.png; light = ./day.png; }";
          description = "An image of your own: one for both modes, or one for each, in place of the generated wallpapers.";
        };
      };
    }
    # the apps that paint their own colors: each file of apps/ is one
    // lib.mapAttrs (name: def: {
      enable = mkOption {
        type = types.bool;
        default = cfg.targets.autoEnable && def.program != null && (config.programs.${def.program}.enable or false);
        defaultText = lib.literalMD "`programs.${name}.enable` when `targets.autoEnable` is on, otherwise false";
        description = "~/.config/nix-quickshell/apps/${name}-<mode>, the colors of ${name}, which `nshell apps` puts in the state folder as ${def.target}, and the include of it in the config of ${name} when Home Manager has it.";
      };
    }) appDefs;
  };

  config = mkIf cfg.enable (lib.mkMerge [ {
    home.packages = [
      cfg.package
    ]
    ++ lib.optionals cfg.targets.gtk.enable [
      pkgs.adw-gtk3
      pkgs.xsettingsd
      cfg.targets.gtk.iconTheme.package
    ]
    ++ lib.optional cursor.enable cursor.package
    ++ lib.optional cfg.targets.wallpaper.enable pkgs.feh;

    xdg.configFile = lib.optionalAttrs (cfg.theme.fallbackFont != null) {
      # the font has the Latin letters and little more: what it has not is drawn by the fallback, not by whatever fontconfig picks
      "fontconfig/conf.d/60-nix-quickshell-fallback.conf".text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <alias binding="same">
            <family>${font}</family>
            <accept><family>${cfg.theme.fallbackFont}</family></accept>
          </alias>
        </fontconfig>
      '';
    } // {
      "nix-quickshell/theme.json".text = builtins.toJSON (
        lib.filterAttrs (_: v: v != null && v != { }) {
          name = cfg.theme.name;
          mode = cfg.theme.mode;
          hours = cfg.theme.hours;
          inherit (cfg.theme) font radius dark light;
          inherit (cfg) calendar;
          network = { interface = cfg.network.interface; };
          session = {
            lock = cfg.session.lock;
            logout = cfg.session.logout;
            suspend = cfg.session.suspend;
            reboot = cfg.session.reboot;
            poweroff = cfg.session.poweroff;
          };
        }
      );
    }
    // lib.optionalAttrs cfg.targets.gtk.enable (
      {
        # for the GTK apps that do not ask xsettingsd, and the apps of GTK 4, which take no theme: the mode of the start
        "gtk-3.0/settings.ini".text = ''
          [Settings]
          gtk-theme-name=${gtkTheme startMode}
          gtk-icon-theme-name=${iconName startMode}
          gtk-font-name=${font} ${fontSize}
          gtk-application-prefer-dark-theme=${if startMode == "light" then "0" else "1"}
          gtk-menu-images=${if cfg.targets.gtk.menuImages then "1" else "0"}
        ''
        + lib.optionalString cursor.enable ''
          gtk-cursor-theme-name=${cursor.name}
          gtk-cursor-theme-size=${toString cursor.size}
        '';
        "gtk-4.0/gtk.css".text = ''
          ${gtkColors.${startMode}}
          ${cfg.targets.gtk.extraCss}
        '';
      }
      // lib.listToAttrs (
        lib.concatMap (m: [
          (lib.nameValuePair "nix-quickshell/xsettings-${m}.conf" { text = xsettings m (gtkTheme m); })
          (lib.nameValuePair "nix-quickshell/xsettings-${m}-twin.conf" { text = xsettings m (gtkTwin m); })
        ]) modes
      )
    )
    // lib.optionalAttrs cfg.targets.wallpaper.enable (
      lib.listToAttrs (
        map (
          m:
          lib.nameValuePair "nix-quickshell/wallpaper-${m}.png" {
            source = wallpaperOf m;
          }
        ) modes
      )
    )
    // lib.optionalAttrs cursor.enable {
      # mode-free, for `xrdb -merge` once, and the session
      "nix-quickshell/Xresources".text = ''
        Xcursor.theme: ${cursor.name}
        Xcursor.size: ${toString cursor.size}
      '';
      "nix-quickshell/session.sh".text = ''
        export XCURSOR_THEME=${cursor.name}
        export XCURSOR_SIZE=${toString cursor.size}
        export XCURSOR_PATH=${config.home.profileDirectory}/share/icons:/run/current-system/sw/share/icons
      '';
    }
    # the apps: the colors of each mode, and what `nshell apps` needs to know of the app, which is a file of shell variables
    // lib.concatMapAttrs (
      name: def:
      {
        "nix-quickshell/apps/${name}.app".text = ''
          target=${lib.escapeShellArg def.target}
          reload=${lib.escapeShellArg (if def.reload == null then "" else def.reload)}
          always=${if def.always then "1" else "0"}
        '';
      }
      // lib.listToAttrs (map (m: lib.nameValuePair "nix-quickshell/apps/${name}-${m}" { text = def.colors palettes.${m} + (def.font or (_: "")) { family = font; size = cfg.theme.fontSize; }; }) modes)
    ) enabledApps;

    xdg.dataFile =
      lib.optionalAttrs cursor.enable {
        "icons/default/index.theme".text = ''
          [Icon Theme]
          Name=Default
          Comment=The default cursor theme
          Inherits=${cursor.name}
        '';
      }
      // lib.optionalAttrs cfg.targets.gtk.enable (
        lib.listToAttrs (
          lib.concatMap (
            m:
            lib.concatMap (name: [
              (lib.nameValuePair "themes/${name}/index.theme" {
                text = ''
                  [Desktop Entry]
                  Type=X-GNOME-Metatheme
                  Name=${name}
                  Comment=adw-gtk3 in the palette of nix-quickshell, ${m}

                  [X-GNOME-Metatheme]
                  GtkTheme=${name}
                '';
              })
              (lib.nameValuePair "themes/${name}/gtk-3.0/gtk.css" { text = gtkThemeCss m; })
            ]) [ (gtkTheme m) (gtkTwin m) ]
          ) modes
        )
      );
  }
    # the include of each app in its config, where Home Manager has the program: the file is in the state folder
    # (the condition is inside, not on the list: which options are set must not depend on `enable`, which reads programs.<app>.enable)
    (lib.mkMerge (lib.mapAttrsToList (n: def: lib.mkIf cfg.targets.${n}.enable (def.wire "${stateDir}/${def.target}")) appDefs))
  ]);
}

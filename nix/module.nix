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

  flavour = builtins.fromJSON (builtins.readFile ../flavours/${cfg.theme.flavour}.json);
  modes = [
    "dark"
    "light"
  ];
  palettes = lib.genAttrs modes (m: flavour.${m} // cfg.theme.${m});
  files = lib.mapAttrs (_: import ./generators.nix) palettes;
  # The apps that follow the theme: each file of apps/ is one, see there. Enabled when Home Manager has the program enabled, or when the user says so
  appDefs = lib.mapAttrs' (n: _: lib.nameValuePair (lib.removeSuffix ".nix" n) (import ./apps/${n})) (
    lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nix" n) (builtins.readDir ./apps)
  );
  enabledApps = lib.filterAttrs (n: _: cfg.integration.apps.${n}.enable) appDefs;
  # The mode the apps have until the shell says its own: the files that the shell copies when the mode changes, see `nshell apps`.
  # Dark, unless the theme is light
  startMode = if cfg.theme.mode == "light" then "light" else "dark";
  stateDir = "${config.xdg.stateHome}/nix-quickshell";

  gtkTheme = m: "nix-quickshell-${m}";
  # The same theme under another name. Brave (Chromium) reads the colors of the GTK theme when its name changes, before GTK has loaded it, and
  # so it shows the mode before: the apps are told the name of the theme, and a moment later the name of its twin, which is when Brave
  # reads the theme that was loaded. See `nshell apps`
  gtkTwin = m: "nix-quickshell-${m}-twin";
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
    description = "Roles of the palette to change, by name, as in flavours/*.json. A color is #rrggbb, or #aarrggbb with alpha.";
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

  font = if cfg.theme.font != null then cfg.theme.font else "Route 159";
  fontSize = toString cfg.integration.fontSize;
  cursor = cfg.integration.cursor;
in
{
  # the apps are `integration.apps.<name>` now, each a file of apps/
  imports =
    let
      at = path: [ "programs" "nix-quickshell" "integration" ] ++ path;
    in
    (map (n: lib.mkRenamedOptionModule (at [ n "enable" ]) (at [ "apps" n "enable" ])) [
      "alacritty"
      "kitty"
      "xresources"
    ])
    ++ [
      (lib.mkRemovedOptionModule (at [ "zathura" "enable" ]) "zathura is an app like the others: `integration.apps.zathura.enable`, and the include of the file, which is no longer written for you, see the README")
      (lib.mkRemovedOptionModule (at [ "zathura" "extraConfig" ]) "write your own zathurarc, see the README")
    ];

  options.programs.nix-quickshell = {
    enable = mkEnableOption "the nix-quickshell desktop shell";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = "the package of this flake";
      description = "The shell.";
    };

    theme = {
      flavour = mkOption {
        type = types.enum [
          "nixos-navy"
          "nixos-graphite"
        ];
        default = "nixos-navy";
        description = "The flavour of the theme, a set of palettes of the package: nixos-navy is the blues of nixos.org, nixos-graphite is the same with greys.";
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

    integration = {
      fontSize = mkOption {
        type = types.ints.positive;
        default = 11;
        description = "The size of the text of the GTK apps and of zathura, in points. The shell has its own sizes.";
      };

      gtk = {
        enable = enableOption ''
          The look of the GTK apps: the settings (adw-gtk3 in the mode of the theme, the icons, the font), and gtk-3.0/gtk.css and
          gtk-4.0/gtk.css with the named colors of the palette, which adw-gtk3 and libadwaita read. Owns those files, and two GTK themes in ~/.local/share/themes: nix-quickshell-dark and nix-quickshell-light
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
          type = types.nullOr types.path;
          default = null;
          description = "An image of your own, set in both modes instead of the generated wallpapers.";
        };
      };

      detectApps = mkOption {
        type = types.bool;
        default = true;
        description = "Turn on the apps below that Home Manager has enabled as programs.<app>.enable. An `enable` of an app says what it says, whatever this is.";
      };
      apps = lib.mapAttrs (name: def: {
        enable = mkOption {
          type = types.bool;
          default = cfg.integration.detectApps && def.program != null && (config.programs.${def.program}.enable or false);
          defaultText = lib.literalMD "`programs.${name}.enable` when `detectApps` is on, otherwise false";
          description = "~/.config/nix-quickshell/apps/${name}-<mode>, the colors of ${name}, which `nshell apps` puts in the state folder as ${def.target}, and the include of it in the config of ${name} when Home Manager has it.";
        };
      }) appDefs;

      i3.enable = enableOption "~/.config/nix-quickshell/i3.conf, the colors of the tabs, for `include` in the config of i3";
    };
  };

  config = mkIf cfg.enable (lib.mkMerge [ {
    home.packages = [
      cfg.package
    ]
    ++ lib.optionals cfg.integration.gtk.enable [
      pkgs.adw-gtk3
      pkgs.xsettingsd
      cfg.integration.gtk.iconTheme.package
    ]
    ++ lib.optional cursor.enable cursor.package
    ++ lib.optional cfg.integration.wallpaper.enable pkgs.feh;

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
          flavour = cfg.theme.flavour;
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
          (lib.nameValuePair "nix-quickshell/xsettings-${m}.conf" { text = xsettings m (gtkTheme m); })
          (lib.nameValuePair "nix-quickshell/xsettings-${m}-twin.conf" { text = xsettings m (gtkTwin m); })
        ]) modes
      )
    )
    // lib.optionalAttrs cfg.integration.wallpaper.enable (
      lib.listToAttrs (
        map (
          m:
          lib.nameValuePair "nix-quickshell/wallpaper-${m}.png" {
            source = if cfg.integration.wallpaper.image != null then cfg.integration.wallpaper.image else wallpaper m;
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
      // lib.listToAttrs (map (m: lib.nameValuePair "nix-quickshell/apps/${name}-${m}" { text = def.colors palettes.${m}; }) modes)
    ) enabledApps
    // lib.optionalAttrs cfg.integration.i3.enable (
      lib.listToAttrs (map (m: lib.nameValuePair "nix-quickshell/i3-${m}.conf" { text = files.${m}.i3; }) modes)
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
    (lib.mkMerge (lib.mapAttrsToList (n: def: lib.mkIf cfg.integration.apps.${n}.enable (def.wire "${stateDir}/${def.target}")) appDefs))
  ]);
}

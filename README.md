# nix-quickshell

[![CI](https://github.com/nixos-contrib/nix-quickshell/actions/workflows/ci.yml/badge.svg)](https://github.com/nixos-contrib/nix-quickshell/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/nixos-contrib/nix-quickshell?include_prereleases)](https://github.com/nixos-contrib/nix-quickshell/releases/latest)
[![NixOS](https://img.shields.io/badge/NixOS-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![License](https://img.shields.io/badge/License-GPL--3.0--or--later-blue.svg)](LICENSE)

A desktop shell for NixOS on X11, written in QML for
[Quickshell](https://quickshell.org). The bar, the notifications, the
launcher, the volume pill and the polkit agent of an i3 session are one
process, in the palette, the typeface and the logo of NixOS. A home-manager
module makes the GTK apps, xterm, zathura, i3 and the wallpaper follow its
dark and light mode.

> [!WARNING]
> This project is a work in progress and has no release yet. Interfaces may
> change without notice.

## Why

There are many good shells for Quickshell, but most of them are for Wayland
compositors. This one is a modern look for **i3 on X11**: flat panels with a
hairline edge and a soft shadow, one palette, one typeface, and a bar that shows
the windows. It is made for working in **NixOS in a virtual machine on macOS**.
The VM has to follow the window it is in, and in our tests sway under Parallels
Desktop on Apple Silicon did not, so the display stayed the wrong size, and
swiping lagged. X11 and i3 do both, and a tiling window manager with tabs is
what the work needed. So the shell gives i3 the aesthetics that the Wayland
shells have, and it was built and tested in a VM of that kind. It is not tied to
one: it is an X11 shell, and runs wherever i3 does.

## Features

- **Notifications.** A server and toasts, with urgency, actions, markup, icons,
  a close button on hover, a stack with show more and clear all, and a history
  with do not disturb (`nshell center`). Do not disturb also mutes the sound
  effects of chat apps (Vesktop, Discord) while it is on, see
  `modules/notifications/QuietSound.qml`.
- **Bar.** The logo, the workspaces of i3, the tray (StatusNotifierItem) with
  menus in the style of the shell, the sound (volume, mute, outputs), the
  battery, the bell, with a dot when something came since the history was last
  opened, and the clock.
- **Windows in the bar.** After the number of every workspace, an icon for
  each of its windows (three at most, then +N), the one in front or with the
  focus lit, a title when the pointer stays on an icon, and a click takes the
  window to the front. Windows side by side are one group; a tabbed container of
  i3 is a group of its own with a chevron, which, or `nshell tabs list`, opens
  the list of its tabs with titles and a filter. The right button on an icon
  opens a menu (close, and move a tab left or right), a drag along a group of
  tabs moves the tab to where it is let go, and the wheel on a group goes from
  one window to the next. i3 draws nothing for its tabs, see
  [`docs/i3.md`](docs/i3.md).
- **Launcher.** Apps (ordered by how often they are run) and the windows of
  i3, Tab goes from one to the other (`nshell launcher`,
  `nshell launcher windows`). An app that has a window is focused and not
  started again, by the `StartupWMClass` of its desktop entry, also from a key:
  `nshell launch brave-browser`. `nshell pick` is the same list for scripts.
- **Volume OSD.** A pill at the bottom of the screen that shows the volume (or
  muted) for a moment when it changes, whatever changed it: the keys, the wheel
  on the bar, the slider, another app. It watches the sound, so there is no
  command for it. The keys are yours to bind, see [`docs/i3.md`](docs/i3.md).
- **Polkit agent.** A card for the touch of the key or the password, with its
  own layout for 1Password unlocking with the system.
- **Theme.** Two flavours, `nixos-navy` (the blues of nixos.org) and
  `nixos-graphite` (greys), each with a dark and a light mode. The bar is the
  color of the windows on dark, and a blue (a dark grey in graphite) with white
  text on light.
  `nshell theme [dark|light|auto|toggle]` changes it live. The palettes are
  data, see [Theme](#theme).

Not done yet: brightness (needs a screen with a backlight), and network and
Bluetooth in the bar.

## Try it

```sh
nix run github:nixos-contrib/nix-quickshell                    # the shell
nix run github:nixos-contrib/nix-quickshell -- center          # the history of the notifications
```

It needs i3 on X11 and a compositor such as picom. `QS_ICON_THEME` has to name
an installed icon theme, for the icons of the apps, and `I3SOCK` has to be set
when it runs outside i3. The windows of the toasts, the popups and the launcher
are floated by i3, see the rules in [`docs/i3.md`](docs/i3.md).

From a checkout, `NSHELL_PATH=. nshell` runs the shell, `bin/preview` sends one
of every kind of notification and `bin/preview burst` a pile of them.
`NSHELL_NO_BAR=1` runs it without the bar, to try the notifications beside
another one.

The launcher lists programs that run in a terminal (Helix, Yazi, bottom…) only
when `TERMINAL` is set in the session, to a terminal that takes `-e command`
(`xterm`, `alacritty`, `foot`…), and runs them in it. Without it they are not
listed, as they would have nowhere to open.

## Install

A flake input, and the home-manager module:

```nix
{
  inputs.nix-quickshell = {
    url = "github:nixos-contrib/nix-quickshell";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # in the configuration of home-manager
  imports = [ inputs.nix-quickshell.homeModules.default ];
  programs.nix-quickshell.enable = true;
}
```

The i3 that the tabs need has a small patch (the room above a tabbed container,
the gap inside tabs, and the tabs that are not in front unmapped). It is an
overlay, and it applies to the i3 of the pkgs that it is used with:

```nix
nixpkgs.overlays = [ inputs.nix-quickshell.overlays.i3 ];
```

`nix build .#i3` says if the patch still applies. Without it the shell works,
with a band of font height and 4 px above the tabbed containers. See
[`docs/i3.md`](docs/i3.md).

## Theme

The palettes are flavours, files of the package: `flavours/nixos-navy.json`
(the default) and `flavours/nixos-graphite.json`, each with the roles of a
`dark` and a `light` palette. `~/.config/nix-quickshell/theme.json`, or the
file of `NSHELL_THEME`, is read over it, and the shell reads both again when
they change:

```json
{
  "flavour": "nixos-navy",
  "mode": "dark",
  "font": "Route 159",
  "radius": 16,
  "hours": { "light": 7, "dark": 19 },
  "dark": { "primary": "#7ebae4" }
}
```

Every key is optional. `flavour` is `nixos-navy` or `nixos-graphite`. `mode` is
`dark`, `light` or `auto` (light from 07:00 to 19:00 by default; a choice of
`nshell theme` is kept in `~/.local/state/nix-quickshell/theme.json` and lasts
over it). `font` is the family: Route 159 by default, the typeface of NixOS,
which has to be installed (nixpkgs has it as `route159`). It has the Latin
letters and little more, so the module adds a fontconfig rule that makes
Inter (`theme.fallbackFont`) draw the rest. `radius` is the large one and the
other two follow it. `dark` and `light` name the roles to change.

### With Nix

The module writes that file from options, and what the apps that follow the
theme need:

```nix
programs.nix-quickshell = {
  enable = true;
  theme = {
    flavour = "nixos-navy";
    mode = "auto";
    font = "SF Pro Text";
    dark.primary = "#7ebae4";
  };
  integration = {
    gtk.enable = true;        # the settings and the colors of the GTK apps (adw-gtk3), GTK 3 and 4
    zathura.enable = true;    # zathurarc with the colors and the font
    alacritty.enable = true;  # the colors of Alacritty, which follow the mode live
    xresources.enable = true; # ~/.config/nix-quickshell/Xresources, for xrdb -merge
    i3.enable = true;         # ~/.config/nix-quickshell/i3.conf, the colors of the tabs, for include
    wallpaper.enable = true;  # the wallpaper of the theme, for each mode
  };
};
```

| Option | Writes | Yours to add |
|---|---|---|
| `integration.gtk` | two GTK themes in `~/.local/share/themes`, `nix-quickshell-dark` and `nix-quickshell-light` (adw-gtk3 with the named colors of the palette after it), each with a twin of the same look (`-twin`), `gtk-3.0/settings.ini` and `gtk-4.0/gtk.css`, and `xsettings-<mode>.conf` and its twin for xsettingsd | `gtk.menuImages` (icons in the menus, on), `gtk.extraCss` (layout rules that can use the colors, as `@window_bg_color`), `gtk.xsettings` (as `Xft/DPI`), `gtk.iconTheme` |
| `integration.zathura` | `zathura/zathurarc`, which includes the colors of the mode from the state folder, and the font | `zathura.extraConfig` |
| `integration.wallpaper` | `wallpaper-<mode>.png`, the surface color of the palette, a step off the bar, with the logomark of NixOS in the middle (white on dark, black on light), and `nshell apps` sets the one of the mode with feh | `wallpaper.image`, an image of your own for both modes |
| `integration.alacritty` | `alacritty-<mode>.toml`, the colors of Alacritty: the background, the foreground, the cursor, the selection and its sixteen colors | `general.import = ["~/.local/state/nix-quickshell/alacritty.toml"]` in the config of Alacritty, which reads it again when the mode changes |
| `integration.xresources` | `xresources-<mode>`, the colors of xterm and its sixteen: the hues of the NixOS palette, light on dark and darker on light | |
| `integration.i3` | `i3-<mode>.conf`, the colors of the tabs | `include ~/.local/state/nix-quickshell/i3.conf` in the config of i3 |
| `integration.cursor` | the cursor theme (capitaine-cursors, the arrow of macOS, by default): its package, `icons/default/index.theme`, the cursor of GTK and `Xresources`, and `session.sh` | `. ~/.config/nix-quickshell/session.sh` in the session, and `cursor.size`: 24 by default, 48 on a screen with twice the pixels |

`integration.fontSize` is the size of the text of GTK and zathura, 11 by
default.

### The apps follow the mode

The module writes the files of both modes into `~/.config/nix-quickshell`.
`nshell apps [dark|light]` copies the ones of a mode into
`~/.local/state/nix-quickshell` (where the configs of zathura and i3 include
them), and the shell runs it when it starts and each time the mode changes.
Then:

- **GTK 3 apps** change live: `xsettingsd` tells them the theme changed from
  `nix-quickshell-dark` to `nix-quickshell-light`, and 0.4 s later to its twin,
  which looks the same. Brave reads the colors of a theme when its name changes,
  before GTK has loaded it, so with one change it shows the mode before. Start
  it in the session after `nshell apps`:
  `xsettingsd -c ~/.local/state/nix-quickshell/xsettings.conf &`, and do not set
  `GTK_THEME`, which GTK puts before everything.
- **i3** reads its include again (`i3-msg reload`), so the tabs change.
- **The wallpaper** is set with feh.
- **Alacritty** reads its colors again when they change, so the open terminals follow.
- **xterm** and **zathura** take the colors when they start.

## Design

[`DESIGN.md`](DESIGN.md) is the design document: the principles, the decisions
with their reasons, the rules of the windows, the branding of NixOS that the
shell follows and where it deviates, the limits, and how it is tested.

## Development

```sh
nix develop                      # shellcheck, actionlint and jq
nix flake check -L               # builds the shell and the patched i3, checks the flavours
nix build .#i3                   # says if the patch of i3 still applies
nix develop --command shellcheck bin/nshell bin/preview
nix develop --command actionlint
```

To try a change, run a copy of the shell over the installed one with
`NSHELL_PATH=$PWD nshell`, with `XDG_STATE_HOME` and `NSHELL_THEME` pointing at
a scratch folder and file, so that the saved history and mode are not touched.
Use made-up values in tests and screenshots, and no real identifiers.

## Releasing

Releases are managed by
[release-please](https://github.com/googleapis/release-please) from
[Conventional Commits](https://www.conventionalcommits.org/). Every push to
`main` is checked, and release-please keeps a release PR open. Merging that PR
tags a release.

A weekly `chore(flake)` PR updates nixpkgs and merges automatically. These
updates don't trigger a release by themselves.

## License

[GPL-3.0-or-later](LICENSE). Parts are adapted from other projects, see
[`CREDITS.md`](CREDITS.md).

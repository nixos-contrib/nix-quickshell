# nix-shell

A small desktop shell for NixOS on X11, written in QML for [Quickshell](https://quickshell.org). It replaces the
notification daemon, the bar and the launcher of an i3 session with one process, in the palette of nixos.org.

It is a work in progress. So far:

- notifications: a server and toasts, with urgency, actions, markup, icons, a close button on hover, a stack with
  show more and clear all, and a history center with do not disturb (`nshell center`). Do not disturb also mutes the sound effects of chat apps
  (Vesktop, Discord) while it is on, see `modules/notifications/QuietSound.qml`

- bar: the logo, the workspaces of i3, the tray (StatusNotifierItem) with menus in the style of the shell, the sound (volume,
  mute, outputs), the battery, the bell, with a dot when something came since the history was last opened (its count is in the panel), and the clock

- polkit agent: a card for the touch of the key or the password, with its own layout for 1Password unlocking with the system

- launcher: apps (ordered by how often they are run) and the windows of i3, Tab goes from one to the other (`nshell launcher`,
  `nshell launcher windows`). An app that has a window is focused and not started again, by the `StartupWMClass` of its desktop
  entry, also from a key: `nshell launch brave-browser`

- windows in the bar: after the number of every workspace, an icon for each of its windows (three at most, then +N), the one in front or
  with the focus lit, a title when the pointer stays on an icon, and a click takes the window to the front. Windows side by side are one
  group; a tabbed container of i3 is a group of its own with a chevron, which, or `nshell tabs list`, opens the list of its tabs with
  titles and a filter; a line is between the groups. The right button on an icon opens a menu (close, and move a tab left or right), a drag
  along a group of tabs moves the tab to where it is let go, and the wheel on a group goes from one window to the next. i3 draws nothing for
  its tabs, see `docs/i3.md`

- volume OSD: a pill at the bottom of the screen that shows the volume (or muted) for a moment when it changes, whatever changed it:
  the keys, the wheel on the bar, the slider, another app. It watches the sound, so there is no command for it. The keys are
  yours to bind, see `docs/i3.md`

- theme: nixos-navy dark and a light mode from the same blues of nixos.org. `nshell theme [dark|light|auto|toggle]` changes it
  live, `auto` is light from 07:00 to 19:00, and the choice is kept in `~/.local/state/nix-shell/theme.json`. The palettes are data,
  see Theme below

Not done: brightness (needs a screen with a backlight), network and Bluetooth in the bar.

## Try it

```sh
nix run github:nixos-contrib/nix-shell      # the shell
nix run github:nixos-contrib/nix-shell -- center   # opens the history of the notifications
```

From a checkout, `NSHELL_PATH=. nshell`, and `bin/preview` sends one of every kind of notification, or `bin/preview burst` a pile
of them.

`NSHELL_NO_BAR=1` runs it without the bar, to try the notifications beside another one.

The launcher lists programs that run in a terminal (Helix, Yazi, bottom…) only when `TERMINAL` is set in the session, to a terminal that takes
`-e command` (`xterm`, `alacritty`, `foot`…), and runs them in it. Without it they are not listed, as they would have nowhere to open.

It needs `QS_ICON_THEME` set to an installed icon theme for the icons of the apps, and `I3SOCK` when it runs outside i3.
The window of the toasts is floated by i3, see the rules in `docs/i3.md`.

## Theme

The palettes are flavours, files of the package, `flavours/navy.json` (the default, the blues of nixos.org) and `flavours/graphite.json` (greys),
each with the roles of a `dark` and a `light` palette. `~/.config/nix-shell/theme.json`, or the file of `NSHELL_THEME`, is read over
it, and the shell reads both again when they change:

```json
{
  "flavour": "navy",
  "mode": "dark",
  "font": "Route 159",
  "radius": 16,
  "hours": { "light": 7, "dark": 19 },
  "dark": { "primary": "#7ebae4" }
}
```

Every key is optional: `flavour` is `navy` or `graphite`, `mode` is `dark`, `light` or `auto` (a choice of `nshell theme` lasts over
it), `font` is the family (Route 159 by default, the typeface of NixOS, which has to be installed: nixpkgs has it as `route159`; it has the Latin letters and little more, and the module adds a fontconfig rule that makes Inter, `theme.fallbackFont`, draw the rest), `radius` is the large one and the other two follow it, and
`dark` and `light` name the roles to change.

### With Nix

`homeModules.default` is a home-manager module that writes that file from options, and what the apps that follow the theme need:

```nix
programs.nix-shell = {
  enable = true;
  theme = {
    flavour = "navy";
    mode = "auto";
    font = "SF Pro Text";
    dark.primary = "#7ebae4";
  };
  integration = {
    gtk.enable = true;        # the settings and the colors of the GTK apps (adw-gtk3), GTK 3 and 4
    zathura.enable = true;    # zathurarc with the colors and the font
    xresources.enable = true; # ~/.config/nix-shell/Xresources, for xrdb -merge
    i3.enable = true;         # ~/.config/nix-shell/i3.conf, the colors of the tabs, for include
  };
};
```

| Option | Writes | Yours to add |
|---|---|---|
| `integration.gtk` | two GTK themes in `~/.local/share/themes`, `nix-shell-dark` and `nix-shell-light` (adw-gtk3 with the named colors of the palette after it), each with a twin of the same look (`-twin`), `gtk-3.0/settings.ini` and `gtk-4.0/gtk.css`, and `xsettings-<mode>.conf` and its twin for xsettingsd | `gtk.menuImages` (icons in the menus, on), `gtk.extraCss` (layout rules that can use the colors, as `@window_bg_color`), `gtk.xsettings` (as `Xft/DPI`), `gtk.iconTheme` |
| `integration.zathura` | `zathura/zathurarc`, which includes the colors of the mode from the state folder, and the font | `zathura.extraConfig` |
| `integration.xresources` | `xresources-<mode>`, the colors of xterm and its sixteen: the hues of the NixOS palette, light on dark and darker on light | |
| `integration.i3` | `i3-<mode>.conf`, the colors of the tabs | `include ~/.local/state/nix-shell/i3.conf` in the config of i3 |
| `integration.cursor` | the cursor theme (capitaine-cursors, the arrow of macOS, by default): its package, `icons/default/index.theme`, the cursor of GTK and `Xresources`, and `session.sh` | `. ~/.config/nix-shell/session.sh` in the session, and `cursor.size`: 24 by default, 48 on a screen with twice the pixels |

### The apps follow the mode

The module writes the files of both modes into `~/.config/nix-shell`. `nshell apps [dark|light]` copies the ones of a mode into
`~/.local/state/nix-shell` (where the configs of zathura and i3 include them), and the shell runs it when it starts and each time the
mode changes. Then:

- **GTK 3 apps** change live: `xsettingsd` tells them the theme changed from `nix-shell-dark` to `nix-shell-light`, and 0.4 s later to its twin, which looks the same: Brave reads the colors of a theme when its name changes, before GTK has loaded it, so with one change it shows the mode before. Start it in the
  session after `nshell apps`: `xsettingsd -c ~/.local/state/nix-shell/xsettings.conf &`, and do not set `GTK_THEME`, which GTK
  puts before everything.
- **i3** reads its include again (`i3-msg reload`), so the tabs change.
- **xterm** and **zathura** take the colors when they start.

`integration.fontSize` is the size of the text of GTK and zathura, 11 by default. 
## License

GPL-3.0-or-later. Parts are adapted from other shells, see `CREDITS.md` when it lists any.

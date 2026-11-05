# nix-shell

A small desktop shell for NixOS on X11, written in QML for [Quickshell](https://quickshell.org). It replaces the
notification daemon, the bar and the launcher of an i3 session with one process, in the palette of nixos.org.

It is a work in progress. So far:

- notifications: a server and toasts, with urgency, actions, markup, icons, a close button on hover, a stack with
  show more and clear all, and a history center with do not disturb (`nshell center`). Do not disturb also mutes the sound effects of chat apps
  (Vesktop, Discord) while it is on, see `modules/notifications/QuietSound.qml`

- bar: the logo, the workspaces of i3, the tray (StatusNotifierItem) with menus in the style of the shell, the sound (volume,
  mute, outputs), the battery, the bell with the count of the history, and the clock

- polkit agent: a card for the touch of the key or the password, with its own layout for 1Password unlocking with the system

- launcher: apps (ordered by how often they are run) and the windows of i3, Tab goes from one to the other (`nshell launcher`,
  `nshell launcher windows`). An app that has a window is focused and not started again, by the `StartupWMClass` of its desktop
  entry, also from a key: `nshell launch brave-browser`

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

The palettes are files of the package, `themes/navy.json` (the default, the blues of nixos.org) and `themes/graphite.json` (greys),
each with the roles of a `dark` and a `light` palette. `~/.config/nix-shell/theme.json`, or the file of `NSHELL_THEME`, is read over
it, and the shell reads both again when they change:

```json
{
  "variant": "navy",
  "mode": "dark",
  "font": "Inter",
  "radius": 16,
  "hours": { "light": 7, "dark": 19 },
  "dark": { "primary": "#7ebae4" }
}
```

Every key is optional: `variant` is `navy` or `graphite`, `mode` is `dark`, `light` or `auto` (a choice of `nshell theme` lasts over
it), `font` is the family (Inter by default, which has to be installed), `radius` is the large one and the other two follow it, and
`dark` and `light` name the roles to change.

### With Nix

`homeModules.default` is a home-manager module that writes that file from options, and the fragments of the apps that follow the theme:

```nix
programs.nix-shell = {
  enable = true;
  theme = {
    variant = "navy";
    mode = "auto";
    font = "SF Pro Text";
    dark.primary = "#7ebae4";
  };
  # each writes a file in ~/.config/nix-shell that the config of the app includes, so the rest of that config stays yours
  integration = { gtk = true; xresources = true; zathura = true; i3 = true; };
};
```

| Option | File | Include it with |
|---|---|---|
| `integration.gtk` | `gtk.css`, the named colors of adw-gtk3 and libadwaita | `@import url("file:///home/you/.config/nix-shell/gtk.css");` in `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css`, with the theme `adw-gtk3` or `adw-gtk3-dark` |
| `integration.xresources` | `Xresources`, the colors of xterm | `xrdb -merge ~/.config/nix-shell/Xresources` |
| `integration.zathura` | `zathurarc`, the colors of zathura | `include ~/.config/nix-shell/zathurarc` in zathurarc |
| `integration.i3` | `i3.conf`, the colors of the tabs | `include ~/.config/nix-shell/i3.conf` in the config of i3 |

The apps have the palette of the `mode` when it is `dark` or `light`, and the dark one when it is `auto`: they take their colors when
they start, and do not change with the shell.

## License

GPL-3.0-or-later. Parts are adapted from other shells, see `CREDITS.md` when it lists any.

# nix-shell

A small desktop shell for NixOS on X11, written in QML for [Quickshell](https://quickshell.org). It replaces the
notification daemon, the bar and the launcher of an i3 session with one process, in the palette of nixos.org.

It is a work in progress. So far:

- notifications: a server and toasts, with urgency, actions, markup, icons, a close button on hover, a stack with
  show more and clear all, and a history center with do not disturb (`bin/center`)

- bar: the logo, the workspaces of i3, the tray (StatusNotifierItem) with menus in the style of the shell, the bell with
  the count of the history, and the clock

Planned: polkit agent, launcher, volume OSD.

## Try it

```sh
nix shell nixpkgs#quickshell -c quickshell -p .
bin/preview   # sends one of every kind of notification
```

`NSHELL_NO_BAR=1` runs it without the bar, to try the notifications beside another one.

It needs `QS_ICON_THEME` set to an installed icon theme for the icons of the apps, and `I3SOCK` when it runs outside i3.
The window of the toasts is floated by i3, see the rules in `docs/i3.md`.

## License

GPL-3.0-or-later. Parts are adapted from other shells, see `CREDITS.md` when it lists any.

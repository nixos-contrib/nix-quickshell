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

## License

GPL-3.0-or-later. Parts are adapted from other shells, see `CREDITS.md` when it lists any.

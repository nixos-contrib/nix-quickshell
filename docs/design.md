# Design of the windows

Every window of the shell is a **panel**, built from the same parts in the same order, with the same text. Nothing has a size, a
color or a radius of its own: it all comes from `Theme.qml`.

## The panel (`modules/common/Panel.qml`)

| Part | Rule |
|---|---|
| Header | a title at the left, then a muted value or the buttons of the window at the right. Or a header of its own (the search field of the launcher) |
| Divider | one line under the header, and none other. A section inside the body is marked by its label, not by a line |
| Body | what the window is about. An empty state is centered in it |
| Footer | a hint, at the bottom left, small and muted |

The container is the dark `bg` for every window (the popups of the bar, the history, the launcher, the polkit card), with one
border, a radius of 18 and 16 of room around. A menu has less room, as its lines have their own, and a dialog more.

What a window holds are **cards** (the entries of the history, the toasts): `surface`, a radius of 14. What is selected or
pressed is `surfaceHigh`.

## The text (`modules/common/Label.qml`)

| Role | Used for | Style |
|---|---|---|
| heading | the search field, the title of a dialog | 17, bold |
| title | the header of a panel | 14, bold |
| body | rows and descriptions | 13 |
| caption | a value, a subtitle, a hint | 12, muted |
| label | a section, the name of the app of a card | 10, capitals, muted |

## Controls

- A **slider** and a **meter** (`Slider.qml`, `Meter.qml`) share the track: the same height and colors. A meter has no handle, as
  there is nothing to move. The battery and the sound have the same row: an icon in a slot, and a track.
- The **buttons** of a window are pills (`PillButton.qml`); the one that is on is filled.
- The items of the bar light up while they are pressed or their popup is open, never for the pointer over them.
- A **right click** on an item of the bar is its quick quiet toggle: on the bell it turns do not disturb on and off, on the speaker
  it mutes (a middle click does the same, but a trackpad has none). On an icon of the tray it is the menu of the app.

## The status area of the bar

Its items, the tray, the sound, the battery, the bell and the clock, are tiles with the same room inside, on each side of what they
hold (`Theme.tilePad`), and the same gap between them (`Theme.statusGap`), so the space between what is shown is the same all
along: 12 to 13 points between any two. Text has a little room of its own at its edges, which `Theme.textBearing` takes back, or a
tile of text would look further from its neighbour than a tile of an icon.

## Keys

The commands that a key can run (`nshell launcher`, `center`, `bar`) toggle, and a key that is held a moment repeats: the command
runs again and again, 25 ms apart, and the repeat would close what the first opened. The command itself catches it (`same_press` in
`bin/nshell`): a run less than 400 ms after the one before is the same press and ends at once, and every run counts as the one
before, so a key held for any time is one press. It has to be the command: starting the client of Quickshell takes long enough
for the runs to pile up and reach the shell in bursts, and a late one looked like a new press. The shell keeps a check of its
own for the commands that reach it by other ways.

## Windows

A window of the shell is drawn only when it is in its place: i3 shows a floating window in the middle of the screen and moves it a
moment later, and what is drawn in that moment is seen. The panels have no opacity until a short while after the move.

The popups close when they lose the focus, which they do on a click outside them, so the focus must not follow the pointer:
`focus_follows_mouse no` in the i3 config, see `docs/i3.md`.

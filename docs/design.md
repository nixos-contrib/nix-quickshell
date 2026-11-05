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

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
hairline border, the large radius, a shadow and 16 of room around. A menu has less room, as its lines have their own, and a dialog more.

What a window holds are **cards** (the entries of the history): `surface`, the medium radius. The toasts are cards that float, so
they have the large radius and a shadow. What is selected or pressed is `surfaceHigh`.

## Color and mode (`Theme.qml`)

Two palettes with the same roles, dark and light, and the roles follow `Theme.mode`, live. Dark is **nixos-navy**: the bar and the windows
in the blues of nixos.org (`#050b18` both, `#15213a` cards, `#28395f` for what is selected, `#87adfa` for what is active). Light is the
white of nixos.org with the same blue, darker so that it reads on white (`#3b5487`): `#ffffff` panels, `#e8effc` cards, `#cfdefd` for
what is selected. Text on both is above 7:1, and the edge is a hairline of white on dark and of black on light. Status colors are
the lighter step on dark and the darker step on light.

`textOnPrimary` is the text on a fill of `primary` (the active button), and `textOnAccent` the text on a fill of `accent` (a pressed
button). The names do not start with `on`: QML reads such a property as a signal handler, and it was always black. `modules/theme/Appearance.qml` holds the choice, dark, light or auto, and sets the mode.

## Branding (NixOS/branding)

The look follows the branding of NixOS, [NixOS/branding](https://github.com/NixOS/branding) (its guide is `nixos-branding-guide.typ`, its
palette `nixos-color-palette/colors.toml`, in OKLCH), and where it does not, the reason is here. Checked on 2026-11-06.

**Color.** Every color of both flavours (`flavours/navy.json`, `flavours/graphite.json`, dark and light) is a color or a tint of the palette,
converted from OKLCH, with one exception below. The neutrals are the greys and the tints of Afghani Blue (NixOS Dark Blue, `#4d6fb7` is
the hex that the palette file gives for it), the status colors are the tints of Zambian Green, Persian Orange and Norwegian Pink, and the
terminal colors are the tints of the accents. The guide says the primary colors (black, white, greys) are for text, backgrounds and
borders, the blues for headers, icons and navigation, and the accents for emphasis, sparingly. Navy has tinted backgrounds, which the guide
allows as tints "for layering and different themes"; graphite is the reading with grey backgrounds.

**Logo.** The bar has the official logomark, `assets/nixos-logomark-white-flat.svg` on dark and `nixos-logomark-black-flat.svg` on light,
made with `nixoslogo` from the branding repo and not changed or painted in another color: the guide has the black and white logomarks
flat. It is 24 px high, the least for a screen, with a quarter of its height of clear space around it, the least that the guide asks
for, so there is no fill behind it. The credit is in `CREDITS.md` (the guide asks for it in the TASL form).

**Typeface.** Route 159, `Theme.font`, installed from nixpkgs as `route159` (OFL-1.1). The guide has Regular as the standard weight, Light
for secondary uses and Bold reserved: the shell uses Regular and SemiBold, and no Medium or Bold.

**Shape.** The corners are rounded, as the website of NixOS has them: the guide gives no rules for the shape of a window or a control, so the
website is the reference. The large radius is 16 and the others follow it (`radius` in the theme). Tried at 8 and at 0 on 2026-11-06: the
panels and the selected row look flat and technical, which is not the look of nixos.org, and a square look is one `radius` away, and
the corner radius of picom for the windows.

**Deviations, on purpose**
- `light.surfaceHigh` is `#cfdefd`, an L90 tint of Afghani Blue, which the ladder (L95, L85, ...) does not have. L95 is the same as `surface`,
  and L85 (`#b7cefd`) makes the lit tile of the light bar a strong blue.
- SemiBold for titles and labels, which the guide does not name, to keep the hierarchy that the weights gave.
- Light is not used at small sizes: it was not tried below 14 and may be too thin on dark.
- Route 159 has the Latin letters and little more (no Cyrillic, no Greek, no arrows, half of the punctuation): a fontconfig rule makes Inter
  draw the rest, see `theme.fallbackFont` in the module.

## Shape and depth (`Theme.qml`)

- **Radius.** Three, from one: large (16) for what floats, medium (10) for rows, buttons and the cards inside a panel, small (6)
  for the tiles of the bar, chips and tracks. The inside is smaller than the outside, so that the corners nest.
- **Edge.** A hairline of white at 10 percent, the same on every surface and wallpaper.
- **Shadow.** Two elevations: 1 for what hangs from the bar (popups, toasts), 2 for what comes to the middle of the screen
  (launcher, polkit, OSD). `Panel` and the toasts draw it (`modules/common/Shadow.qml`).
- **Room for the shadow.** Every window of the shell is a transparent window with the card in it, so the window is bigger than the
  card by `marginLow` or `marginHigh`. The shape of the window (`mask`) is the card and that room: it is also the shape that is
  drawn, so a shadow outside of it would be cut. The cost is a dead ring of that width around a card, where a click does not go to
  the window under it. The windows that hang from the bar start under it, so that the ring never covers an item of the bar.

## Popups close on a click anywhere

A popup (the ones of the bar, the history, the launcher) closes when it loses the focus, which is a click on an app, and also on:
- **the wallpaper**, or any place where no window is: `modules/common/ClickAway.qml` listens to the raw presses of the buttons of X
  (`xinput`) while a popup is open, and asks what is under the pointer (`xdotool`). A window of the shell, or the strip of the bar,
  is not outside; anything else is, and the click goes on to what it was on.
- **another item of the bar**: it closes this popup and opens its own. **The bar where no item is**: it closes it.
- **a change of workspace**, from its number or from a key: the popups are on every workspace.

## The text (`modules/common/Label.qml`)

| Role | Used for | Style |
|---|---|---|
| heading | the search field, the title of a dialog | 17, semibold |
| title | the header of a panel | 14, semibold |
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

## Closing on a loss of focus

The launcher, the popups and the history close when they lose the focus, which is a click outside them. But a window also reports
a loss of focus when a key grab starts, as i3 does while a key that it binds is held: X sends a FocusOut with the mode
NotifyGrab, Qt gives it to QML as a loss of focus, and the window closed in the middle of a held Mod+Shift+d. So a loss is checked
with i3 (`FocusGuard`): if i3 still has the focus on the window it was a grab, and only a click that moved the focus closes it.


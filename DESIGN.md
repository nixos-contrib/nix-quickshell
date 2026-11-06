# Design

Why the shell is the way it is. The other documents say what it is and how it works:

- `README.md`: what exists, how to install and configure it.
- `docs/i3.md`: what the shell needs from i3 and from picom, with the configuration to copy.

This is the one design document: the principles, the decisions with their reasons and the roads not taken, the rules of the windows,
the limits and what was learned. It is changed in the same commit as what it describes. The numbers (sizes, radii, colors) are in
`Theme.qml` and `flavours/*.json`, and are not repeated here, so that they cannot drift. A decision that is reversed gets a new row,
with its date, and the old one is not rewritten.

## What it is for

One process that replaces the notification daemon, the bar, the launcher and the polkit agent of an i3 session on X11, with one look:
the palette, the typeface and the logo of NixOS. It is for a developer desktop where windows are tiled and tabbed, the keyboard is the
main input, and the screen is mostly the windows. The shell is the frame around them and stays quiet.

It is private and not released: there are no tags. The system that uses it pins a commit in its `flake.lock`.

## Principles

1. **One process, one set of tokens.** Nothing in the shell has a size, a color or a radius of its own: it all comes from `Theme.qml`.
   A window is a panel with the same parts in the same order (the rules of the windows, below).
2. **The theme is data.** A flavour (`flavours/*.json`) has the roles of a dark and a light palette. A user file and the home-manager
   module change roles, not code. The apps that are not the shell (GTK, zathura, xterm, i3, the wallpaper) are written from the same
   palette and follow the mode live.
3. **Branding first, but not strictly.** The palette, the logomark and the typeface are the ones of NixOS, from NixOS/branding. Where the
   shell leaves the guide, the reason is written (Branding, below). The guide has no rules for UI shape or density, so those
   follow nixos.org and good practice.
4. **Quiet.** The background recedes and the content leads. No counts where a dot says enough, no color for decoration, no motion that
   does not explain something. A control has the weight of its neighbours: the logo in the bar is a button, not a billboard.
5. **Ask i3, do not replace it.** The shell reads the tree of i3 and runs its commands (`con_id` criteria). What i3 cannot do, the shell
   draws. What has to change inside i3 is a small patch (`nix/patches/i3.patch`), not a rewrite.
6. **Reliable over clever.** A trick that flashes, polls or guesses is a cost: the swap of the location bar of Thunar to refresh an icon
   was removed because it flashed. Where X sends no event (i3 does not for a layout change), the tree is read again every second, and the
   shell repairs what it can detect (a bar that lost its place as a dock is shown again).
7. **Declarative and overridable.** The system that uses the shell relies on its defaults, and says what it changes and why. The
   shell carries no font and no icons; it names them, and the system installs them.

## The parts

| Part | Where | What it does |
|---|---|---|
| Bar | `modules/bar` | the logo, the workspaces with their windows, the tray, the sound, the battery, the bell, the clock, and the popups that hang from them |
| Windows in the bar | `modules/tabs`, `modules/bar/Workspaces.qml` | an icon per window after the number of its workspace, a group per tabbed container, its list, a menu, a drag, the wheel |
| Notifications | `modules/notifications` | the server, the toasts, the history, do not disturb, the quiet sound of chat apps |
| Launcher | `modules/launcher` | apps and windows, `nshell pick` for scripts |
| OSD, polkit | `modules/osd`, `modules/polkit` | the volume pill, the card for the key or the password |
| Theme | `Theme.qml`, `modules/theme` | the tokens, the mode (dark, light, auto), the files of the apps |
| `nshell` | `bin/nshell` | the commands: the IPC of the shell, `apps` (the files of a mode into place), `theme`, `tabs list` |
| Nix | `nix/`, `flake.nix` | the home-manager module, the generators, the i3 patch as an overlay, the packages |

Files: the module writes both modes into `~/.config/nix-quickshell`; `nshell apps` copies the ones of the current mode into the state folder
(`~/.local/state/nix-quickshell`), which the configs of the apps include. The mode is saved there, and is only changed by `nshell theme`.

## Decisions

| Decision | Why | What was tried or rejected |
|---|---|---|
| i3 on X11 stays | the work uses nested containers and tabs; a VM on a Mac host needs the display to follow the window | sway with another shell: it ran, but the display did not follow the host window and swiping lagged. Other window managers are not on the table |
| An own shell | one look, and no patches to a bar or a notification daemon | dunst, i3bar, a rofi notification center, rofi and polkit-gnome, all replaced |
| No generated theming framework | plain dotfiles shared between machines, and generated configs clash with them | Stylix, twice |
| GTK base is adw-gtk3 | it takes the palette through named colors (`@window_bg_color`), the same names libadwaita reads, so GTK 3 and 4 match | Qogir, Fluent, WhiteSur: install-time color variants, built from SCSS, no runtime palette, GTK 4 only by a link |
| Tabs in the bar | no overlay windows: no flicker, no glitches over apps that draw their own corners, no drift after a screen change, nothing reserved | strips over the windows, three looks (flush, card, attached); stacked layout was dropped as redundant |
| Windows of every workspace in the bar, not only the tabbed | the bar answers one question the same way everywhere: what is on this workspace | icons only for tabs: a workspace with a split looked empty |
| A group per tabbed container | two stacks side by side are two things | one group per workspace |
| Dot, not count | the history is not "unread"; the bell has a dot for what came since it was opened, a window has a red dot when i3 marks it urgent | a count on the bell and a count on each icon: noisy, and wrong as soon as the history holds old entries |
| Rounded corners, large radius 16 | the website of NixOS has them | 8 and 0 were tried: more technical, less like nixos.org |
| Route 159, Regular and SemiBold, Inter for what it lacks | it is the typeface of NixOS; it has the Latin letters and little more, so a fontconfig rule adds Inter | Inter alone; Bold is reserved by the guide, Light was not used at small sizes |
| The official logomark, 18 points in the bar | it is flat white or black, as the guide asks, with its clear space and no fill behind it | the older snowflake of nixos-artwork, painted in the text color; 24 points was too big for a bar |
| Wallpaper: the `surface` color, the logomark at 12% of the height | a step off the bar, so the bar reads as a strip; quiet behind windows | the color of the bar (the bar dissolved), `surfaceHigh` (heavier), a bright blue (inverts the hierarchy), the nixos.org line pattern (cropped art, unknown license), the archived nixos-artwork wallpapers |
| No clipboard history | a password manager and the clipboard sync of the Mac would be recorded | |
| App icons, no thumbnails, in the lists | enough to tell windows apart, and cheap | thumbnails: heavy, and not needed in the first version |
| 2026-11-06: the design pass is done | the tokens, the radius scale, the hairline edge and the shadows, a navy flavour as the default and a graphite one, `theme.json` over the flavour, and the home-manager module that writes the files of the apps | |
| 2026-11-06: fields, the hover of a row and tips of GTK apps are tints of the palette | adw-gtk3 draws them as a veil of the text color (`alpha(currentColor, 0.1)`), which is grey on white and almost grey on the navy, and no named color changes it; the shell uses the `surface` role for its own fields and cards, so GTK does too | leaving the veils: a grey address field in a blue theme |
| The mode is only written by `nshell theme` | the saved choice survives restarts and deploys | |
| Brave gets the theme twice | Brave reads the colors of a GTK theme when its name changes, before GTK has loaded it, and so shows the mode before | one change; nudging other settings did nothing |

## The rules of the windows

### The panel (`modules/common/Panel.qml`)

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

### Color and mode (`Theme.qml`, `flavours/`)

Two palettes with the same roles, dark and light, and the roles follow `Theme.mode`, live. Dark is **nixos-navy**: the bar and the windows
in the blues of nixos.org. Light is the white of nixos.org with the same blue, darker so that it reads on white. Text on both is above
7:1, the edge is a hairline of white on dark and of black on light, and the status colors are the lighter step on dark and the darker
step on light. The values are in `flavours/*.json`, and not repeated here.

`textOnPrimary` is the text on a fill of `primary` (the active button), and `textOnAccent` the text on a fill of `accent` (a pressed
button). The names do not start with `on`: QML reads such a property as a signal handler, and it was always black. `modules/theme/Appearance.qml` holds the choice, dark, light or auto, and sets the mode.

### Branding (NixOS/branding)

The look follows the branding of NixOS, [NixOS/branding](https://github.com/NixOS/branding) (its guide is `nixos-branding-guide.typ`, its
palette `nixos-color-palette/colors.toml`, in OKLCH), and where it does not, the reason is here. Checked on 2026-11-06.

**Color.** Every color of both flavours (`flavours/nixos-navy.json`, `flavours/nixos-graphite.json`, dark and light) is a color or a tint of the palette,
converted from OKLCH, with one exception below. The neutrals are the greys and the tints of Afghani Blue (NixOS Dark Blue, `#4d6fb7` is
the hex that the palette file gives for it), the status colors are the tints of Zambian Green, Persian Orange and Norwegian Pink, and the
terminal colors are the tints of the accents. The guide says the primary colors (black, white, greys) are for text, backgrounds and
borders, the blues for headers, icons and navigation, and the accents for emphasis, sparingly. Navy has tinted backgrounds, which the guide
allows as tints "for layering and different themes"; nixos-graphite is the reading with grey backgrounds.

**Logo.** The bar has the official logomark, `assets/nixos-logomark-white-flat.svg` on dark and `nixos-logomark-black-flat.svg` on light,
made with `nixoslogo` from the branding repo and not changed or painted in another color: the guide has the black and white logomarks
flat. It is 20 points high, the size of the other icons of the bar, which is 40 pixels on this screen: the guide has 24 px as the least for
a screen, which is read in the pixels of the screen and not in points (it was 24 points, and too big for a bar). A quarter of its height is
free around it, the least that the guide asks for, so there is no fill behind it. The credit is in `CREDITS.md` (the guide asks for it in the TASL form).

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

### Shape and depth (`Theme.qml`)

- **Radius.** Three, from one (`radius`): large for what floats, medium for rows, buttons and the cards inside a panel, small for the
  tiles of the bar, chips and tracks. The inside is smaller than the outside, so that the corners nest. The values are in `Theme.qml`.
- **Edge.** A hairline of white at 10 percent, the same on every surface and wallpaper.
- **Shadow.** Two elevations: 1 for what hangs from the bar (popups, toasts), 2 for what comes to the middle of the screen
  (launcher, polkit, OSD). `Panel` and the toasts draw it (`modules/common/Shadow.qml`).
- **Room for the shadow.** Every window of the shell is a transparent window with the card in it, so the window is bigger than the
  card by `marginLow` or `marginHigh`. The shape of the window (`mask`) is the card and that room: it is also the shape that is
  drawn, so a shadow outside of it would be cut. The cost is a dead ring of that width around a card, where a click does not go to
  the window under it. The windows that hang from the bar start under it, so that the ring never covers an item of the bar.

### Popups close on a click anywhere

A popup (the ones of the bar, the history, the launcher) closes when it loses the focus, which is a click on an app, and also on:
- **the wallpaper**, or any place where no window is: `modules/common/ClickAway.qml` listens to the raw presses of the buttons of X
  (`xinput`) while a popup is open, and asks what is under the pointer (`xdotool`). A window of the shell, or the strip of the bar,
  is not outside; anything else is, and the click goes on to what it was on.
- **another item of the bar**: it closes this popup and opens its own. **The bar where no item is**: it closes it.
- **a change of workspace**, from its number or from a key: the popups are on every workspace.

### The text (`modules/common/Label.qml`)

| Role | Used for | Style (the sizes are in `Theme.qml`) |
|---|---|---|
| heading | the search field, the title of a dialog | the largest, semibold |
| title | the header of a panel | semibold |
| body | rows and descriptions | regular |
| caption | a value, a subtitle, a hint | small, muted |
| label | a section, the name of the app of a card | the smallest, capitals, muted |

### Controls

- A **slider** and a **meter** (`Slider.qml`, `Meter.qml`) share the track: the same height and colors. A meter has no handle, as
  there is nothing to move. The battery and the sound have the same row: an icon in a slot, and a track.
- The **buttons** of a window are pills (`PillButton.qml`); the one that is on is filled.
- The items of the bar light up while they are pressed or their popup is open, never for the pointer over them.
- A **right click** on an item of the bar is its quick quiet toggle: on the bell it turns do not disturb on and off, on the speaker
  it mutes (a middle click does the same, but a trackpad has none). On an icon of the tray it is the menu of the app.

### The status area of the bar

Its items, the tray, the sound, the battery, the bell and the clock, are tiles with the same room inside, on each side of what they
hold (`Theme.tilePad`), and the same gap between them (`Theme.statusGap`), so the space between what is shown is the same all
along: 12 to 13 points between any two. Text has a little room of its own at its edges, which `Theme.textBearing` takes back, or a
tile of text would look further from its neighbour than a tile of an icon.

### Keys

The commands that a key can run (`nshell launcher`, `center`, `bar`) toggle, and a key that is held a moment repeats: the command
runs again and again, 25 ms apart, and the repeat would close what the first opened. The command itself catches it (`same_press` in
`bin/nshell`): a run less than 400 ms after the one before is the same press and ends at once, and every run counts as the one
before, so a key held for any time is one press. It has to be the command: starting the client of Quickshell takes long enough
for the runs to pile up and reach the shell in bursts, and a late one looked like a new press. The shell keeps a check of its
own for the commands that reach it by other ways.

### Windows

A window of the shell is drawn only when it is in its place: i3 shows a floating window in the middle of the screen and moves it a
moment later, and what is drawn in that moment is seen. The panels have no opacity until a short while after the move.

The popups close when they lose the focus, which they do on a click outside them, so the focus must not follow the pointer:
`focus_follows_mouse no` in the i3 config, see `docs/i3.md`.

### Closing on a loss of focus

The launcher, the popups and the history close when they lose the focus, which is a click outside them. But a window also reports
a loss of focus when a key grab starts, as i3 does while a key that it binds is held: X sends a FocusOut with the mode
NotifyGrab, Qt gives it to QML as a loss of focus, and the window closed in the middle of a held Mod+Shift+d. So a loss is checked
with i3 (`FocusGuard`): if i3 still has the focus on the window it was a grab, and only a click that moved the focus closes it.

## What the shell needs from i3

In short: transparent colors for the tabs with no title and no icon, 2 points of room above a tabbed container, the gap inside tabs,
the other tabs unmapped when the one in front is a split, `focus_follows_mouse no`, and rules for its floating windows. The patch is
exported as `overlays.i3` and checked by `nix build .#i3`. See `docs/i3.md`.

## Limits

- Network, Bluetooth and brightness are not built: they need real hardware, and a VM cannot test them.
- A second monitor and a fullscreen app that goes fullscreen by itself were not tried. A window made fullscreen with i3 was: the layout
  comes back exactly.
- A toast and the volume OSD are not shown over a fullscreen window, as i3 hides floating windows that do not belong to it. The history
  still has the notification. `popup_during_fullscreen all` would show them, and every other popup too.
- After a change of the mode, the small icon in the location bar of an open Thunar keeps the one of the other mode until it goes to
  another folder. GTK does not draw it again, and the only way to force it flashed.
- Route 159 Light was not tried at small sizes.
- It is X11 only.

## Lessons

- A QML property that starts with `on` is read as a signal handler: `textOnPrimary`, not `onPrimary`.
- The `mask` of a Quickshell window also clips what is drawn, so a shadow needs room inside the mask.
- Hot reload leaves the IPC "not ready": restart the shell.
- A window of the shell that is not a dock takes the focus unless i3 is told not to; a `PopupWindow` works for a tooltip and takes none.
- i3 keeps the windows of hidden tabs mapped under the one in front. A split in front shows them through its gaps.
- `deco_rect` of i3 is not in the same coordinates in x and in y: use the rectangle of the container. The rectangles of a workspace that is
  not in view are stale.
- A drag in a model that is rebuilt on every change ends in the middle of it: keep the delegates (`ScriptModel` with `objectProp`).
- adw-gtk3 takes the palette through named colors, but some states are `alpha(currentColor, x)`: those need a rule of their own (`nix/generators.nix`).
- A key that is held repeats the command: `nshell` catches a run less than 400 ms after the one before, so scripts need a pause between
  two `nshell theme` calls.
- A loss of focus is also reported when a key grab starts: ask i3 before closing a window (`FocusGuard`).
- `i3-msg restart` drops the dock registration of the bar: restart the shell after it.

## How it is tested

- A copy of the shell runs with `NSHELL_PATH` over the one that is installed, with a private state folder (`XDG_STATE_HOME`) and its
  own theme file (`NSHELL_THEME`), so that the real history and the real mode are not touched.
- Screenshots of the screen, cropped to what is being judged. A screenshot of a real window shows its content, so tests use windows of
  their own, with made-up titles, and close them by id.
- A before and after of the rectangles of the windows, taken with their workspace in view, when anything touches the layout.
- A second X server with a real i3 (`Xephyr`) for layout work. It has no compositor, so transparent windows look black there.
- Scripts are files: `pkill -f` in a command line matches the command line itself.

## Rules

- No secrets or real identifiers in code, tests, fixtures, commits or documents: made-up values only.
- The colors and the tabs of i3 come from the file that the module writes, never by hand.
- Anything taken from another project is credited in `CREDITS.md`, in the form that its license asks for.

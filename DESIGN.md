# Design

Why the shell is the way it is. The other documents say what it is and how it works:

- `README.md`: what exists, how to install and configure it.
- `docs/i3.md`: what the shell needs from i3 and from picom, with the configuration to copy.

This is the one design document: the principles, the decisions with their reasons and the roads not taken, the rules of the windows,
the limits and what was learned. It is changed in the same commit as what it describes. The numbers (sizes, radii, colors) are in
`Theme.qml` and `themes/*.json`, and are not repeated here, so that they cannot drift. A decision that is reversed gets a new row,
with its date, and the old one is not rewritten.

## What it is for

One process that replaces the notification daemon, the bar, the launcher and the polkit agent of an i3 session on X11, with one look:
the palette, the typeface and the logo of NixOS. It is for a developer desktop where windows are tiled and tabbed, the keyboard is the
main input, and the screen is mostly the windows. The shell is the frame around them and stays quiet.

The aim is modern aesthetics for i3, and a desktop that works well in a virtual machine on macOS. There are many shells for Wayland, but in
our tests Wayland under Parallels Desktop on Apple Silicon did not let the display follow the window of the VM, so the shell stays on X11
and i3. It is not tied to a VM: it is an X11 shell.

It is a work in progress and has no release yet: release-please keeps the pull request for 0.0.1 open until the shell is stable, and
merging it is what tags the first release. The system that uses it pins a commit in its `flake.lock`.

## Principles

1. **One process, one set of tokens.** Nothing in the shell has a size, a color or a radius of its own: it all comes from `Theme.qml`.
   A window is a panel with the same parts in the same order (the rules of the windows, below).
2. **The theme is data.** A theme (`themes/*.json`) has the roles of a dark and a light palette. A user file and the home-manager
   module change roles, not code. The desktop that is not the shell (GTK, the wallpaper) is written from the same palette and follows
   the mode live. The apps with their own colors (i3, kitty, Alacritty, xterm, zathura) are a file each in `nix/apps/`, off unless asked for or
   found as a Home Manager program, so that a theme of your own is never overruled.
3. **Branding first, but not strictly.** The palette, the logomark and the typeface are the ones of NixOS, from NixOS/branding. Where the
   shell leaves the guide, the reason is written (Branding, below). The guide has no rules for UI shape or density, so those
   follow nixos.org and good practice.
4. **Quiet.** The background recedes and the content leads. No counts where a dot says enough, no color for decoration, no motion that
   does not explain something. A control has the weight of its neighbours: the logo in the bar is a button, not a billboard.
5. **Ask i3, do not replace it.** The shell reads the tree of i3 and runs its commands (`con_id` criteria). What i3 cannot do, the shell
   draws. What has to change inside i3 is a small patch (`nix/apps/i3.patch`), not a rewrite.
6. **Reliable over clever.** A trick that flashes, polls or guesses is a cost: the swap of the location bar of Thunar to refresh an icon
   was removed because it flashed. Where X sends no event (i3 does not for a layout change), the tree is read again every second, and the
   shell repairs what it can detect (a bar that lost its place as a dock is shown again).
7. **Declarative and overridable.** The system that uses the shell relies on its defaults, and says what it changes and why. The
   shell carries no font and no icons; it names them, and the system installs them.

## The parts

| Part | Where | What it does |
|---|---|---|
| Bar | `modules/bar` | the logo and its menu, the workspaces with their windows, the tray, the player, the sound, the battery, the bell, the clock with its calendar, and the popups that hang from them |
| Windows in the bar | `modules/tabs`, `modules/bar/Workspaces.qml` | an icon per window after the number of its workspace, a group per tabbed container, its list, a menu, a drag, the wheel |
| Notifications | `modules/notifications` | the server, the toasts, the groups, the progress, the history, do not disturb, the quiet sound of chat apps |
| Launcher | `modules/launcher` | apps and windows, `nshell pick` for scripts |
| Session, media | `modules/session`, `modules/common/Media.qml` | the card in the middle of the screen for the session and for About, and the players that speak MPRIS |
| OSD, polkit | `modules/osd`, `modules/polkit` | the volume pill, the card for the key or the password |
| Theme | `Theme.qml`, `modules/theme` | the tokens, the mode (dark, light, auto), the files of the apps |
| `nshell` | `bin/nshell` | the commands: the IPC of the shell, `apps` (the files of a mode into place), `theme`, `tabs list` |
| Nix | `nix/`, `flake.nix` | the home-manager module, the GTK theme, the apps that follow the theme (the colors of i3 and its patch among them), the i3 patch as an overlay, the packages |

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
| A group of more than five windows is its front icon and a chevron; no `+N`, no badge on a split | the only numbers of the bar are the names of the workspaces; the list has the titles and the filter, the tip says how many, and the chevron is the one sign of "more" for tabs and for a collapsed group | `+N` after three icons and a count on a split tab (noise, heavy); a bar that scrolls sideways (hidden state, the focused workspace can be off screen, the wheel is the one of the group); a width budget (the layout moves as windows come and go); a floating button over the window (an overlay on the content, which the tabs dropped for good reasons) |
| The list of a group hangs from the left edge of the number of its workspace | a menu lines up with its item, and a list centred on the chevron had no edge to line up with (it moved as icons came and went, and was pushed when near the screen's edge); the number is the owner of the windows, and every list of a workspace opens at one place | centred on the chevron (the old one), its left edge at the chevron (closest to the pointer, but it moves with the icons) |
| What is selected is `surfaceHigh` in every list, in the shell and in the GTK apps; fields have the hairline of a card | the lit tile of the bar, the row of the tab list and the selected row of Thunar are one color, and the text stays the text color, which reads on both modes. The accent is for what is active or can be pressed. The wallpaper is the `surface` color, so a field of the same color without an edge looked like a hole in the window | the accent for a selected row (adw-gtk3 draws the sidebar with a veil of it and Thunar draws its list with it solid, two looks in one window; loud on a long list), another color for fields (heavier than the rest of the shell) |
| The left of the bar has tighter gaps (2 pt inside a workspace, 4 pt between workspaces) than the right (4 pt between the status items) | proximity: a number and its icons are one thing, so they are closer than two workspaces are; the status items are independent controls and have one even gap. The edges (`Theme.edge`, 20 pt) and the centring are the same on both sides, which was measured: 50 and 49 px at twice the pixels, all items within 1.5 px of the centre | one gap for the whole bar (the number drifts from its icons) |
| Dot, not count | the history is not "unread"; the bell has a dot for what came since it was opened, a window has a red dot when i3 marks it urgent | a count on the bell and a count on each icon: noisy, and wrong as soon as the history holds old entries |
| Rounded corners, large radius 16 | the website of NixOS has them | 8 and 0 were tried: more technical, less like nixos.org |
| Route 159, Regular and SemiBold, Inter for what it lacks | it is the typeface of NixOS; it has the Latin letters and little more, so a fontconfig rule adds Inter | Inter alone; Bold is reserved by the guide, Light was not used at small sizes |
| Light mode: a blue bar (`#3b5487`, the primary blue of the palette) with white text, over white windows and a pale blue wallpaper; in graphite a dark grey | the guide has the blues for headers and navigation bars, and the bar is the anchor of the screen: a white bar on white windows had nothing to hold it. It is the same shape as dark, a coloured strip over a quiet surface | the white bar (blends into the windows, the only part of the light desktop with no colour), a near black bar (`#050b18`: the most contrast, but it looks like dark mode with a white window under it, and is heavy) |
| The official logomark, 18 points in the bar | it is flat white or black, as the guide asks, with its clear space and no fill behind it | the older snowflake of nixos-artwork, painted in the text color; 24 points was too big for a bar |
| Wallpaper: the `surface` color, the logomark with the gradient at 12% of the height, the same on both modes | a step off the bar, so the bar reads as a strip; quiet behind windows; the bar has the small flat mark and the wallpaper has the brand one, in its own colors, from one file | the flat white and black marks (the same as the bar, and two files), the lockups with the wordmark, vertical and horizontal (the name twice, and heavier), | the color of the bar (the bar dissolved), `surfaceHigh` (heavier), a bright blue (inverts the hierarchy), the nixos.org line pattern (cropped art, unknown license), the archived nixos-artwork wallpapers |
| No clipboard history | a password manager and the clipboard sync of the Mac would be recorded | |
| App icons, no thumbnails, in the lists | enough to tell windows apart, and cheap | thumbnails: heavy, and not needed in the first version |
| 2026-11-06: the design pass is done | the tokens, the radius scale, the hairline edge and the shadows, a navy theme as the default and a graphite one, `theme.json` over the theme, and the home-manager module that writes the files of the apps | |
| 2026-11-06: fields, the hover of a row and tips of GTK apps are tints of the palette | adw-gtk3 draws them as a veil of the text color (`alpha(currentColor, 0.1)`), which is grey on white and almost grey on the navy, and no named color changes it; the shell uses the `surface` role for its own fields and cards, so GTK does too | leaving the veils: a grey address field in a blue theme |
| The mode is only written by `nshell theme` | the saved choice survives restarts and deploys | |
| Brave gets the theme twice | Brave reads the colors of a GTK theme when its name changes, before GTK has loaded it, and so shows the mode before | one change; nudging other settings did nothing |
| 2026-11-07: the logo opens a menu, as the Apple menu | About This Computer, the apps, the mode, Force Quit and the session are in one place, at the corner where the eye starts, and a bar that is full has no power icon | the logo as the launcher only; a power item at the right of the bar; a right click for the session |
| 2026-11-07: icons for places and concepts, none for what is done | the Apple menu has them for its places and not for Sleep, Restart or Log Out, and Apple went back to that in macOS 27 after the icons of every item in Tahoe: see Icons | an icon on every line of the menu of the logo (built, shown, removed); a sun for the mode, which drew as a gear; the icon of the app on Force Quit |
| 2026-11-07: the history of the notifications has no panel | a card inside a panel had five lines around it, and was not the card of the toast that came to the same corner before | the panel with the count of all of them in its header |
| 2026-11-07: a group of notifications is a stack with a badge, opened by a click | the newest card says what is latest, the badge says how many, and the destructive Clear says what it does | a chevron and the count in the header of the card, and a round close button that cleared forty-four |
| 2026-11-07: the apps with their own colors are files, off unless asked for | the shell does not overrule the terminal theme of the user (Catppuccin, which Neovim and tmux are made for), and `nshell` has no app in it | integrations for each app, on by default |
| 2026-11-07: the options are `theme`, `targets` and the behavior of the shell | `theme` is only how it looks (`name`, `mode`, the font, the roles). What follows it is a target, whether it is a program or a part of the desktop: GTK, the wallpaper, the cursor, i3 and the colors of each app are `targets.<name>`, as in Stylix and Catppuccin, and `autoEnable` turns on the ones that Home Manager has. `calendar`, `session` and `network` are not look, and are not in `theme`. The old names are gone, with no aliases: there is no release | `integration` and `apps` as two groups, `theme.gtk`, a wallpaper inside `theme.dark`, `programs.nix.quickshell` (which reads as an option of Nix itself) | 
| 2026-11-09: the launcher groups its list: Suggestions (the five most run), Applications, Windows, and Results (N) for a search | a long list of the same icons has no places to look at; the label of a section says where the eye is, with no line and no new color. The mode is called Applications | the key caps and a kind on every row, as Raycast and Vicinae have them: more to look at in a card that is quiet, and a second footer in a panel that has one hint |

## Other shells

Four Quickshell shells were read on 2026-11-06 (the QML, not run): [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland),
[caelestia-dots/shell](https://github.com/caelestia-dots/shell), [duxlabs-dev/dux-shell](https://github.com/duxlabs-dev/dux-shell) and
[snowarch/iNiR](https://github.com/snowarch/iNiR). Their UI is not copied, and this is why.

| | Size | Built for | License |
|---|---|---|---|
| dots-hyprland | 586 files, 57k lines | Hyprland, in 97 files | GPL-3.0 |
| caelestia shell | 282 files, 40k lines, and a C++ plugin | Hyprland | GPL-3.0 |
| dux-shell | 1,027 files, 228k lines, and a Go backend | the Wayland compositors, i3 only for the compositor service in 3 files | MIT |
| iNiR | 1,422 files, 409k lines | niri, in 196 files | GPL-3.0 |
| this shell | about 4k lines | i3 on X11 | GPL-3.0-or-later |

- **They are Wayland shells.** Layer-shell is in 5 to 87 files of each, and the capture of the screen, the lock of the session and the
  protocols of the compositors are all over them. A panel taken from them has its compositor layer to write again.
- **Their look is not the one of NixOS.** The colors come from the wallpaper (Material You, matugen) and the icons are Material Symbols,
  in 99 files of one and 451 of another. The principles above, branding first and quiet, are the opposite of a theme that changes with the wallpaper.
- **The size is theirs to keep.** Ten to a hundred times the lines of this one, each pushed within the last month. A copy is a fork that
  has to be followed.
- **The licenses need a look at the headers.** GitHub says GPL-3.0 for three of them, which may not be "or later" as this one is. dux-shell is MIT.

Four more were read on 2026-11-07, for the open issues, and none of them changes the answer:

| | Built for | License | What it gave |
|---|---|---|---|
| [pik4li/i3-quickshell](https://github.com/pik4li/i3-quickshell) | Hyprland and Niri (the name is i3bar-styled, it has no i3) | MIT | a calendar, a power menu with its commands from a config, and a player chosen as the one that plays, as planned here, and a default of 120 ms for its motion, which was our most common duration |
| [rudv-ar/aevum-shell](https://github.com/rudv-ar/aevum-shell) | bspwm on X11, an Arch installer | none | the commands of the power menu from a config, notifications grouped by app, and a keep-awake tile |
| [MarioRRom/aetheris-shell](https://github.com/MarioRRom/aetheris-shell) | bspwm, and Hyprland | GPL-3.0, not "or later" in what was read | media controls that check what the player can do, and a marquee for long titles |
| [shalevc1098/nixos-quickshell](https://github.com/shalevc1098/nixos-quickshell) | Hyprland, in the pattern of dots-hyprland | none | nothing: its Mpris service is a wrapper of the API of Quickshell |

A repository with no license is read for ideas and not copied, and a GPL-3.0 one would take the parts that use it to GPL-3.0 only. What
came of them is in this document: the controls of the media popup follow what the player says it can do, a group is by app, and the
session commands are config. A keep-awake toggle and a marquee for long titles were seen and not built.

What is not done on purpose: the overview with live previews and the lock screen (they need Wayland protocols that X11 has no answer for),
desktop widgets (they have no place in a tiling layout), a settings app, an assistant, a mascot, and colors from the wallpaper. What is
taken is ideas, and each one is written here again for this shell and credited if it is close: a calendar on the clock (done, see Controls), notifications with
progress, groups and the inline reply (done, see Notifications), a media item (done, see Media), a menu for the session (done, see Session), and one set of durations and easings for the motion (done, see Motion). They are issues of the repo.

## The rules of the windows

### The panel (`modules/common/Panel.qml`)

| Part | Rule |
|---|---|
| Header | a title at the left, then a muted value or the buttons of the window at the right. Or a header of its own (the search field of the launcher) |
| Divider | one line under the header, and none other. A section inside the body is marked by its label, not by a line |
| Body | what the window is about. An empty state is centered in it |
| Footer | a hint, at the bottom left, small and muted |

The container is the dark `bg` for every window (the popups of the bar, the launcher, the polkit card), with one hairline border, the
large radius, a shadow and 16 of room around. A menu has less room, as its lines have their own, and a dialog more. **The history of the
notifications is the one exception: it has no container.** Its entries are cards, and a card inside a panel had its own border, its own corners
and its own edges inside the border and the corners of the panel, five lines around one notification, and it was not the card that the toast is
in the same corner a moment before. So the history is the cards of the toasts, of the same width in the same place, floating with their own shadows, and
its header is a card of its own, as there is no blur to read bare text on what is behind it.

What a window holds are **rows** and **cards**. A row is part of a panel and has no border. A card is a notification: `surface`, the large radius, a hairline
and a shadow, whether it is a toast or an entry of the history. What is selected or pressed is `surfaceHigh`.

### Color and mode (`Theme.qml`, `themes/`)

Two palettes with the same roles, dark and light, and the roles follow `Theme.mode`, live. Dark is **nixos-navy**: the bar and the windows
in the blues of nixos.org. Light is the white of nixos.org with the same blue, darker so that it reads on white, and the bar is that blue
with white text. The bar has roles of its own, `barBg`, `barText`, `barMuted` and `barFocus` (the tile of the focused workspace, white at
20% on the blue bar), and the logomark is white or black by the brightness of `barBg`. Text on both is above
7:1, the edge is a hairline of white on dark and of black on light, and the status colors are the lighter step on dark and the darker
step on light. The values are in `themes/*.json`, and not repeated here.

`textOnPrimary` is the text on a fill of `primary` (the active button), and `textOnAccent` the text on a fill of `accent` (a pressed
button). The names do not start with `on`: QML reads such a property as a signal handler, and it was always black. `modules/theme/Appearance.qml` holds the choice, dark, light or auto, and sets the mode.

### Branding (NixOS/branding)

The look follows the branding of NixOS, [NixOS/branding](https://github.com/NixOS/branding) (its guide is `nixos-branding-guide.typ`, its
palette `nixos-color-palette/colors.toml`, in OKLCH), and where it does not, the reason is here. Checked on 2026-11-06.

**Color.** Every color of both themes (`themes/nixos-navy.json`, `themes/nixos-graphite.json`, dark and light) is a color or a tint of the palette,
converted from OKLCH, with one exception below. The neutrals are the greys and the tints of Afghani Blue (NixOS Dark Blue, `#4d6fb7` is
the hex that the palette file gives for it), the status colors are the tints of Zambian Green, Persian Orange and Norwegian Pink, and the
terminal colors are the tints of the accents. The guide says the primary colors (black, white, greys) are for text, backgrounds and
borders, the blues for headers, icons and navigation, and the accents for emphasis, sparingly. Navy has tinted backgrounds, which the guide
allows as tints "for layering and different themes"; nixos-graphite is the reading with grey backgrounds.

**Logo.** The bar has the official logomark, `assets/nixos-logomark-white-flat.svg` on a dark bar (both modes of nixos-navy and nixos-graphite)
and `nixos-logomark-black-flat.svg` on a light one (a theme of your own), made with `nixoslogo` from the branding repo and not changed or
painted in another color: the guide has the black and white logomarks flat. The gradient one would not show on the blue bar, and its thin
strokes are too fine at this size, so it is only for the wallpaper. The flat one is 18 points high, which is 36 pixels on this screen: the guide has 24 px as the least for
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
  and L85 (`#b7cefd`) makes the lit tile of a light menu a strong blue.
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

### Icons

**An icon is for a place, a thing that one symbol says, or a control that has no room for a word. It is not for what is done, which a verb names.**
This is the rule of the Apple menu: the icons of its top group (About This Mac, System Settings, the App Store) are places, and Sleep, Restart,
Shut Down and Log Out have none. Apple's guidance minimises them, and went back to it in macOS 27, which had icons on every item in Tahoe.
Checked against [9to5Mac](https://9to5mac.com/2026/06/11/apple-again-warns-developers-not-to-do-what-apple-did-in-macos-26-tahoe/) on 2026-11-07,
and not against the page of Apple, which did not load.

| Where | Icon | Why |
|---|---|---|
| The items of the bar (tray, player, sound, battery, bell) | yes, drawn or a glyph | there is no room for a word, and each is told from its neighbours by shape |
| The lines of a menu that are places: About This Computer, Applications | yes | a place, as in the Apple menu |
| The line of the mode in the menu of the logo | the half-circle | a visual concept that one symbol says |
| The lines of a menu that are actions (Sleep, Restart, Shut Down, Log Out, Lock, Force Quit) | none | a verb is named by its text; the icons for them are not told apart without it, and a menu where every line has one is read by the icons and not by the words |
| The card of the session | yes, a glyph for each line | it is a card of five large choices, and not a text menu |
| The player: previous, play or pause, next | yes, drawn | controls |
| The icon of the app that plays, and the icon of an app in a list | yes: it is the app | a click on the one of the player takes the window of the app to the front, so it is a control and not an ornament |
| A notification | its own picture or the icon of its app | it is content of the app |

Rules that follow:
- **A line without an icon starts at the edge**, and does not line up with the ones that have it, as in macOS.
- **No color is added to an icon to decorate it.** Color says state: the accent for do not disturb that is on, the red of an urgent window.
- **The same thing has the same icon everywhere:** the bell of the bar and the bell of the history are the same two glyphs, bell and crossed bell.
- **Two lines never share an icon**, and an icon that is read as another thing without its text is not used. The test is to cover the text.
- **The app is not the icon of its destructive action.** Force Quit has no icon of the app: a logo at the left of a line reads as "switch to" or "open", the
  opposite of the line, it is the loudest thing in a quiet menu, and it exists only for the apps that have a desktop entry, so some lines would have it and some not.
- **The shell carries no icons of apps.** It draws the shapes of its own controls (the speaker, the chevron, the controls of the player, as Lucide
  has them, so that they are the same at every size), takes the glyphs from the icon font that the system installs (`Theme.iconFont`), and takes
  the icons of apps from the icon theme, through their desktop entries.

What was tried and went: an icon on every line of the menu of the logo, which was a column of glyphs that did not say more than the words, with the red of
Restart and Shut Down as decoration; and the sun of the icon font for the mode, which drew as the gear of settings at this size, so the half-circle came back.

### Motion (`Theme.qml`)

Principle 4 is a rule for each animation: it has to explain something, and the explanation is one of three. A color or an opacity that
**follows the pointer** (a press, a hover, an open menu) is `motionFast`, 120 ms. A surface that **comes or goes**, and a list that closes
up after a card left, is `motionBase`, 180 ms. The one movement over a distance, a toast sliding in from the edge, is `motionSlow`,
220 ms. What moves over a distance eases out (`motionEasing`, `OutCubic`), and a color or an opacity has no easing. Nothing in the shell
has a duration of its own: a new animation picks the token that says why it moves. A popup or a tip does not move at all, it is there.
There is one easing, not one for entering and one for leaving, because a `Behavior` runs the same curve in both directions.

### Notifications: groups and progress (`modules/notifications`)

**More than two notifications of one app are one card**, in the stack and in the history. The card is the newest of them, which is the latest line, with two edges behind it that say that
there are more, as the stack of macOS does, and its count as a badge in its header. While the pointer is over the card the badge says **Clear 44**, and a
click on it clears the group: the destructive thing says what it does, and cannot be taken for the close button of one notification, which a
card that stands for a group does not have. The others are not shown, take no room, and have their time stopped, as the cards behind the limit
of the stack do; so the group runs out as one, a close on it closes all of it, and what is dismissed or has run out stays in the history, as
before. A click on the card opens the list, and then the group has a header of its own above its cards and outside of them, the app and how
many, with **Show less** and **Clear all**, the pills of the footer of the stack: the cards in it are cards, and have no count and no chevron.
The count is in one place at a time, the badge or the header. An app with one or two is as it was: a group of two is not a group, and one that falls to two folds back. The
count of "Show 3 more" is of the cards that are shown. **Progress is the `value` hint**, 0 to 100, as a thin bar in the card; the app sends the
same notification again, which Quickshell updates in place, so it is one card that fills, the history has one entry, and each update starts the
time of the card again. **The header of the history is the bell**, the one of the bar, with its glyphs: it is the switch of do not disturb,
crossed and in the accent color while it is on, with the line "Do not disturb is on" under the title, and **Clear all** is the one pill. There is no
count of all the notifications there: with groups it says little, and the count is in the header of a group. **The inline reply** is a field under the text of a toast whose app offers one, with the action `inline-reply` as KDE has it (the server says that it can, and an app that does not know it
sends nothing different). It is sent with Enter and the card goes with it; Escape leaves the field, and the card keeps its time while the user is in it or has written in it, as when the pointer
is over it. It is only in the toast: the history keeps what was said and not the way to answer it, which the app may have taken back. Few apps send it on Linux: Vesktop and the other Electron
ones do not, and it was tried with a made-up app on a private bus (`scripts/preview reply`, and a listener for `NotificationReplied`).

### Network (`modules/common/Net.qml`, `modules/bar/NetworkItem.qml`)

The item is a **cable, a Wi-Fi with its waves, or the plane of the airplane mode**, in a slot like the sound, crossed and muted when it is not connected,
and it is not there when the machine has no network device. **NetworkManager is the network when it is there**, through Quickshell, which has no other
backend; **when it is not, the network is the wired interface**, read from the system every few seconds and when the popup opens, so that a machine with plain
networking has an icon too. That interface is the one of the default route when it is a card of the machine, and otherwise the first card with a cable: Tailscale,
Docker and VPN interfaces have no device behind them, and are not the connection (`network.interface` chooses one). A cable that is connected is the connection
before a Wi-Fi is, as NetworkManager prefers it, and the airplane mode is only what the machine is in when it has no cable to say otherwise.
In the popup a Wi-Fi has its radio as a switch, and the networks it sees: **a network that is known is joined with a click, an open one too, and one that
asks for a password opens a field under its line**, sent with Enter or with Join. The one that is connected has Disconnect and Forget. A network that asks for the login
of an organization says that the shell cannot take it, and is not tried. The Wi-Fi scans only while the popup is open. **The right button on the item
turns the Wi-Fi off and on**, as it mutes the sound.

### Bluetooth (`modules/common/Bt.qml`, `modules/bar/BluetoothItem.qml`)

The item is the **sign of the Bluetooth**, with the two bars at its sides when a device is connected and the slash when the adapter is off, in the slot of the
network, and it is not there when the machine has no adapter. The popup has **the power as the switch of its header**, which says what is connected, and two lists as
the Apple menu has them: **My devices** (the paired ones, the connected first) and **Nearby**, the ones in range with a name: a device that has only its address
for a name is noise, and is left out. The adapter looks for devices only while the popup is open. A click on a device that is paired connects it, and on
one that is not pairs it and connects it when it is paired. The connected one opens its **Disconnect and Forget**, and the right button on any device of the
user does the same, with Connect. The battery is said while a device is connected and reports one: BlueZ keeps the last value for a while after. **The pairing has no
agent:** Quickshell cannot be one, so a device that asks for a code or a confirmation fails, and the line says that it may ask for what the shell cannot take. The
right button on the item turns the adapter off and on.

### Media (`modules/common/Media.qml`, `modules/bar/MediaItem.qml`)

The player is any program that speaks MPRIS. **The active player is the one that plays**, and when none plays it is one that is paused: a
player that is stopped is not shown, and the item is not in the bar when there is none. The popup can choose another player from its
short list, for as long as it is open, and the bar follows the one that plays again after it. The bar item and the main button of the
popup show the **action** and not the state, a pause while it plays and a play while it is paused, so that the two never say the opposite
at the same moment. A control that the player cannot do (previous on the first track, seek on a stream) is dimmed or has no slider, and
the player is asked where it is a second at a time, only while it plays and the popup is open. The cover is loaded only while the popup is
open: it is an address. The **icon of the app** that plays is at the right of the heading, and a click on it takes the window of the app to
the front, on whatever workspace it is (i3 finds it by the class of its desktop entry, and never starts the app). Brave names no desktop
entry and cannot raise itself, so the entry is found by the name the player gives itself, and then by the name in its address on the bus. Two
windows of one app have one class, so i3 takes the first it finds.

### Session (`modules/session/Session.qml`)

A card in the middle of the screen, as the launcher is: Lock, Log out, Suspend, Reboot and Power off, each with the letter that
runs it underlined, and the arrows with Enter for those who look first. **Log out, Reboot, Power off and Force Quit ask once more**, in the same card,
because they lose what is not saved and cannot be taken back with a key; Sleep and Lock are as quick as the key. The entry in the bar
is the **menu of the logo**, as the Apple menu is the first thing of the menu bar: About This Computer, Applications…, the mode of the theme
(there is no settings app, and the mode is the one setting that a click changes), Force Quit for the app that has the focus, Sleep,
Restart…, Shut Down…, Lock Screen and Log Out…. The lines with dots are the ones that ask, as in macOS. The launcher is a line of the menu
and a key (`$mod+d`), and the focused window is looked up when the logo is pressed, so that Force Quit is in the menu when it opens. A power
icon at the right of a bar that is already full would be one more thing to look at for what is done twice a month. **The icons of the menu follow the rules of Icons, below**: the places and the mode have one, and what is done has none. There is no
lock screen drawn by the shell, as X11 has no protocol for one: **Lock runs the command of the user** (`i3lock`, `xss-lock`) and is not in
the card when there is none. The commands are the `session` of the theme file. The card has the height of its lines as it opens, as
i3 does not follow a floating window that grows.

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
- The **clock** opens the calendar and the **bell** opens the history of the notifications. The clock opened the history before, as the
  clock does in macOS and in Windows 11, but the bell opened the same, and a clock with no job of its own is a tile that does nothing
  that the one beside it does not. The calendar is one month and no events: the shell has no accounts, so nothing in it would be
  anyone's agenda. Today is the filled tile, as the focused workspace is in the bar, and the days of the months around are muted.
- A **right click** on an item of the bar is its quick quiet toggle: on the bell it turns do not disturb on and off, on the speaker
  it mutes, on the player it plays and pauses (a middle click does the same, but a trackpad has none). On an icon of the tray it is the menu of the app.

### The status area of the bar

Its items, the tray, the player, the sound, the battery, the bell and the clock, are tiles with the same room inside, on each side of what they
hold (`Theme.tilePad`), and the same gap between them (`Theme.statusGap`), so the space between what is shown is the same all
along: 12 to 13 points between any two. Text has a little room of its own at its edges, which `Theme.textBearing` takes back, or a
tile of text would look further from its neighbour than a tile of an icon.

### Keys

The commands that a key can run (`nshell launcher`, `center`, `bar`, `calendar`) toggle, and a key that is held a moment repeats: the command
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

- Network was tried against a mock of NetworkManager (`scripts/nm-mock.py`) and the wired interface of the VM, not against a radio, and a join that fails
  (a wrong password) was not seen: its message is mapped and not exercised. Bluetooth was tried against a mock of BlueZ (`scripts/bt-mock.py`) only,
  and the pairing of a device that asks for a code or a confirmation is not possible: Quickshell has no agent for it, so the shell pairs the ones that need none
  and says so for the others. Both want one pass on real hardware. Brightness needs a backlight, which a VM has not.
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
- The menus of GTK 3 apps here are opaque windows (depth 24), so a rounded corner of the theme shows black outside the round: the menus of a menu bar are square, as the context menus are. Tooltips have an alpha channel and stay round.
- A key that is held repeats the command: `nshell` catches a run less than 400 ms after the one before, so scripts need a pause between
  two `nshell theme` calls.
- A loss of focus is also reported when a key grab starts: ask i3 before closing a window (`FocusGuard`).
- `i3-msg restart` drops the dock registration of the bar: restart the shell after it.
- i3 moves a floating window that starts before the screen back to the edge, so a popup that hangs near the left edge has less room for its shadow there, and must not move its panel to make it.
- A `ListView` does not move the `x` of its delegates: inset the card inside the delegate. A property of an item named `top` clashes with a built-in.
- A `Timer` that runs only while its item is visible does not run for the cards that are hidden: a group has the time of the card that stands for it.
- A glyph of an icon font is judged at the size it is drawn at: the sun of the font was a gear at 16 points.
- The lookup of Quickshell for a desktop entry by name did not find Brave by "Brave", which its entry has: the list of entries is matched by its id, its name and the class of its window.
- A step of a pointer script that clicks hits whatever is on that place of the real screen: check that no window of the shell is open first.

## How it is tested

- A copy of the shell runs with `NSHELL_PATH` over the one that is installed, with a private state folder (`XDG_STATE_HOME`) and its
  own theme file (`NSHELL_THEME`), so that the real history and the real mode are not touched.
- Screenshots of the screen, cropped to what is being judged. A screenshot of a real window shows its content, so tests use windows of
  their own, with made-up titles, and close them by id.
- A before and after of the rectangles of the windows, taken with their workspace in view, when anything touches the layout.
- A second X server with a real i3 (`Xephyr`) for layout work. It has no compositor, so transparent windows look black there.
- **A separate X server for what is clicked.** An `Xvfb` with its own i3, a private session bus, and a mock of a service on a private system bus (NetworkManager
  or BlueZ, `scripts/nm-mock.py` and `scripts/bt-mock.py`): nothing that a test clicks, types or captures can reach the real screen, and the real shell is not replaced.
- **The same lab, for the screenshots of the README.** At the size of the real screen (3840x2160, `Xft.dpi` 192), with `picom` on the `xrender` backend (the shadows and the
  corners), a home of a made-up user that has only the settings of the real one (the GTK themes, the fonts, the theme file, the config of the terminal), a mock of UPower for
  the battery, a null sound card of PipeWire for the sound, a made-up player on MPRIS and a folder of empty files for the file manager. The terminal and the file manager show
  made-up text and names, and the shell reads nothing of the real session. Two things in it to know: the windows of a workspace that is not in view are not painted again
  when the theme changes, so the windows are opened again after a change of mode and the shots are taken with the workspace in view for a few seconds; and a workspace that is
  itself tabbed (`layout tabbed` on a window that is alone in the workspace) has all its windows unmapped while a floating window has the focus, which is i3 and not the shell, so
  the tabs are in a container of their own (`split h` first).
- A second copy of the shell on a private bus (`dbus-daemon`, `NSHELL_NO_BAR=1`, a private `XDG_STATE_HOME`) takes the notifications that a script sends, and a fake
  player that speaks MPRIS (a few lines of `dbus-next`, which logs what it is asked) takes the controls of the media popup.
- Clicks of a test are sent only when no window of the shell is open on the real screen, and the test works on an empty workspace.
- Scripts are files: `pkill -f` in a command line matches the command line itself.

## Rules

- No secrets or real identifiers in code, tests, fixtures, commits or documents: made-up values only.
- The colors and the tabs of i3 come from the file that the module writes, never by hand.
- Anything taken from another project is credited in `CREDITS.md`, in the form that its license asks for.

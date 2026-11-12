# Changelog

## [0.4.0](https://github.com/nixos-contrib/nix-quickshell/compare/v0.3.0...v0.4.0) (2026-11-12)


### ⚠ BREAKING CHANGES

* one palette, palette.json, and no theme.name

### Code Refactoring

* one palette, palette.json, and no theme.name ([7c00f1b](https://github.com/nixos-contrib/nix-quickshell/commit/7c00f1b3a975191b9e797b17331aad899ebbe954))

## [0.3.0](https://github.com/nixos-contrib/nix-quickshell/compare/v0.2.0...v0.3.0) (2026-11-12)


### ⚠ BREAKING CHANGES

* the config and the state are back in nix-quickshell, from nix/quickshell of 0.2.0, with no alias.

### Code Refactoring

* keep the config and the state in nix-quickshell, flat ([b51c449](https://github.com/nixos-contrib/nix-quickshell/commit/b51c449587ddc52110d7b2cf531ede55e13fc3df))

## [0.2.0](https://github.com/nixos-contrib/nix-quickshell/compare/v0.1.0...v0.2.0) (2026-11-12)


### ⚠ BREAKING CHANGES

* the command nshell is nix-quickshell, the variables NSHELL_* are NIX_QUICKSHELL_*, and the config and the state moved to nix/quickshell, with no alias. The window titles are unchanged.

### Code Refactoring

* rename nshell to nix-quickshell, and keep config and state under nix/quickshell ([757dcf6](https://github.com/nixos-contrib/nix-quickshell/commit/757dcf61107fe59bb0e7facf9b624ab26d43d0db))

## 0.1.0 (2026-11-09)


### Features

* a burst example to try the stack ([4e0f098](https://github.com/nixos-contrib/nix-quickshell/commit/4e0f098afbb56d87d16bdc518516b44e8523045c))
* a flake with the package, and the nix-quickshell command ([c372c84](https://github.com/nixos-contrib/nix-quickshell/commit/c372c84666bd23539f412a0b792acfe5ee15f07f))
* **alacritty:** the colors of Alacritty from the palette, which it reads again when the mode changes ([128ee54](https://github.com/nixos-contrib/nix-quickshell/commit/128ee54b214a078122a4073c3b423301387a4676))
* **apps:** WezTerm follows the theme, as an app that is off unless asked for ([df28010](https://github.com/nixos-contrib/nix-quickshell/commit/df280105991daefa8b9416f418f9f48979420954))
* **bar:** a blue bar on light, with its own roles ([be3a282](https://github.com/nixos-contrib/nix-quickshell/commit/be3a2829d44a426cbc5360910d7ea7f15e3fb552))
* **bar:** a Bluetooth item with its devices to connect, pair and forget ([327662f](https://github.com/nixos-contrib/nix-quickshell/commit/327662f21b299267b50ed33f6a6342db9a9e5b4a)), closes [#3](https://github.com/nixos-contrib/nix-quickshell/issues/3)
* **bar:** a calendar under the clock, and the history stays on the bell ([6fb39c5](https://github.com/nixos-contrib/nix-quickshell/commit/6fb39c522f2ae6fd1e1d7e2e1f007efc9c8e0d97)), closes [#6](https://github.com/nixos-contrib/nix-quickshell/issues/6)
* **bar:** a group of more than five windows is one icon and a chevron, the icons are as big as the tray's ([092a753](https://github.com/nixos-contrib/nix-quickshell/commit/092a7539f011bc27dea52625426e2f85b8f5f804))
* **bar:** every workspace shows its windows after its number, a title on hover, and each tabbed container is a group of its own with its chevron ([13cc065](https://github.com/nixos-contrib/nix-quickshell/commit/13cc06547b4707f01a65619d3c2a7150efd23a7b))
* **bar:** logo, workspaces of i3, bell with the count of the history and clock ([605ee33](https://github.com/nixos-contrib/nix-quickshell/commit/605ee3309a0d706aae0eea7d113ddad443c65f2d))
* **bar:** the battery, with its charge and details, and one popup open at a time ([097e866](https://github.com/nixos-contrib/nix-quickshell/commit/097e866190cb87569846ba42696b7ae1df77d746))
* **bar:** the bell has a dot when something came since the history was opened, and the count of the history is in its panel ([671dc3f](https://github.com/nixos-contrib/nix-quickshell/commit/671dc3f4184a90d6b84da1468fe5e03c65239b6d))
* **bar:** the clock is a tile that opens the history, as in macOS and Windows 11 ([5d2a888](https://github.com/nixos-contrib/nix-quickshell/commit/5d2a888d9eacb55d479f48d91f4ca9a44e716de2))
* **bar:** the icon of the app that plays, and a click on it takes the app to the front ([7b754da](https://github.com/nixos-contrib/nix-quickshell/commit/7b754da7d24a131f46a3f759b037e4ad35f70902))
* **bar:** the icons of the tray are in the order of their names, not of the order the apps started in ([d9a1632](https://github.com/nixos-contrib/nix-quickshell/commit/d9a16328655fc7eac59a084006536c6890dfc220))
* **bar:** the logo opens a menu, as the Apple menu of macOS ([64370e8](https://github.com/nixos-contrib/nix-quickshell/commit/64370e82d9a39ff9005122ea2e31f48650b754a6))
* **bar:** the logo, the tray and the bell have one size and one gap, and the logo opens the launcher ([1161afa](https://github.com/nixos-contrib/nix-quickshell/commit/1161afaa783f324743f2719c6ccd626661e2f183))
* **bar:** the logomark of NixOS is the official one from NixOS/branding, flat, white on dark and black on light, 24 px high with its clear space, and not the old snowflake painted in the text color ([68f90bf](https://github.com/nixos-contrib/nix-quickshell/commit/68f90bf38be44d8fcd5ec45fe9728ee622d440ac))
* **bar:** the network with NetworkManager, Wi-Fi to join and the airplane mode ([87d52d4](https://github.com/nixos-contrib/nix-quickshell/commit/87d52d44f710c695f93c617a7d0c523326f8522f)), closes [#2](https://github.com/nixos-contrib/nix-quickshell/issues/2)
* **bar:** the network, as the wired interface when there is no NetworkManager ([6c07a01](https://github.com/nixos-contrib/nix-quickshell/commit/6c07a01a8cd5189bb93db09be65cf4a2580e10d8))
* **bar:** the popups can be opened by ipc: nix-quickshell bar audio, battery or tray ([298f13c](https://github.com/nixos-contrib/nix-quickshell/commit/298f13cfd3530ba5803f4cf06998371e958e0f7f))
* **bar:** the sound, with its volume, mute and outputs ([5b1183d](https://github.com/nixos-contrib/nix-quickshell/commit/5b1183d5b1ea5264b67769825a676d7b82363951))
* **bar:** the speaker is drawn, the same at every level, and a right click mutes it ([3b2053d](https://github.com/nixos-contrib/nix-quickshell/commit/3b2053d463295da18b6ad401b5ab6d94aa50328a))
* **bar:** the wheel on a group goes from one window to the next, the right button on an icon opens a menu (close, move), and a drag along a group of tabs moves the tab ([c49b293](https://github.com/nixos-contrib/nix-quickshell/commit/c49b293dfd7ea4830ae067a60bbb484ba2047600))
* **bar:** tray with menus in the style of the shell ([8fb4894](https://github.com/nixos-contrib/nix-quickshell/commit/8fb4894259bc337372920c1e238edf7096451422))
* **bar:** what is playing, for any player that speaks MPRIS ([4b41f87](https://github.com/nixos-contrib/nix-quickshell/commit/4b41f8765391abab094336793896860bb5d8d4c3)), closes [#8](https://github.com/nixos-contrib/nix-quickshell/issues/8)
* design tokens, and the edge and the gap that line the bar and the panels up ([21d189f](https://github.com/nixos-contrib/nix-quickshell/commit/21d189f8f6524ae4517e5af10cd340ad5f83dc09))
* **gtk:** a field, the hover of a row and a tip are tints of the palette, not a grey veil of the text color or black ([db4d550](https://github.com/nixos-contrib/nix-quickshell/commit/db4d5504fc88d43459fb18b51c8afc0258f4f7d4))
* **i3:** the patch of i3 that the shell needs is here, as the overlay overlays.i3 and the package i3, with its docs ([22a2ff2](https://github.com/nixos-contrib/nix-quickshell/commit/22a2ff2545db90bc37ea11282240a198ba3e9c8d))
* **integration:** the colors of kitty, which follow the mode live ([a438870](https://github.com/nixos-contrib/nix-quickshell/commit/a438870a1a7a816b1fe4fab2e7f5864b84781bab))
* **launcher:** an app that has a window is focused and not started again, also from a key: nix-quickshell launch ID ([fde7f0a](https://github.com/nixos-contrib/nix-quickshell/commit/fde7f0adb759f34a4659d15fdabff22753b647ab))
* **launcher:** apps and windows in a card in the middle of the screen, ordered by use, and the logo opens it ([7bbc700](https://github.com/nixos-contrib/nix-quickshell/commit/7bbc70000806f3dea88a196475caf23b268413ae))
* **launcher:** nix-quickshell pick, a choice among the lines of a script, in the card of the launcher ([9040581](https://github.com/nixos-contrib/nix-quickshell/commit/90405819934d8c331e5ac9fe88f152164700d2a5))
* **launcher:** the history of the clipboard is a third mode ([4749d9b](https://github.com/nixos-contrib/nix-quickshell/commit/4749d9bd37c5cb1d330dad6d0a5d5ffcb32cf043))
* **launcher:** the list has sections, and the mode is called Applications ([f298047](https://github.com/nixos-contrib/nix-quickshell/commit/f298047bd5b25f263bd15445bde627a77236a238))
* **launcher:** the programs that run in a terminal are listed and run in TERMINAL when it is set, and are not listed when it is not ([b27ee30](https://github.com/nixos-contrib/nix-quickshell/commit/b27ee301404e26e819cec3fc78e8385308161a2c))
* **network:** a click on the address, the gateway or the hardware address copies it ([6560970](https://github.com/nixos-contrib/nix-quickshell/commit/65609705829c5e138281c5953cd38b36f2c78824))
* **nix:** a home-manager module with the theme as options and the colors of GTK, xterm, zathura and i3 as fragments ([e6c3a3e](https://github.com/nixos-contrib/nix-quickshell/commit/e6c3a3ee8f96d3e7a59d710608f00f415c3c7767))
* **nix:** the cursor as an integration: capitaine-cursors by default, for X, GTK and the session ([12d61c1](https://github.com/nixos-contrib/nix-quickshell/commit/12d61c12903c586e043de702ce902fd2662aeb62))
* **nix:** the module owns the GTK settings and css and the zathurarc, with extraCss, extraConfig, the icon theme and the font size ([086549a](https://github.com/nixos-contrib/nix-quickshell/commit/086549a1b3e3807c12cd1e57c492b94766640591))
* **nix:** zathura follows the font of the theme, and fontSize is theme.fontSize ([c8094e9](https://github.com/nixos-contrib/nix-quickshell/commit/c8094e962935040f2ceb9f8f2c194b0a3ca9016b))
* **notifications:** a field for the reply when the app offers one ([5b8bc23](https://github.com/nixos-contrib/nix-quickshell/commit/5b8bc230e5aec5b7273d406b05795b0fd5c91dc4)), closes [#7](https://github.com/nixos-contrib/nix-quickshell/issues/7)
* **notifications:** do not disturb mutes the sound effects of chat apps, which play their pings themselves ([0922ba6](https://github.com/nixos-contrib/nix-quickshell/commit/0922ba6ca084d1b31a69c7dd8e5f3db959aa53fe))
* **notifications:** groups, and progress from the value hint ([987940d](https://github.com/nixos-contrib/nix-quickshell/commit/987940dce54885da6cf970543d9b5ed6a57eb7bd))
* **notifications:** history center with relative times, clear all and do not disturb ([9b6db86](https://github.com/nixos-contrib/nix-quickshell/commit/9b6db86e38547fe30b47a63c0d6ca38dd64d1bb1))
* **notifications:** record the history and open the center by ipc ([6d6958d](https://github.com/nixos-contrib/nix-quickshell/commit/6d6958dfae79516fb60439e18d1ac8422d20e56d))
* **notifications:** server and toasts with urgency, actions, markup, icons and a close button on hover ([8483169](https://github.com/nixos-contrib/nix-quickshell/commit/8483169ab77861a8681ad5f69bef6e66e77db536))
* **notifications:** stack of four with show more, clear all and scrolling, newest on top ([c7d3d4f](https://github.com/nixos-contrib/nix-quickshell/commit/c7d3d4f0e4bbc6f9b696a7ac7b82642d9c918914))
* **notifications:** the history follows its notifications and is kept in a file, and toasts wait while a popup is open ([911ff7d](https://github.com/nixos-contrib/nix-quickshell/commit/911ff7d024c2f8f954d52ebf45f774a2a5ab6379))
* **osd:** the volume on the screen for a moment when it changes, from a key, the wheel, the slider or another app ([08d6df0](https://github.com/nixos-contrib/nix-quickshell/commit/08d6df01f68562ec62e68f935bc723a685457697))
* **polkit:** the agent of the session as a card, for the touch of the key or the password ([4ef6c0a](https://github.com/nixos-contrib/nix-quickshell/commit/4ef6c0a5fe42da5c066a3f6712741e199272236a))
* **polkit:** the card has room, as the card of macOS has ([2838f95](https://github.com/nixos-contrib/nix-quickshell/commit/2838f9593ae7657fd24e9c9c9a9afc9edf63469c))
* **polkit:** the card is as tall as its content, and its buttons are larger ([ad22d25](https://github.com/nixos-contrib/nix-quickshell/commit/ad22d25e196d0e4e6c93317eb88e1daa28eb0d3e))
* **portal:** nix-quickshell writes the appearance of the system, for the apps that follow it ([34483f9](https://github.com/nixos-contrib/nix-quickshell/commit/34483f947b4f5e84110e055b17bc9d485a70fb7e))
* **session:** a menu for lock, log out, suspend, reboot and power off ([c7d5b6d](https://github.com/nixos-contrib/nix-quickshell/commit/c7d5b6d97f4ec44a1285e3320a2b68c8987e98c0)), closes [#9](https://github.com/nixos-contrib/nix-quickshell/issues/9)
* **tabs:** a strip under the bar that fills the width is a row of the bar, flush and square, or a card, and nix-quickshell tabs style changes it ([4eff086](https://github.com/nixos-contrib/nix-quickshell/commit/4eff086c98d6f1680a3625d8f1a6ecf457a14c47))
* **tabs:** an attached look: a row of tabs on top of the window, with rounded top corners, as the tabs of a browser ([a4326af](https://github.com/nixos-contrib/nix-quickshell/commit/a4326afa7c84968f091d7b9ae0ef6d12258eeab3))
* **tabs:** flush again by default and without the corner pieces and the overlap, which glitched on apps with corners of their own, and a row as low as a menu bar ([8cd16dd](https://github.com/nixos-contrib/nix-quickshell/commit/8cd16dd25d5a96d29cb0e3cacc8bbafcb4d90e38))
* **tabs:** the attached row is the default, the corners of the window under it are filled, and the row is the height of the strip that i3 keeps ([de0707c](https://github.com/nixos-contrib/nix-quickshell/commit/de0707cca5d296a94cc1b62de12135507f65819e))
* **tabs:** the button of the list has a drawn chevron, thin as the one of Brave, and not a glyph of a font ([2afbc36](https://github.com/nixos-contrib/nix-quickshell/commit/2afbc360b980e88df44957eee82de42c7980dfbd))
* **tabs:** the tabs of the tabbed containers of i3 are drawn by the shell over the strip that i3 reserves and draws as nothing: a strip of tabs, a list of the windows, no stacked layout ([7f15491](https://github.com/nixos-contrib/nix-quickshell/commit/7f154916f0b1a94682ee51e8ba370826be7f80e8))
* **tabs:** the windows of a workspace are a group in the bar, at its number: an icon each, the chevron opens the list, and no strip ([743dd76](https://github.com/nixos-contrib/nix-quickshell/commit/743dd7671fbd3cfc794db42e689f6547d4709c0b))
* the bar fills an item while it is pressed or its menu is open, and has no hover ([3870a4b](https://github.com/nixos-contrib/nix-quickshell/commit/3870a4b06ad09dc7a1c626e4bdf3593fb62117ff))
* the panel and the label, one anatomy and five roles of text for every window, and a doc of it ([44da0a3](https://github.com/nixos-contrib/nix-quickshell/commit/44da0a390fdb72c6e472f90a840d990d850d8959))
* **theme:** a shadow under what floats, in two elevations, and the windows have room for it ([82a0967](https://github.com/nixos-contrib/nix-quickshell/commit/82a09676795e028633301e1df7e7fbb136483c02))
* **theme:** nixos-navy dark and a light mode from the blues of nixos.org, live, with nix-quickshell theme ([a9e3359](https://github.com/nixos-contrib/nix-quickshell/commit/a9e335973b7d484895cbe4e71a9eca48719df350))
* **theme:** the apps follow the mode: two GTK themes switched live by xsettingsd, and nix-quickshell apps for xterm, zathura and the tabs of i3 ([e2f014e](https://github.com/nixos-contrib/nix-quickshell/commit/e2f014e418170be2bc9447ee10608568829409ea))
* **theme:** the dark bar is the color of the windows, and Thunar draws its location bar again when the mode changes, so Papirus-Dark and Papirus-Light stay ([babb89b](https://github.com/nixos-contrib/nix-quickshell/commit/babb89b506ba5c6d8808bfa3eb0906ab7ce0dd18))
* **theme:** the flavours are nixos-navy and nixos-graphite; wallpaper: the base color of the palette with the logomark of NixOS in the middle, for each mode, set by nix-quickshell apps ([cd71350](https://github.com/nixos-contrib/nix-quickshell/commit/cd71350b9ff21c0675449a37768c5af548269a20))
* **theme:** the font is Route 159, the typeface of NixOS, with Inter drawing what it has not, and the shell uses Regular and SemiBold only, no Medium or Bold ([6581910](https://github.com/nixos-contrib/nix-quickshell/commit/6581910ef831305f7d84c44c57a460d87f6e4a8d))
* **theme:** the palettes are data, a variant of the package and the file of the user over it, read live: variant, font, radius, hours and roles ([83664f4](https://github.com/nixos-contrib/nix-quickshell/commit/83664f4501e4bfccf33b406abef614d0e8231e4a))
* **theme:** the status colors of the light mode are the official tints of the palette of NixOS, at L55 ([429a9c8](https://github.com/nixos-contrib/nix-quickshell/commit/429a9c844101ddf0247db56265d21576f90a6180))
* **theme:** three radii from one, a hairline for the edges, and the logo in the color of the text ([598bdda](https://github.com/nixos-contrib/nix-quickshell/commit/598bdda4b9fed9b8062ea079507e59cabb92baf4))
* **wallpaper:** the logomark with the gradient, the same on both modes ([34d06bd](https://github.com/nixos-contrib/nix-quickshell/commit/34d06bd2fdd16f01a7fefad3d748e98d23808602))


### Bug Fixes

* a held key is one press: the command catches the repeat, as starting the client of Quickshell made the runs reach the shell in bursts ([0d83b3e](https://github.com/nixos-contrib/nix-quickshell/commit/0d83b3e12c4451070444005bc03e2206a058ee44))
* a held key no longer closes the launcher: the loss of focus of a key grab is checked with i3, and only a click that moved the focus closes the window ([ab2d033](https://github.com/nixos-contrib/nix-quickshell/commit/ab2d033cc4ec97013cd5ee91d6494838a94f4964))
* a key that is held counts once: the commands that toggle ignore the repeat of the same press ([ca6eb61](https://github.com/nixos-contrib/nix-quickshell/commit/ca6eb61426dbb30cc58e7cd26f3ac5f4262ddfb7))
* a window is drawn only when it is in its place, so the popups no longer show for a moment in the middle of the screen ([8b0e09c](https://github.com/nixos-contrib/nix-quickshell/commit/8b0e09cc22a1d014e2f4b8f21f9f8ff68223d9d7))
* **apps:** find the Thunar that the key started, whose command is thunar and not the path of the wrapper ([f8d40bb](https://github.com/nixos-contrib/nix-quickshell/commit/f8d40bb8e84be583a521afd8ef7a1632e72b8d5a))
* **apps:** the GTK theme is told twice, as its name and as its twin, so that Brave shows the mode and not the one before ([b6e0d47](https://github.com/nixos-contrib/nix-quickshell/commit/b6e0d47f5462df724bde341b2626941290dd56a7))
* **apps:** the location bar of Thunar is no longer swapped when the mode changes, which flashed the path buttons ([e4de8a4](https://github.com/nixos-contrib/nix-quickshell/commit/e4de8a42c2b3768417e6870d9da3052928a4a491))
* **bar:** a tab that is a split of several windows shows how many, in its icon, its title and the list ([f98a92f](https://github.com/nixos-contrib/nix-quickshell/commit/f98a92f87943ddeb5580cc6d8cd93c2c82cbd112))
* **bar:** the arrows of the calendar are in its header, with Today ([224379e](https://github.com/nixos-contrib/nix-quickshell/commit/224379e99b70ff8f68e9a57f69a73dc370a0de03))
* **bar:** the bell and its slash are glyphs of the same set, so they are the same size ([f4d6761](https://github.com/nixos-contrib/nix-quickshell/commit/f4d6761fb44d55fc7ea3837e6e5d2e231fb92c46))
* **bar:** the icon of the tab in front is always among the icons of its group, in the last place when it would not be ([9e93db5](https://github.com/nixos-contrib/nix-quickshell/commit/9e93db52cf2109bd32043e9deff0f853630da6e4))
* **bar:** the icons of the windows are as big as the tray's ([3269109](https://github.com/nixos-contrib/nix-quickshell/commit/326910912cb5789bbd1df4691498c46d2ec214c9))
* **bar:** the logo is nearer to the workspaces, and the docs say why the keys and the windows are as they are ([785ee1e](https://github.com/nixos-contrib/nix-quickshell/commit/785ee1eac468e2d2f6da21027811ec7b338cf182))
* **bar:** the logomark is 20 points high, the size of the other icons, which is 40 pixels on this screen, over the 24 px of the guide ([1f6e2e6](https://github.com/nixos-contrib/nix-quickshell/commit/1f6e2e664a8cf8ec665903ab92a184562c93c697))
* **bar:** the menu of the logo has icons for its places and none for what is done, as the Apple menu ([32dd969](https://github.com/nixos-contrib/nix-quickshell/commit/32dd9690730443f309a94b75a363488266e0142c))
* **bar:** the mode in the menu of the logo has its half-circle ([6def6d3](https://github.com/nixos-contrib/nix-quickshell/commit/6def6d3f1af6e2526d933769b9aaf4cf0f948aee))
* **bar:** the popup that hangs near the left edge is where it is asked to be, and the menu of the logo has icons ([d3e85dc](https://github.com/nixos-contrib/nix-quickshell/commit/d3e85dc43304dcc0c728d9fd3e866013c5a28bb4))
* **bar:** the status items have the same room inside and the same gap, and a keys of the bar are held once ([2aa9ef9](https://github.com/nixos-contrib/nix-quickshell/commit/2aa9ef9db1040cce0848217da556f3299687bd37))
* **ci:** ignore the stale actionlint inputs in merge.yml too ([3fa6920](https://github.com/nixos-contrib/nix-quickshell/commit/3fa69207a14bb1c014bbc9103a2dbbfd3a63800b))
* **ci:** merge with the App token so main gets its CI run ([#12](https://github.com/nixos-contrib/nix-quickshell/issues/12)) ([3a012c6](https://github.com/nixos-contrib/nix-quickshell/commit/3a012c6355b1f940150f1bedc4e7235b2b02d72e))
* **gtk:** one color for what is selected, and the hairline of a card on fields ([1b60359](https://github.com/nixos-contrib/nix-quickshell/commit/1b6035923947427e7c1c95e48284081c37e9151d))
* **gtk:** the menus of a menu bar are square, as the context menus: their round corners were black in a window with no alpha channel ([30d2632](https://github.com/nixos-contrib/nix-quickshell/commit/30d263253de75797c92e4619e990e2fcbb0809a8))
* **gtk:** the menus of the GTK apps have icons again: gtk-menu-images and Gtk/MenuImages, as an option that is on ([6666983](https://github.com/nixos-contrib/nix-quickshell/commit/6666983370a0a676c659f4cf6ac0e4fdaa1956c9))
* **launcher:** a click outside closes it and cancels a pick, the focus is on the search field ([55a49e7](https://github.com/nixos-contrib/nix-quickshell/commit/55a49e75ce9eda9874a025ebfbd9e4b4481099cd))
* **notifications:** the close button of an entry of the history removes it, the attached ListView.view was null in the button ([2b9c7f8](https://github.com/nixos-contrib/nix-quickshell/commit/2b9c7f86e13e06b07bc24c325ad8ca5c2208fafe))
* **notifications:** the groups as the stack of macOS, and the bell in the header of the history ([8f663ae](https://github.com/nixos-contrib/nix-quickshell/commit/8f663ae80e1660fd82df3226cf985b94367b8ffd)), closes [#7](https://github.com/nixos-contrib/nix-quickshell/issues/7)
* **notifications:** the history has no panel around its cards, they float as the toasts do ([7d907c8](https://github.com/nixos-contrib/nix-quickshell/commit/7d907c814247a85d68376484687f658a9b08b82b)), closes [#7](https://github.com/nixos-contrib/nix-quickshell/issues/7)
* **notifications:** the list of the history ends inside the panel, with the gap above it and the room of its shadow under it taken off, not a fixed 24 ([a96356e](https://github.com/nixos-contrib/nix-quickshell/commit/a96356ee3508b32848ed2ace63a5729f5aa3966a))
* **notifications:** the pictures survive in the history, and come from the desktop entry of the app when there is no icon ([adda805](https://github.com/nixos-contrib/nix-quickshell/commit/adda805482195758e0bc39fd5e4b4c2238d1ac0b))
* **notifications:** the time that an app asks for is in milliseconds ([b57e210](https://github.com/nixos-contrib/nix-quickshell/commit/b57e2100316aa702116236ddf48e6c7c1d4de48e))
* **nix-quickshell:** kitty is signalled by the name of its wrapped process ([42c8fd7](https://github.com/nixos-contrib/nix-quickshell/commit/42c8fd72cd6400b2155d0fb350e7c8502ab2250e))
* **nix-quickshell:** the wallpaper is drawn at each start, and not only when its copy changed ([dc09df0](https://github.com/nixos-contrib/nix-quickshell/commit/dc09df03a7c273e7e1aadfc77faab6a42d244f02))
* **popups:** they close on a click anywhere (the wallpaper, the bar, a workspace), and the windows that hang from the bar start under it, so that their shadow does not cover its items ([c28ecc4](https://github.com/nixos-contrib/nix-quickshell/commit/c28ecc49622967cb792b8d26295496dd73eddac3))
* **tabs:** a strip is in the workspace of its container and i3 hides it with it, so it does not flicker on the next workspace; the row overlaps the window a little, with wider corners ([1e0f411](https://github.com/nixos-contrib/nix-quickshell/commit/1e0f411e4f9bd45377bbc783ba7ed8f4368c1249))
* **tabs:** a strip that i3 moved when the screen changed is put back, and a bar that is not a dock of i3 is shown again ([ed687a5](https://github.com/nixos-contrib/nix-quickshell/commit/ed687a584565ef77ec6645beffec1f12f04bea43))
* **tabs:** the chevron of the list that is open closes it, as the items of the other popups do, and taking a window to the front closes the list ([7bf1604](https://github.com/nixos-contrib/nix-quickshell/commit/7bf160463a352bc2f98593458e2a5b37f3188618))
* **tabs:** the list hangs from the number of its workspace, lined up on its left edge ([daf65ec](https://github.com/nixos-contrib/nix-quickshell/commit/daf65ec6a86e65d264eacfc3bcc488e06493db51))
* **tabs:** the list says how many tabs it has, a tab that is a split has no close button, and its line is short ([cd785b0](https://github.com/nixos-contrib/nix-quickshell/commit/cd785b09f20816d7b4ae77bcb4b3599d2950261a))
* **tabs:** the strip is sent to its workspace only when its container changes workspace, not each time it is placed ([4bbe937](https://github.com/nixos-contrib/nix-quickshell/commit/4bbe937879660246f76b0bc2e01e0c8604d0d9fb))
* **tabs:** the tree is read each second and after a binding, as i3 sends no event for a layout, and the strip is at the top of the container ([718f381](https://github.com/nixos-contrib/nix-quickshell/commit/718f381dd77c7141b3424873b9832ceff37fdf29))
* the history of the notifications is one of the popups: the others close when it opens, it closes when it loses the focus, and they take the focus from i3 ([68a4ed3](https://github.com/nixos-contrib/nix-quickshell/commit/68a4ed367131e8c25dfe6d745ebb423ea46a1fda))
* the theme of the package is read into shipped, as base is the color of the windows ([ea3cbbe](https://github.com/nixos-contrib/nix-quickshell/commit/ea3cbbe181c1e17b3f5d7bfd1d2f80a505eb4f5c))
* **theme:** one icon theme for both modes, since the location bar of Thunar kept the icon of the other one until the next folder ([55e004a](https://github.com/nixos-contrib/nix-quickshell/commit/55e004ad16a6af24d0328968c733110cff3a5a23))
* **theme:** the page of zathura is on the surface color, and xterm has its sixteen colors from the hues of the palette, so a prompt reads in the light mode ([fd06812](https://github.com/nixos-contrib/nix-quickshell/commit/fd06812715ed0c9000ef8520b6b572efd2188785))
* **theme:** the text colors on a fill were always black (a property named onPrimary is read by QML as a handler): they are textOnPrimary and textOnAccent, and the focused workspace has the color of the text ([e467fd3](https://github.com/nixos-contrib/nix-quickshell/commit/e467fd3329e5ee2bc50bf5e9320645691cd8ee0b))
* **ux:** the logomark of the bar is 18 points, and the one of the wallpaper 12% of the height, so that neither draws the eye ([8034186](https://github.com/nixos-contrib/nix-quickshell/commit/8034186ddc8f07bffbd1947eccea3ae41e2dacdb))
* **wallpaper:** the surface color of the palette and not the base one, so that the bar is seen against it ([1cb12a9](https://github.com/nixos-contrib/nix-quickshell/commit/1cb12a9be50adc991e4e505a38e035768f5bb7cb))


### Continuous Integration

* release-please and the workflows of the other nixos-contrib repos, a development shell and the flake checks ([60c4624](https://github.com/nixos-contrib/nix-quickshell/commit/60c46248465a1f59924cd8d42b5b46f9bcccd122))

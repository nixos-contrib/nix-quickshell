# WezTerm: its `colors` are the scheme file of the state folder, `~/.local/state/nix-quickshell/wezterm.toml`, in the format of a color scheme
# of WezTerm. The config adds the file to the list that WezTerm watches, so the open terminals read it again when `nshell apps` puts the file of
# the new mode there, and follow it. A file that is not there yet is no scheme, and the colors of WezTerm are its own
# `program` is the name under programs.<program> of Home Manager: when it is enabled the app is found, and `wire` puts the colors in its
# config. `target` is the name in the state folder, `reload` runs when the file there changed (or at each `nshell apps` when `always`), with the
# path of the file in $NSHELL_FILE. A file that is not here is not an app of nix-quickshell: add one, and `targets.<name>` is there
{
  program = "wezterm";
  target = "wezterm.toml";
  reload = null;
  always = false;
  # `settings` is rendered by Home Manager into the config, and a value with `_type = "lua-inline"` is written as Lua code. It is only
  # there for the colors, so the rest of the config of the user, the `settings` and the `extraConfig` of his own, is not in the way
  wire = path: {
    programs.wezterm.settings.colors = {
      _type = "lua-inline";
      expr = ''
        (function()
          wezterm.add_to_config_reload_watch_list("${path}")
          local ok, scheme = pcall(wezterm.color.load_scheme, "${path}")
          return ok and scheme or nil
        end)()
      '';
    };
  };
  colors = p: ''
    [colors]
    foreground = "${p.text}"
    background = "${p.bg}"
    cursor_fg = "${p.bg}"
    cursor_bg = "${p.primary}"
    cursor_border = "${p.primary}"
    selection_fg = "${p.text}"
    selection_bg = "${p.surfaceHigh}"
    split = "${p.surfaceHigh}"
    scrollbar_thumb = "${p.surfaceHigh}"
    ansi = ["${p.black}", "${p.red}", "${p.green}", "${p.yellow}", "${p.blue}", "${p.magenta}", "${p.cyan}", "${p.white}"]
    brights = ["${p.brightBlack}", "${p.brightRed}", "${p.brightGreen}", "${p.brightYellow}", "${p.brightBlue}", "${p.brightMagenta}", "${p.brightCyan}", "${p.brightWhite}"]

    [colors.tab_bar]
    background = "${p.base}"

    [colors.tab_bar.active_tab]
    bg_color = "${p.surfaceHigh}"
    fg_color = "${p.text}"

    [colors.tab_bar.inactive_tab]
    bg_color = "${p.bg}"
    fg_color = "${p.muted}"

    [colors.tab_bar.inactive_tab_hover]
    bg_color = "${p.surface}"
    fg_color = "${p.text}"

    [colors.tab_bar.new_tab]
    bg_color = "${p.bg}"
    fg_color = "${p.muted}"

    [colors.tab_bar.new_tab_hover]
    bg_color = "${p.surface}"
    fg_color = "${p.text}"
  '';
}

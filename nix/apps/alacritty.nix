# alacritty: import it from the config, `general.import = ["~/.local/state/nix/quickshell/alacritty.toml"]`: Alacritty reads an imported file
# again when it changes, so the open terminals follow the mode. The sixteen colors are the ones of xterm
# `program` is the name under programs.<program> of Home Manager: when it is enabled the app is found, and `wire` puts the include in its
# config. `target` is the name in the state folder, `reload` runs when the file there changed (or at each `nix-quickshell apps` when `always`), with the
# path of the file in $NIX_QUICKSHELL_FILE. A file that is not here is not an app of nix-quickshell: add one, and `targets.<name>` is there
{
  program = "alacritty";
  target = "alacritty.toml";
  reload = null;
  always = false;
  wire = path: { programs.alacritty.settings.general.import = [ path ]; };
  colors = p: ''
    [colors.primary]
    background = "${p.bg}"
    foreground = "${p.text}"

    [colors.cursor]
    text = "${p.bg}"
    cursor = "${p.primary}"

    [colors.selection]
    text = "${p.text}"
    background = "${p.surfaceHigh}"

    [colors.normal]
    black = "${p.black}"
    red = "${p.red}"
    green = "${p.green}"
    yellow = "${p.yellow}"
    blue = "${p.blue}"
    magenta = "${p.magenta}"
    cyan = "${p.cyan}"
    white = "${p.white}"

    [colors.bright]
    black = "${p.brightBlack}"
    red = "${p.brightRed}"
    green = "${p.brightGreen}"
    yellow = "${p.brightYellow}"
    blue = "${p.brightBlue}"
    magenta = "${p.brightMagenta}"
    cyan = "${p.brightCyan}"
    white = "${p.brightWhite}"
  '';
}

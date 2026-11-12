# kitty: `include` it from kitty.conf, `include ~/.local/state/nix-quickshell/kitty.conf`: `nix-quickshell apps` sends SIGUSR1 to kitty when the file
# changes, which reads its config again in every window, so the open terminals follow the mode
# `program` is the name under programs.<program> of Home Manager: when it is enabled the app is found, and `wire` puts the include in its
# config. `target` is the name in the state folder, `reload` runs when the file there changed (or at each `nix-quickshell apps` when `always`), with the
# path of the file in $NIX_QUICKSHELL_FILE. A file that is not here is not an app of nix-quickshell: add one, and `targets.<name>` is there
{
  program = "kitty";
  target = "kitty.conf";
  reload = "pkill -USR1 -x '\\.?kitty(-wrapped)?'";
  always = false;
  wire = path: { programs.kitty.extraConfig = "include ${path}"; };
  colors = p: ''
    background ${p.bg}
    foreground ${p.text}
    cursor ${p.primary}
    cursor_text_color ${p.bg}
    selection_foreground ${p.text}
    selection_background ${p.surfaceHigh}
    color0 ${p.black}
    color1 ${p.red}
    color2 ${p.green}
    color3 ${p.yellow}
    color4 ${p.blue}
    color5 ${p.magenta}
    color6 ${p.cyan}
    color7 ${p.white}
    color8 ${p.brightBlack}
    color9 ${p.brightRed}
    color10 ${p.brightGreen}
    color11 ${p.brightYellow}
    color12 ${p.brightBlue}
    color13 ${p.brightMagenta}
    color14 ${p.brightCyan}
    color15 ${p.brightWhite}
  '';
}

# xresources: the colors of xterm, merged with xrdb. The sixteen colors of the terminal are the hues of the palette of NixOS: light ones on dark, and
# darker ones on light, so that a prompt is read in both
# `program` is the name under programs.<program> of Home Manager: when it is enabled the app is found, and `wire` puts the include in its
# config. `target` is the name in the state folder, `reload` runs when the file there changed (or at each `nshell apps` when `always`), with the
# path of the file in $NSHELL_FILE. A file that is not here is not an app of nix-quickshell: add one, and `targets.<name>` is there
{
  program = null;
  target = "xresources";
  reload = "xrdb -merge \"$NSHELL_FILE\"";
  always = true;
  wire = _: { };
  colors = p: ''
    XTerm*background: ${p.bg}
    XTerm*foreground: ${p.text}
    XTerm*cursorColor: ${p.primary}
    XTerm*color0: ${p.black}
    XTerm*color1: ${p.red}
    XTerm*color2: ${p.green}
    XTerm*color3: ${p.yellow}
    XTerm*color4: ${p.blue}
    XTerm*color5: ${p.magenta}
    XTerm*color6: ${p.cyan}
    XTerm*color7: ${p.white}
    XTerm*color8: ${p.brightBlack}
    XTerm*color9: ${p.brightRed}
    XTerm*color10: ${p.brightGreen}
    XTerm*color11: ${p.brightYellow}
    XTerm*color12: ${p.brightBlue}
    XTerm*color13: ${p.brightMagenta}
    XTerm*color14: ${p.brightCyan}
    XTerm*color15: ${p.brightWhite}
  '';
}

# i3: `include` it from the config. The tabs of the tabbed containers are shown by the shell, in its bar (modules/tabs), and i3 draws
# nothing for them, no colors, no title and no icon: the little room that it keeps for them is transparent. The same for both modes
# The patch of i3 that the tabs need is beside this file, i3.patch, and flake.nix applies it as an overlay, see docs/i3.md
# The apps have `program`, `target`, `reload`, `always` and `wire`: see the others in this folder. i3 is no Home Manager program, so it is on when asked for
{
  program = null;
  target = "i3.conf";
  # the tabs are drawn again with the colors of the mode
  reload = "i3-msg reload";
  always = false;
  wire = _: { };
  colors = _: ''
    client.focused          #00000000 #00000000 #00000000 #00000000 #00000000
    client.focused_inactive #00000000 #00000000 #00000000 #00000000 #00000000
    client.unfocused        #00000000 #00000000 #00000000 #00000000 #00000000
    client.urgent           #00000000 #00000000 #00000000 #00000000 #00000000
    client.placeholder      #00000000 #00000000 #00000000 #00000000 #00000000
    client.background       #00000000
    for_window [all] title_format " "
    for_window [all] title_window_icon off
  '';
}

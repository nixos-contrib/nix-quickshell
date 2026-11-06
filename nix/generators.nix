# The files of the apps that are not the shell, from a palette: the roles of one mode of a theme, as in flavours/*.json. Each is a
# fragment that a config of the user includes, so that the user keeps the rest of the file
palette:

let
  p = palette;
in
{
  # The named colors that adw-gtk3 reads, and libadwaita: with them the theme draws every GTK app in the palette. And the few rules for what the
  # theme draws with a veil of the text color, which no named color changes (a field, the hover of a row, a tip). Import it from
  # gtk-3.0/gtk.css and gtk-4.0/gtk.css: @import url("../nix-quickshell/gtk.css");
  gtk = ''
    @define-color window_bg_color ${p.bg};
    @define-color window_fg_color ${p.text};
    @define-color view_bg_color ${p.bg};
    @define-color view_fg_color ${p.text};
    @define-color headerbar_bg_color ${p.surface};
    @define-color headerbar_fg_color ${p.text};
    @define-color headerbar_backdrop_color ${p.bg};
    @define-color card_bg_color ${p.surface};
    @define-color card_fg_color ${p.text};
    @define-color popover_bg_color ${p.surface};
    @define-color popover_fg_color ${p.text};
    @define-color sidebar_bg_color ${p.bg};
    @define-color sidebar_fg_color ${p.text};
    @define-color sidebar_backdrop_color ${p.bg};
    @define-color dialog_bg_color ${p.surface};
    @define-color dialog_fg_color ${p.text};
    @define-color accent_bg_color ${p.accent};
    @define-color accent_fg_color ${p.textOnAccent};
    @define-color accent_color ${p.primary};
    @define-color destructive_bg_color ${p.critical};
    @define-color destructive_fg_color ${p.textOnPrimary};
    @define-color destructive_color ${p.critical};
    @define-color success_bg_color ${p.success};
    @define-color success_fg_color ${p.textOnPrimary};
    @define-color success_color ${p.success};
    @define-color warning_bg_color ${p.warning};
    @define-color warning_fg_color ${p.textOnPrimary};
    @define-color warning_color ${p.warning};
    @define-color error_bg_color ${p.critical};
    @define-color error_fg_color ${p.textOnPrimary};
    @define-color error_color ${p.critical};

    /* adw-gtk3 draws a field and the hover of a row as a veil of the text color, which is grey on white and almost grey on the dark navy:
       here they are the surface of the palette, as the fields and the cards of the shell are. What is selected is the accent, as it was */
    entry, spinbutton:not(.vertical) { background-color: @card_bg_color; }
    treeview.view:not(:backdrop):not(:selected):hover { background-color: @card_bg_color; }
    /* the menus of a menu bar are round in adw-gtk3, for a popup window with an alpha channel, which a menu has not here: the corners
       outside the round were black. They are square, as the context menus are */
    menubar > menuitem menu:dir(rtl), menubar > menuitem menu:dir(ltr),
    .menubar > menuitem menu:dir(rtl), .menubar > menuitem menu:dir(ltr),
    menubar .csd.popup decoration, .menubar .csd.popup decoration { border-radius: 0; }
    /* a tip is a card of the palette, and not black on both modes */
    tooltip.background { background-color: @popover_bg_color; color: @popover_fg_color; border: 1px solid alpha(currentColor, 0.15); border-radius: 10px; }
    tooltip.background * { background-color: transparent; color: @popover_fg_color; }
  '';

  # xterm: load it with xrdb -merge. The sixteen colors of the terminal are the hues of the palette of NixOS: light ones on dark, and
  # darker ones on light, so that a prompt is read in both
  xresources = ''
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

  # zathura: `include` it from zathurarc
  zathura = ''
    set default-bg "${p.surface}"
    set default-fg "${p.text}"
    set statusbar-bg "${p.bg}"
    set statusbar-fg "${p.text}"
    set inputbar-bg "${p.bg}"
    set inputbar-fg "${p.text}"
    set notification-bg "${p.surface}"
    set notification-fg "${p.text}"
    set notification-error-bg "${p.critical}"
    set notification-error-fg "${p.textOnPrimary}"
    set notification-warning-bg "${p.warning}"
    set notification-warning-fg "${p.textOnPrimary}"
    set completion-bg "${p.surface}"
    set completion-fg "${p.text}"
    set completion-highlight-bg "${p.surfaceHigh}"
    set completion-highlight-fg "${p.text}"
    set highlight-color "${p.warning}"
    set highlight-active-color "${p.accent}"
    set recolor-lightcolor "${p.bg}"
    set recolor-darkcolor "${p.text}"
    set recolor-keephue true
  '';

  # i3: `include` it from the config. The tabs of the tabbed containers are shown by the shell, in its bar (modules/tabs), and i3 draws
  # nothing for them, no colors, no title and no icon: the little room that it keeps for them is transparent. The same for both modes
  i3 = ''
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

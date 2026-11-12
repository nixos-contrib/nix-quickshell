# The GTK theme from a palette, the roles of one mode of a theme, as in themes/*.json: the named colors that adw-gtk3 reads, and libadwaita. With
# them the theme draws every GTK app in the palette, and the few rules for what the theme draws with a veil of the text color, which no named
# color changes (a field, the hover of a row, a tip). GTK is not one of the apps of apps/: it is the base of the desktop, and the shell tells the
# GTK apps the theme of the mode itself, see `nix-quickshell apps`
palette:

let
  p = palette;
in
''
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
    /* what is selected, in every list: the same step of the palette as the lit tile of the bar. adw-gtk3 paints a selected row of a tree as a veil of
       the accent and Thunar paints its list with the named colors below (the accent, solid), so two lists had two looks */
    @define-color theme_selected_bg_color ${p.surfaceHigh};
    @define-color theme_selected_fg_color ${p.text};
    @define-color selected_bg_color ${p.surfaceHigh};
    @define-color selected_fg_color ${p.text};

    /* adw-gtk3 draws a field and the hover of a row as a veil of the text color, which is grey on white and almost grey on the dark navy:
       here they are the surface of the palette, as the fields and the cards of the shell are, with the hairline of a card: the wallpaper is the
       same color, and a field without an edge looked like a hole in the window. The accent is for what is active, not for what is selected */
    entry, spinbutton:not(.vertical) { background-color: @card_bg_color; border: 1px solid alpha(currentColor, 0.15); }
    treeview.view:selected, treeview.view:selected:focus, iconview:selected, iconview:selected:focus, row:selected, row:selected:focus {
      background-color: @theme_selected_bg_color; color: @theme_selected_fg_color;
    }
    treeview.view:not(:backdrop):not(:selected):hover { background-color: @card_bg_color; }
    /* the menus of a menu bar are round in adw-gtk3, for a popup window with an alpha channel, which a menu has not here: the corners
       outside the round were black. They are square, as the context menus are */
    menubar > menuitem menu:dir(rtl), menubar > menuitem menu:dir(ltr),
    .menubar > menuitem menu:dir(rtl), .menubar > menuitem menu:dir(ltr),
    menubar .csd.popup decoration, .menubar .csd.popup decoration { border-radius: 0; }
    /* a tip is a card of the palette, and not black on both modes */
    tooltip.background { background-color: @popover_bg_color; color: @popover_fg_color; border: 1px solid alpha(currentColor, 0.15); border-radius: 10px; }
    tooltip.background * { background-color: transparent; color: @popover_fg_color; }
''

# The files of the apps that are not the shell, from a palette: the roles of one mode of a theme, as in themes/*.json. Each is a
# fragment that a config of the user includes, so that the user keeps the rest of the file
palette:

let
  p = palette;
in
{
  # The named colors that adw-gtk3 reads, and libadwaita: with them the theme draws every GTK app in the palette. Import it from
  # gtk-3.0/gtk.css and gtk-4.0/gtk.css: @import url("../nix-shell/gtk.css");
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
    @define-color accent_fg_color ${p.onFill};
    @define-color accent_color ${p.primary};
    @define-color destructive_bg_color ${p.critical};
    @define-color destructive_fg_color ${p.onPrimary};
    @define-color destructive_color ${p.critical};
    @define-color success_bg_color ${p.success};
    @define-color success_fg_color ${p.onPrimary};
    @define-color success_color ${p.success};
    @define-color warning_bg_color ${p.warning};
    @define-color warning_fg_color ${p.onPrimary};
    @define-color warning_color ${p.warning};
    @define-color error_bg_color ${p.critical};
    @define-color error_fg_color ${p.onPrimary};
    @define-color error_color ${p.critical};
  '';

  # xterm: load it with xrdb -merge
  xresources = ''
    XTerm*background: ${p.bg}
    XTerm*foreground: ${p.text}
    XTerm*cursorColor: ${p.primary}
  '';

  # zathura: `include` it from zathurarc
  zathura = ''
    set default-bg "${p.bg}"
    set default-fg "${p.text}"
    set statusbar-bg "${p.bg}"
    set statusbar-fg "${p.text}"
    set inputbar-bg "${p.bg}"
    set inputbar-fg "${p.text}"
    set notification-bg "${p.surface}"
    set notification-fg "${p.text}"
    set notification-error-bg "${p.critical}"
    set notification-error-fg "${p.onPrimary}"
    set notification-warning-bg "${p.warning}"
    set notification-warning-fg "${p.onPrimary}"
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

  # i3: `include` it from the config. The tabs of the stacked and tabbed layouts: the one in use is a tile in surfaceHigh when its
  # container has the focus and in surface when it has not, the others are text on the base. Order of the colors: border,
  # background, text, indicator and the border of the window
  i3 = ''
    client.focused          ${p.surfaceHigh} ${p.surfaceHigh} ${p.text} ${p.surfaceHigh} ${p.surfaceHigh}
    client.focused_inactive ${p.surface} ${p.surface} ${p.text} ${p.surface} ${p.surface}
    client.unfocused        #00000000 #00000000 ${p.muted} #00000000 #00000000
    client.urgent           ${p.critical} ${p.critical} ${p.onPrimary} ${p.critical} ${p.critical}
    client.placeholder      ${p.base} ${p.base} ${p.text} ${p.base} ${p.base}
    client.background       ${p.base}
  '';
}

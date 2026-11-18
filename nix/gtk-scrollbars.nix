# The scrollbars of the GTK apps as on macOS: a round thumb on the content, with no track, that gets darker
# and wider under the pointer. With Gtk/OverlayScrolling, which the module sets as well, adw-gtk3 hides the
# thumb until the content scrolls. The sizes are in pixels of the screen, and adw-gtk3 draws the thumb 3
# pixels wide, which is thin on a screen with more pixels than points. The selectors are as long as those of
# adw-gtk3, so that these win in its theme. GTK 4 takes the file as the rules of the user, which win anyway
{ thickness, hoverThickness, ... }:

''
  scrollbar trough { background-color: transparent; }
  scrollbar slider { border-radius: 999px; background-color: alpha(@window_fg_color, 0.4); }
  scrollbar slider:hover, scrollbar slider:active { background-color: alpha(@window_fg_color, 0.6); }
  scrollbar.overlay-indicator:not(.dragging):not(.hovering).vertical slider { min-width: ${toString thickness}px; }
  scrollbar.overlay-indicator:not(.dragging):not(.hovering).horizontal slider { min-height: ${toString thickness}px; }
  scrollbar.overlay-indicator.vertical.hovering slider, scrollbar.overlay-indicator.vertical.dragging slider {
    min-width: ${toString hoverThickness}px;
  }
  scrollbar.overlay-indicator.horizontal.hovering slider, scrollbar.overlay-indicator.horizontal.dragging slider {
    min-height: ${toString hoverThickness}px;
  }
''

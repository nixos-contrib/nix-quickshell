# zathura: `include` it from zathurarc
# `program` is the name under programs.<program> of Home Manager: when it is enabled the app is found, and `wire` puts the include in its
# config. `target` is the name in the state folder, `reload` runs when the file there changed (or at each `nshell apps` when `always`), with the
# path of the file in $NSHELL_FILE. A file that is not here is not an app of nix-quickshell: add one, and `integration.apps.<name>` is there
{
  program = "zathura";
  target = "zathurarc";
  reload = null;
  always = false;
  wire = path: { programs.zathura.extraConfig = "include ${path}"; };
  colors = p: ''
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
}

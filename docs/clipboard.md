# The clipboard history

The launcher has a third mode, the history of the clipboard: `nshell launcher clipboard`, or Tab from the other two. It lists what
was copied, newest first, with when, and a search narrows it. Enter puts the copy back on the clipboard, and the window closes:
the paste is yours, in the app that had the focus.

The shell does not watch the clipboard. [clipmenu](https://github.com/cdown/clipmenu) does, and the system runs it; the shell reads
what it keeps. Without it the mode is an empty list.

## What the system needs

- `clipmenud` running in the session, with `xclip` in the path (the copy goes back with it). With Home Manager:

```nix
services.clipmenu.enable = true;
systemd.user.services.clipmenu.Service.Environment = [
  "CM_SELECTIONS=clipboard"   # not what is selected with the mouse
  "CM_MAX_CLIPS=50"           # a short history
  "CM_IGNORE_WINDOW=1Password" # a regex on the title of the window that has the focus, not recorded there
];
```

- A key in i3: `bindsym $mod+Shift+v exec --no-startup-id nshell launcher clipboard`.

## Where it is kept, and what it holds

`$XDG_RUNTIME_DIR/clipmenu.6.$USER/`: the runtime directory is memory (tmpfs) and goes with the session, with the mode 0700. The
file `line_cache` has a line for each copy, `<time in ns> <first line>`, and each copy is a file named by the checksum of its first
line. `modules/launcher/clipboard-list.sh` prints the list, and the text is not read until a copy is chosen.

## What it does not protect

- A password that the extension of a password manager copies in the browser is recorded: the window that has the focus is the
  browser, and a rule on it would drop every copy from the browser. The manager clears the clipboard after a time, the history does
  not. `clipdel` (of clipmenu) deletes entries, and `clipctl disable` stops the recording while a secret is copied.
- The clipboard that Parallels shares with the Mac is a copy like the others, and what comes through it is in the history.
- The first line is what the list shows on the screen, so a window that is shared shows it.

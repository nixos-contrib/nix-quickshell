import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.notifications
import qs.modules.polkit

ShellRoot {
    Notifications { id: center }
    Polkit {}
    // NSHELL_NO_BAR=1 runs the shell without its bar, to try the notifications beside another one
    Loader {
        active: Quickshell.env("NSHELL_NO_BAR") !== "1"
        sourceComponent: Bar { notifications: center }
    }
}

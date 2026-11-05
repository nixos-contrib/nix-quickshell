import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd
import qs.modules.polkit

ShellRoot {
    Notifications { id: center }
    Polkit {}
    Osd { suppressed: center.popupOpen }
    Launcher { id: appLauncher }
    // NSHELL_NO_BAR=1 runs the shell without its bar, to try the notifications beside another one
    Loader {
        active: Quickshell.env("NSHELL_NO_BAR") !== "1"
        sourceComponent: Bar { notifications: center; launcher: appLauncher }
    }
}

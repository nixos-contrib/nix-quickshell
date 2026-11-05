import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.common
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd
import qs.modules.polkit
import qs.modules.theme

ShellRoot {
    Appearance {}
    Notifications { id: center }
    Polkit {}
    Osd { suppressed: center.popupOpen }
    Launcher { id: appLauncher }
    // NSHELL_NO_BAR=1 runs the shell without its bar, to try the notifications beside another one
    Loader {
        id: barLoader
        active: Quickshell.env("NSHELL_NO_BAR") !== "1"
        sourceComponent: Bar { notifications: center; launcher: appLauncher }
    }
    // A popup closes on a click anywhere outside of it, the wallpaper too, see ClickAway
    ClickAway {
        active: center.popupOpen || center.centerOpen || appLauncher.open
        barHeight: Theme.barHeight * (Quickshell.screens.length > 0 ? Quickshell.screens[0].devicePixelRatio : 1)
        onOutside: {
            center.closeCenter();
            appLauncher.hide();
            if (barLoader.item)
                barLoader.item.closePopups();
        }
    }
}

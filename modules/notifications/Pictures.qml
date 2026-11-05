pragma Singleton
import QtQuick
import Quickshell

// The picture of a notification, the same for the toast and the history. The first of these that exists:
//   1. the image that came with it, a photo or an avatar, which Electron apps send as data
//   2. the icon the app named: a name of the icon theme, or a path
//   3. the icon of the desktop entry of the app, found by its name
// An empty string when there is none
Singleton {
    function of(image: string, appIcon: string, appName: string, desktopEntry: string): string {
        if (image !== "")
            return image;
        if (appIcon !== "") {
            if (appIcon.startsWith("/"))
                return "file://" + appIcon;
            const named = Quickshell.iconPath(appIcon, true);
            if (named !== "")
                return named;
        }
        const entry = (desktopEntry !== "" ? DesktopEntries.byId(desktopEntry) : null) ?? DesktopEntries.heuristicLookup(appName);
        if (entry && entry.icon !== "")
            return entry.icon.startsWith("/") ? "file://" + entry.icon : Quickshell.iconPath(entry.icon, true);
        return "";
    }
}

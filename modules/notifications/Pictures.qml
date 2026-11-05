pragma Singleton
import QtQuick
import Quickshell

// The picture of a notification, the same for the toast and the history. The first of these that exists:
//   1. the image that came with it, a photo or an avatar, which Electron apps send as data
//   2. the icon the app named: a name of the icon theme, or a path
//   3. the icon of the desktop entry of the app, found by its name
// An empty string when there is none
Singleton {
    // The name of the icon of the app: the one it named, or the one of its desktop entry. It is what the history keeps of a
    // picture, as the picture itself is an address that does not last: the one of the image of a notification is gone when it
    // closes, and the one of a theme icon changes with the system
    function iconName(image: string, appIcon: string, appName: string, desktopEntry: string): string {
        // an icon of the theme or a file that came as the image, as notify-send sends its icon: both last. The raw data of
        // an image does not, and the icon of the app is kept in its place
        if (image.startsWith("image://icon/"))
            return decodeURIComponent(image.substring("image://icon/".length));
        if (image.startsWith("file://"))
            return image.substring("file://".length);
        if (appIcon !== "")
            return appIcon;
        const entry = (desktopEntry !== "" ? DesktopEntries.byId(desktopEntry) : null) ?? DesktopEntries.heuristicLookup(appName);
        return entry ? entry.icon : "";
    }

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

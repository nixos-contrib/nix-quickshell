pragma Singleton
import QtQuick
import Quickshell

// Desktop entries by a name, for what knows an app only by the name it gives itself: a player on the bus, the class of a window. The lookup of
// Quickshell by heuristics did not find Brave by its name, and its list has the entries that the launcher shows
Singleton {
    // an entry by a name that it answers to: its id, its name or the class of its window, in any case, and then one that starts with it and a
    // dash, as brave is brave-browser
    function match(name: string): var {
        if (!name)
            return null;
        const lower = name.toLowerCase();
        const apps = DesktopEntries.applications.values;
        return DesktopEntries.byId(name)
            ?? apps.find(e => e.id.toLowerCase() === lower || e.name.toLowerCase() === lower || e.startupClass.toLowerCase() === lower)
            ?? apps.find(e => e.id.toLowerCase().startsWith(lower + "-") || e.startupClass.toLowerCase().startsWith(lower + "-"))
            ?? null;
    }
    // the name to show for a window of this class: the one of its entry, and the class when there is none
    function nameOfClass(cls: string): string {
        const entry = match(cls);
        return entry && entry.name !== "" ? entry.name : cls;
    }
}

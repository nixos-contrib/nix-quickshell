pragma Singleton
import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Services.Mpris

// The players of the desktop, for the item in the bar and its popup: any program that speaks MPRIS, a browser, a music app, a video player.
// The active player is the one that plays, or the one that was paused when none plays; a player that is stopped is not shown. The popup can
// choose another for as long as it is open, and the bar always follows the one that plays
Singleton {
    id: media

    readonly property var players: Mpris.players.values
    readonly property var playing: players.find(p => p.playbackState === MprisPlaybackState.Playing) ?? null
    readonly property var paused: players.find(p => p.playbackState === MprisPlaybackState.Paused) ?? null
    // the one the popup chose, kept while it is there
    property var selected: null
    readonly property var active: (selected !== null && players.includes(selected)) ? selected : (playing ?? paused ?? null)
    // there is something to show: a player that plays or that is paused
    readonly property bool present: active !== null && active.playbackState !== MprisPlaybackState.Stopped

    // "Title - Artist", or the title, for the tip
    readonly property string summary: {
        if (!present)
            return "";
        const title = active.trackTitle !== "" ? active.trackTitle : active.identity;
        return active.trackArtist !== "" ? title + " – " + active.trackArtist : title;
    }

    // the desktop entry of the app that plays. A player may name it, and Brave does not, so after it the name it gives itself, and then the
    // name in its address on the bus, org.mpris.MediaPlayer2.brave.instance123: brave
    function entryOf(p: var): var {
        if (!p)
            return null;
        const bus = (p.dbusName ?? "").replace(/^org\.mpris\.MediaPlayer2\./, "").replace(/\.instance\d+$/, "");
        for (const name of [p.desktopEntry, p.identity, bus]) {
            if (!name)
                continue;
            const entry = Apps.match(name);
            if (entry)
                return entry;
        }
        return null;
    }
    // the icon of that app, as an address for an Image, or nothing
    function iconOf(p: var): string {
        const entry = entryOf(p);
        if (!entry || entry.icon === "")
            return "";
        return entry.icon.startsWith("/") ? "file://" + entry.icon : Quickshell.iconPath(entry.icon, true);
    }
    // the window of the app that plays, to the front: i3 finds it by the class of its desktop entry, on whatever workspace it is, and does
    // not start the app when it has none. A player that has no entry is asked to raise itself, which is what MPRIS has for it
    function focusApp(p: var): void {
        if (!p)
            return;
        const entry = entryOf(p);
        if (entry && entry.startupClass !== "") {
            const cls = entry.startupClass.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
            I3.dispatch(`[class="(?i)^${cls}$"] focus`);
        } else if (p.canRaise) {
            p.raise();
        }
    }

    // "3:07", "1:02:11": a time in seconds, as a player says it
    function clock(seconds: real): string {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00";
        const total = Math.floor(seconds);
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        return (h > 0 ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(s).padStart(2, "0");
    }
}

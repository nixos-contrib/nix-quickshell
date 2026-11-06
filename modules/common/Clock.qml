pragma Singleton
import QtQuick
import Quickshell

// The time of the shell, to the minute: the cards say how long ago they came, and the bar will say the hour
Singleton {
    readonly property date date: system.date

    // "now", "5m ago", "2h ago", "3d ago"
    function ago(seconds: int): string {
        const diff = Math.max(0, Math.floor(date.getTime() / 1000) - seconds);
        if (diff < 60)
            return "now";
        if (diff < 3600)
            return Math.floor(diff / 60) + "m ago";
        if (diff < 86400)
            return Math.floor(diff / 3600) + "h ago";
        return Math.floor(diff / 86400) + "d ago";
    }

    SystemClock {
        id: system
        precision: SystemClock.Minutes
    }
}

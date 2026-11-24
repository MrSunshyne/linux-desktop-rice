pragma Singleton
// MPRIS players. `active` is the one playing, else the first one.
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    readonly property var players: Mpris.players.values
    readonly property var active: players.find(p => p.isPlaying) ?? players[0] ?? null

    function formatTime(s) {
        if (!isFinite(s) || s < 0) return "0:00";
        s = Math.floor(s);
        const m = Math.floor(s / 60), r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }
}

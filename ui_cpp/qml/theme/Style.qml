pragma Singleton
import QtQuick

QtObject {
    // Spotify Dark Color Palette
    readonly property color background: "#121212"
    readonly property color sidebarBackground: "#000000"
    readonly property color surface: "#181818"
    readonly property color surfaceHover: "#282828"
    readonly property color playerBackground: "#181818"
    
    // Accents
    readonly property color primary: "#1DB954"
    readonly property color primaryHover: "#1ed760"
    readonly property color primaryPressed: "#169c46"
    readonly property color accent: "#1DB954"
    
    // Typography
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#B3B3B3"
    readonly property color textMuted: "#727272"
    readonly property color divider: "#282828"
    readonly property color border: "#333333"

    // Metrics
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 8
    readonly property int radiusLarge: 12
    readonly property int playerBarHeight: 90
    readonly property int sidebarWidth: 240

    function formatTime(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00";
        var totalSec = Math.floor(seconds);
        var mins = Math.floor(totalSec / 60);
        var secs = totalSec % 60;
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }
}

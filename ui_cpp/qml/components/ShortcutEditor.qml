import QtQuick
import Melyar.Theme

Item {
    id: root

    property var shortcuts: {}
    signal shortcutChanged(string action, string key)

    Column {
        width: parent.width
        spacing: Style.space1

        Repeater {
            model: [
                { action: "playPause", label: "Play / Pause" },
                { action: "nextTrack", label: "Next Track" },
                { action: "previousTrack", label: "Previous Track" },
                { action: "volumeUp", label: "Volume Up" },
                { action: "volumeDown", label: "Volume Down" },
                { action: "seekForward", label: "Seek Forward (+5s)" },
                { action: "seekBackward", label: "Seek Backward (-5s)" },
                { action: "toggleLyrics", label: "Toggle Lyrics" },
                { action: "toggleQueue", label: "Toggle Queue" },
                { action: "toggleShuffle", label: "Toggle Shuffle" },
                { action: "toggleRepeat", label: "Toggle Repeat" },
                { action: "mute", label: "Mute / Unmute" },
                { action: "search", label: "Focus Search" }
            ]

            delegate: ShortcutRow {
                label: modelData.label
                action: modelData.action
                currentKey: shortcuts[modelData.action]
                onKeyChanged: parent.shortcutChanged(action, key)
            }
        }
    }
}
import QtQuick
import Melyar.Theme

Rectangle {
    id: root
    color: Style.background

    property var lyricsLines: []
    property int activeIndex: -1

    // Parse LRC string when bridge.currentLyrics changes
    Connections {
        target: bridge
        function onLyricsChanged() {
            root.parseLrc(bridge.currentLyrics);
        }
        function onProgressUpdated(current, total) {
            root.updateActiveLine(current);
        }
    }

    Component.onCompleted: {
        parseLrc(bridge.currentLyrics);
    }

    function parseLrc(lrcText) {
        if (!lrcText || lrcText.trim() === "") {
            lyricsLines = [];
            activeIndex = -1;
            return;
        }

        var lines = lrcText.split("\n");
        var parsed = [];
        var regex = /\[(\d{2}):(\d{2})\.?(\d{0,3})\](.*)/;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            var match = regex.exec(line);
            if (match) {
                var min = parseInt(match[1]);
                var sec = parseInt(match[2]);
                var ms = match[3] ? parseInt(match[3].padEnd(3, '0')) : 0;
                var time = min * 60 + sec + ms / 1000.0;
                var text = match[4].trim();
                if (text !== "") {
                    parsed.push({ time: time, text: text });
                }
            } else if (line !== "" && !line.startsWith("[")) {
                // Plain lyrics fallback line
                parsed.push({ time: i * 3.5, text: line });
            }
        }

        parsed.sort(function(a, b) { return a.time - b.time; });
        lyricsLines = parsed;
        updateActiveLine(bridge.currentPosition);
    }

    function updateActiveLine(currentSecs) {
        if (lyricsLines.length === 0) {
            activeIndex = -1;
            return;
        }

        var found = -1;
        for (var i = 0; i < lyricsLines.length; i++) {
            if (lyricsLines[i].time <= currentSecs + 0.2) {
                found = i;
            } else {
                break;
            }
        }

        if (found !== activeIndex) {
            activeIndex = found;
            if (found >= 0) {
                lyricsList.positionViewAtIndex(found, ListView.Center);
            }
        }
    }

    // Blurred background album art glow
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.6
        z: 0
    }

    ListView {
        id: lyricsList
        anchors.fill: parent
        anchors.topMargin: 40
        anchors.bottomMargin: 40
        model: root.lyricsLines
        clip: true
        spacing: 24
        boundsBehavior: Flickable.StopAtBounds

        Behavior on contentY {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            width: lyricsList.width
            height: lyricText.implicitHeight + 16

            property bool isCurrent: index === root.activeIndex

            Text {
                id: lyricText
                anchors.centerIn: parent
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
                text: modelData.text
                font.pixelSize: parent.isCurrent ? 24 : 18
                font.bold: parent.isCurrent
                color: parent.isCurrent ? Style.textPrimary : Style.textMuted
                opacity: parent.isCurrent ? 1.0 : (Math.abs(index - root.activeIndex) <= 1 ? 0.6 : 0.25)
                wrapMode: Text.WordWrap

                Behavior on font.pixelSize {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }
                Behavior on color {
                    ColorAnimation { duration: 250 }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    bridge.seek(modelData.time);
                }
            }
        }
    }

    // Empty state
    Column {
        anchors.centerIn: parent
        spacing: 12
        visible: root.lyricsLines.length === 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "🎤"
            font.pixelSize: 48
            color: Style.textMuted
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: bridge.currentTrackId !== "" ? "No synchronized lyrics available" : "Play a song to view lyrics"
            color: Style.textSecondary
            font.pixelSize: 16
        }
    }
}

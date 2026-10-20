import QtQuick
import QtQuick.Layouts
import components 1.0
import Melyar.Theme

Item {
    id: lyricsView
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 60

        // Sol Panel: Dev Albüm Kapağı
        ColumnLayout {
            Layout.preferredWidth: parent.width * 0.38
            Layout.alignment: Qt.AlignVCenter
            spacing: 24

            GlassCard {
                Layout.preferredWidth: 340
                Layout.preferredHeight: 340
                Layout.alignment: Qt.AlignHCenter
                radius: 28

                Image {
                    anchors.fill: parent
                    anchors.margins: 8
                    source: bridge.currentThumbnail
                    fillMode: Image.PreserveAspectCrop
                    visible: bridge.currentThumbnail !== "" && bridge.currentTrackId !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: Style.textMuted
                    font.pixelSize: 40
                    visible: bridge.currentThumbnail === "" || bridge.currentTrackId === ""
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Text {
                    text: bridge.currentTitle !== "" ? bridge.currentTitle : ""
                    color: Style.textPrimary
                    font.pixelSize: 26
                    font.bold: true
                }

                Text {
                    text: bridge.currentArtist !== "" ? bridge.currentArtist : ""
                    color: Style.textSecondary
                    font.pixelSize: 18
                }
            }
        }

        // Sağ Panel: Akıcı Senkronize Sözler (Karaoke Scroll)
        ListView {
            id: lyricsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 24
            preferredHighlightBegin: height * 0.35
            preferredHighlightEnd: height * 0.5
            highlightMoveDuration: 400

            model: bridge.currentLyrics !== "" ? parsedLyrics : []

            delegate: Item {
                width: lyricsList.width
                height: lyricText.implicitHeight + 16

                property bool isActive: bridge.currentPosition >= modelData.at && bridge.currentPosition < (modelData.endTime || 9999999)

                onIsActiveChanged: {
                    if (isActive) {
                        lyricsList.positionViewAtIndex(index, ListView.Center);
                    }
                }

                Text {
                    id: lyricText
                    text: modelData.line
                    width: parent.width - 40
                    wrapMode: Text.WordWrap
                    font.pixelSize: isActive ? 34 : 24
                    font.bold: true
                    color: isActive ? Style.textPrimary : Style.textMuted

                    Behavior on font.pixelSize { NumberAnimation { duration: 250 } }
                    Behavior on color { ColorAnimation { duration: 250 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var ratio = modelData.at / (bridge.currentDuration > 0 ? bridge.currentDuration : 1)
                            bridge.seek(ratio * bridge.currentDuration)
                        }
                    }
                }
            }
        }
    }

    // LRC parser - bridge.currentLyrics değiştiğinde çalışır
    property var parsedLyrics: []

    Connections {
        target: bridge
        function onLyricsChanged() {
            root.parseLrc(bridge.currentLyrics)
        }
    }

    Component.onCompleted: {
        parseLrc(bridge.currentLyrics)
    }

    function parseLrc(lrcText) {
        if (!lrcText || lrcText.trim() === "") {
            parsedLyrics = []
            return
        }

        var lines = lrcText.split("\n")
        var parsed = []
        var regex = /\[(\d{2}):(\d{2})\.?(\d{0,3})\](.*)/

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            var match = regex.exec(line)
            if (match) {
                var min = parseInt(match[1])
                var sec = parseInt(match[2])
                var ms = match[3] ? parseInt(match[3].padEnd(3, '0')) : 0
                var time = min * 60 + sec + ms / 1000.0
                var text = match[4].trim()
                if (text !== "") {
                    parsed.push({ at: time, line: text })
                }
            } else if (line !== "" && !line.startsWith("[")) {
                parsed.push({ at: i * 3.5, line: line })
            }
        }

        parsed.sort(function(a, b) { return a.time - b.time })

        // Add endTime for each line
        for (var i = 0; i < parsed.length; i++) {
            if (i + 1 < parsed.length) {
                parsed[i].endTime = parsed[i + 1].at
            } else {
                parsed[i].endTime = 9999999
            }
        }

        parsedLyrics = parsed
    }
}

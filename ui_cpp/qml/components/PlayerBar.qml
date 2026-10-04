import QtQuick
import Melyar.Theme

Rectangle {
    id: root
    color: Style.playerBackground
    height: Style.playerBarHeight

    signal toggleLyricsClicked()
    property bool lyricsActive: false

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Style.divider
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        // -------------------------------------------------------------
        // LEFT: Current Track Info
        // -------------------------------------------------------------
        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            width: parent.width * 0.28

            // Thumbnail
            Rectangle {
                width: 56
                height: 56
                radius: Style.radiusSmall
                color: Style.surfaceHover
                clip: true

                Image {
                    anchors.fill: parent
                    source: bridge.currentThumbnail
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: Style.textMuted
                    font.pixelSize: 22
                    visible: bridge.currentThumbnail === ""
                }
            }

            // Title & Artist
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                width: parent.width - 70 - 32
                clip: true

                Text {
                    text: bridge.currentTitle !== "" ? bridge.currentTitle : "No Track Playing"
                    color: Style.textPrimary
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: bridge.currentArtist !== "" ? bridge.currentArtist : "Melyar Player"
                    color: Style.textSecondary
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // Favorite Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: "transparent"
                anchors.verticalCenter: parent.verticalCenter
                visible: bridge.currentTrackId !== ""

                property bool isFav: bridge.isFavorite(bridge.currentTrackId)

                Text {
                    anchors.centerIn: parent
                    text: parent.isFav ? "♥" : "♡"
                    color: parent.isFav ? Style.primary : Style.textSecondary
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bridge.toggleFavorite(
                            bridge.currentTrackId,
                            bridge.currentTitle,
                            bridge.currentArtist,
                            bridge.currentAlbum,
                            bridge.currentDuration,
                            bridge.currentThumbnail
                        );
                        parent.isFav = bridge.isFavorite(bridge.currentTrackId);
                    }
                }
            }
        }

        // -------------------------------------------------------------
        // CENTER: Transport Controls & Seekbar
        // -------------------------------------------------------------
        Column {
            id: centerSection
            anchors.centerIn: parent
            width: parent.width * 0.44
            spacing: 6

            // Control Buttons
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 24

                // Previous Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        color: prevMouse.containsMouse ? Style.textPrimary : Style.textSecondary
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.previousTrack()
                    }
                }

                // Play / Pause Circle Button
                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: playMouse.containsMouse ? Style.primaryHover : Style.primary
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: bridge.isPlaying ? 0 : 1
                        text: bridge.isPlaying ? "❚❚" : "▶"
                        color: "#000000"
                        font.pixelSize: bridge.isPlaying ? 12 : 14
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.togglePlay()
                    }
                }

                // Next Button
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        color: nextMouse.containsMouse ? Style.textPrimary : Style.textSecondary
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.nextTrack()
                    }
                }
            }

            // Seek Bar + Timers
            Row {
                width: parent.width
                spacing: 8
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    text: Style.formatTime(bridge.currentPosition)
                    color: Style.textMuted
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    horizontalAlignment: Text.AlignRight
                }

                // Custom Seek Track Bar
                Rectangle {
                    id: seekTrack
                    width: parent.width - 80
                    height: 4
                    radius: 2
                    color: Style.surfaceHover
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        id: seekProgress
                        height: parent.height
                        radius: 2
                        color: seekMouse.containsMouse ? Style.primary : Style.textPrimary
                        width: {
                            if (bridge.currentDuration > 0) {
                                return Math.min(seekTrack.width, (bridge.currentPosition / bridge.currentDuration) * seekTrack.width);
                            }
                            return 0;
                        }
                    }

                    // Scrubber thumb
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: "#FFFFFF"
                        x: seekProgress.width - 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: seekMouse.containsMouse
                    }

                    MouseArea {
                        id: seekMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: (mouse) => {
                            if (bridge.currentDuration > 0) {
                                var ratio = Math.max(0, Math.min(1, (mouse.x - 6) / seekTrack.width));
                                bridge.seek(ratio * bridge.currentDuration);
                            }
                        }
                    }
                }

                Text {
                    text: Style.formatTime(bridge.currentDuration)
                    color: Style.textMuted
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    horizontalAlignment: Text.AlignLeft
                }
            }
        }

        // -------------------------------------------------------------
        // RIGHT: Lyrics & Volume
        // -------------------------------------------------------------
        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            // Lyrics Toggle Button
            Rectangle {
                width: 32
                height: 32
                radius: Style.radiusSmall
                color: root.lyricsActive ? Style.surfaceHover : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "🎤"
                    font.pixelSize: 15
                    color: root.lyricsActive ? Style.primary : Style.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleLyricsClicked()
                }
            }

            // Volume Section
            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: bridge.volume > 50 ? "🔊" : (bridge.volume > 0 ? "🔉" : "🔇")
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: Style.textSecondary
                }

                Rectangle {
                    id: volumeTrack
                    width: 90
                    height: 4
                    radius: 2
                    color: Style.surfaceHover
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        height: parent.height
                        radius: 2
                        color: volMouse.containsMouse ? Style.primary : Style.textSecondary
                        width: Math.min(volumeTrack.width, (bridge.volume / 100.0) * volumeTrack.width)
                    }

                    MouseArea {
                        id: volMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function updateVolume(mouse) {
                            var ratio = Math.max(0, Math.min(1, (mouse.x - 6) / volumeTrack.width));
                            bridge.setVolume(ratio * 100.0);
                        }

                        onClicked: (mouse) => updateVolume(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateVolume(mouse);
                        }
                    }
                }
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root

    property string playlistId: ""
    signal backClicked()
    signal loadPlaylist()

    Column {
        anchors.fill: parent
        spacing: 0

        // Back button
        Rectangle {
            width: parent.width
            height: 48
            color: "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.space4
                anchors.verticalCenter: parent.verticalCenter

                ActionButton {
                    icon: "←"
                    flat: true
                    size: 32
                    iconSize: 16
                    onClicked: root.backClicked()
                }

                Text {
                    text: "Library"
                    color: Style.textSecondary
                    font.pixelSize: Style.fontSizeBase
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Playlist Hero
        Rectangle {
            width: parent.width
            height: 300
            color: "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space6

                // Playlist Artwork
                Rectangle {
                    width: 200
                    height: 200
                    radius: Style.radiusMedium
                    color: Style.surfaceHover
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "" // playlist artwork
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: Style.border
                        border.width: 1
                    }
                }

                // Playlist Info & Actions
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space3
                    width: parent.width - 280 - Style.space6 * 2

                    Text {
                        text: "PLAYLIST"
                        color: Style.primary
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Text {
                        text: "Playlist Name"
                        color: Style.textPrimary
                        font.pixelSize: Style.fontSize4xl
                        font.bold: true
                        font.weight: Style.fontWeightBold
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Row {
                        spacing: Style.space3

                        Text {
                            text: "By Username • 50 songs, 2hr 30min"
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeBase
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        spacing: Style.space3

                        // Play Button
                        Rectangle {
                            id: playPlaylistBtn
                            height: 48
                            radius: Style.radiusRound
                            color: Style.primary

                            Row {
                                anchors.fill: parent
                                anchors.margins: Style.space4
                                spacing: Style.space2

                                Text {
                                    text: "▶"
                                    color: Style.textOnPrimary
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    text: "Play"
                                    color: Style.textOnPrimary
                                    font.pixelSize: Style.fontSizeBase
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: playPlaylistBtn.color = Style.primaryHover
                                onExited: playPlaylistBtn.color = Style.primary
                            }
                        }

                        // Shuffle Button
                        Rectangle {
                            id: shufflePlaylistBtn
                            height: 48
                            radius: Style.radiusRound
                            color: Style.surfaceHover

                            Row {
                                anchors.fill: parent
                                anchors.margins: Style.space4
                                spacing: Style.space2

                                Text {
                                    text: "🔀"
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: "Shuffle"
                                    color: Style.textPrimary
                                    font.pixelSize: Style.fontSizeBase
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: shufflePlaylistBtn.color = Style.surfacePressed
                                onExited: shufflePlaylistBtn.color = Style.surfaceHover
                            }
                        }

                        // Save Button
                        Rectangle {
                            id: savePlaylistBtn
                            height: 48
                            radius: Style.radiusRound
                            color: Style.surfaceHover

                            Row {
                                anchors.fill: parent
                                anchors.margins: Style.space4
                                spacing: Style.space2

                                Text {
                                    text: "♥"
                                    color: Style.textSecondary
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: "Save"
                                    color: Style.textSecondary
                                    font.pixelSize: Style.fontSizeBase
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: savePlaylistBtn.color = Style.surfacePressed
                                onExited: savePlaylistBtn.color = Style.surfaceHover
                            }
                        }

                        // More Button
                        ActionButton {
                            icon: "⋯"
                            size: 48
                            iconSize: 20
                        }
                    }
                }
            }
        }

        // Playlist Tracks
        Column {
            anchors.fill: parent
            anchors.leftMargin: Style.space6
            anchors.rightMargin: Style.space6

            // Track list header
            Rectangle {
                width: parent.width
                height: 40
                color: "transparent"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space4
                    anchors.rightMargin: Style.space4
                    spacing: Style.space4

                    Text {
                        text: "#"
                        width: 40
                        color: Style.textMuted
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "TITLE"
                        width: parent.width * 0.4
                        color: Style.textMuted
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "ALBUM"
                        width: parent.width * 0.25
                        color: Style.textMuted
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "ADDED"
                        width: parent.width * 0.15
                        color: Style.textMuted
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        font.letterSpacing: 1
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "⏱"
                        width: 60
                        color: Style.textMuted
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        font.letterSpacing: 1
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            ListView {
                anchors.fill: parent
                clip: true
                model: 20 // placeholder
                spacing: 0
                cacheBuffer: 40

                delegate: PlaylistTrackItem {
                    width: parent.ListView.view.width
                    trackData: { title: "Track " + (index + 1); artist: "Artist"; album: "Album"; addedDate: "2024-01-15"; duration: 180 + index * 10 }
                    index: index
                    isCurrent: false
                    isPlaying: false
                    onPlayClicked: console.log("Play track")
                    onAddToQueueClicked: console.log("Add to queue")
                    onContextMenu: trackContextMenu.popup(Qt.point(mouse.x, mouse.y))
                }
            }
        }
    }

    Menu {
        id: trackContextMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }
        MenuItem { text: "Play"; onTriggered: console.log("Play track") }
        MenuItem { text: "Add to Queue"; onTriggered: console.log("Add to queue") }
        MenuItem { text: "Remove from Playlist"; onTriggered: console.log("Remove from playlist") }
        MenuSeparator {}
        MenuItem { text: "Go to Artist"; onTriggered: console.log("Go to artist") }
        MenuItem { text: "Go to Album"; onTriggered: console.log("Go to album") }
        MenuItem { text: "Save to Library"; onTriggered: console.log("Save track") }
        MenuSeparator {}
        MenuItem { text: "Share"; onTriggered: console.log("Share track") }
    }
}
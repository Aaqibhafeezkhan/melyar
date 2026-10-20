import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root

    property string albumId: ""
    signal backClicked()
    signal loadAlbum()

    property var albumData: null
    property var tracks: []

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

        // Album Hero Section
        Rectangle {
            width: parent.width
            height: 300
            color: "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space6

                // Album Artwork
                Rectangle {
                    width: 200
                    height: 200
                    radius: Style.radiusMedium
                    color: Style.surfaceHover
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.albumData ? root.albumData.artwork : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        visible: status === Image.Ready
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: Style.border
                        border.width: 1
                    }
                }

                // Album Info & Actions
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space3
                    width: parent.width - 280 - Style.space6 * 2

                    Row {
                        spacing: Style.space2

                        Text {
                            text: "ALBUM"
                            color: Style.primary
                            font.pixelSize: Style.fontSizeXs
                            font.bold: true
                            font.letterSpacing: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        id: albumTitle
                        text: root.albumData ? root.albumData.title : "Loading..."
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
                            text: root.albumData ? root.albumData.artist : ""
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeLg
                            font.weight: Style.fontWeightMedium
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "•"
                            color: Style.textMuted
                            font.pixelSize: Style.fontSizeLg
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.albumData ? (root.albumData.year + " • " + root.albumData.trackCount + " songs • " + Style.formatTimeLong(root.albumData.duration)) : ""
                            color: Style.textMuted
                            font.pixelSize: Style.fontSizeBase
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Action Buttons
                    Row {
                        spacing: Style.space3

                        // Play Button
                        Rectangle {
                            id: playAlbumBtn
                            height: 48
                            radius: Style.radiusRound
                            color: Style.primary
                            anchors.verticalCenter: parent.verticalCenter

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
                                onEntered: playAlbumBtn.color = Style.primaryHover
                                onExited: playAlbumBtn.color = Style.primary
                                onClicked: console.log("Play album:", root.albumId)
                            }
                        }

                        // Shuffle Button
                        Rectangle {
                            id: shuffleAlbumBtn
                            height: 48
                            radius: Style.radiusRound
                            color: Style.surfaceHover
                            anchors.verticalCenter: parent.verticalCenter

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
                                onEntered: shuffleAlbumBtn.color = Style.surfacePressed
                                onExited: shuffleAlbumBtn.color = Style.surfaceHover
                                onClicked: console.log("Shuffle album:", root.albumId)
                            }
                        }

                        // Save/Unsave Button
                        Rectangle {
                            id: saveAlbumBtn
                            height: 48
                            radius: Style.radiusRound
                            color: root.albumData && root.albumData.saved ? Style.surfaceHover : Style.surface
                            border.color: root.albumData && root.albumData.saved ? Style.primary : Style.border
                            border.width: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Row {
                                anchors.fill: parent
                                anchors.margins: Style.space4
                                spacing: Style.space2

                                Text {
                                    text: "♥"
                                    color: root.albumData && root.albumData.saved ? Style.primary : Style.textSecondary
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: root.albumData && root.albumData.saved ? "Saved" : "Save"
                                    color: root.albumData && root.albumData.saved ? Style.primary : Style.textSecondary
                                    font.pixelSize: Style.fontSizeBase
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: saveAlbumBtn.color = Style.surfacePressed
                                onExited: saveAlbumBtn.color = root.albumData && root.albumData.saved ? Style.surfaceHover : Style.surface
                                onClicked: console.log("Toggle save album:", root.albumId)
                            }
                        }

                        // More Button
                        Rectangle {
                            id: moreAlbumBtn
                            width: 48
                            height: 48
                            radius: 24
                            color: Style.surfaceHover
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: "⋯"
                                color: Style.textSecondary
                                font.pixelSize: 20
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: moreAlbumBtn.color = Style.surfacePressed
                                onExited: moreAlbumBtn.color = Style.surfaceHover
                                onClicked: albumMoreMenu.popup(Qt.point(mouseX + parent.x, mouseY + parent.y))
                            }
                        }
                    }
                }
            }
        }

        // Tracks List
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
                        width: parent.width * 0.5
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
                        visible: false
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

            // Tracks
            ListView {
                id: trackList
                anchors.fill: parent
                clip: true
                model: root.tracks
                spacing: 0
                cacheBuffer: 40

                delegate: AlbumTrackItem {
                    width: parent.ListView.view.width
                    trackData: modelData
                    index: index
                    isCurrent: bridge.currentTrackId === (modelData ? modelData.id : "")
                    isPlaying: bridge.isPlaying && bridge.currentTrackId === (modelData ? modelData.id : "")
                    onPlayClicked: {
                        bridge.playTrack(modelData.id)
                    }
                    onAddToQueueClicked: {
                        bridge.addToQueue(modelData.id)
                    }
                    onContextMenu: trackContextMenu.popup(Qt.point(mouse.x, mouse.y))
                }
            }
        }
    }

    // Context Menu
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
        MenuItem { text: "Add to Playlist..."; onTriggered: console.log("Add to playlist") }
        MenuSeparator {}
        MenuItem { text: "Go to Artist"; onTriggered: console.log("Go to artist") }
        MenuItem { text: "Save to Library"; onTriggered: console.log("Save track") }
        MenuSeparator {}
        MenuItem { text: "Share"; onTriggered: console.log("Share track") }
    }

    Menu {
        id: albumMoreMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }
        MenuItem { text: "Add to Queue"; onTriggered: console.log("Add album to queue") }
        MenuItem { text: "Add to Playlist..."; onTriggered: console.log("Add to playlist") }
        MenuSeparator {}
        MenuItem { text: "Share"; onTriggered: console.log("Share album") }
        MenuItem { text: "Report"; onTriggered: console.log("Report album") }
    }
}
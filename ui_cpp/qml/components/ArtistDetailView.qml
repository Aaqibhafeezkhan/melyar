import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root

    property string artistId: ""
    signal backClicked()
    signal loadArtist()

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

        // Artist Hero
        Rectangle {
            width: parent.width
            height: 300
            color: "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space6

                // Artist Image (circular)
                Rectangle {
                    width: 200
                    height: 200
                    radius: 100
                    color: Style.surfaceHover
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "" // artist artwork
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

                // Artist Info & Actions
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space3
                    width: parent.width - 280 - Style.space6 * 2

                    Text {
                        text: "ARTIST"
                        color: Style.primary
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        font.letterSpacing: 1
                    }

                    Text {
                        text: "Artist Name"
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
                            text: "1.2M monthly listeners"
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeBase
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        ActionButton {
                            icon: "⋯"
                            size: 32
                            iconSize: 16
                            flat: true
                        }
                    }

                    Row {
                        spacing: Style.space3

                        // Play Button
                        Rectangle {
                            id: playArtistBtn
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
                                onEntered: playArtistBtn.color = Style.primaryHover
                                onExited: playArtistBtn.color = Style.primary
                            }
                        }

                        // Follow Button
                        Rectangle {
                            id: followArtistBtn
                            height: 48
                            radius: Style.radiusRound
                            color: Style.surfaceHover

                            Row {
                                anchors.fill: parent
                                anchors.margins: Style.space4
                                spacing: Style.space2

                                Text {
                                    text: "+"
                                    color: Style.textPrimary
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Text {
                                    text: "Follow"
                                    color: Style.textPrimary
                                    font.pixelSize: Style.fontSizeBase
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: followArtistBtn.color = Style.surfacePressed
                                onExited: followArtistBtn.color = Style.surfaceHover
                            }
                        }
                    }
                }
            }
        }

        // Popular Tracks Section
        Column {
            anchors.fill: parent
            anchors.leftMargin: Style.space6
            anchors.rightMargin: Style.space6

            Text {
                text: "Popular"
                color: Style.textPrimary
                font.pixelSize: Style.fontSizeXl
                font.bold: true
                anchors.leftMargin: Style.space4
            }

            ListView {
                anchors.fill: parent
                clip: true
                model: 10 // placeholder
                spacing: 0
                cacheBuffer: 40

                delegate: AlbumTrackItem {
                    width: parent.ListView.view.width
                    trackData: { title: "Track " + (index + 1); artist: "Artist Name"; duration: 180 + index * 10 }
                    index: index
                    isCurrent: false
                    isPlaying: false
                }
            }
        }
    }
}
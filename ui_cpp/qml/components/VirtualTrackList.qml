import QtQuick
import Melyar.Theme

Item {
    id: root

    property alias model: listView.model
    property string emptyMessage: "No tracks found"

    signal trackClicked(string trackId)
    signal trackContextMenu(variant mouse)

    // Header row
    Rectangle {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        color: "transparent"

        Row {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

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
                width: parent.width * 0.45
                color: Style.textMuted
                font.pixelSize: Style.fontSizeXs
                font.bold: true
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "ALBUM"
                width: parent.width * 0.35
                color: Style.textMuted
                font.pixelSize: Style.fontSizeXs
                font.bold: true
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "⏱"
                width: 50
                color: Style.textMuted
                font.pixelSize: Style.fontSizeXs
                font.bold: true
                font.letterSpacing: 1
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            height: 1
            color: Style.divider
        }
    }

    // High performance virtualized list
    ListView {
        id: listView
        anchors.top: headerRow.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true

        // Strict buffer limit for memory minimization (<=25MB RAM target)
        cacheBuffer: 60
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: rowItem
            width: listView.width
            height: 56
            color: itemMouse.containsMouse ? Style.surfaceHover : "transparent"
            radius: Style.radiusSmall

            property var trackData: modelData
            property bool isCurrent: bridge.currentTrackId === (trackData ? trackData.id : "")

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                // Index or Play Icon
                Item {
                    width: 40
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: (index + 1).toString()
                        color: rowItem.isCurrent ? Style.primary : Style.textMuted
                        font.pixelSize: 13
                        visible: !itemMouse.containsMouse && !rowItem.isCurrent
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "▶"
                        color: Style.textPrimary
                        font.pixelSize: 12
                        visible: itemMouse.containsMouse && !(rowItem.isCurrent && bridge.isPlaying)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "♫"
                        color: Style.primary
                        font.pixelSize: 14
                        visible: rowItem.isCurrent && bridge.isPlaying && !itemMouse.containsMouse
                    }
                }

                // Thumbnail & Title/Artist
                Row {
                    width: parent.width * 0.45
                    height: parent.height
                    spacing: 12
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 40
                        height: 40
                        radius: Style.radiusSmall
                        color: Style.surface
                        anchors.verticalCenter: parent.verticalCenter
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: rowItem.trackData ? (rowItem.trackData.thumbnail || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 52
                        spacing: 2

                        Text {
                            text: rowItem.trackData ? rowItem.trackData.title : ""
                            color: rowItem.isCurrent ? Style.primary : Style.textPrimary
                            font.pixelSize: Style.fontSizeBase
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: rowItem.trackData ? rowItem.trackData.artist : ""
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeSm
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                // Album
                Text {
                    width: parent.width * 0.35
                    anchors.verticalCenter: parent.verticalCenter
                    text: rowItem.trackData ? (rowItem.trackData.album || "") : ""
                    color: Style.textSecondary
                    font.pixelSize: Style.fontSizeSm
                    elide: Text.ElideRight
                }

                // Duration
                Text {
                    width: 50
                    anchors.verticalCenter: parent.verticalCenter
                    text: rowItem.trackData ? Style.formatTime(rowItem.trackData.duration) : "0:00"
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeSm
                    horizontalAlignment: Text.AlignRight
                }
            }

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onDoubleClicked: {
                    if (rowItem.trackData) {
                        root.trackClicked(rowItem.trackData.id)
                    }
                }
                onClicked: {
                    if (rowItem.trackData) {
                        root.trackClicked(rowItem.trackData.id)
                    }
                }
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            text: root.emptyMessage
            color: Style.textMuted
            font.pixelSize: Style.fontSizeLg
            visible: listView.count === 0
        }
    }
}
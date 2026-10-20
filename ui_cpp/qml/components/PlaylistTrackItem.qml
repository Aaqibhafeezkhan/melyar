import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root

    property var trackData: null
    property int index: 0
    property bool isCurrent: false
    property bool isPlaying: false
    signal playClicked()
    signal addToQueueClicked()
    signal contextMenu(variant mouse)

    height: 56
    width: parent.width

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? Style.surfaceHover : (parent.isCurrent ? Style.primary + "20" : "transparent")

        Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space4
            anchors.rightMargin: Style.space4
            spacing: Style.space3

            // Index / Play indicator
            Item {
                width: 40
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: parent.isCurrent ? (parent.isPlaying ? "♫" : "▶") : (parent.index + 1).toString()
                    color: parent.isCurrent ? Style.primary : Style.textMuted
                    font.pixelSize: 13
                    font.bold: parent.isCurrent
                }
            }

            // Thumbnail
            Rectangle {
                width: 40
                height: 40
                radius: Style.radiusSmall
                color: Style.surface
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Image {
                    anchors.fill: parent
                    source: parent.trackData ? parent.trackData.thumbnail : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            // Title, Artist, Album
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space1
                width: parent.width * 0.65 - 60

                Text {
                    text: parent.trackData ? parent.trackData.title : ""
                    color: parent.isCurrent ? Style.primary : Style.textPrimary
                    font.pixelSize: Style.fontSizeBase
                    font.bold: parent.isCurrent
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: parent.trackData ? parent.trackData.artist : ""
                    color: Style.textSecondary
                    font.pixelSize: Style.fontSizeSm
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: parent.trackData ? parent.trackData.album : ""
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeXs
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // Date Added
            Text {
                width: parent.width * 0.15
                anchors.verticalCenter: parent.verticalCenter
                text: parent.trackData ? parent.trackData.addedDate : ""
                color: Style.textMuted
                font.pixelSize: Style.fontSizeXs
                elide: Text.ElideRight
            }

            // Duration
            Text {
                width: 60
                anchors.verticalCenter: parent.verticalCenter
                text: parent.trackData ? Style.formatTime(parent.trackData.duration) : ""
                color: Style.textMuted
                font.pixelSize: Style.fontSizeSm
                horizontalAlignment: Text.AlignRight
            }

            // More button
            ActionButton {
                icon: "⋯"
                size: 32
                iconSize: 16
                flat: true
                visible: mouseArea.containsMouse
                onClicked: parent.contextMenu(mouse)
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: parent.playClicked()
        onDoubleClicked: parent.playClicked()
    }
}
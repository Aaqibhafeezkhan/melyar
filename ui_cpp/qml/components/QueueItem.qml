import QtQuick
import Melyar.Theme

Item {
    id: root

    property var trackData: null
    property int index: 0
    property bool isCurrent: false
    property bool isPlaying: false
    signal removeClicked()
    signal playClicked()

    height: 52
    width: parent.width

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? Style.surfaceHover : (root.isCurrent ? Style.primary + "20" : "transparent")

        Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space3
            anchors.rightMargin: Style.space3
            spacing: Style.space2

            // Index / Play indicator
            Item {
                width: 32
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: root.isCurrent ? (root.isPlaying ? "♫" : "▶") : (root.index + 1).toString()
                    color: root.isCurrent ? Style.primary : Style.textMuted
                    font.pixelSize: 13
                    font.bold: root.isCurrent
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
                    source: root.trackData ? (root.trackData.thumbnail || "") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            // Title & Artist
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                width: parent.width - 120

                Text {
                    text: root.trackData ? root.trackData.title : ""
                    color: root.isCurrent ? Style.primary : Style.textPrimary
                    font.pixelSize: Style.fontSizeSm
                    font.bold: root.isCurrent
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: root.trackData ? root.trackData.artist : ""
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeXs
                    elide: Text.ElideRight
                    width: parent.width
                }
            }

            // Duration
            Text {
                text: root.trackData ? Style.formatTime(root.trackData.duration) : ""
                color: Style.textMuted
                font.pixelSize: Style.fontSizeXs
                font.family: Style.fontFamilyMono
                width: 40
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
            }

            // Remove button
            ActionButton {
                icon: "✕"
                size: 24
                iconSize: 10
                flat: true
                visible: mouseArea.containsMouse
                onClicked: root.removeClicked()
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onDoubleClicked: root.playClicked()
        onClicked: root.playClicked()
    }
}
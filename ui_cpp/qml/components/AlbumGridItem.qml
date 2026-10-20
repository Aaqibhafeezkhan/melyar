import QtQuick
import Melyar.Theme

Item {
    id: root

    property string title: ""
    property string artist: ""
    property string artwork: ""
    property string year: ""
    signal clicked()
    signal contextMenu(variant mouse)

    Rectangle {
        anchors.fill: parent
        anchors.margins: Style.space2
        color: "transparent"

        Column {
            anchors.fill: parent
            spacing: Style.space2

            // Artwork
            Rectangle {
                width: parent.width
                height: parent.width
                radius: Style.radiusMedium
                color: Style.surfaceHover
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.artwork
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: mouseArea.containsMouse ? 0.4 : 0
                    visible: root.artwork !== ""
                    Behavior on opacity { NumberAnimation { duration: Style.durationNormal } }
                }

                // Play overlay
                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: Style.primary
                    anchors.centerIn: parent
                    visible: mouseArea.containsMouse
                    opacity: mouseArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Style.durationNormal } }

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: 2
                        text: "▶"
                        color: Style.textOnPrimary
                        font.pixelSize: 18
                        font.bold: true
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "💿"
                    font.pixelSize: 48
                    color: Style.textMuted
                    visible: root.artwork === ""
                }
            }

            // Info
            Column {
                width: parent.width
                spacing: Style.space1

                Text {
                    text: root.title
                    color: Style.textPrimary
                    font.pixelSize: Style.fontSizeSm
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: root.artist
                    color: Style.textSecondary
                    font.pixelSize: Style.fontSizeXs
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: root.year
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeXs
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onPressAndHold: root.contextMenu(mouse)
    }
}
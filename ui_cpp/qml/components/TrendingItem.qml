import QtQuick
import Melyar.Theme

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string artwork: ""
    signal clicked()

    Rectangle {
        anchors.fill: parent
        anchors.margins: Style.space2
        color: "transparent"

        Column {
            anchors.fill: parent
            spacing: Style.space2

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
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "🎵"
                    font.pixelSize: 32
                    color: Style.textMuted
                    visible: root.artwork === ""
                }
            }

            Text {
                text: root.title
                color: Style.textPrimary
                font.pixelSize: Style.fontSizeSm
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.subtitle
                color: Style.textSecondary
                font.pixelSize: Style.fontSizeXs
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
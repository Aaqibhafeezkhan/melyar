import QtQuick
import Melyar.Theme

Item {
    id: root

    property string name: ""
    property string icon: ""
    property string accentColor: "#1DB954"
    signal clicked()

    Rectangle {
        anchors.fill: parent
        anchors.margins: Style.space2
        radius: Style.radiusMedium
        color: Style.surface
        border.color: Style.border
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.margins: Style.space4
            spacing: Style.space3

            Rectangle {
                width: 48
                height: 48
                radius: Style.radiusMedium
                color: root.accentColor

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    font.pixelSize: 24
                }
            }

            Text {
                text: root.name
                color: Style.textPrimary
                font.pixelSize: Style.fontSizeBase
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Behavior on border.color { ColorAnimation { duration: Style.durationFast } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            parent.border.color = Style.primary
            parent.color = Style.surfaceHover
        }
        onExited: {
            parent.border.color = Style.border
            parent.color = Style.surface
        }
        onClicked: root.clicked()
    }
}
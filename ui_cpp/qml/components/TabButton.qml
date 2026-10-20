import QtQuick
import Melyar.Theme

Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool isActive: false
    signal clicked()

    height: 40
    width: 100

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Style.radiusRound
        color: root.isActive ? Style.surfaceHover : (mouseArea.containsMouse ? Style.surface : "transparent")

        Row {
            anchors.centerIn: parent
            spacing: Style.space2

            Text {
                text: root.icon
                font.pixelSize: 16
                visible: root.icon !== ""
            }

            Text {
                text: root.text
                font.pixelSize: Style.fontSizeSm
                font.bold: root.isActive
                color: root.isActive ? Style.textPrimary : Style.textSecondary
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
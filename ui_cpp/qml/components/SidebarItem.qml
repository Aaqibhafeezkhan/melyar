import QtQuick
import Melyar.Theme

Item {
    id: root

    property string icon: ""
    property string text: ""
    property string subtitle: ""
    property bool active: false
    property bool collapsed: false
    signal clicked()

    height: 42
    width: parent.width

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Style.radiusSmall
        color: active ? Style.surfaceHover : (mouseArea.containsMouse ? Style.surface : "transparent")

        Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space3
            spacing: Style.space3

            Text {
                id: iconText
                text: root.icon
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
                color: active ? Style.primary : Style.textSecondary
                visible: !root.collapsed || root.icon !== ""
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                visible: !root.collapsed

                Text {
                    text: root.text
                    font.pixelSize: Style.fontSizeBase
                    font.bold: root.active
                    color: root.active ? Style.textPrimary : Style.textSecondary
                }

                Text {
                    text: root.subtitle
                    font.pixelSize: Style.fontSizeXs
                    color: Style.textMuted
                    visible: root.subtitle !== ""
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
    }
}
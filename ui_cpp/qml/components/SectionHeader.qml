import QtQuick
import Melyar.Theme

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    signal viewAllClicked()

    width: parent.width
    height: 48

    Row {
        anchors.fill: parent
        anchors.leftMargin: Style.space4
        anchors.rightMargin: Style.space4
        spacing: Style.space3

        Text {
            text: root.title
            color: Style.textPrimary
            font.pixelSize: Style.fontSizeXl
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.subtitle
            color: Style.textSecondary
            font.pixelSize: Style.fontSizeBase
            anchors.verticalCenter: parent.verticalCenter
            visible: root.subtitle !== ""
        }

        Item { width: 1 }

        Text {
            text: "View All"
            color: Style.textSecondary
            font.pixelSize: Style.fontSizeSm
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Style.space2
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.color = Style.primary
                onExited: parent.color = Style.textSecondary
                onClicked: root.viewAllClicked()
            }
        }
    }
}
import QtQuick
import Melyar.Theme

Item {
    id: root
    property string title: ""
    property string icon: ""

    Column {
        width: parent.width
        spacing: Style.space3

        Row {
            spacing: Style.space2
            Text {
                text: root.icon
                font.pixelSize: Style.fontSizeLg
            }
            Text {
                text: root.title
                color: Style.textPrimary
                font.pixelSize: Style.fontSizeXl
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Style.divider
            radius: 0.5
        }
    }
}
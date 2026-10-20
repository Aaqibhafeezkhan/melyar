import QtQuick
import Melyar.Theme

Item {
    id: root

    property string label: ""
    property string description: ""

    height: 56
    width: parent.width

    Row {
        anchors.fill: parent
        anchors.leftMargin: Style.space4
        anchors.rightMargin: Style.space4
        spacing: Style.space4

        Column {
            width: 180
            spacing: 2

            Text {
                text: root.label
                color: Style.textPrimary
                font.pixelSize: Style.fontSizeBase
                font.weight: Style.fontWeightMedium
            }

            Text {
                text: root.description
                color: Style.textMuted
                font.pixelSize: Style.fontSizeXs
                visible: root.description !== ""
            }
        }

        Item { id: controlItem; width: 1 } // placeholder for control
    }
}
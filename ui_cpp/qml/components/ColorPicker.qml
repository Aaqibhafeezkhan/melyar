import QtQuick
import Melyar.Theme

Item {
    id: root

    property string color: "#1DB954"
    property bool selected: false
    signal clicked()

    width: 32
    height: 32

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.color
        border.color: root.selected ? Style.textPrimary : Style.border
        border.width: root.selected ? 3 : 1

        // Checkmark when selected
        Text {
            anchors.centerIn: parent
            text: "✓"
            color: root.selected ? "#000000" : "transparent"
            font.pixelSize: 16
            font.bold: true
            visible: root.selected
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
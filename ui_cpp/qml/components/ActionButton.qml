import QtQuick
import Melyar.Theme

Item {
    id: root

    property string icon: ""
    property int size: 32
    property int iconSize: 14
    property bool active: false
    property color activeColor: Style.primary
    property bool flat: false
    property string toolTip: ""
    signal clicked()

    width: root.size
    height: root.size

    Rectangle {
        id: btnBg
        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: root.size / 2
        color: root.active ? root.activeColor : (root.flat ? "transparent" : (mouseArea.containsMouse ? Style.surfaceHover : "transparent"))
        border.color: root.active ? root.activeColor : "transparent"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.pixelSize: root.iconSize
            color: root.active ? Style.textOnPrimary : (mouseArea.containsMouse ? Style.textPrimary : Style.textSecondary)
            font.bold: root.active
        }

        Behavior on color { ColorAnimation { duration: Style.durationFast } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
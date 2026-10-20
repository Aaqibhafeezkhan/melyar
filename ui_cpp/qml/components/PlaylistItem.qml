import QtQuick
import Melyar.Theme

Item {
    id: root

    property string name: ""
    property int trackCount: 0
    property string artwork: ""
    property bool active: false
    signal clicked()
    signal contextMenu(variant mouse)

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

            // Artwork placeholder
            Rectangle {
                width: 32
                height: 32
                radius: Style.radiusSmall
                color: Style.primary
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    anchors.fill: parent
                    source: parent.artwork
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "♫"
                    color: Style.textOnPrimary
                    font.pixelSize: 14
                    visible: parent.artwork === ""
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: root.name
                    font.pixelSize: Style.fontSizeBase
                    font.bold: root.active
                    color: root.active ? Style.textPrimary : Style.textSecondary
                    elide: Text.ElideRight
                    width: parent.ListView.view ? parent.ListView.view.width - 80 : 160
                }

                Text {
                    text: root.trackCount + " songs"
                    font.pixelSize: Style.fontSizeXs
                    color: Style.textMuted
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
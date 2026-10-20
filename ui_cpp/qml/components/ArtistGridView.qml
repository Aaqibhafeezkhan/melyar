import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root

    property var model: []
    signal artistClicked(string artistId)

    GridView {
        anchors.fill: parent
        cellWidth: 180
        cellHeight: 240
        model: parent.model
        clip: true

        delegate: ArtistGridItem {
            width: parent.GridView.view.cellWidth
            height: parent.GridView.view.cellHeight
            name: modelData.name
            artwork: modelData.artwork
            followerCount: modelData.followerCount
            onClicked: parent.artistClicked(modelData.id)
            onContextMenu: artistContextMenu.popup(Qt.point(mouse.x, mouse.y))
        }
    }

    Menu {
        id: artistContextMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }
        MenuItem { text: "Play"; onTriggered: console.log("Play artist") }
        MenuItem { text: "Add to Queue"; onTriggered: console.log("Add artist to queue") }
        MenuSeparator {}
        MenuItem { text: "Follow"; onTriggered: console.log("Follow artist") }
        MenuItem { text: "Go to Radio"; onTriggered: console.log("Go to radio") }
        MenuSeparator {}
        MenuItem { text: "Share"; onTriggered: console.log("Share artist") }
    }
}
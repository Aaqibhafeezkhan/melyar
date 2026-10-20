import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root

    property var model: []
    signal playlistClicked(string playlistId)

    GridView {
        anchors.fill: parent
        cellWidth: 180
        cellHeight: 240
        model: parent.model
        clip: true

        delegate: PlaylistGridItem {
            width: parent.GridView.view.cellWidth
            height: parent.GridView.view.cellHeight
            name: modelData.name
            artwork: modelData.artwork
            trackCount: modelData.trackCount
            isOwner: modelData.isOwner
            onClicked: parent.playlistClicked(modelData.id)
            onContextMenu: playlistContextMenu.popup(Qt.point(mouse.x, mouse.y))
        }
    }

    Menu {
        id: playlistContextMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }
        MenuItem { text: "Play"; onTriggered: console.log("Play playlist") }
        MenuItem { text: "Add to Queue"; onTriggered: console.log("Add playlist to queue") }
        MenuSeparator {}
        MenuItem { text: "Edit Playlist"; onTriggered: console.log("Edit playlist") }
        MenuItem { text: "Add to Library"; onTriggered: console.log("Add to library") }
        MenuSeparator {}
        MenuItem { text: "Share"; onTriggered: console.log("Share playlist") }
        MenuItem { text: "Delete"; onTriggered: console.log("Delete playlist") }
    }
}
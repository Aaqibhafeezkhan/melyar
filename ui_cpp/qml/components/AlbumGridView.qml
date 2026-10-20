import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root

    property var model: []
    signal albumClicked(string albumId)

    GridView {
        anchors.fill: parent
        cellWidth: 180
        cellHeight: 240
        model: parent.model
        clip: true

        delegate: AlbumGridItem {
            width: parent.GridView.view.cellWidth
            height: parent.GridView.view.cellHeight
            title: modelData.title
            artist: modelData.artist
            artwork: modelData.artwork
            year: modelData.year
            onClicked: parent.albumClicked(modelData.id)
            onContextMenu: albumContextMenu.popup(Qt.point(mouse.x, mouse.y))
        }
    }

    Menu {
        id: albumContextMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }
        MenuItem { text: "Play"; onTriggered: console.log("Play album") }
        MenuItem { text: "Add to Queue"; onTriggered: console.log("Add album to queue") }
        MenuItem { text: "Add to Playlist..."; onTriggered: console.log("Add to playlist") }
        MenuSeparator {}
        MenuItem { text: "Save to Library"; onTriggered: console.log("Save album") }
        MenuItem { text: "Go to Artist"; onTriggered: console.log("Go to artist") }
        MenuSeparator {}
        MenuItem { text: "Share"; onTriggered: console.log("Share album") }
    }
}
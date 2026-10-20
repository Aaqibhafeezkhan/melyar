import QtQuick
import QtQuick.Controls
import Melyar.Theme
import "."

Item {
    id: root
    width: parent.width
    height: parent.height

    property string searchQuery: ""
    property bool searching: false
    property var results: []
    property string activeFilter: "tracks"

    // Search Input Focus Handler
    FocusScope {
        anchors.fill: parent
        focus: true

        TextField {
            id: searchInput
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.6, 600)
            height: 56
            color: Style.textPrimary
            font.pixelSize: Style.fontSizeLg
            font.family: Style.fontFamily
            selectionColor: Style.primary
            selectedTextColor: Style.textOnPrimary
            placeholderText: "Search"
            clip: true

            onAccepted: {
                if (text.trim() !== "") {
                    root.searchQuery = text.trim()
                    root.performSearch(text.trim())
                }
            }
        }
    }

    // Results or Suggestions
    Loader {
        id: contentLoader
        anchors.fill: parent
        anchors.topMargin: 120
        sourceComponent: root.searchQuery === "" ? suggestionsComponent : resultsComponent
    }

    // -------------------------------------------------------------
    // SUGGESTIONS VIEW (when no query)
    // -------------------------------------------------------------
    Component {
        id: suggestionsComponent

        Column {
            anchors.fill: parent
            spacing: Style.space6

            // Recent Searches
            Column {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.right: parent.right
                anchors.rightMargin: Style.space6
                spacing: Style.space3

                Row {
                    spacing: Style.space3
                    Text {
                        text: "Recent Searches"
                        color: Style.textPrimary
                        font.pixelSize: Style.fontSizeLg
                        font.bold: true
                    }

                    ActionButton {
                        icon: "🗑"
                        size: 32
                        iconSize: 14
                        flat: true
                        visible: bridge.searchHistory.length > 0
                        onClicked: bridge.clearSearchHistory()
                    }
                }

                ListView {
                    width: parent.width
                    height: Math.min(bridge.searchHistory.length * 48, 200)
                    clip: true
                    model: bridge.searchHistory
                    spacing: 0

                    delegate: Rectangle {
                        width: parent.width
                        height: 48
                        color: mouseArea.containsMouse ? Style.surfaceHover : "transparent"
                        radius: Style.radiusSmall

                        Row {
                            anchors.fill: parent
                            anchors.margins: Style.space3
                            spacing: Style.space3

                            Text {
                                text: "🕐"
                                font.pixelSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData
                                color: Style.textPrimary
                                font.pixelSize: Style.fontSizeBase
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }

                            Item { width: 1 }

                            ActionButton {
                                icon: "✕"
                                size: 24
                                iconSize: 10
                                flat: true
                                onClicked: bridge.removeFromSearchHistory(modelData)
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = modelData
                                root.performSearch(modelData)
                            }
                        }
                    }
                }

                Text {
                    text: bridge.searchHistory.length === 0 ? "No recent searches" : ""
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeBase
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: bridge.searchHistory.length === 0
                }
            }

            // Browse Categories
            Column {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.right: parent.right
                anchors.rightMargin: Style.space6
                spacing: Style.space3

                Text {
                    text: "Browse All"
                    color: Style.textPrimary
                    font.pixelSize: Style.fontSizeLg
                    font.bold: true
                }

                GridView {
                    width: parent.width
                    height: 240
                    cellWidth: 160
                    cellHeight: 80
                    clip: true
                    model: [
                        { name: "Top 50 Global", icon: "🌍", color: "#1DB954" },
                        { name: "Viral 50", icon: "📈", color: "#FF6B6B" },
                        { name: "New Music Friday", icon: "🆕", color: "#4ECDC4" },
                        { name: "Chill Hits", icon: "🌊", color: "#45B7D1" },
                        { name: "Workout", icon: "💪", color: "#FFA07A" },
                        { name: "Focus", icon: "🎯", color: "#98D8C8" },
                        { name: "Party", icon: "🎉", color: "#F7DC6F" },
                        { name: "Sleep", icon: "🌙", color: "#BB8FCE" }
                    ]

                    delegate: CategoryCard {
                        width: parent.GridView.view.cellWidth
                        height: parent.GridView.view.cellHeight
                        name: modelData.name
                        icon: modelData.icon
                        accentColor: modelData.color
                        onClicked: root.performSearch(modelData.name)
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------
    // RESULTS VIEW
    // -------------------------------------------------------------
    Component {
        id: resultsComponent

        Column {
            anchors.fill: parent
            spacing: Style.space4

            // Results Header
            Rectangle {
                width: parent.width
                height: 56
                color: "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space6
                    anchors.right: parent.right
                    anchors.rightMargin: Style.space6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space3

                    Text {
                        text: "Search Results for \""
                        color: Style.textSecondary
                        font.pixelSize: Style.fontSizeBase
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.searchQuery
                        color: Style.textPrimary
                        font.pixelSize: Style.fontSizeBase
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "\""
                        color: Style.textSecondary
                        font.pixelSize: Style.fontSizeBase
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: 1 }

                    // Filter Tabs
                    Row {
            spacing: Style.space1

            Repeater {
                model: ["Tracks", "Albums", "Artists", "Playlists"]
                delegate: TabButton {
                    text: modelData
                    isActive: root.activeFilter === modelData.toLowerCase()
                    onClicked: root.activeFilter = modelData.toLowerCase()
                }
            }
        }
                }
            }

            // Results Content
            Loader {
                anchors.fill: parent
                sourceComponent: root.activeFilter === "tracks" ? tracksResults :
                                 root.activeFilter === "albums" ? albumsResults :
                                 root.activeFilter === "artists" ? artistsResults :
                                 playlistsResults
            }
        }
    }

    // Tracks Results
    Component {
        id: tracksResults

        VirtualTrackList {
            anchors.fill: parent
            model: bridge.searchResults
            emptyMessage: "No tracks found for \"" + root.searchQuery + "\""
            onTrackClicked: bridge.playTrack(trackId)
            onTrackContextMenu: trackContextMenu.popup(Qt.point(mouse.x, mouse.y))
        }
    }

    // Albums Results
    Component {
        id: albumsResults

        GridView {
            anchors.fill: parent
            anchors.margins: Style.space6
            cellWidth: 180
            cellHeight: 240
            clip: true
            model: bridge.searchAlbums // Would need to be added to bridge

            delegate: AlbumGridItem {
                width: parent.GridView.view.cellWidth
                height: parent.GridView.view.cellHeight
                title: modelData.title
                artist: modelData.artist
                artwork: modelData.artwork
                year: modelData.year
                onClicked: console.log("Open album:", modelData.id)
                onContextMenu: albumContextMenu.popup(Qt.point(mouse.x, mouse.y))
            }
        }
    }

    // Artists Results
    Component {
        id: artistsResults

        GridView {
            anchors.fill: parent
            anchors.margins: Style.space6
            cellWidth: 180
            cellHeight: 240
            clip: true
            model: bridge.searchArtists // Would need to be added to bridge

            delegate: ArtistGridItem {
                width: parent.GridView.view.cellWidth
                height: parent.GridView.view.cellHeight
                name: modelData.name
                artwork: modelData.artwork
                followerCount: modelData.followerCount
                onClicked: console.log("Open artist:", modelData.id)
                onContextMenu: artistContextMenu.popup(Qt.point(mouse.x, mouse.y))
            }
        }
    }

    // Playlists Results
    Component {
        id: playlistsResults

        GridView {
            anchors.fill: parent
            anchors.margins: Style.space6
            cellWidth: 180
            cellHeight: 240
            clip: true
            model: bridge.searchPlaylists // Would need to be added to bridge

            delegate: PlaylistGridItem {
                width: parent.GridView.view.cellWidth
                height: parent.GridView.view.cellHeight
                name: modelData.name
                artwork: modelData.artwork
                trackCount: modelData.trackCount
                isOwner: modelData.isOwner
                onClicked: console.log("Open playlist:", modelData.id)
                onContextMenu: playlistContextMenu.popup(Qt.point(mouse.x, mouse.y))
            }
        }
    }

    // -------------------------------------------------------------
    // CONTEXT MENUS
    // -------------------------------------------------------------

    Menu {
        id: trackContextMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }
        MenuItem { text: "Play"; onTriggered: console.log("Play track") }
        MenuItem { text: "Add to Queue"; onTriggered: console.log("Add to queue") }
        MenuItem { text: "Add to Playlist..."; onTriggered: console.log("Add to playlist") }
        MenuSeparator {}
        MenuItem { text: "Go to Artist"; onTriggered: console.log("Go to artist") }
        MenuItem { text: "Go to Album"; onTriggered: console.log("Go to album") }
        MenuSeparator {}
        MenuItem { text: "Save to Library"; onTriggered: console.log("Save track") }
        MenuItem { text: "Share"; onTriggered: console.log("Share track") }
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
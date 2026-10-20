import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root
    width: parent.width
    height: parent.height

    property string currentView: "albums" // albums, artists, playlists

    // Header with tabs
    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        // Page Title
        Rectangle {
            width: parent.width
            height: 72
            color: "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Style.space4
                text: "Library"
                font.pixelSize: Style.fontSize4xl
                font.bold: true
                font.weight: Style.fontWeightBold
                color: Style.textPrimary
            }
        }

        // Tab Bar
        Rectangle {
            id: tabBar
            width: parent.width
            height: 48
            color: "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space1

                Repeater {
                    model: [
                        { id: "albums", label: "Albums", icon: "💿" },
                        { id: "artists", label: "Artists", icon: "🎤" },
                        { id: "playlists", label: "Playlists", icon: "📋" }
                    ]

                    delegate: TabButton {
                        text: modelData.label
                        icon: modelData.icon
                        isActive: root.currentView === modelData.id
                        onClicked: root.currentView = modelData.id
                    }
                }
            }
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Style.divider
            anchors.leftMargin: Style.space6
            anchors.rightMargin: Style.space6
        }
    }

    // Content Area
    Item {
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Style.space4

        // Albums View
        AlbumGridView {
            id: albumsView
            anchors.fill: parent
            visible: root.currentView === "albums"
            model: bridge.libraryAlbums
            onAlbumClicked: {
                albumDetailView.albumId = albumId
                albumDetailView.loadAlbum()
                root.currentView = "albumDetail"
            }
        }

        // Artists View
        ArtistGridView {
            id: artistsView
            anchors.fill: parent
            visible: root.currentView === "artists"
            model: bridge.libraryArtists
            onArtistClicked: {
                artistDetailView.artistId = artistId
                artistDetailView.loadArtist()
                root.currentView = "artistDetail"
            }
        }

        // Playlists View
        PlaylistGridView {
            id: playlistsView
            anchors.fill: parent
            visible: root.currentView === "playlists"
            model: bridge.libraryPlaylists
            onPlaylistClicked: {
                playlistDetailView.playlistId = playlistId
                playlistDetailView.loadPlaylist()
                root.currentView = "playlistDetail"
            }
        }

        // Album Detail View
        AlbumDetailView {
            id: albumDetailView
            anchors.fill: parent
            visible: root.currentView === "albumDetail"
            onBackClicked: root.currentView = "albums"
        }

        // Artist Detail View
        ArtistDetailView {
            id: artistDetailView
            anchors.fill: parent
            visible: root.currentView === "artistDetail"
            onBackClicked: root.currentView = "artists"
        }

        // Playlist Detail View
        PlaylistDetailView {
            id: playlistDetailView
            anchors.fill: parent
            visible: root.currentView === "playlistDetail"
            onBackClicked: root.currentView = "playlists"
        }

        // Empty State
        Rectangle {
            id: emptyState
            anchors.fill: parent
            color: "transparent"
            visible: root.currentView === "albums" && bridge.libraryAlbums.length === 0 ||
                     root.currentView === "artists" && bridge.libraryArtists.length === 0 ||
                     root.currentView === "playlists" && bridge.libraryPlaylists.length === 0

            Column {
                anchors.centerIn: parent
                spacing: Style.space3

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.currentView === "albums" ? "💿" : (root.currentView === "artists" ? "🎤" : "📋")
                    font.pixelSize: 64
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.currentView === "albums" ? "No albums in library" :
                          root.currentView === "artists" ? "No artists in library" :
                          "No playlists yet"
                    color: Style.textSecondary
                    font.pixelSize: Style.fontSizeLg
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Search for music and add to your library"
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeBase
                }
            }
        }
    }
}
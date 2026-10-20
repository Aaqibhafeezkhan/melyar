import QtQuick
import QtQuick.Controls
import components 1.0
import Melyar.Theme

Rectangle {
    id: root
    width: Style.sidebarWidth
    color: Style.sidebarBackground

    signal tabSelected(string tabName)
    property string activeTab: "search"
    property bool collapsed: false

    // Playlist model (will be populated from bridge)
    property var playlists: []

    // Animations for smooth transitions
    Behavior on width {
        NumberAnimation { duration: Style.durationNormal; easing.type: Easing.OutCubic }
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // -------------------------------------------------------------
        // TOP SECTION: Branding & Main Navigation
        // -------------------------------------------------------------
        Column {
            width: parent.width
            spacing: Style.space2

            // App Branding
            Rectangle {
                id: brandingArea
                width: parent.width
                height: collapsed ? Style.sidebarWidthCollapsed : (Style.sidebarWidth - 36)
                color: "transparent"

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: collapsed ? 0 : Style.space3

                    Rectangle {
                        width: 34
                        height: 34
                        radius: 17
                        color: Style.primary

                        Text {
                            anchors.centerIn: parent
                            text: "M"
                            color: Style.textOnPrimary
                            font.bold: true
                            font.pixelSize: 18
                            visible: !collapsed
                        }
                    }

                    Text {
                        text: "MELYAR"
                        color: Style.textPrimary
                        font.bold: true
                        font.pixelSize: 16
                        font.letterSpacing: 1.5
                        visible: !collapsed
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.collapsed = !root.collapsed
                    }
                }
            }

            // Main Navigation Items
            Column {
                id: mainNav
                width: parent.width
                spacing: Style.space1
                anchors.leftMargin: Style.space3
                anchors.rightMargin: Style.space3

                // Search
                SidebarItem {
                    id: searchItem
                    width: parent.width
                    icon: "🔍"
                    text: "Search"
                    active: root.activeTab === "search"
                    collapsed: root.collapsed
                    onClicked: {
                        root.activeTab = "search"
                        root.tabSelected("search")
                    }
                }

                // Home/Explore
                SidebarItem {
                    id: homeItem
                    width: parent.width
                    icon: "🏠"
                    text: "Home"
                    active: root.activeTab === "home"
                    collapsed: root.collapsed
                    onClicked: {
                        root.activeTab = "home"
                        root.tabSelected("home")
                    }
                }

                // Library
                SidebarItem {
                    id: libraryItem
                    width: parent.width
                    icon: "📁"
                    text: "Library"
                    active: root.activeTab === "library"
                    collapsed: root.collapsed
                    onClicked: {
                        root.activeTab = "library"
                        root.tabSelected("library")
                    }
                }
            }
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Style.divider
            anchors.leftMargin: Style.space3
            anchors.rightMargin: Style.space3
            visible: !collapsed
        }

        // -------------------------------------------------------------
        // MIDDLE SECTION: Your Library - Playlists
        // -------------------------------------------------------------
        Column {
            id: librarySection
            width: parent.width
            spacing: Style.space2
            anchors.leftMargin: Style.space3
            anchors.rightMargin: Style.space3
            visible: !collapsed

            // Section Header with "Create Playlist" button
            Row {
                width: parent.width
                height: 32
                spacing: Style.space2

                Text {
                    text: "YOUR LIBRARY"
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeXs
                    font.bold: true
                    font.letterSpacing: 1
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 1 } // spacer

                // Create playlist button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Style.textSecondary
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: parent.color = Style.surfaceHover
                        onExited: parent.color = "transparent"
                        onClicked: {
                            createPlaylistDialog.open()
                        }
                    }
                }
            }

            // Liked Songs (special playlist)
            SidebarItem {
                id: likedSongsItem
                width: parent.width
                icon: "♥"
                text: "Liked Songs"
                subtitle: bridge.favorites.length + " songs"
                active: root.activeTab === "favorites"
                collapsed: false
                onClicked: {
                    root.activeTab = "favorites"
                    bridge.loadFavorites()
                    root.tabSelected("favorites")
                }
            }

            // Divider before playlists
            Rectangle {
                width: parent.width
                height: 1
                color: Style.divider
                visible: root.playlists.length > 0
            }

            // Dynamic Playlists from model
            ListView {
                id: playlistList
                width: parent.width
                height: Math.min(root.playlists.length * 42, 300)
                clip: true
                model: root.playlists
                spacing: 0

                delegate: PlaylistItem {
                    width: parent.width
                    name: model.name
                    trackCount: model.trackCount
                    artwork: model.artwork
                    active: root.activeTab === "playlist_" + model.id
                    onClicked: {
                        root.activeTab = "playlist_" + model.id
                        root.tabSelected("playlist_" + model.id)
                    }
                    onContextMenu: {
                        playlistContextMenu.popup(Qt.point(mouse.x, mouse.y))
                    }
                }
            }
        }

        // Spacer
        Item {
            height: Style.space6
        }

        // -------------------------------------------------------------
        // BOTTOM SECTION: Settings & System Info
        // -------------------------------------------------------------
        Column {
            width: parent.width
            spacing: Style.space1
            anchors.leftMargin: Style.space3
            anchors.rightMargin: Style.space3
            visible: !collapsed

            // History
            SidebarItem {
                id: historyItem
                width: parent.width
                icon: "⏱"
                text: "History"
                active: root.activeTab === "history"
                onClicked: {
                    root.activeTab = "history"
                    bridge.loadHistory()
                    root.tabSelected("history")
                }
            }

            // Settings
            SidebarItem {
                id: settingsItem
                width: parent.width
                icon: "⚙"
                text: "Settings"
                active: root.activeTab === "settings"
                onClicked: {
                    root.activeTab = "settings"
                    root.tabSelected("settings")
                }
            }
        }

        // System specs pill (always visible at bottom)
        Item {
            height: Style.space6
        }

        Rectangle {
            width: parent.width
            height: collapsed ? 0 : 60
            radius: Style.radiusMedium
            color: Style.surface
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.space4
            anchors.leftMargin: Style.space4
            anchors.rightMargin: Style.space4
            visible: !collapsed
            clip: true

            Column {
                anchors.centerIn: parent
                spacing: Style.space1

                Text {
                    text: "PIPEWIRE AUDIO"
                    color: Style.primary
                    font.bold: true
                    font.pixelSize: Style.fontSizeXs
                    font.letterSpacing: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Pure C++ & Rust | Zero-Web"
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeXs
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // -------------------------------------------------------------
    // DIALOGS & MENUS
    // -------------------------------------------------------------

    // Create Playlist Dialog
    Dialog {
        id: createPlaylistDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: "Create New Playlist"

        Column {
            spacing: Style.space3
            width: 300

            TextField {
                id: playlistNameInput
                width: parent.width
                placeholderText: "Playlist name"
                color: Style.textPrimary
                background: Rectangle {
                    color: Style.surface
                    border.color: Style.border
                    border.width: 1
                    radius: Style.radiusSmall
                }
            }
        }

        onAccepted: {
            if (playlistNameInput.text.trim() !== "") {
                // TODO: Call bridge to create playlist
                console.log("Create playlist:", playlistNameInput.text)
                playlistNameInput.text = ""
            }
        }
    }

    // Playlist Context Menu
    Menu {
        id: playlistContextMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }

        MenuItem {
            text: "Play"
            onTriggered: console.log("Play playlist")
        }
        MenuItem {
            text: "Add to Queue"
            onTriggered: console.log("Add to queue")
        }
        MenuSeparator {}
        MenuItem {
            text: "Rename"
            onTriggered: console.log("Rename playlist")
        }
        MenuItem {
            text: "Delete"
            onTriggered: console.log("Delete playlist")
        }
    }
}
import QtQuick
import QtQuick.Window
import Melyar.Theme
import "components"

Window {
    id: window
    width: 1100
    height: 720
    minimumWidth: 800
    minimumHeight: 550
    visible: true
    title: "Melyar - Ultra-Lightweight YouTube Music"
    color: Style.background

    property string currentTab: "search"
    property bool showLyrics: false

    // Root Layout
    Item {
        anchors.fill: parent

        // -------------------------------------------------------------
        // LEFT: Sidebar
        // -------------------------------------------------------------
        Sidebar {
            id: sidebar
            anchors.top: parent.top
            anchors.bottom: playerBar.top
            anchors.left: parent.left
            activeTab: window.currentTab

            onTabSelected: (tab) => {
                window.currentTab = tab;
                window.showLyrics = false;
            }
        }

        // -------------------------------------------------------------
        // MAIN CONTENT AREA
        // -------------------------------------------------------------
        Rectangle {
            id: mainContent
            anchors.top: parent.top
            anchors.bottom: playerBar.top
            anchors.left: sidebar.right
            anchors.right: parent.right
            color: Style.background

            // Top Navigation & Search Bar
            Rectangle {
                id: topBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 64
                color: "transparent"
                z: 10

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    // Modern Search Input
                    Rectangle {
                        width: 320
                        height: 40
                        radius: 20
                        color: Style.surfaceHover

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                text: "🔍"
                                font.pixelSize: 13
                                color: Style.textSecondary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TextInput {
                                id: searchInput
                                width: parent.width - 40
                                anchors.verticalCenter: parent.verticalCenter
                                color: Style.textPrimary
                                font.pixelSize: 13
                                clip: true
                                selectByMouse: true
                                text: ""

                                Text {
                                    text: "What do you want to play?"
                                    color: Style.textMuted
                                    font.pixelSize: 13
                                    visible: !searchInput.text && !searchInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                onAccepted: {
                                    if (text.trim() !== "") {
                                        window.currentTab = "search";
                                        window.showLyrics = false;
                                        bridge.search(text.trim());
                                    }
                                }
                            }
                        }
                    }

                    // Search Button
                    Rectangle {
                        width: 76
                        height: 38
                        radius: 19
                        color: searchBtnMouse.containsMouse ? Style.primaryHover : Style.primary
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            anchors.centerIn: parent
                            text: "Search"
                            font.bold: true
                            font.pixelSize: 13
                            color: "#000000"
                        }

                        MouseArea {
                            id: searchBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (searchInput.text.trim() !== "") {
                                    window.currentTab = "search";
                                    window.showLyrics = false;
                                    bridge.search(searchInput.text.trim());
                                }
                            }
                        }
                    }
                }
            }

            // Views Container
            Item {
                anchors.top: topBar.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                // View 1: Search Track List
                VirtualTrackList {
                    anchors.fill: parent
                    model: bridge.searchResults
                    visible: window.currentTab === "search" && !window.showLyrics
                    emptyMessage: "Search for songs, artists, or albums above"
                }

                // View 2: Favorites
                VirtualTrackList {
                    anchors.fill: parent
                    model: bridge.favorites
                    visible: window.currentTab === "favorites" && !window.showLyrics
                    emptyMessage: "No favorite tracks saved yet. Click ♥ to add!"
                }

                // View 3: History
                VirtualTrackList {
                    anchors.fill: parent
                    model: bridge.history
                    visible: window.currentTab === "history" && !window.showLyrics
                    emptyMessage: "No tracks in history yet"
                }

                // View 4: Synced Lyrics View
                SyncedLyrics {
                    anchors.fill: parent
                    visible: window.showLyrics
                }
            }
        }

        // -------------------------------------------------------------
        // BOTTOM: Player Bar
        // -------------------------------------------------------------
        PlayerBar {
            id: playerBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            lyricsActive: window.showLyrics

            onToggleLyricsClicked: {
                window.showLyrics = !window.showLyrics;
            }
        }
    }
}

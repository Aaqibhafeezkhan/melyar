import QtQuick
import QtQuick.Controls
import Melyar.Theme

Item {
    id: root
    width: parent.width
    height: parent.height

    property var recentlyPlayed: []
    property var recommendedAlbums: []
    property var recommendedArtists: []
    property var topCharts: []
    property var newReleases: []

    Column {
        anchors.fill: parent
        spacing: 0

        // Hero Section
        Rectangle {
            id: heroSection
            width: parent.width
            height: 320
            color: "transparent"

            // Background gradient/artwork
            Rectangle {
                anchors.fill: parent
                color: Style.surface
            }

            // Hero Content
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Style.space6
                spacing: Style.space6

                // Main Artwork
                Rectangle {
                    id: heroArtwork
                    width: 240
                    height: 240
                    radius: Style.radiusMedium
                    color: Style.surfaceHover
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "" // featured playlist/album artwork
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#000000"
                        opacity: mouseArea.containsMouse ? 0.3 : 0
                        Behavior on opacity { NumberAnimation { duration: Style.durationNormal } }
                    }

                    Rectangle {
                        width: 64
                        height: 64
                        radius: 32
                        color: Style.primary
                        anchors.centerIn: parent
                        visible: mouseArea.containsMouse
                        opacity: mouseArea.containsMouse ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Style.durationNormal } }

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 2
                            text: "▶"
                            color: Style.textOnPrimary
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }
                }

                // Hero Info
                Column {
                    anchors.verticalCenter: heroArtwork.verticalCenter
                    spacing: Style.space3
                    width: parent.width - 320 - Style.space6 * 2

                    Row {
                        spacing: Style.space2
                        Text {
                            text: "MADE FOR YOU"
                            color: Style.primary
                            font.pixelSize: Style.fontSizeXs
                            font.bold: true
                            font.letterSpacing: 1
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: "Your Daily Mix"
                        color: Style.textPrimary
                        font.pixelSize: Style.fontSize4xl
                        font.bold: true
                        font.weight: Style.fontWeightBold
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Row {
                        spacing: Style.space3

                        Text {
                            text: "Updated today • Based on your listening history"
                            color: Style.textSecondary
                            font.pixelSize: Style.fontSizeBase
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Action Buttons
                    Row {
                        spacing: Style.space3

                        // Play Button
                        Rectangle {
                            id: heroPlayBtn
                            height: 48
                            radius: Style.radiusRound
                            color: Style.primary

                            Row {
                                anchors.fill: parent
                                anchors.margins: Style.space4
                                spacing: Style.space2

                                Text {
                                    text: "▶"
                                    color: Style.textOnPrimary
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                Text {
                                    text: "Play"
                                    color: Style.textOnPrimary
                                    font.pixelSize: Style.fontSizeBase
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: heroPlayBtn.color = Style.primaryHover
                                onExited: heroPlayBtn.color = Style.primary
                            }
                        }

                        // Shuffle Button
                        Rectangle {
                            id: heroShuffleBtn
                            height: 48
                            radius: Style.radiusRound
                            color: Style.surfaceHover

                            Row {
                                anchors.fill: parent
                                anchors.margins: Style.space4
                                spacing: Style.space2

                                Text {
                                    text: "🔀"
                                    font.pixelSize: 18
                                }

                                Text {
                                    text: "Shuffle"
                                    color: Style.textPrimary
                                    font.pixelSize: Style.fontSizeBase
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: heroShuffleBtn.color = Style.surfacePressed
                                onExited: heroShuffleBtn.color = Style.surfaceHover
                            }
                        }

                        // Save Button
                        Rectangle {
                            id: heroSaveBtn
                            width: 48
                            height: 48
                            radius: 24
                            color: Style.surfaceHover

                            Text {
                                anchors.centerIn: parent
                                text: "♥"
                                color: Style.textSecondary
                                font.pixelSize: 18
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: { heroSaveBtn.color = Style.surfacePressed; heroSaveBtn.border.color = Style.primary }
                                onExited: { heroSaveBtn.color = Style.surfaceHover; heroSaveBtn.border.color = "transparent" }
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: heroArtwork
                hoverEnabled: true
            }
        }

        // Content Sections
        ScrollView {
            anchors.fill: parent
            clip: true
            ScrollBar.vertical: ScrollBar {
                width: 8
                policy: ScrollBar.AlwaysOff
                contentItem: Rectangle {
                    radius: 4
                    color: Style.primary
                }
            }

            Column {
                width: parent.width
                spacing: Style.space6
                anchors.leftMargin: Style.space6
                anchors.rightMargin: Style.space6

                // -------------------------------------------------------------
                // RECENTLY PLAYED
                // -------------------------------------------------------------
                SectionHeader {
                    title: "Recently Played"
                    onViewAllClicked: console.log("View all recently played")
                }

                Flickable {
                    width: parent.width
                    height: 220
                    clip: true
                    contentWidth: recentlyPlayedRow.width
                    contentHeight: 220
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: recentlyPlayedRow
                        spacing: Style.space4
                        height: 220

                        Repeater {
                            model: Math.max(root.recentlyPlayed.length, 6)

                            delegate: HomeCardItem {
                                width: 160
                                height: 220
                                title: root.recentlyPlayed.length > index ? root.recentlyPlayed[index].title : "Recently Played " + (index + 1)
                                subtitle: root.recentlyPlayed.length > index ? root.recentlyPlayed[index].artist : "Artist"
                                artwork: root.recentlyPlayed.length > index ? root.recentlyPlayed[index].artwork : ""
                                type: "album"
                                onClicked: console.log("Open recently played")
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // JUMP BACK IN
                // -------------------------------------------------------------
                SectionHeader {
                    title: "Jump Back In"
                    onViewAllClicked: console.log("View all jump back in")
                }

                Flickable {
                    width: parent.width
                    height: 220
                    clip: true
                    contentWidth: jumpBackRow.width
                    contentHeight: 220
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: jumpBackRow
                        spacing: Style.space4
                        height: 220

                        Repeater {
                            model: 6

                            delegate: HomeCardItem {
                                width: 160
                                height: 220
                                title: "Album " + (index + 1)
                                subtitle: "Artist Name"
                                artwork: ""
                                type: "album"
                                progress: Math.random() * 0.7
                                onClicked: console.log("Continue listening")
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // RECOMMENDED ALBUMS
                // -------------------------------------------------------------
                SectionHeader {
                    title: "Recommended Albums"
                    onViewAllClicked: console.log("View all recommended albums")
                }

                Flickable {
                    width: parent.width
                    height: 240
                    clip: true
                    contentWidth: recAlbumsRow.width
                    contentHeight: 240
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: recAlbumsRow
                        spacing: Style.space4
                        height: 240

                        Repeater {
                            model: Math.max(root.recommendedAlbums.length, 8)

                            delegate: HomeCardItem {
                                width: 160
                                height: 240
                                title: root.recommendedAlbums.length > index ? root.recommendedAlbums[index].title : "Recommended Album " + (index + 1)
                                subtitle: root.recommendedAlbums.length > index ? root.recommendedAlbums[index].artist : "Artist"
                                artwork: root.recommendedAlbums.length > index ? root.recommendedAlbums[index].artwork : ""
                                type: "album"
                                onClicked: console.log("Open recommended album")
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // RECOMMENDED ARTISTS
                // -------------------------------------------------------------
                SectionHeader {
                    title: "Recommended Artists"
                    onViewAllClicked: console.log("View all recommended artists")
                }

                Flickable {
                    width: parent.width
                    height: 240
                    clip: true
                    contentWidth: recArtistsRow.width
                    contentHeight: 240
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: recArtistsRow
                        spacing: Style.space4
                        height: 240

                        Repeater {
                            model: Math.max(root.recommendedArtists.length, 8)

                            delegate: HomeCardItem {
                                width: 160
                                height: 240
                                title: root.recommendedArtists.length > index ? root.recommendedArtists[index].name : "Recommended Artist " + (index + 1)
                                subtitle: ""
                                artwork: root.recommendedArtists.length > index ? root.recommendedArtists[index].artwork : ""
                                type: "artist"
                                onClicked: console.log("Open recommended artist")
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // TOP CHARTS
                // -------------------------------------------------------------
                SectionHeader {
                    title: "Top Charts"
                    subtitle: "Global Top 50"
                    onViewAllClicked: console.log("View all charts")
                }

                Flickable {
                    width: parent.width
                    height: 220
                    clip: true
                    contentWidth: chartsRow.width
                    contentHeight: 220
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: chartsRow
                        spacing: Style.space4
                        height: 220

                        Repeater {
                            model: Math.max(root.topCharts.length, 6)

                            delegate: HomeCardItem {
                                width: 160
                                height: 220
                                title: root.topCharts.length > index ? root.topCharts[index].title : "Chart Track " + (index + 1)
                                subtitle: root.topCharts.length > index ? root.topCharts[index].artist : "Artist"
                                artwork: root.topCharts.length > index ? root.topCharts[index].artwork : ""
                                type: "track"
                                showRank: true
                                rank: index + 1
                                onClicked: console.log("Play chart track")
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // NEW RELEASES
                // -------------------------------------------------------------
                SectionHeader {
                    title: "New Releases"
                    subtitle: "This Week"
                    onViewAllClicked: console.log("View all new releases")
                }

                Flickable {
                    width: parent.width
                    height: 240
                    clip: true
                    contentWidth: newReleasesRow.width
                    contentHeight: 240
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: newReleasesRow
                        spacing: Style.space4
                        height: 240

                        Repeater {
                            model: Math.max(root.newReleases.length, 8)

                            delegate: HomeCardItem {
                                width: 160
                                height: 240
                                title: root.newReleases.length > index ? root.newReleases[index].title : "New Release " + (index + 1)
                                subtitle: root.newReleases.length > index ? root.newReleases[index].artist : "Artist"
                                artwork: root.newReleases.length > index ? root.newReleases[index].artwork : ""
                                type: "album"
                                badge: "NEW"
                                onClicked: console.log("Open new release")
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // MADE FOR YOU PLAYLISTS
                // -------------------------------------------------------------
                SectionHeader {
                    title: "Made for You"
                    onViewAllClicked: console.log("View all made for you")
                }

                Flickable {
                    width: parent.width
                    height: 240
                    clip: true
                    contentWidth: madeForYouRow.width
                    contentHeight: 240
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: madeForYouRow
                        spacing: Style.space4
                        height: 240

                        Repeater {
                            model: [
                                { name: "Daily Mix 1", type: "Daily Mix", color: "#1DB954" },
                                { name: "Daily Mix 2", type: "Daily Mix", color: "#FF6B6B" },
                                { name: "Daily Mix 3", type: "Daily Mix", color: "#4ECDC4" },
                                { name: "Daily Mix 4", type: "Daily Mix", color: "#45B7D1" },
                                { name: "Discover Weekly", type: "Weekly", color: "#FFA07A" },
                                { name: "Release Radar", type: "Weekly", color: "#98D8C8" },
                                { name: "Your Daily Podcasts", type: "Podcasts", color: "#BB8FCE" },
                                { name: "On Repeat", type: "Personalized", color: "#F7DC6F" }
                            ]

                            delegate: HomeCardItem {
                                width: 160
                                height: 240
                                title: modelData.name
                                subtitle: modelData.type
                                artwork: ""
                                type: "playlist"
                                accentColor: modelData.color
                                onClicked: console.log("Open made for you:", modelData.name)
                            }
                        }
                    }
                }

                // Bottom padding
                Item {
                    width: parent.width
                    height: Style.space6
                }
            }
        }
    }
}
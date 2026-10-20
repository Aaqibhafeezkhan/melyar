import QtQuick
import QtQuick.Controls
import components 1.0
import Melyar.Theme

Rectangle {
    id: root
    color: Style.playerBackground
    height: root.expanded ? Style.playerBarHeightExpanded : Style.playerBarHeight

    signal toggleLyricsClicked()
    signal toggleQueueClicked()

    property bool lyricsActive: false
    property bool queueActive: false
    property bool expanded: false

    // Top divider
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Style.divider
    }

    // Main Content
    Item {
        id: content
        anchors.fill: parent
        anchors.topMargin: 1
        anchors.leftMargin: Style.space4
        anchors.rightMargin: Style.space4
        anchors.bottomMargin: Style.space3

        // -------------------------------------------------------------
        // LEFT: Current Track Info
        // -------------------------------------------------------------
        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space3
            width: parent.width * 0.28

            // Thumbnail with animation
            Rectangle {
                id: thumbContainer
                width: 56
                height: 56
                radius: Style.radiusSmall
                color: Style.surfaceHover
                clip: true

                Image {
                    anchors.fill: parent
                    source: bridge.currentThumbnail
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }

                // Placeholder when no thumbnail
                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: Style.textMuted
                    font.pixelSize: 24
                    visible: bridge.currentThumbnail === ""
                }

                // Play indicator overlay
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: bridge.isPlaying ? 0 : 0.3
                    visible: bridge.currentThumbnail !== ""
                    Behavior on opacity { NumberAnimation { duration: Style.durationNormal } }
                }
            }

            // Title & Artist with marquee for long text
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space1
                width: parent.width - 70 - Style.space4

                Text {
                    id: titleText
                    text: bridge.currentTitle !== "" ? bridge.currentTitle : "No Track Playing"
                    color: Style.textPrimary
                    font.pixelSize: Style.fontSizeBase
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                }

                Row {
                    spacing: Style.space2
                    Text {
                        text: bridge.currentArtist !== "" ? bridge.currentArtist : "Melyar Player"
                        color: Style.textSecondary
                        font.pixelSize: Style.fontSizeSm
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "•"
                        color: Style.textMuted
                        font.pixelSize: Style.fontSizeSm
                        visible: bridge.currentAlbum !== ""
                    }
                    Text {
                        text: bridge.currentAlbum !== "" ? bridge.currentAlbum : ""
                        color: Style.textMuted
                        font.pixelSize: Style.fontSizeSm
                        elide: Text.ElideRight
                    }
                }
            }

            // Action Buttons: Favorite, More Options
            Row {
                spacing: Style.space1
                anchors.verticalCenter: parent.verticalCenter

                // Favorite Button
                ActionButton {
                    id: favBtn
                    icon: bridge.isFavorite(bridge.currentTrackId) ? "♥" : "♡"
                    active: bridge.isFavorite(bridge.currentTrackId)
                    activeColor: Style.primary
                    onClicked: {
                        bridge.toggleFavorite(
                            bridge.currentTrackId,
                            bridge.currentTitle,
                            bridge.currentArtist,
                            bridge.currentAlbum,
                            bridge.currentDuration,
                            bridge.currentThumbnail
                        )
                        parent.active = bridge.isFavorite(bridge.currentTrackId)
                        parent.icon = parent.active ? "♥" : "♡"
                    }
                    visible: bridge.currentTrackId !== ""
                }

                // More Options (3 dots)
                ActionButton {
                    icon: "⋯"
                    onClicked: trackContextMenu.popup(Qt.point(mouseX + parent.x, mouseY + parent.y))
                    visible: bridge.currentTrackId !== ""
                }
            }
        }

        // -------------------------------------------------------------
        // CENTER: Transport Controls & Seekbar
        // -------------------------------------------------------------
        Column {
            id: centerSection
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.44
            spacing: Style.space2

            // Control Buttons Row
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space3

                // Shuffle
                ActionButton {
                    id: shuffleBtn
                    icon: "🔀"
                    active: bridge.shuffleMode
                    toolTip: "Shuffle"
                    onClicked: bridge.toggleShuffle()
                }

                // Previous
                ActionButton {
                    id: prevBtn
                    icon: "⏮"
                    size: 38
                    iconSize: 18
                    onClicked: bridge.previousTrack()
                }

                // Play / Pause - Large central button
                Rectangle {
                    id: playBtn
                    width: 48
                    height: 48
                    radius: 24
                    color: Style.primary
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: bridge.isPlaying ? 0 : 1.5
                        text: bridge.isPlaying ? "❚❚" : "▶"
                        color: Style.textOnPrimary
                        font.pixelSize: bridge.isPlaying ? 14 : 16
                        font.bold: true
                    }

                    Behavior on color { ColorAnimation { duration: Style.durationFast } }
                    Behavior on width { NumberAnimation { duration: Style.durationFast } }
                    Behavior on height { NumberAnimation { duration: Style.durationFast } }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: playBtn.color = Style.primaryHover
                        onExited: playBtn.color = Style.primary
                        onClicked: bridge.togglePlay()
                    }
                }

                // Next
                ActionButton {
                    id: nextBtn
                    icon: "⏭"
                    size: 38
                    iconSize: 18
                    onClicked: bridge.nextTrack()
                }

                // Repeat
                ActionButton {
                    id: repeatBtn
                    icon: root.repeatIcon
                    active: bridge.repeatMode !== 0
                    activeColor: Style.primary
                    toolTip: root.repeatToolTip
                    onClicked: bridge.cycleRepeat()
                }
            }

            // Seek Bar + Timers
            Row {
                width: parent.width
                spacing: Style.space2
                anchors.horizontalCenter: parent.horizontalCenter

                // Current time
                Text {
                    text: Style.formatTime(bridge.currentPosition)
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeXs
                    font.family: Style.fontFamilyMono
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    horizontalAlignment: Text.AlignRight
                }

                // Custom Seek Track Bar
                Rectangle {
                    id: seekTrack
                    width: parent.width - 96
                    height: 4
                    radius: 2
                    color: Style.surfaceHover
                    anchors.verticalCenter: parent.verticalCenter

                    // Progress fill
                    Rectangle {
                        id: seekProgress
                        height: parent.height
                        radius: 2
                        color: seekMouse.containsMouse || seekMouse.pressed ? Style.primary : Style.textPrimary
                        width: {
                            if (bridge.currentDuration > 0) {
                                return Math.min(seekTrack.width, (bridge.currentPosition / bridge.currentDuration) * seekTrack.width)
                            }
                            return 0
                        }
                        Behavior on width { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
                        Behavior on color { ColorAnimation { duration: Style.durationFast } }
                    }

                    // Scrubber thumb
                    Rectangle {
                        id: scrubber
                        width: 12
                        height: 12
                        radius: 6
                        color: Style.textPrimary
                        x: Math.max(0, Math.min(seekTrack.width - width, seekProgress.width - 6))
                        anchors.verticalCenter: parent.verticalCenter
                        visible: seekMouse.containsMouse || seekMouse.pressed
                        opacity: (seekMouse.containsMouse || seekMouse.pressed) ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Style.durationFast } }
                        Behavior on x { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
                    }

                    // Hover Tooltip with preview timestamp
                    Rectangle {
                        id: seekTooltip
                        width: 48
                        height: 22
                        radius: Style.radiusSmall
                        color: "#1e1e1e"
                        border.color: Style.border
                        border.width: 1
                        y: -30
                        x: Math.max(0, Math.min(seekTrack.width - width, seekMouse.mouseX - width / 2))
                        visible: (seekMouse.containsMouse || seekMouse.pressed) && bridge.currentDuration > 0
                        z: Style.zTooltip

                        Text {
                            anchors.centerIn: parent
                            text: {
                                var ratio = Math.max(0, Math.min(1.0, (seekMouse.mouseX - 6) / seekTrack.width))
                                return Style.formatTime(ratio * bridge.currentDuration)
                            }
                            color: Style.textPrimary
                            font.pixelSize: Style.fontSizeXs
                            font.bold: true
                            font.family: Style.fontFamilyMono
                        }
                    }

                    MouseArea {
                        id: seekMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        function updateSeek(mouse) {
                            if (bridge.currentDuration > 0) {
                                var ratio = Math.max(0, Math.min(1.0, (mouse.x - 6) / seekTrack.width))
                                bridge.seek(ratio * bridge.currentDuration)
                            }
                        }

                        onClicked: (mouse) => updateSeek(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                updateSeek(mouse)
                            }
                        }
                    }
                }

                // Total time / Remaining time toggle
                Text {
                    id: timeDisplay
                    text: root.showRemainingTime ? "-" + Style.formatTime(bridge.currentDuration - bridge.currentPosition) : Style.formatTime(bridge.currentDuration)
                    color: Style.textMuted
                    font.pixelSize: Style.fontSizeXs
                    font.family: Style.fontFamilyMono
                    anchors.verticalCenter: parent.verticalCenter
                    width: 45
                    horizontalAlignment: Text.AlignLeft

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showRemainingTime = !root.showRemainingTime
                    }
                }
            }

            // Volume & Queue row (when expanded)
            Row {
                id: bottomControls
                width: parent.width
                spacing: Style.space3
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.expanded
                opacity: root.expanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Style.durationNormal } }

                // Sleep Timer
                ActionButton {
                    id: sleepTimerBtn
                    icon: "🌙"
                    active: bridge.sleepTimerActive
                    activeColor: Style.primary
                    toolTip: bridge.sleepTimerText
                    onClicked: sleepTimerMenu.popup(Qt.point(mouseX + parent.x, mouseY + parent.y))
                }

                Item { width: Style.space2 }

                // Volume Section
                Row {
                    id: volRow
                    spacing: Style.space2
                    anchors.verticalCenter: parent.verticalCenter

                    property double prevVolume: 100.0

                    ActionButton {
                        id: volIcon
                        icon: bridge.volume > 66 ? "🔊" : (bridge.volume > 33 ? "🔉" : (bridge.volume > 0 ? "🔈" : "🔇"))
                        flat: true
                        onClicked: {
                            if (bridge.volume > 0) {
                                volRow.prevVolume = bridge.volume
                                bridge.setVolume(0)
                            } else {
                                bridge.setVolume(volRow.prevVolume > 0 ? volRow.prevVolume : 100)
                            }
                        }
                    }

                    Rectangle {
                        id: volumeTrack
                        width: 90
                        height: 4
                        radius: 2
                        color: Style.surfaceHover
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            height: parent.height
                            radius: 2
                            color: volMouse.containsMouse ? Style.primary : Style.textSecondary
                            width: Math.min(volumeTrack.width, (bridge.volume / 100.0) * volumeTrack.width)
                            Behavior on width { NumberAnimation { duration: 50; easing.type: Easing.Linear } }
                        }

                        MouseArea {
                            id: volMouse
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            function updateVolume(mouse) {
                                var ratio = Math.max(0, Math.min(1, (mouse.x - 6) / volumeTrack.width))
                                bridge.setVolume(ratio * 100.0)
                            }

                            onClicked: (mouse) => updateVolume(mouse)
                            onPositionChanged: (mouse) => {
                                if (pressed) updateVolume(mouse)
                            }
                        }
                    }
                }

                Item { width: Style.space2 }

                // Lyrics Toggle
                ActionButton {
                    id: lyricsBtn
                    icon: "🎤"
                    active: root.lyricsActive
                    activeColor: Style.primary
                    toolTip: "Lyrics"
                    onClicked: root.toggleLyricsClicked()
                }

                // Queue Toggle
                ActionButton {
                    id: queueBtn
                    icon: "☰"
                    active: root.queueActive
                    activeColor: Style.primary
                    toolTip: "Queue"
                    onClicked: root.toggleQueueClicked()
                }

                // Expand/Collapse
                ActionButton {
                    id: expandBtn
                    icon: root.expanded ? "⌄" : "⌃"
                    flat: true
                    onClicked: root.expanded = !root.expanded
                }
            }
        }

        // -------------------------------------------------------------
        // RIGHT: Queue Panel (slides in)
        // -------------------------------------------------------------
        Item {
            id: queuePanel
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.queueActive ? 320 : 0
            visible: root.queueActive
            clip: true

            Behavior on width {
                NumberAnimation { duration: Style.durationSlow; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.fill: parent
                color: Style.surface
                border.color: Style.divider
                border.width: 1
                radius: Style.radiusMedium
                clip: true

                Column {
                    anchors.fill: parent

                    // Queue Header
                    Rectangle {
                        width: parent.width
                        height: 48
                        color: "transparent"
                        border.color: Style.divider
                        border.width: 1

                        // Bottom border line
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Style.divider
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: Style.space3

                            Text {
                                text: "QUEUE"
                                color: Style.textMuted
                                font.pixelSize: Style.fontSizeXs
                                font.bold: true
                                font.letterSpacing: 1
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Item { width: 1 } // spacer

                            Text {
                                text: bridge.queueLength + " in queue"
                                color: Style.textMuted
                                font.pixelSize: Style.fontSizeXs
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Item { width: 1 }

                            ActionButton {
                                icon: "🗑"
                                flat: true
                                toolTip: "Clear Queue"
                                onClicked: bridge.clearQueue()
                            }
                        }
                    }

                    // Queue List
                    ListView {
                        id: queueList
                        anchors.fill: parent
                        clip: true
                        model: bridge.queue
                        spacing: 0
                        cacheBuffer: 20

                        delegate: QueueItem {
                            width: parent.width
                            trackData: modelData
                            index: index
                            isCurrent: bridge.currentTrackId === (modelData ? modelData.id : "")
                            isPlaying: bridge.isPlaying && bridge.currentTrackId === (modelData ? modelData.id : "")
                            onRemoveClicked: {
                                bridge.removeFromQueue(index)
                            }
                            onPlayClicked: {
                                bridge.playFromQueue(index)
                            }
                        }
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------
    // CONTEXT MENUS
    // -------------------------------------------------------------

    property bool showRemainingTime: false
    property string repeatIcon: bridge.repeatMode === 2 ? "🔂" : (bridge.repeatMode === 1 ? "🔁" : "🔁")
    property string repeatToolTip: bridge.repeatMode === 2 ? "Repeat One" : (bridge.repeatMode === 1 ? "Repeat All" : "Repeat Off")

    // Track Context Menu
    Menu {
        id: trackContextMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }

        MenuItem {
            text: "Add to Queue"
            onTriggered: bridge.addToQueue(bridge.currentTrackId)
        }
        MenuItem {
            text: "Add to Playlist..."
            onTriggered: console.log("Add to playlist")
        }
        MenuSeparator {}
        MenuItem {
            text: "Go to Artist"
            onTriggered: console.log("Go to artist:", bridge.currentArtist)
        }
        MenuItem {
            text: "Go to Album"
            onTriggered: console.log("Go to album:", bridge.currentAlbum)
        }
        MenuSeparator {}
        MenuItem {
            text: bridge.isFavorite(bridge.currentTrackId) ? "Remove from Liked" : "Add to Liked"
            onTriggered: {
                bridge.toggleFavorite(
                    bridge.currentTrackId,
                    bridge.currentTitle,
                    bridge.currentArtist,
                    bridge.currentAlbum,
                    bridge.currentDuration,
                    bridge.currentThumbnail
                )
            }
        }
        MenuItem {
            text: "Share"
            onTriggered: console.log("Share track")
        }
        MenuSeparator {}
        MenuItem {
            text: "View Lyrics"
            onTriggered: {
                root.lyricsActive = true
                root.toggleLyricsClicked()
            }
        }
    }

    // Sleep Timer Menu
    Menu {
        id: sleepTimerMenu
        background: Rectangle {
            color: Style.surface
            border.color: Style.border
            border.width: 1
            radius: Style.radiusMedium
        }

        MenuItem {
            text: "5 minutes"
            onTriggered: bridge.setSleepTimer(5 * 60)
        }
        MenuItem {
            text: "10 minutes"
            onTriggered: bridge.setSleepTimer(10 * 60)
        }
        MenuItem {
            text: "15 minutes"
            onTriggered: bridge.setSleepTimer(15 * 60)
        }
        MenuItem {
            text: "30 minutes"
            onTriggered: bridge.setSleepTimer(30 * 60)
        }
        MenuItem {
            text: "45 minutes"
            onTriggered: bridge.setSleepTimer(45 * 60)
        }
        MenuItem {
            text: "60 minutes"
            onTriggered: bridge.setSleepTimer(60 * 60)
        }
        MenuItem {
            text: "End of track"
            onTriggered: bridge.setSleepTimer(-1)
        }
        MenuSeparator {}
        MenuItem {
            text: "Cancel Timer"
            enabled: bridge.sleepTimerActive
            onTriggered: bridge.cancelSleepTimer()
        }
    }
}
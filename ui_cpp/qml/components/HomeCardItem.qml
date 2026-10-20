import QtQuick
import Melyar.Theme

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string artwork: ""
    property string type: "album" // album, artist, track, playlist
    property string badge: ""
    property string accentColor: "#1DB954"
    property int rank: 0
    property bool showRank: false
    property real progress: 0 // 0-1 for jump back in
    signal clicked()

    Rectangle {
        anchors.fill: parent
        anchors.margins: Style.space2
        color: "transparent"

        Column {
            anchors.fill: parent
            spacing: Style.space2

            // Artwork
            Rectangle {
                width: parent.width
                height: type === "artist" ? parent.width : parent.width
                radius: type === "artist" ? parent.width / 2 : Style.radiusMedium
                color: Style.surfaceHover
                clip: true
                anchors.horizontalCenter: parent.horizontalCenter

                Image {
                    anchors.fill: parent
                    source: root.artwork
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }

                // Overlay on hover
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: mouseArea.containsMouse ? 0.4 : 0
                    visible: root.artwork !== ""
                    Behavior on opacity { NumberAnimation { duration: Style.durationNormal } }
                }

                // Play button overlay
                Rectangle {
                    id: playOverlay
                    width: type === "artist" ? 56 : 48
                    height: type === "artist" ? 56 : 48
                    radius: type === "artist" ? 28 : 24
                    color: Style.primary
                    anchors.centerIn: parent
                    visible: mouseArea.containsMouse
                    opacity: mouseArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Style.durationNormal } }

                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: type === "artist" ? 3 : 2
                        text: "▶"
                        color: Style.textOnPrimary
                        font.pixelSize: type === "artist" ? 20 : 18
                        font.bold: true
                    }
                }

                // Badge
                Rectangle {
                    id: badgeRect
                    height: 20
                    radius: Style.radiusSmall
                    color: Style.error
                    anchors.top: parent.top
                    anchors.topMargin: Style.space2
                    anchors.right: parent.right
                    anchors.rightMargin: Style.space2
                    visible: root.badge !== ""

                    Text {
                        anchors.centerIn: parent
                        text: root.badge
                        color: Style.textOnPrimary
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        padding: 0
                        anchors.margins: Style.space2
                    }
                }

                // Rank indicator (for charts)
                Rectangle {
                    id: rankRect
                    width: 28
                    height: 28
                    radius: 14
                    color: "#000000"
                    opacity: 0.7
                    anchors.top: parent.top
                    anchors.topMargin: Style.space2
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space2
                    visible: root.showRank && !mouseArea.containsMouse

                    Text {
                        anchors.centerIn: parent
                        text: root.rank
                        color: root.rank <= 3 ? "#FFD700" : Style.textPrimary
                        font.pixelSize: Style.fontSizeXs
                        font.bold: true
                        font.family: Style.fontFamilyMono
                    }
                }

                // Progress ring for jump back in
                Canvas {
                    id: progressCanvas
                    anchors.fill: parent
                    visible: root.progress > 0 && root.progress < 1 && type === "album"

                    onPaint: {
                        var ctx = getContext("2d")
                        var centerX = width / 2
                        var centerY = height / 2
                        var radius = Math.min(width, height) / 2 - 4

                        ctx.clearRect(0, 0, width, height)

                        // Background ring
                        ctx.beginPath()
                        ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI)
                        ctx.strokeStyle = "#333333"
                        ctx.lineWidth = 3
                        ctx.stroke()

                        // Progress ring
                        ctx.beginPath()
                        ctx.arc(centerX, centerY, radius, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * root.progress)
                        ctx.strokeStyle = "#1DB954"
                        ctx.lineWidth = 3
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                }

                // Placeholder icons
                Text {
                    anchors.centerIn: parent
                    text: root.type === "artist" ? "🎤" : (root.type === "playlist" ? "📋" : "💿")
                    font.pixelSize: parent.width * 0.3
                    color: Style.textMuted
                    visible: root.artwork === ""
                }
            }

            // Info
            Column {
                width: parent.width
                spacing: Style.space1

                Text {
                    text: root.title
                    color: Style.textPrimary
                    font.pixelSize: Style.fontSizeSm
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width
                    horizontalAlignment: type === "artist" ? Text.AlignHCenter : Text.AlignLeft
                }

                Text {
                    text: root.subtitle
                    color: Style.textSecondary
                    font.pixelSize: Style.fontSizeXs
                    elide: Text.ElideRight
                    width: parent.width
                    horizontalAlignment: type === "artist" ? Text.AlignHCenter : Text.AlignLeft
                    visible: root.subtitle !== ""
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
    }
}
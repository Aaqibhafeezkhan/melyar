import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import components 1.0
import Melyar.Theme

ListView {
    id: trackList
    clip: true
    spacing: 10
    model: []
    cacheBuffer: 200

    delegate: GlassCard {
        width: trackList.width
        height: 64
        radius: Style.radiusMedium
        isHovered: itemArea.containsMouse

        property var modelData: modelData

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 16
            spacing: 14

            Text {
                text: (index + 1).toString()
                color: Style.textMuted
                font.pixelSize: 13
                Layout.preferredWidth: 20
            }

            Rectangle {
                width: 44
                height: 44
                radius: 8
                color: "#222"
                clip: true

                Image {
                    anchors.fill: parent
                    source: modelData.thumbnail
                    fillMode: Image.PreserveAspectCrop
                    visible: modelData.thumbnail !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: Style.textMuted
                    font.pixelSize: 16
                    visible: modelData.thumbnail === ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: modelData.title
                    color: Style.textPrimary
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Text {
                    text: modelData.artist
                    color: Style.textSecondary
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            Text {
                text: modelData.duration > 0 ? Style.formatTimeSeconds(modelData.duration) : ""
                color: Style.textMuted
                font.pixelSize: 12
                font.family: Style.fontFamilyMono
            }
        }

        MouseArea {
            id: itemArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                bridge.playTrack(modelData.id)
            }
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Populate with tracks from bridge search results or favorites
    Component.onCompleted: {
        // Initial load - show favorites if available
        if (bridge.favorites.length > 0) {
            model = bridge.favorites
        }
    }

    Connections {
        target: bridge
        function onSearchResultsChanged() {
            model = bridge.searchResults
        }
        function onFavoritesChanged() {
            if (model.length === 0 || model === bridge.searchResults) {
                model = bridge.favorites
            }
        }
    }
}

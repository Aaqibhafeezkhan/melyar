import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import components 1.0
import Melyar.Theme

GlassCard {
    id: playerDock
    height: Style.playerBarHeight
    radius: Style.radiusXLarge

    signal toggleLyricsClicked()
    property bool favActive: bridge.isFavorite(bridge.currentTrackId)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        // 1. Albüm Kapağı & Bilgileri
        RowLayout {
            spacing: 14
            Layout.preferredWidth: 280

            Rectangle {
                width: 56
                height: 56
                radius: 12
                color: "#1A1A1A"
                clip: true

                Image {
                    anchors.fill: parent
                    source: bridge.currentThumbnail
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: bridge.currentThumbnail !== "" && bridge.currentTrackId !== ""
                }

                // Placeholder
                Text {
                    anchors.centerIn: parent
                    text: "♪"
                    color: Style.textMuted
                    font.pixelSize: 20
                    visible: bridge.currentThumbnail === "" || bridge.currentTrackId === ""
                }

                // Tıklanınca Şarkı Sözleri Moduna Geç
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: playerDock.toggleLyricsClicked()
                }
            }

            ColumnLayout {
                spacing: 3
                Layout.fillWidth: true

                Text {
                    text: bridge.currentTitle !== "" ? bridge.currentTitle : "Bir parça seç"
                    color: Style.textPrimary
                    font.pixelSize: 15
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 8
                    Text {
                        text: bridge.currentArtist !== "" ? bridge.currentArtist : ""
                        color: Style.textSecondary
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    // Lossless Rozeti
                    Rectangle {
                        width: 54
                        height: 16
                        radius: 4
                        color: "#33FFFFFF"
                        Text {
                            anchors.centerIn: parent
                            text: "LOSSLESS"
                            color: "#E0E0E0"
                            font.pixelSize: 8
                            font.bold: true
                        }
                        visible: bridge.currentTrackId !== ""
                    }
                }
            }

            // Favori (Kalp) Butonu
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: favArea.containsMouse ? Style.surfaceHover : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: favActive ? "♥" : "♡"
                    color: favActive ? "#FF2D55" : Style.textSecondary
                    font.pixelSize: 18
                }

                MouseArea {
                    id: favArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        bridge.toggleFavorite(bridge.currentTrackId, bridge.currentTitle, bridge.currentArtist, bridge.currentAlbum, bridge.currentDuration, bridge.currentThumbnail)
                        favActive = bridge.isFavorite(bridge.currentTrackId)
                    }

                    Component.onCompleted: {
                        favActive = bridge.isFavorite(bridge.currentTrackId)
                    }

                    Connections {
                        target: bridge
                        function onFavoritesChanged() {
                            favActive = bridge.isFavorite(bridge.currentTrackId)
                        }
                    }
                }
            }

            // Favori durumu takibi
            property bool favActive: false
        }

        // 2. Orta Oynatma Kontrolleri & İlerleme Çubuğu
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 22

                // Önceki Şarkı
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: prevArea.containsMouse ? "#22FFFFFF" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⏮"
                        color: "#FFF"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.previousTrack()
                    }
                }

                // Oynat / Durdur Butonu
                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: playArea.containsMouse ? "#FFFFFF" : "#E5FFFFFF"
                    scale: playArea.pressed ? 0.92 : 1.0

                    Text {
                        anchors.centerIn: parent
                        text: bridge.isPlaying ? "⏸" : "▶"
                        color: "#000000"
                        font.pixelSize: 18
                    }

                    MouseArea {
                        id: playArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.togglePlay()
                    }

                    Behavior on scale { NumberAnimation { duration: 100 } }
                }

                // Sonraki Şarkı
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: nextArea.containsMouse ? "#22FFFFFF" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⏭"
                        color: "#FFF"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.nextTrack()
                    }
                }
            }

            // İlerleme Slider'ı ve Zaman Etiketleri
            RowLayout {
                spacing: 10
                Layout.fillWidth: true

                Text {
                    text: Style.formatTimeSeconds(bridge.currentPosition)
                    color: Style.textMuted
                    font.pixelSize: 11
                    font.bold: true
                    font.family: Style.fontFamilyMono
                }

                Slider {
                    id: progressSlider
                    Layout.fillWidth: true
                    from: 0
                    to: bridge.currentDuration > 0 ? bridge.currentDuration : 1
                    value: bridge.currentPosition

                    onValueChanged: {
                        if (pressed) {
                            bridge.seek(value)
                        }
                    }

                    background: Rectangle {
                        x: progressSlider.leftPadding
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 200
                        implicitHeight: 4
                        width: progressSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#33FFFFFF"

                        Rectangle {
                            width: progressSlider.visualPosition * parent.width
                            height: parent.height
                            color: Style.primary
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                        y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                        implicitWidth: 12
                        implicitHeight: 12
                        radius: 6
                        color: "#FFFFFF"
                        visible: progressSlider.hovered || progressSlider.pressed
                    }
                }

                Text {
                    text: Style.formatTimeSeconds(bridge.currentDuration)
                    color: Style.textMuted
                    font.pixelSize: 11
                    font.bold: true
                    font.family: Style.fontFamilyMono
                }
            }
        }

        // 3. Sağ Taraf Ses ve Söz Modu Düğmeleri
        RowLayout {
            spacing: 12
            Layout.preferredWidth: 180
            Layout.alignment: Qt.AlignRight

            // Şarkı Sözü Butonu
            Rectangle {
                width: 36
                height: 36
                radius: 10
                color: bridge.isPlaying && bridge.currentTrackId !== "" ? (lyrArea.containsMouse ? "#22FFFFFF" : "transparent") : "#1AFFFFFF"
                border.color: bridge.isPlaying ? (lyrArea.containsMouse ? "#00F2FE" : "transparent") : "transparent"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "💬"
                    color: "#FFF"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: lyrArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        playerDock.toggleLyricsClicked()
                    }
                    enabled: bridge.currentTrackId !== ""
                }
            }

            // Ses Slider'ı
            Text {
                text: "🔊"
                color: Style.textMuted
                font.pixelSize: 13
            }

            Slider {
                id: volumeSlider
                Layout.preferredWidth: 90
                from: 0
                to: 100
                value: bridge.volume

                onValueChanged: {
                    if (pressed) {
                        bridge.setVolume(value / 100.0)
                    }
                }

                background: Rectangle {
                    implicitHeight: 4
                    radius: 2
                    color: "#33FFFFFF"
                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        color: "#FFFFFF"
                        radius: 2
                    }
                }
                handle: Item {
                    width: 0
                    height: 0
                }
            }
        }
    }

    function formatTime(ms) {
        return Style.formatTimeSeconds(ms)
    }
}

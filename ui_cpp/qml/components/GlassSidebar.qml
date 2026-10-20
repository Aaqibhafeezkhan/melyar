import QtQuick
import QtQuick.Layouts
import components 1.0
import Melyar.Theme

GlassCard {
    id: sidebar
    width: Style.sidebarWidth
    radius: Style.radiusXLarge

    property int activeTab: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Logo
        RowLayout {
            spacing: 12
            Layout.topMargin: 12
            Layout.leftMargin: 12

            Rectangle {
                width: 32
                height: 32
                radius: 10
                color: Style.primary

                Text {
                    anchors.centerIn: parent
                    text: "M"
                    color: Style.textOnPrimary
                    font.bold: true
                    font.pixelSize: 18
                }
            }

            Text {
                text: "Melyar"
                color: Style.textPrimary
                font.pixelSize: 20
                font.bold: true
            }
        }

        Item { height: 20 }

        // Menü Öğeleri
        Repeater {
            model: [
                { title: "Keşfet", icon: "🔍" },
                { title: "Arşivim", icon: "📚" },
                { title: "Favoriler", icon: "❤️" },
                { title: "Çalma Listeleri", icon: "🎵" }
            ]

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: Style.radiusMedium
                color: sidebar.activeTab === index ? "#33FFFFFF" : (menuArea.containsMouse ? "#1AFFFFFF" : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    spacing: 14

                    Text {
                        text: modelData.icon
                        font.pixelSize: 16
                    }

                    Text {
                        text: modelData.title
                        color: Style.textPrimary
                        font.pixelSize: 14
                        font.bold: sidebar.activeTab === index
                    }
                }

                MouseArea {
                    id: menuArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidebar.activeTab = index
                }

                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

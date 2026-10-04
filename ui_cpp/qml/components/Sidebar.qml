import QtQuick
import Melyar.Theme

Rectangle {
    id: root
    width: Style.sidebarWidth
    color: Style.sidebarBackground

    signal tabSelected(string tabName)
    property string activeTab: "search"

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 20

        // App Branding
        Row {
            spacing: 10
            anchors.left: parent.left

            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: Style.primary
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "M"
                    color: "#000000"
                    font.bold: true
                    font.pixelSize: 18
                }
            }

            Text {
                text: "MELYAR"
                color: Style.textPrimary
                font.bold: true
                font.pixelSize: 18
                font.letterSpacing: 2
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Navigation Menu
        Column {
            width: parent.width
            spacing: 6

            // Search Tab
            Rectangle {
                width: parent.width
                height: 42
                radius: Style.radiusSmall
                color: root.activeTab === "search" ? Style.surfaceHover : (searchMouse.containsMouse ? Style.surface : "transparent")

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 14

                    Text {
                        text: "🔍"
                        font.pixelSize: 15
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.activeTab === "search" ? Style.primary : Style.textSecondary
                    }

                    Text {
                        text: "Search"
                        font.pixelSize: 14
                        font.bold: root.activeTab === "search"
                        color: root.activeTab === "search" ? Style.textPrimary : Style.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: searchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.activeTab = "search";
                        root.tabSelected("search");
                    }
                }
            }

            // Favorites Tab
            Rectangle {
                width: parent.width
                height: 42
                radius: Style.radiusSmall
                color: root.activeTab === "favorites" ? Style.surfaceHover : (favMouse.containsMouse ? Style.surface : "transparent")

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 14

                    Text {
                        text: "♥"
                        font.pixelSize: 16
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.activeTab === "favorites" ? Style.primary : Style.textSecondary
                    }

                    Text {
                        text: "Favorites"
                        font.pixelSize: 14
                        font.bold: root.activeTab === "favorites"
                        color: root.activeTab === "favorites" ? Style.textPrimary : Style.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: favMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.activeTab = "favorites";
                        bridge.loadFavorites();
                        root.tabSelected("favorites");
                    }
                }
            }

            // History Tab
            Rectangle {
                width: parent.width
                height: 42
                radius: Style.radiusSmall
                color: root.activeTab === "history" ? Style.surfaceHover : (histMouse.containsMouse ? Style.surface : "transparent")

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    spacing: 14

                    Text {
                        text: "⏱"
                        font.pixelSize: 15
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.activeTab === "history" ? Style.primary : Style.textSecondary
                    }

                    Text {
                        text: "History"
                        font.pixelSize: 14
                        font.bold: root.activeTab === "history"
                        color: root.activeTab === "history" ? Style.textPrimary : Style.textSecondary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: histMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.activeTab = "history";
                        bridge.loadHistory();
                        root.tabSelected("history");
                    }
                }
            }
        }

        Item {
            // Spacer
            width: parent.width
            height: 20
        }

        // System specs pill
        Rectangle {
            width: parent.width
            height: 60
            radius: Style.radiusMedium
            color: Style.surface

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "PIPEWIRE AUDIO"
                    color: Style.primary
                    font.bold: true
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Pure C++ & Rust | Zero-Web"
                    color: Style.textMuted
                    font.pixelSize: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}

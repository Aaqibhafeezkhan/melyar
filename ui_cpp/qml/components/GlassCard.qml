import QtQuick
import Melyar.Theme

Rectangle {
    id: glassCard
    radius: 20
    color: Qt.rgba(1, 1, 1, isHovered ? 0.16 : 0.10)
    border.color: Qt.rgba(1, 1, 1, isHovered ? 0.35 : 0.20)
    border.width: 1.5

    property bool isHovered: false
    property bool enableGlow: false
    default property alias contentData: container.data

    // Cam İçi Vurgu Işığı (Top-Left Specular Gradient)
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1
        anchors.margins: 1

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#25FFFFFF" }
            GradientStop { position: 0.4; color: "#00FFFFFF" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }

    // İçerik Yerleşim Alanı
    Item {
        id: container
        anchors.fill: parent
        anchors.margins: 12
    }

    // Hover ve Tıklama Animasyonu
    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
}

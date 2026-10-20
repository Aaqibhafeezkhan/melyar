import QtQuick
import Melyar.Theme

Item {
    id: liquidBg
    anchors.fill: parent

    property color dominantColor: "#8E0E00"
    property color secondaryColor: "#1F1C18"

    // Taban Karanlık Zemin
    Rectangle {
        anchors.fill: parent
        color: "#0B0C10"
    }

    // 1. Sıfırdan Sıfıra Akışkan Renk Balonu (Dominant Color Blob)
    Item {
        id: blob1
        width: parent.width * 0.8
        height: parent.height * 0.8
        x: parent.width * 0.1
        y: parent.height * 0.05

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: liquidBg.dominantColor
            opacity: 0.45

            Behavior on color { ColorAnimation { duration: Style.durationFluid; easing.type: Easing.InOutQuad } }
        }

        // Yavaş Dairesel Salınım Animasyonu
        SequentialAnimation on x {
            loops: Animation.Infinite
            NumberAnimation { to: liquidBg.width * 0.25; duration: 8000; easing.type: Style.easingFluid }
            NumberAnimation { to: liquidBg.width * 0.05; duration: 8000; easing.type: Style.easingFluid }
        }
        SequentialAnimation on y {
            loops: Animation.Infinite
            NumberAnimation { to: liquidBg.height * 0.2; duration: 6000; easing.type: Style.easingFluid }
            NumberAnimation { to: liquidBg.height * 0.05; duration: 6000; easing.type: Style.easingFluid }
        }
    }

    // 2. Sıfırdan Sıfıra Akışkan Renk Balonu (Secondary Color Blob)
    Item {
        id: blob2
        width: parent.width * 0.7
        height: parent.height * 0.7
        x: parent.width * 0.3
        y: parent.height * 0.35

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: liquidBg.secondaryColor
            opacity: 0.35

            Behavior on color { ColorAnimation { duration: Style.durationFluid; easing.type: Easing.InOutQuad } }
        }

        SequentialAnimation on x {
            loops: Animation.Infinite
            NumberAnimation { to: liquidBg.width * 0.1; duration: 9000; easing.type: Style.easingFluid }
            NumberAnimation { to: liquidBg.width * 0.3; duration: 9000; easing.type: Style.easingFluid }
        }
    }

    // Üst Vignette / Noise Kaplaması
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0A000000" }
            GradientStop { position: 0.5; color: "#2A000000" }
            GradientStop { position: 1.0; color: "#8A0B0C10" }
        }
    }
}

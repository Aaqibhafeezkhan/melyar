import QtQuick
import Melyar.Theme

Item {
    id: root

    property string freq: ""
    property real gain: 0

    width: 50
    height: 160

    Column {
        anchors.fill: parent
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space2

        // Vertical slider
        Slider {
            id: eqSlider
            width: 30
            height: 120
            orientation: Qt.Vertical
            from: -12
            to: 12
            value: root.gain
            stepSize: 1
            onValueChanged: root.gain = value
        }

        Text {
            text: root.freq
            color: Style.textMuted
            font.pixelSize: Style.fontSizeXs
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: (root.gain >= 0 ? "+" : "") + root.gain.toFixed(0) + " dB"
            color: Style.textSecondary
            font.pixelSize: Style.fontSizeXs
            font.family: Style.fontFamilyMono
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
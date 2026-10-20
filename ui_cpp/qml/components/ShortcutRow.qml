import QtQuick
import Melyar.Theme

Item {
    id: root

    property string label: ""
    property string action: ""
    property string currentKey: ""
    signal keyChanged(string action, string key)

    height: 40
    width: parent.width

    property bool editing: false

    Rectangle {
        anchors.fill: parent
        radius: Style.radiusSmall
        color: mouseArea.containsMouse ? Style.surfaceHover : "transparent"

        Row {
            anchors.fill: parent
            anchors.margins: Style.space3
            spacing: Style.space3

            Text {
                text: root.label
                color: Style.textPrimary
                font.pixelSize: Style.fontSizeBase
                width: 180
            }

            Item { width: 1 } // spacer

            // Shortcut Display / Editor
            Rectangle {
                id: shortcutDisplay
                height: 32
                radius: Style.radiusSmall
                color: root.editing ? Style.primary : Style.surface
                border.color: root.editing ? Style.primary : Style.border
                border.width: 1
                minimumWidth: 120

                Text {
                    anchors.centerIn: parent
                    text: root.editing ? "Press keys..." : root.currentKey
                    color: root.editing ? Style.textOnPrimary : Style.textPrimary
                    font.pixelSize: Style.fontSizeSm
                    font.family: Style.fontFamilyMono
                    font.bold: root.editing
                }

                Behavior on color { ColorAnimation { duration: Style.durationFast } }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.editing = !root.editing
            if (root.editing) {
                shortcutDisplay.focus = true
            }
        }
    }

    Keys.onPressed: {
        if (root.editing) {
            var keyText = event.text
            if (event.key === Qt.Key_Space) keyText = "Space"
            else if (event.key === Qt.Key_Escape) keyText = "Escape"
            else if (event.key === Qt.Key_Return) keyText = "Enter"
            else if (event.key === Qt.Key_Tab) keyText = "Tab"
            else if (event.key === Qt.Key_Backspace) keyText = "Backspace"
            else if (event.key === Qt.Key_Delete) keyText = "Delete"
            else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12) keyText = "F" + (event.key - Qt.Key_F1 + 1)
            else if (event.key === Qt.Key_Left) keyText = "Left"
            else if (event.key === Qt.Key_Right) keyText = "Right"
            else if (event.key === Qt.Key_Up) keyText = "Up"
            else if (event.key === Qt.Key_Down) keyText = "Down"
            else if (event.key === Qt.Key_Shift) keyText = "Shift"
            else if (event.key === Qt.Key_Control) keyText = "Ctrl"
            else if (event.key === Qt.Key_Alt) keyText = "Alt"
            else if (event.key === Qt.Key_Meta) keyText = "Meta"
            else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) keyText = String.fromCharCode(event.key)
            else if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) keyText = String.fromCharCode(event.key)

            // Build modifier string
            var modifiers = []
            if (event.modifiers & Qt.ControlModifier) modifiers.push("Ctrl")
            if (event.modifiers & Qt.AltModifier) modifiers.push("Alt")
            if (event.modifiers & Qt.ShiftModifier) modifiers.push("Shift")
            if (event.modifiers & Qt.MetaModifier) modifiers.push("Meta")

            var fullKey = modifiers.join("+") + (modifiers.length > 0 && keyText ? "+" : "") + keyText
            if (fullKey) {
                root.keyChanged(root.action, fullKey)
                root.editing = false
            }
            event.accepted = true
        }
    }

    Keys.onEscapePressed: {
        if (root.editing) {
            root.editing = false
        }
    }
}
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Melyar.Theme

Item {
    id: root
    width: parent.width
    height: parent.height

    // Settings model
    property var settings: QtObject {
        // Appearance
        property string theme: "dark"
        property string accentColor: "#1DB954"
        property bool compactMode: false
        property bool showAlbumArt: true
        property bool animationsEnabled: true

        // Playback
        property bool crossfadeEnabled: false
        property int crossfadeDuration: 5
        property bool gaplessPlayback: true
        property bool normalizeVolume: false
        property bool equalizerEnabled: false

        // Audio Quality
        property string streamingQuality: "high"
        property string downloadQuality: "high"

        // Behavior
        property bool minimizeToTray: true
        property bool closeToTray: false
        property bool startMinimized: false
        property bool autoPlayNext: true
        property bool showNotifications: true
        property bool showLyricsAutomatically: false

        // Shortcuts
        property var shortcuts: {
            playPause: "Space"
            nextTrack: "Right"
            previousTrack: "Left"
            volumeUp: "Up"
            volumeDown: "Down"
            seekForward: "Ctrl+Right"
            seekBackward: "Ctrl+Left"
            toggleLyrics: "L"
            toggleQueue: "Q"
            toggleShuffle: "S"
            toggleRepeat: "R"
            mute: "M"
            search: "Ctrl+F"
        }

        // Advanced
        property int cacheSize: 500
        property bool proxyEnabled: false
        property string pipewireLatency: "low"
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            width: parent.width
            height: 80
            color: "transparent"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Style.space6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Style.space4
                text: "Settings"
                font.pixelSize: Style.fontSize4xl
                font.bold: true
                font.weight: Style.fontWeightBold
                color: Style.textPrimary
            }
        }

        // Settings Content
        ScrollView {
            anchors.fill: parent
            clip: true
            ScrollBar.vertical: ScrollBar {
                width: 8
                policy: ScrollBar.AlwaysOff
                contentItem: Rectangle {
                    radius: 4
                    color: Style.primary
                }
            }

            Column {
                width: parent.width
                spacing: Style.space6
                anchors.leftMargin: Style.space6
                anchors.rightMargin: Style.space6

                // -------------------------------------------------------------
                // APPEARANCE SECTION
                // -------------------------------------------------------------
                SettingsSection {
                    title: "Appearance"
                    icon: "🎨"

                    Column {
                        spacing: Style.space3

                        // Theme Selection
                        SettingRow {
                            label: "Theme"
                            description: "Choose color theme"

                            ComboBox {
                                id: themeCombo
                                width: 200
                                height: 36
                                model: ["Dark", "Light", "System"]
                                currentIndex: 0 // dark=0, light=1, system=2
                                delegate: ItemDelegate {
                                    width: parent.width
                                    height: 36
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: Style.textPrimary
                                        font.pixelSize: Style.fontSizeBase
                                    }
                                    highlighted: Rectangle {
                                        color: Style.primary
                                    }
                                }
                                background: Rectangle {
                                    color: Style.surface
                                    border.color: Style.border
                                    border.width: 1
                                    radius: Style.radiusSmall
                                }
                                indicator: Canvas {
                                    width: 16
                                    height: 16
                                    contextType: "2d"
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.fillStyle = themeCombo.hovered ? "#1ed760" : "#1DB954"
                                        ctx.beginPath()
                                        ctx.moveTo(4, 6)
                                        ctx.lineTo(8, 10)
                                        ctx.lineTo(14, 4)
                                        ctx.strokeStyle = ctx.fillStyle
                                        ctx.lineWidth = 2
                                        ctx.stroke()
                                    }
                                }
                                onActivated: settings.theme = ["dark", "light", "system"][index]
                            }
                        }

                        // Accent Color
                        SettingRow {
                            label: "Accent Color"
                            description: "Customize the highlight color"

                            Row {
                                spacing: Style.space3
                                Repeater {
                                    model: ["#1DB954", "#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8", "#BB8FCE", "#F7DC6F", "#FF8B94", "#A8E6CF"]
                                    delegate: ColorPicker {
                                        color: modelData
                                        selected: settings.accentColor === modelData
                                        onClicked: settings.accentColor = modelData
                                    }
                                }
                            }
                        }

                        // Compact Mode
                        SettingRow {
                            label: "Compact Mode"
                            description: "Reduce spacing for more content"

                            Switch {
                                checked: settings.compactMode
                                onToggled: settings.compactMode = checked
                            }
                        }

                        // Show Album Art
                        SettingRow {
                            label: "Show Album Art"
                            description: "Display artwork in lists and player"

                            Switch {
                                checked: settings.showAlbumArt
                                onToggled: settings.showAlbumArt = checked
                            }
                        }

                        // Animations
                        SettingRow {
                            label: "Animations"
                            description: "Enable smooth transitions and effects"

                            Switch {
                                checked: settings.animationsEnabled
                                onToggled: settings.animationsEnabled = checked
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // PLAYBACK SECTION
                // -------------------------------------------------------------
                SettingsSection {
                    title: "Playback"
                    icon: "▶"

                    Column {
                        spacing: Style.space3

                        // Crossfade
                        SettingRow {
                            label: "Crossfade"
                            description: "Blend between tracks"

                            Row {
                                spacing: Style.space3

                                Switch {
                                    checked: settings.crossfadeEnabled
                                    onToggled: settings.crossfadeEnabled = checked
                                }

                                Slider {
                                    id: crossfadeSlider
                                    width: 200
                                    height: 36
                                    from: 1
                                    to: 12
                                    value: settings.crossfadeDuration
                                    stepSize: 1
                                    enabled: settings.crossfadeEnabled
                                    onValueChanged: settings.crossfadeDuration = value
                                }

                                Text {
                                    text: settings.crossfadeDuration + "s"
                                    color: Style.textSecondary
                                    font.pixelSize: Style.fontSizeSm
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 40
                                }
                            }
                        }

                        // Gapless Playback
                        SettingRow {
                            label: "Gapless Playback"
                            description: "Seamless transitions between tracks"

                            Switch {
                                checked: settings.gaplessPlayback
                                onToggled: settings.gaplessPlayback = checked
                            }
                        }

                        // Normalize Volume
                        SettingRow {
                            label: "Normalize Volume"
                            description: "Equalize volume across tracks"

                            Switch {
                                checked: settings.normalizeVolume
                                onToggled: settings.normalizeVolume = checked
                            }
                        }

                        // Equalizer
                        SettingRow {
                            label: "Equalizer"
                            description: "Adjust frequency response"

                            Row {
                                spacing: Style.space3

                                Switch {
                                    checked: settings.equalizerEnabled
                                    onToggled: settings.equalizerEnabled = checked
                                }

                                ActionButton {
                                    icon: "⋯"
                                    size: 36
                                    iconSize: 16
                                    flat: true
                                    enabled: settings.equalizerEnabled
                                    onClicked: equalizerDialog.open()
                                }
                            }
                        }

                        // Auto-play Next
                        SettingRow {
                            label: "Autoplay Next"
                            description: "Automatically play similar music when queue ends"

                            Switch {
                                checked: settings.autoPlayNext
                                onToggled: settings.autoPlayNext = checked
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // AUDIO QUALITY SECTION
                // -------------------------------------------------------------
                SettingsSection {
                    title: "Audio Quality"
                    icon: "🔊"

                    Column {
                        spacing: Style.space3

                        // Streaming Quality
                        SettingRow {
                            label: "Streaming Quality"
                            description: "Higher quality uses more bandwidth"

                            ComboBox {
                                id: streamingQualityCombo
                                width: 200
                                height: 36
                                model: [
                                    { name: "Low (48 kbps)", value: "low" },
                                    { name: "Normal (128 kbps)", value: "normal" },
                                    { name: "High (256 kbps)", value: "high" },
                                    { name: "Very High (320 kbps)", value: "very_high" }
                                ]
                                currentIndex: 2 // high
                                delegate: ItemDelegate {
                                    width: parent.width
                                    height: 36
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: Style.textPrimary
                                        font.pixelSize: Style.fontSizeBase
                                    }
                                    highlighted: Rectangle { color: Style.primary }
                                }
                                background: Rectangle {
                                    color: Style.surface
                                    border.color: Style.border
                                    border.width: 1
                                    radius: Style.radiusSmall
                                }
                                onActivated: settings.streamingQuality = modelData.value
                            }
                        }

                        // Download Quality
                        SettingRow {
                            label: "Download Quality"
                            description: "Quality for offline downloads"

                            ComboBox {
                                id: downloadQualityCombo
                                width: 200
                                height: 36
                                model: [
                                    { name: "Low (48 kbps)", value: "low" },
                                    { name: "Normal (128 kbps)", value: "normal" },
                                    { name: "High (256 kbps)", value: "high" },
                                    { name: "Very High (320 kbps)", value: "very_high" }
                                ]
                                currentIndex: 2
                                delegate: ItemDelegate {
                                    width: parent.width
                                    height: 36
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: Style.textPrimary
                                        font.pixelSize: Style.fontSizeBase
                                    }
                                    highlighted: Rectangle { color: Style.primary }
                                }
                                background: Rectangle {
                                    color: Style.surface
                                    border.color: Style.border
                                    border.width: 1
                                    radius: Style.radiusSmall
                                }
                                onActivated: settings.downloadQuality = modelData.value
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // BEHAVIOR SECTION
                // -------------------------------------------------------------
                SettingsSection {
                    title: "Behavior"
                    icon: "⚙"

                    Column {
                        spacing: Style.space3

                        SettingRow {
                            label: "Minimize to Tray"
                            description: "Hide to system tray when minimized"

                            Switch {
                                checked: settings.minimizeToTray
                                onToggled: settings.minimizeToTray = checked
                            }
                        }

                        SettingRow {
                            label: "Close to Tray"
                            description: "Minimize to tray instead of closing"

                            Switch {
                                checked: settings.closeToTray
                                onToggled: settings.closeToTray = checked
                            }
                        }

                        SettingRow {
                            label: "Start Minimized"
                            description: "Launch application in tray"

                            Switch {
                                checked: settings.startMinimized
                                onToggled: settings.startMinimized = checked
                            }
                        }

                        SettingRow {
                            label: "Show Notifications"
                            description: "Display track change notifications"

                            Switch {
                                checked: settings.showNotifications
                                onToggled: settings.showNotifications = checked
                            }
                        }

                        SettingRow {
                            label: "Show Lyrics Automatically"
                            description: "Open lyrics view when available"

                            Switch {
                                checked: settings.showLyricsAutomatically
                                onToggled: settings.showLyricsAutomatically = checked
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // KEYBOARD SHORTCUTS SECTION
                // -------------------------------------------------------------
                SettingsSection {
                    title: "Keyboard Shortcuts"
                    icon: "⌨"

                    Column {
                        spacing: Style.space2

                        Text {
                            text: "Click a shortcut to change it"
                            color: Style.textMuted
                            font.pixelSize: Style.fontSizeSm
                            anchors.left: parent.left
                        }

                        ShortcutEditor {
                            shortcuts: settings.shortcuts
                            onShortcutChanged: (action, key) => {
                                settings.shortcuts[action] = key
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // ADVANCED SECTION
                // -------------------------------------------------------------
                SettingsSection {
                    title: "Advanced"
                    icon: "🔧"

                    Column {
                        spacing: Style.space3

                        // Cache Size
                        SettingRow {
                            label: "Cache Size"
                            description: "Maximum disk space for cached audio"

                            Row {
                                spacing: Style.space3

                                Slider {
                                    id: cacheSlider
                                    width: 200
                                    height: 36
                                    from: 100
                                    to: 5000
                                    value: settings.cacheSize
                                    stepSize: 100
                                    onValueChanged: settings.cacheSize = value
                                }

                                Text {
                                    text: settings.cacheSize + " MB"
                                    color: Style.textSecondary
                                    font.pixelSize: Style.fontSizeSm
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 70
                                }
                            }
                        }

                        // Clear Cache Button
                        SettingRow {
                            label: "Clear Cache"
                            description: "Free up disk space"

                            ActionButton {
                                text: "Clear Now"
                                onClicked: clearCacheDialog.open()
                            }
                        }

                        // Hardware Acceleration
                        SettingRow {
                            label: "Hardware Acceleration"
                            description: "Use GPU for rendering (requires restart)"

                            Switch {
                                checked: settings.hardwareAcceleration
                                onToggled: settings.hardwareAcceleration = checked
                            }
                        }

                        // PipeWire Latency
                        SettingRow {
                            label: "PipeWire Latency"
                            description: "Audio buffer latency mode"

                            ComboBox {
                                id: latencyCombo
                                width: 200
                                height: 36
                                model: [
                                    { name: "Low (Best for desktop)", value: "low" },
                                    { name: "Balanced", value: "balanced" },
                                    { name: "High (Best for Bluetooth)", value: "high" }
                                ]
                                currentIndex: 0
                                delegate: ItemDelegate {
                                    width: parent.width
                                    height: 36
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: Style.textPrimary
                                        font.pixelSize: Style.fontSizeBase
                                    }
                                    highlighted: Rectangle { color: Style.primary }
                                }
                                background: Rectangle {
                                    color: Style.surface
                                    border.color: Style.border
                                    border.width: 1
                                    radius: Style.radiusSmall
                                }
                                onActivated: settings.pipewireLatency = modelData.value
                            }
                        }

                        // Proxy Settings
                        SettingRow {
                            label: "Proxy"
                            description: "Configure network proxy"

                            Switch {
                                checked: settings.proxyEnabled
                                onToggled: settings.proxyEnabled = checked
                            }
                        }

                        // Proxy fields (shown when enabled)
                        Item {
                            id: proxyFields
                            height: settings.proxyEnabled ? 80 : 0
                            width: parent.width
                            visible: settings.proxyEnabled

                            Behavior on height {
                                NumberAnimation { duration: Style.durationNormal }
                            }

                            Column {
                                spacing: Style.space2
                                anchors.left: parent.left
                                anchors.leftMargin: 180 // align with setting controls

                                SettingRow {
                                    label: "Address"
                                    description: "Proxy server address"

                                    TextField {
                                        id: proxyAddress
                                        width: 250
                                        height: 36
                                        placeholderText: "127.0.0.1"
                                        text: settings.proxyAddress
                                        color: Style.textPrimary
                                        background: Rectangle {
                                            color: Style.surface
                                            border.color: Style.border
                                            border.width: 1
                                            radius: Style.radiusSmall
                                        }
                                        onTextChanged: settings.proxyAddress = text
                                    }
                                }

                                SettingRow {
                                    label: "Port"
                                    description: "Proxy server port"

                                    TextField {
                                        id: proxyPort
                                        width: 100
                                        height: 36
                                        placeholderText: "8080"
                                        text: settings.proxyPort
                                        color: Style.textPrimary
                                        background: Rectangle {
                                            color: Style.surface
                                            border.color: Style.border
                                            border.width: 1
                                            radius: Style.radiusSmall
                                        }
                                        onTextChanged: settings.proxyPort = text
                                    }
                                }
                            }
                        }

                        // Reset to Defaults
                        SettingRow {
                            label: "Reset to Defaults"
                            description: "Restore all settings to default values"

                            ActionButton {
                                text: "Reset"
                                icon: "↺"
                                size: 36
                                iconSize: 14
                                onClicked: resetDialog.open()
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // ABOUT SECTION
                // -------------------------------------------------------------
                SettingsSection {
                    title: "About"
                    icon: "ℹ"

                    Column {
                        spacing: Style.space3

                        Row {
                            spacing: Style.space4
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                width: 80
                                height: 80
                                radius: Style.radiusLarge
                                color: Style.primary

                                Text {
                                    anchors.centerIn: parent
                                    text: "M"
                                    color: Style.textOnPrimary
                                    font.bold: true
                                    font.pixelSize: 36
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Style.space1

                                Text {
                                    text: "Melyar"
                                    color: Style.textPrimary
                                    font.pixelSize: Style.fontSize2xl
                                    font.bold: true
                                }

                                Text {
                                    text: "Version 1.0.0"
                                    color: Style.textSecondary
                                    font.pixelSize: Style.fontSizeBase
                                }

                                Text {
                                    text: "Ultra-Lightweight YouTube Music Client"
                                    color: Style.textMuted
                                    font.pixelSize: Style.fontSizeSm
                                }

                                Text {
                                    text: "Built with Qt/QML + Rust"
                                    color: Style.textMuted
                                    font.pixelSize: Style.fontSizeSm
                                }
                            }
                        }

                        Row {
                            spacing: Style.space4
                            anchors.horizontalCenter: parent.horizontalCenter

                            ActionButton {
                                text: "GitHub"
                                icon: "⭐"
                                onClicked: console.log("Open GitHub")
                            }

                            ActionButton {
                                text: "Report Issue"
                                icon: "🐛"
                                onClicked: console.log("Open Issues")
                            }

                            ActionButton {
                                text: "License"
                                icon: "📄"
                                onClicked: console.log("Show License")
                            }
                        }
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------
    // DIALOGS
    // -------------------------------------------------------------

    // Equalizer Dialog
    Dialog {
        id: equalizerDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: "Equalizer"

        Column {
            spacing: Style.space4
            width: 400

            Text {
                text: "Adjust frequency bands"
                color: Style.textSecondary
                font.pixelSize: Style.fontSizeBase
                anchors.horizontalCenter: parent.horizontalCenter
            }

            GridLayout {
                columns: 5
                spacing: Style.space3
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: [
                        { freq: "60 Hz", gain: 0 },
                        { freq: "170 Hz", gain: 0 },
                        { freq: "310 Hz", gain: 0 },
                        { freq: "600 Hz", gain: 0 },
                        { freq: "1 kHz", gain: 0 },
                        { freq: "3 kHz", gain: 0 },
                        { freq: "6 kHz", gain: 0 },
                        { freq: "12 kHz", gain: 0 },
                        { freq: "14 kHz", gain: 0 },
                        { freq: "16 kHz", gain: 0 }
                    ]

                    delegate: EqualizerBand {
                        freq: modelData.freq
                        gain: modelData.gain
                    }
                }
            }

            Row {
                spacing: Style.space3
                anchors.horizontalCenter: parent.horizontalCenter

                ActionButton {
                    text: "Flat"
                    flat: true
                    onClicked: console.log("Reset EQ to flat")
                }

                ActionButton {
                    text: "Bass Boost"
                    flat: true
                    onClicked: console.log("Apply bass boost preset")
                }

                ActionButton {
                    text: "Vocal Boost"
                    flat: true
                    onClicked: console.log("Apply vocal boost preset")
                }
            }
        }
    }

    // Clear Cache Dialog
    Dialog {
        id: clearCacheDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: "Clear Cache"

        Text {
            text: "This will delete all cached audio files and free up disk space. You may need to re-download tracks for offline playback."
            color: Style.textSecondary
            font.pixelSize: Style.fontSizeBase
            wrapMode: Text.WordWrap
            width: 350
        }

        onAccepted: console.log("Clear cache confirmed")
    }

    // Reset Settings Dialog
    Dialog {
        id: resetDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: "Reset Settings"

        Text {
            text: "Are you sure you want to reset all settings to their default values? This cannot be undone."
            color: Style.textSecondary
            font.pixelSize: Style.fontSizeBase
            wrapMode: Text.WordWrap
            width: 350
        }

        onAccepted: console.log("Reset settings confirmed")
    }
}
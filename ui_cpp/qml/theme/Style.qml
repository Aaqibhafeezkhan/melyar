pragma Singleton
import QtQuick

QtObject {
    // =========================================================================
    // APPLE MUSIC "LIQUID GLASS" THEME
    // =========================================================================
    // Dark theme with glassmorphism - transparent layers, depth, blur

    // Background
    readonly property color background: "#0B0C10"

    // Glass surfaces - semi-transparent frosted glass
    readonly property color surface: Qt.rgba(1.0, 1.0, 1.0, 0.08)
    readonly property color surfaceHover: Qt.rgba(1.0, 1.0, 1.0, 0.14)
    readonly property color surfacePressed: Qt.rgba(1.0, 1.0, 1.0, 0.22)
    readonly property color surfaceStrong: Qt.rgba(1.0, 1.0, 1.0, 0.16)

    // Player background
    readonly property color playerBackground: Qt.rgba(1.0, 1.0, 1.0, 0.10)

    // Card glass
    readonly property color cardBackground: Qt.rgba(1.0, 1.0, 1.0, 0.06)
    readonly property color cardHover: Qt.rgba(1.0, 1.0, 1.0, 0.12)

    // Accents - Apple Music cyan/blue
    readonly property color primary: "#00F2FE"
    readonly property color primaryHover: "#33F5FE"
    readonly property color primaryPressed: "#00B8D4"
    readonly property color accent: "#00F2FE"

    // Typography colors
    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#B0B0B0"
    readonly property color textMuted: "#808080"
    readonly property color textDisabled: "#4d4d4d"
    readonly property color textOnPrimary: "#000000"

    // Dividers & Borders - subtle specular highlight
    readonly property color divider: Qt.rgba(1.0, 1.0, 1.0, 0.12)
    readonly property color border: Qt.rgba(1.0, 1.0, 1.0, 0.20)
    readonly property color specularBorder: Qt.rgba(1.0, 1.0, 1.0, 0.30)

    // Status colors
    readonly property color error: "#FF453A"
    readonly property color warning: "#FF9F0A"
    readonly property color success: "#32D74B"
    readonly property color info: "#00F2FE"

    // =========================================================================
    // SPACING SYSTEM (8px base)
    // =========================================================================
    readonly property int space0: 0
    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 20
    readonly property int space6: 24
    readonly property int space7: 28
    readonly property int space8: 32
    readonly property int space10: 40
    readonly property int space12: 48
    readonly property int space16: 64

    // =========================================================================
    // BORDER RADIUS
    // =========================================================================
    readonly property int radiusNone: 0
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 16
    readonly property int radiusXLarge: 20
    readonly property int radiusRound: 9999

    // =========================================================================
    // TYPOGRAPHY
    // =========================================================================
    readonly property string fontFamily: "SF Pro Text, Inter, Ubuntu, Roboto, Noto Sans, sans-serif"
    readonly property string fontFamilyMono: "SF Mono, Ubuntu Mono, monospace"

    readonly property int fontSizeXs: 10
    readonly property int fontSizeSm: 12
    readonly property int fontSizeBase: 14
    readonly property int fontSizeLg: 16
    readonly property int fontSizeXl: 20
    readonly property int fontSize2xl: 24
    readonly property int fontSize3xl: 32
    readonly property int fontSize4xl: 48

    readonly property int fontWeightLight: 300
    readonly property int fontWeightNormal: 400
    readonly property int fontWeightMedium: 500
    readonly property int fontWeightSemiBold: 600
    readonly property int fontWeightBold: 700

    readonly property real lineHeightTight: 1.2
    readonly property real lineHeightNormal: 1.5
    readonly property real lineHeightRelaxed: 1.75

    // =========================================================================
    // COMPONENT DIMENSIONS
    // =========================================================================
    readonly property int playerBarHeight: 88
    readonly property int sidebarWidth: 240
    readonly property int sidebarCollapsedWidth: 72
    readonly property int topBarHeight: 50
    readonly property int trackRowHeight: 64
    readonly property int cardSize: 160

    // =========================================================================
    // Z-INDEX LAYERS
    // =========================================================================
    readonly property int zBase: 0
    readonly property int zDropdown: 100
    readonly property int zModal: 200
    readonly property int zTooltip: 300
    readonly property int zToast: 400

    // =========================================================================
    // ANIMATION DURATIONS
    // =========================================================================
    readonly property int durationInstant: 0
    readonly property int durationFast: 100
    readonly property int durationNormal: 200
    readonly property int durationSlow: 300
    readonly property int durationSlower: 400
    readonly property int durationFluid: 1600

    readonly property string easingStandard: "OutCubic"
    readonly property string easingEmphasized: "OutQuart"
    readonly property string easingDecelerated: "OutQuint"
    readonly property string easingFluid: "InOutSine"

    // =========================================================================
    // SHADOWS & GLOW
    // =========================================================================
    readonly property color shadowColor: "#000000"
    readonly property real shadowOpacity: 0.5
    readonly property color glowColor: "#00F2FE"
    readonly property real glowOpacity: 0.3

    // =========================================================================
    // UTILITY FUNCTIONS
    // =========================================================================
    function formatTime(ms) {
        if (isNaN(ms) || ms < 0) return "0:00"
        var totalSec = Math.floor(ms / 1000)
        var mins = Math.floor(totalSec / 60)
        var secs = totalSec % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function formatTimeSeconds(seconds) {
        if (isNaN(seconds) || seconds < 0) return "0:00"
        var totalSec = Math.floor(seconds)
        var mins = Math.floor(totalSec / 60)
        var secs = totalSec % 60
        return mins + ":" + (secs < 10 ? "0" : "") + secs
    }

    function getContrastColor(bgColor) {
        return "#FFFFFF"
    }

    function responsiveSize(base, min, max, factor) {
        return Math.max(min, Math.min(max, base * factor))
    }
}

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtWebEngine
import QtWebChannel

Window {
    id: window
    width: 1360
    height: 860
    minimumWidth: 1000
    minimumHeight: 640
    visible: true
    title: "Melyar"
    color: "#0d0d0f"

    // The single WebChannel instance. The page url is set from C++ AFTER
    // the bridge object is registered here (race-free handshake).
    WebChannel {
        id: appChannel
        objectName: "appChannel"
    }

    WebEngineView {
        id: webView
        objectName: "webView"
        anchors.fill: parent
        focus: true
        webChannel: appChannel
        backgroundColor: "#0d0d0f"

        settings.localContentCanAccessRemoteUrls: true
        settings.localContentCanAccessFileUrls: true
        settings.allowRunningInsecureContent: true
        settings.webGLEnabled: true
        settings.javascriptEnabled: true
        settings.playbackRequiresUserGesture: false
        settings.showScrollBars: false

        onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceID) {
            console.log("[Web " + level + "] " + message + " (" + sourceID + ":" + lineNumber + ")")
        }

        onLoadingChanged: function(loadRequest) {
            if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                console.error("Failed to load web UI: " + loadRequest.errorString)
            }
        }
    }

    // Global Hardware / Desktop Media Key Shortcuts
    Shortcut {
        sequence: StandardKey.PlayPause
        onActivated: bridge.togglePlay()
    }
    Shortcut {
        sequence: "Ctrl+Space"
        onActivated: bridge.togglePlay()
    }
    Shortcut {
        sequence: "Ctrl+Right"
        onActivated: bridge.nextTrack()
    }
    Shortcut {
        sequence: "Ctrl+Left"
        onActivated: bridge.previousTrack()
    }
    Shortcut {
        sequence: "Ctrl+Up"
        onActivated: bridge.setVolume(Math.min(100, bridge.volume + 5))
    }
    Shortcut {
        sequence: "Ctrl+Down"
        onActivated: bridge.setVolume(Math.max(0, bridge.volume - 5))
    }
}

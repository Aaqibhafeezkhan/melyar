import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property alias coverSource: coverImage.source
    property string albumTitle: "Unknown Album"
    width: 150
    height: 200

    Image {
        id: coverImage
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 140
        height: 140
        fillMode: Image.PreserveAspectCrop
        source: "" // will be set by caller
        smooth: true
        cache: true
        radius: 8
    }

    Text {
        id: titleText
        anchors.top: coverImage.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.albumTitle
        font.pointSize: 10
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.NoWrap
        width: parent.width
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // Emit signal to parent via Qt event system if needed
            root.clicked()
        }
    }

    // Signal for clicks
    signal clicked()
}

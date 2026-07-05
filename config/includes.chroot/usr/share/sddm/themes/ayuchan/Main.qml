import QtQuick 2.11
import SddmComponents 2.0

Rectangle {
    color: "#121a2e"

    Image {
        anchors.fill: parent
        source: "/usr/share/wallpapers/Ayuchan/contents/images/ayuchan.svg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.30
    }

    Login {
        id: login
        anchors.fill: parent
    }
}

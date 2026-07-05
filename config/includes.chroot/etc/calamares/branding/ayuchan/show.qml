import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation
    function nextSlide() { console.log("Ayuchan Linux 1.0"); }
    function previousSlide() { console.log("Ayuchan Linux 1.0"); }
    Slide {
        id: slide1
        Text {
            anchors.centerIn: parent
            text: "欢迎使用 Ayuchan Linux\nWelcome to Ayuchan Linux"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
        }
    }
}

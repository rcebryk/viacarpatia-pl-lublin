import QtQuick

// Kafelek napoju na ekranie głównym
Rectangle {
    id: tile

    property string name
    property string volume
    property color accent: "#8d5b3c"
    signal clicked()

    radius: 18
    color: tap.pressed ? Qt.darker(accent, 1.3) : accent
    scale: tap.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }

    // "Filiżanka": kółko z pierwszą literą nazwy
    Rectangle {
        id: cup
        width: 64
        height: 64
        radius: 32
        anchors { top: parent.top; topMargin: 16; horizontalCenter: parent.horizontalCenter }
        color: "#f3e2cf"

        Text {
            anchors.centerIn: parent
            text: tile.name.charAt(0)
            color: tile.accent
            font.pixelSize: 34
            font.bold: true
        }
    }

    Text {
        anchors { top: cup.bottom; topMargin: 8; horizontalCenter: parent.horizontalCenter }
        text: tile.name
        color: "white"
        font.pixelSize: 24
        font.bold: true
    }

    Text {
        anchors { bottom: parent.bottom; bottomMargin: 8; horizontalCenter: parent.horizontalCenter }
        text: tile.volume
        color: "#fbeee0"
        font.pixelSize: 16
    }

    TapHandler {
        id: tap
        onTapped: tile.clicked()
    }
}

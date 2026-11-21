pragma ComponentBehavior: Bound

import QtQuick
import EspressoHmi

Window {
    id: root
    width: 800
    height: 480
    visible: true
    title: "Espresso HMI"
    color: "#1c1512"

    // Menu napojów pochodzi z C++ (src/core/drinkcatalog.cpp) - tam jest
    // logika testowana jednostkowo w CI. Demo na żywo: dopisz tam napój.
    readonly property var drinks: Menu.drinks

    // --- pasek górny -------------------------------------------------
    Rectangle {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 60
        color: "#2a201b"

        Text {
            id: logo
            anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
            text: "Espresso HMI"
            color: "#f3e2cf"
            font.pixelSize: 26
            font.bold: true

            // Ukryte wejście do menu serwisowego: przytrzymaj logo 2 s
            TapHandler {
                longPressThreshold: 2
                onLongPressed: service.open()
            }
        }

        Text {
            id: clock
            anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
            color: "#f3e2cf"
            font.pixelSize: 24
            text: Qt.formatTime(new Date(), "hh:mm")

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatTime(new Date(), "hh:mm")
            }
        }
    }

    // --- siatka napojów ----------------------------------------------
    Text {
        id: prompt
        anchors { top: header.bottom; topMargin: 14; horizontalCenter: parent.horizontalCenter }
        text: qsTr("Wybierz napój")
        color: "#cbb39b"
        font.pixelSize: 22
    }

    // Przewijana siatka: przy więcej niż 6 napojach kolejne rzędy przesuwa się palcem
    GridView {
        id: grid
        objectName: "drinkGrid"
        anchors {
            top: prompt.bottom; topMargin: 10
            bottom: parent.bottom; bottomMargin: 28
            horizontalCenter: parent.horizontalCenter
        }
        width: cellWidth * 3
        cellWidth: 252
        cellHeight: 166
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        // Gdy na wierzchu jest ekran parzenia albo menu serwisowe, kafelki nie mogą
        // przejąć dotyku (błąd: "Anuluj" uruchamiał napój z kafelka pod przyciskiem)
        enabled: !brew.visible && !service.visible
        model: root.drinks

        delegate: Item {
            id: cell
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight

            DrinkTile {
                objectName: "tile_" + cell.modelData.name
                anchors.centerIn: parent
                width: 236
                height: 150
                name: cell.modelData.name
                volume: cell.modelData.volume
                accent: cell.modelData.color
                onClicked: brew.start(cell.modelData)
            }
        }

        // Wskaźnik przewijania - widoczny tylko, gdy wszystko się nie mieści
        Rectangle {
            visible: grid.contentHeight > grid.height
            anchors.right: parent.right
            anchors.rightMargin: -10
            y: grid.visibleArea.yPosition * grid.height
            width: 5
            height: grid.visibleArea.heightRatio * grid.height
            radius: 2
            color: "#cbb39b"
            opacity: grid.moving ? 0.9 : 0.5
        }
    }

    Text {
        anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
        text: "v" + MachineInfo.appVersion + "  ·  Qt " + MachineInfo.qtVersion
        color: "#6e5d50"
        font.pixelSize: 14
    }

    // --- nakładki ----------------------------------------------------
    BrewScreen {
        id: brew
        anchors.fill: parent
    }

    ServicePanel {
        id: service
        anchors.fill: parent
    }
}

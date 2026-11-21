import QtQuick
import EspressoHmi

// Ekran parzenia: kroki procesu + pasek postępu
Rectangle {
    id: screen
    objectName: "brewScreen"

    property var drink: ({ name: "", seconds: 1, milk: false, color: "#8d5b3c" })
    property real progress: 0
    property bool done: false

    // Kroki i bieżący krok liczy C++ (DrinkCatalog) - logika objęta testami
    readonly property var steps: Menu.stepsFor(drink.milk)
    readonly property int stepIndex: Menu.stepIndexAt(steps.length, progress)

    function start(d) {
        drink = d
        done = false
        progress = 0
        visible = true
        anim.duration = d.seconds * 1000
        anim.restart()
    }

    visible: false
    color: "#1c1512"

    // Blokuje dotyk dla elementów pod spodem
    MouseArea { anchors.fill: parent }

    NumberAnimation {
        id: anim
        target: screen
        property: "progress"
        from: 0
        to: 1
        onFinished: {
            screen.done = true
            MachineInfo.logDrink(screen.drink.name)
            closeTimer.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: 2500
        onTriggered: screen.visible = false
    }

    Column {
        anchors.centerIn: parent
        spacing: 24
        width: parent.width * 0.75

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: screen.drink.name
            color: "#f3e2cf"
            font.pixelSize: 44
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: screen.done ? qsTr("Gotowe! Smacznej kawy") : screen.steps[screen.stepIndex] + "…"
            color: screen.done ? "#9fd39a" : "#cbb39b"
            font.pixelSize: 28
        }

        Rectangle {
            width: parent.width
            height: 28
            radius: 14
            color: "#3a2d26"

            Rectangle {
                width: parent.width * screen.progress
                height: parent.height
                radius: parent.radius
                color: screen.drink.color
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(screen.progress * 100) + " %"
            color: "#cbb39b"
            font.pixelSize: 22
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200
            height: 56
            radius: 28
            objectName: "cancelButton"
            visible: !screen.done
            color: cancelTap.pressed ? "#5a3a32" : "#7a4a3f"

            Text {
                anchors.centerIn: parent
                text: qsTr("Anuluj")
                color: "white"
                font.pixelSize: 22
            }

            TapHandler {
                id: cancelTap
                onTapped: {
                    anim.stop()
                    screen.visible = false
                }
            }
        }
    }
}

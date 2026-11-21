import QtQuick
import EspressoHmi

// Menu serwisowe (przytrzymaj logo 2 s): wersje + symulacja awarii
Rectangle {
    id: panel

    function open() {
        uptimeText.text = MachineInfo.uptime()
        visible = true
    }

    visible: false
    color: "#e6101010"

    MouseArea { anchors.fill: parent }

    Timer {
        interval: 1000
        running: panel.visible
        repeat: true
        onTriggered: uptimeText.text = MachineInfo.uptime()
    }

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            text: qsTr("Menu serwisowe")
            color: "#f3e2cf"
            font.pixelSize: 32
            font.bold: true
        }

        Grid {
            columns: 2
            columnSpacing: 24
            rowSpacing: 6

            Text { text: qsTr("Aplikacja:");  color: "#cbb39b"; font.pixelSize: 20 }
            Text { text: MachineInfo.appVersion; color: "white"; font.pixelSize: 20 }
            Text { text: qsTr("Zbudowana:");  color: "#cbb39b"; font.pixelSize: 20 }
            Text { text: MachineInfo.buildDate; color: "white"; font.pixelSize: 20 }
            Text { text: "Qt:";         color: "#cbb39b"; font.pixelSize: 20 }
            Text { text: MachineInfo.qtVersion; color: "white"; font.pixelSize: 20 }
            Text { text: qsTr("System:");     color: "#cbb39b"; font.pixelSize: 20 }
            Text { text: MachineInfo.osName; color: "white"; font.pixelSize: 20 }
            Text { text: qsTr("Maszyna:");    color: "#cbb39b"; font.pixelSize: 20 }
            Text { text: MachineInfo.hostName; color: "white"; font.pixelSize: 20 }
            Text { text: qsTr("Czas pracy:"); color: "#cbb39b"; font.pixelSize: 20 }
            Text { id: uptimeText; color: "white"; font.pixelSize: 20 }
        }

        Row {
            spacing: 20
            topPadding: 16

            Rectangle {
                width: 240; height: 60; radius: 30
                color: crashTap.pressed ? "#7a1f1f" : "#a32b2b"
                Text { anchors.centerIn: parent; text: qsTr("Symuluj awarię"); color: "white"; font.pixelSize: 22 }
                TapHandler { id: crashTap; onTapped: MachineInfo.simulateCrash() }
            }

            Rectangle {
                width: 180; height: 60; radius: 30
                color: closeTap.pressed ? "#3a2d26" : "#5a463b"
                Text { anchors.centerIn: parent; text: qsTr("Zamknij"); color: "white"; font.pixelSize: 22 }
                TapHandler { id: closeTap; onTapped: panel.visible = false }
            }
        }
    }
}

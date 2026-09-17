/*
TODO:
2. make sure it starts on boot if wanted
3. make the osd longer (olmazmış)
5. make the icons uniform
*/

import QtQuick
import org.kde.notification
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    property int remainingSeconds: 60 * 45
    property bool iconState: false

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"

        onNewData: function(source, data) {
            disconnectSource(source)
        }

        function exec(command) {
            connectSource(command)
        }
    }

    function showOsd(text, icon) {
        icon = icon || ""

        executable.exec(
            "qdbus6 org.kde.plasmashell " +
            "/org/kde/osdService " +
            "org.kde.osdService.showText " +
            "'" + icon.replace(/'/g, "'\\''") + "' " +
            "'" + text.replace(/'/g, "'\\''") + "'"
        )
    }


    preferredRepresentation: {
        const edge = Plasmoid.location;
        if (edge === PlasmaCore.Types.TopEdge || edge === PlasmaCore.Types.BottomEdge
            || edge === PlasmaCore.Types.LeftEdge || edge === PlasmaCore.Types.RightEdge)
            return compactRepresentation;
        return fullRepresentation;
    }

    Plasmoid.title: i18n("LookAway")
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: Plasmoid.title




    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: 320
        Layout.minimumHeight: 156
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Kirigami.Icon {
                source: "system-shutdown-symbolic"
            }
            PlasmaComponents.Label {
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                topPadding: Kirigami.Units.smallSpacing
                bottomPadding: Kirigami.Units.largeSpacing
                text: i18n("Enabled")
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: Kirigami.Theme.defaultFont.pointSize * 1.75
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
            PlasmaComponents.Label {
                text: String(parseInt(Math.floor((root.remainingSeconds/60)/60)).toString().padStart(2, "0") + ":" + parseInt(root.remainingSeconds/60%60).toString().padStart(2, "0") + ":" + (parseInt(root.remainingSeconds%60).toString().padStart(2, "0")))
            }

            function setmswitch(value) {
                mswitch.enabled = value
            }

            PlasmaComponents.Switch {
                id: "mswitch"
                checked: false
                onCheckedChanged: {
                    if (checked == true){
                        root.iconState= true
                        myTimer.running = true
                        console.log("timer started for " + remainingSeconds + " secs")
                        spinBox.enabled = false
                        pauseButton.enabled = true
                    } else {
                        root.iconState= false
                        spinBox.enabled = true
                        myTimer.stop()
                        root.remainingSeconds = 60 * spinBox.value
                        pauseButton.text = "Pause"
                        pauseButton.icon.name= "kt-pause-symbolic"
                        pauseButton.enabled = false
                        console.log("stopped")
                    }
                }
                Component.onCompleted:{
                    if (plasmoid.configuration.startOnBoot){
                        checked= true
                        myTimer.running = true
                        console.log("timer started for " + remainingSeconds + " secs")
                        spinBox.enabled = false
                        pauseButton.enabled = true
                        console.log("boot!")
                    }
                }
                Timer {
                    id: myTimer
                    interval: 1000
                    repeat: true
                    running: false

                    onTriggered: {
                        if (root.remainingSeconds > 0) {
                            console.log("remaining: " + root.remainingSeconds)
                            root.remainingSeconds--
                            console.log("repeat: " + plasmoid.configuration.repeat)

                        } else {
                            if (plasmoid.configuration.repeat){
                                root.remainingSeconds = 60 * spinBox.value
                                showOsd("Look away from your screen", "chronometer-symbolic")
                                myTimer.running = true
                            } else{
                                mswitch.checked = false
                                showOsd("Look away from your screen", "chronometer-symbolic")

                                //timer.stop()
                            }
                        }
                    }
                }

            }
            PlasmaComponents.Button{
                id: "pauseButton"
                text: "Pause"
                icon.name: "kt-pause-symbolic"
                enabled: false
                onClicked: {
                    if (text== "Pause"){
                        text= "Resume"
                        icon.name= "kt-start-symbolic"
                        root.iconState= false
                        myTimer.stop()
                    } else {
                        text = "Pause"
                        root.iconState= true
                        icon.name="kt-pause-symbolic"
                        myTimer.start()
                    }
                }
            }
        }

        RowLayout{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Kirigami.Icon {
                source: "clock-symbolic"
            }
            PlasmaComponents.Label {
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                text: i18n("Interval")
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: Kirigami.Theme.defaultFont.pointSize * 1.75
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            PlasmaComponents.SpinBox {
                id: spinBox
                Layout.alignment: Qt.AlignRight
                from: 1
                to: 1000
                editable: true
                value: plasmoid.configuration.interval
                stepSize: 15
                onValueChanged: root.remainingSeconds = 60 * value

                contentItem: TextInput {
                    text: spinBox.textFromValue(spinBox.value, spinBox.locale)
                    validator: spinBox.validator
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    color: Kirigami.Theme.textColor
                    selectionColor: Kirigami.Theme.highlightColor
                    selectedTextColor: Kirigami.Theme.highlightedTextColor
                    cursorVisible: false

                    onTextEdited: {
                        const n = parseInt(text, 10)

                        if (!isNaN(n) && n >= spinBox.from && n <= spinBox.to) {
                            spinBox.value = n
                        }
                    }
                }

            }

            PlasmaComponents.Label {
                text: "mins"
                font.pixelSize: Kirigami.Theme.defaultFont.pointSize * 2 - 6
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Kirigami.Icon {
                source: "backup-symbolic"
            }
            PlasmaComponents.Label {
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                text: i18n("Repeat")
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: Kirigami.Theme.defaultFont.pointSize * 1.75
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            PlasmaComponents.Switch {
                id: "repeatSwitch"
                checked: plasmoid.configuration.repeat
                onCheckedChanged:{
                    plasmoid.configuration.repeat = checked
                }
            }
        }

        RowLayout{
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Kirigami.Icon {
                source: "kstars_supernovae-symbolic"
            }
            PlasmaComponents.Label {
                leftPadding: Kirigami.Units.largeSpacing
                rightPadding: Kirigami.Units.largeSpacing
                text: i18n("Start on Boot")
                horizontalAlignment: Text.AlignLeft
                font.pixelSize: Kirigami.Theme.defaultFont.pointSize * 1.75
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            PlasmaComponents.Switch {
                id: "startOnBootSwitch"
                checked: plasmoid.configuration.startOnBoot
                onCheckedChanged:{
                    console.log("checked:" + checked)
                    plasmoid.configuration.startOnBoot = checked
                }
                onToggled:{
                    console.log("toggle:" + checked)
                    plasmoid.configuration.startOnBoot = checked

                }
            }
        }

        Item {
            Notification {
                id: timerNotification

                componentName: "LookAway"
                eventId: "timerFinished"
                title: i18n("Timer finished")
                text: i18n("Your countdown has finished.")
                iconName: "alarm"

                onClosed: {
                    console.log("Notification closed")
                }
            }

        }
        Item {
            Layout.fillHeight: true
        }

    }

    compactRepresentation: Item {
        MouseArea {
            anchors.fill: parent
            z: 0
            cursorShape: Qt.PointingHandCursor
            onClicked: expanded = !expanded
        }

        Kirigami.Icon {
            source: iconState ? "redeyes-symbolic" : "quickview-symbolic"
            anchors.fill: parent
        }
    }
}

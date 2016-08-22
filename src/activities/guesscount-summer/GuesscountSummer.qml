/* GCompris - guesscount-summer.qml
 *
 * Copyright (C) 2016 RAHUL YADAV <rahulyadav170923@gmail.com>
 *
 * Authors:
 *   <Pascal Georges> (GTK+ version)
 *   RAHUL YADAV <rahulyadav170923@gmail.com> (Qt Quick port)
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation; either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.1

import "../../core"
import "guesscount-summer.js" as Activity

ActivityBase {
    id: activity

    onStart: focus = true
    onStop: {}

    pageComponent: Rectangle {
        id: background
        anchors.fill: parent
        color: "#ABCDEF"
        signal start
        signal stop
        property string mode: "builtin"

        Component.onCompleted: {
            dialogActivityConfig.getInitialConfiguration()
            activity.start.connect(start)
            activity.stop.connect(stop)
        }

        // Add here the QML items you need to access in javascript
        QtObject {
            id: items
            property Item main: activity.main
            property alias background: background
            property alias bar: bar
            property alias bonus: bonus
            property int sublevel: 0
            property alias operand_row : operand_row
            property  var data
            property int result: data[sublevel-1][1]
            property alias timer: timer
            property alias dialog: dialog
            property GCAudio audioEffects: activity.audioEffects
            property bool solved
            property bool levelchanged : false
        }

        onStart: { Activity.start(items) }
        onStop: { Activity.stop() }

        Loader {
            id: admin
            active: false
            sourceComponent: Column {
                spacing: 10
                width: parent.width
                height: parent.height

                Repeater{
                    id:levels
                    model: 6
                    Admin{
                        id:level
                        level: modelData+1
                        width: parent.width
                        height: parent.height
                    }
                }
            }

        }

        Rectangle {
            id: row1
            width: parent.width
            height: parent.height/10
            anchors{
                top: parent.top
                topMargin: (parent.height/80)*3
            }
            color: "transparent"
            Rectangle {
                id: question_no
                width: parent.width*0.328;
                height: parent.height;
                radius: 20.0;
                color: "steelblue"
                anchors{
                    left: parent.left
                    leftMargin: parent.width*0.028
                }
                GCText{
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    fontSize: mediumSize
                    text: qsTr("%1/%2").arg(items.sublevel).arg(items.data.length)
                }
            }
            Rectangle{
                width: parent.width*0.35;
                height: parent.height;
                radius: 20
                color: "orange"
                anchors{
                    right: parent.right
                    rightMargin: parent.width*0.028
                }
                GCText{
                    id: guess
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    fontSize: mediumSize
                    text: qsTr("Guesscount : %1").arg(items.result)
                }
            }
        }

        Column {
            spacing: 10
            anchors.top:row1.bottom
            anchors.topMargin: 10
            width: parent.width
            height: parent.height
            Operator_row {
                width: parent.width
                height: parent.height/10
            }
            Operand_row {
                id: operand_row
                width: parent.width
                height: parent.height/10
            }
            Repeater {
                id: repeat
                model: items.operand_row.repeater.model.length-1
                delegate: Operation_row{
                    id: operation_row
                    width: background.width
                    height: background.height/10
                    property alias operation_row: operation_row
                    no_of_rows: items.operand_row.repeater.model.length-1
                    row_no: modelData
                    guesscount: items.result
                    prev_result: modelData ? repeat.itemAt(modelData-1).row_result : -1
                    prev_complete: modelData ? repeat.itemAt(modelData-1).complete : false
                    reparent: items.solved || items.levelchanged
                }
            }
        }

        DialogHelp {
            id: dialogHelp
            onClose: home()
        }

        DialogActivityConfig {
            id: dialogActivityConfig
            currentActivity: activity
            content: Component {
                Item {
                    property alias modeBox: modeBox

                    property var availableModes: [
                        { "text": qsTr("Admin"), "value": "admin" },
                        { "text": qsTr("BuiltIn"), "value": "builtin" }
                    ]

                    Flow {
                        id: flow
                        spacing: 5
                        width: dialogActivityConfig.width
                        GCComboBox {
                            id: modeBox
                            model: availableModes
                            background: dialogActivityConfig
                            label: qsTr("Select your mode")
                        }
                        Column {
                            visible: modeBox.currentIndex==0
                            spacing: 10
                            width: parent.width
                            Repeater{
                                id:levels
                                model: 10
                                Admin{
                                    id: level
                                    level: modelData+1
                                    width: background.width
                                    height: background.height/10
                                }
                            }
                        }
                    }
                }
            }
            onClose: home()
            onLoadData: {
                if(dataToSave && dataToSave["mode"]) {
                    mode = dataToSave["mode"];
                    Activity.mode = dataToSave["mode"];
                }
            }

            onSaveData: {
                mode = dialogActivityConfig.configItem.availableModes[dialogActivityConfig.configItem.modeBox.currentIndex].value;
                dataToSave = {"mode": mode}
                Activity.mode = mode;
            }

            function setDefaultValues() {
                for(var i = 0 ; i < dialogActivityConfig.configItem.availableModes.length ; i ++) {
                    if(dialogActivityConfig.configItem.availableModes[i].value === mode) {
                        dialogActivityConfig.configItem.modeBox.currentIndex = i;
                        break;
                    }
                }
            }
        }

        Bar {
            id: bar
            content: BarEnumContent { value: help | home | level | config}
            onConfigClicked: {
                dialogActivityConfig.active = true
                // Set default values
                dialogActivityConfig.setDefaultValues();
                displayDialog(dialogActivityConfig)
            }
            onHelpClicked: {
                displayDialog(dialogHelp)
            }
            onPreviousLevelClicked: {
                items.levelchanged=true
                Activity.previousLevel()
            }
            onNextLevelClicked: {
                items.levelchanged=true
                Activity.nextLevel()
            }
            onHomeClicked: activity.home()

        }

        Bonus {
            id: bonus
            Component.onCompleted: win.connect(Activity.nextLevel)
        }
        Timer {
            id: timer
            interval: 1500
            repeat: false
            onTriggered: {
                items.solved=true
                if(items.sublevel<items.data.length)
                {
                    Activity.next_sublevel()
                }
            }
        }
        Rectangle {
            id: dialog
            width: parent.width*0.49
            height: parent.height/8
            visible: false
            color: "steelblue"
            radius: 30
            anchors.centerIn: parent
            GCText{
                anchors.centerIn: parent
                fontSize: mediumSize
                text: qsTr("result is not an integer")
            }
            onVisibleChanged:SequentialAnimation{
                PropertyAnimation { target: dialog; property: "opacity";from : 1 ; to: 0 ;duration: 3000 }
                PropertyAnimation { target: dialog; property: "visible";to: false }
            }
        }
    }

}

﻿

/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.15

import QGroundControl 1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controls 1.0
import QGroundControl.Palette 1.0
import QGroundControl.Vehicle 1.0
import QGroundControl.Controllers 1.0

import SiYi.Object 1.0
import QtGraphicalEffects 1.12
import "qrc:/qml/QGroundControl/Controls"
import "qrc:/qml/QGroundControl/FlightDisplay"

Rectangle {
    id: root
    clip: true
    anchors.fill: parent
    color: "#00000000"

    property var siyi: SiYi
    property SiYiCamera camera: siyi.camera
    property SiYiTransmitter transmitter: siyi.transmitter
    property bool isRecording: camera.isRecording
    property int minDelta: 5
    property bool hasBeenMoved: false

    property real videoW: using1080p ? 1920 : 1280 //camera.resolutionW //1280
    property real videoH: using1080p ? 1080 : 720 //camera.resolutionH //720
    property bool expended: true
    property bool using1080p: camera.using1080p

    MouseArea {
        id: controlMouseArea
        anchors.fill: parent
        hoverEnabled: true
        visible: camera.isConnected
        onPressed: {
            if (camera.isTracking) {
                return
            }

            enableControl = true
            controlMouseArea.originX = mouse.x
            controlMouseArea.originY = mouse.y
            controlMouseArea.currentX = mouse.x
            controlMouseArea.currentY = mouse.y
            controlMouseArea.pitch = 0
            controlMouseArea.yaw = 0
            contrlTimer.start()
        }
        onReleased: {
            if (camera.isTracking) {
                return
            }

            camera.turn(0, 0)
            console.info("camera.turn(0, 0)")
            enableControl = false
            contrlTimer.stop()
        }
        onPositionChanged: {
            if (camera.isTracking) {
                return
            }

            controlMouseArea.currentX = mouse.x
            controlMouseArea.currentY = mouse.y
            controlMouseArea.yaw = controlMouseArea.currentX - controlMouseArea.originX
            controlMouseArea.pitch = controlMouseArea.currentY - controlMouseArea.originY
            controlMouseArea.yaw = controlMouseArea.yaw / 5
            controlMouseArea.pitch = controlMouseArea.pitch / 5
            if (Math.abs(controlMouseArea.yaw) > Math.abs(controlMouseArea.pitch)) {
                if (Math.abs(controlMouseArea.yaw) > minDelta) {
                    controlMouseArea.pitch = 0
                    controlMouseArea.isYDirection = false
                }
            } else {
                if (Math.abs(controlMouseArea.pitch) > minDelta) {
                    controlMouseArea.yaw = 0
                    controlMouseArea.isYDirection = true
                }
            }
        }
        onDoubleClicked: {
            if (camera.isTracking) {
                return
            }
            console.info("camera.resetPostion()")
            camera.resetPostion()
        }
        onClicked: function (mouse) {
            if (camera.aiModeOn) {
                var w = root.width
                var h = root.height
                var x = mouse.x
                var y = mouse.y
                var cookedX = (x * videoW) / root.width
                var cookedY = (y * videoH) / root.height
                console.info("camera.setTrackingTarget()", cookedX, cookedY, root.width,
                             root.height)
                camera.setTrackingTarget(true, cookedX, cookedY)
            } else {
                console.info("camera.autoFocus()")
                camera.autoFocus(mouse.x, mouse.y, root.width, root.height)
            }
        }

        Timer {
            id: contrlTimer
            running: false
            interval: 100
            repeat: true
            onTriggered: {
                if (controlMouseArea.enableControl) {
                    if (controlMouseArea.yaw < -100) {
                        controlMouseArea.yaw = -100
                    }

                    if (controlMouseArea.yaw > 100) {
                        controlMouseArea.yaw = 100
                    }

                    if (controlMouseArea.pitch < -100) {
                        controlMouseArea.pitch = -100
                    }

                    if (controlMouseArea.pitch > 100) {
                        controlMouseArea.pitch = 100
                    }

                    if (Math.abs(controlMouseArea.pitch) > minDelta) {
                        controlMouseArea.prePitch = controlMouseArea.pitch
                    }

                    if (Math.abs(controlMouseArea.yaw) > minDelta) {
                        controlMouseArea.preYaw = controlMouseArea.yaw
                    }

                    if (Math.abs(controlMouseArea.pitch) < minDelta && Math.abs(
                                controlMouseArea.yaw) < minDelta) {
                        return
                    }

                    hasBeenMoved = true
                    camera.turn(controlMouseArea.isYDirection ? 0 : Math.abs(
                                                                    controlMouseArea.yaw) < minDelta ? controlMouseArea.preYaw : controlMouseArea.yaw,
                                controlMouseArea.isYDirection ? Math.abs(
                                                                    controlMouseArea.pitch) < minDelta ? -controlMouseArea.prePitch : -controlMouseArea.pitch : 0)
                }
                onRunningChanged: {
                    if (!running) {
                        controlMouseArea.originX = 0
                        controlMouseArea.originY = 0
                        controlMouseArea.currentX = 0
                        controlMouseArea.currentY = 0
                        camera.turn(0, 0)
                    }
                }
            }
        }

        property bool enableControl: false
        property int pitch: 0
        property int yaw: 0
        property int prePitch: 0
        property int preYaw: 0
        property int originX: 0
        property int originY: 0
        property int currentX: 0
        property int currentY: 0
        property bool isYDirection: false
    }

    Item {
        id: controlRectangle
        anchors.left: parent.left
        anchors.leftMargin: 150
        anchors.topMargin: 10
        width: controlColumn.width
        height: controlColumn.height
        anchors.top: parent.top
        //visible: camera.isConnected
        Text {
            id: btText
            text: "1234"
            anchors.verticalCenter: parent.verticalCenter
            visible: false
        }

        Row {
            id: controlColumn
            spacing: 20
            Image {
                source: "qrc:/resources/SiYi/buttonRight.svg"
                fillMode: Image.PreserveAspectFit
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                rotation: expended ? 180 : 0
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.expended = !root.expended
                }
            }
            Image {
                source: SiYi.hideWidgets ? using1080p ? "qrc:/resources/SiYi/NavGreen.svg" : "qrc:/resources/SiYi/NavRed.svg" : "qrc:/resources/SiYi/nav.svg"
                fillMode: Image.PreserveAspectFit
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                visible: expended
                MouseArea {
                    anchors.fill: parent
                    onClicked: SiYi.hideWidgets = !SiYi.hideWidgets
                    onPressAndHold: {
                        camera.using1080p = !camera.using1080p
                        console.info("using1080p", using1080p)
                    }
                }
            }

            Image {
                // 放大
                id: zoomInImage
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                source: zoomInMA.pressed ? "qrc:/resources/SiYi/ZoomInGreen.svg" : "qrc:/resources/SiYi/ZoomIn.svg"
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                cache: false
                visible: expended ? camera.enableZoom : false
                MouseArea {
                    id: zoomInMA
                    anchors.fill: parent
                    onPressed: {
                        if (camera.is4k) {
                            camera.emitOperationResultChanged(-1)
                        } else {
                            camera.zoom(1)
                            zoomInTimer.start()
                        }
                    }
                    onReleased: {
                        zoomInTimer.stop()
                        camera.zoom(0)
                    }
                }
                Timer {
                    id: zoomInTimer
                    interval: 100
                    repeat: false
                    running: false
                    onTriggered: {
                        camera.zoom(1)
                        zoomInTimer.start()
                    }
                }
            }

            Image {
                // 缩小
                id: zoomOut
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                source: zoomOutMA.pressed ? "qrc:/resources/SiYi/ZoomOutGreen.svg" : "qrc:/resources/SiYi/ZoomOut.svg"
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                cache: false
                visible: expended ? camera.enableZoom : false
                MouseArea {
                    id: zoomOutMA
                    anchors.fill: parent
                    onPressed: {
                        if (camera.is4k) {
                            camera.emitOperationResultChanged(-1)
                        } else {
                            camera.zoom(-1)
                            zoomOutTimer.start()
                        }
                    }
                    onReleased: {
                        zoomOutTimer.stop()
                        camera.zoom(0)
                    }
                }
                Timer {
                    id: zoomOutTimer
                    interval: 100
                    repeat: false
                    running: false
                    onTriggered: {
                        camera.zoom(-1)
                        zoomOutTimer.start()
                    }
                }
            }

            Image {
                // 回中
                id: reset
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                source: resetMA.pressed ? "qrc:/resources/SiYi/ResetGreen.svg" : "qrc:/resources/SiYi/Reset.svg"
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                cache: false
                visible: expended ? camera.enableControl : false
                MouseArea {
                    id: resetMA
                    anchors.fill: parent
                    onPressed: camera.resetPostion()
                }
            }

            Image {
                // 拍照
                id: photo
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                source: photoMA.pressed ? "qrc:/resources/SiYi/PhotoGreen.svg" : "qrc:/resources/SiYi/Photo.svg"
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                cache: false
                visible: expended ? camera.enablePhoto : false
                MouseArea {
                    id: photoMA
                    anchors.fill: parent
                    onPressed: {
                        console.info("camera.sendCommand(SiYiCamera.CameraCommandTakePhoto)")
                        camera.sendCommand(SiYiCamera.CameraCommandTakePhoto)
                    }
                }
            }

            Image {
                // 录像
                id: video
                //sourceSize.width: btText.width
                //sourceSize.height: btText.width
                width: btText.width
                height: btText.width
                cache: false
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                visible: expended ? camera.enableVideo : false
                MouseArea {
                    id: videoMA
                    anchors.fill: parent
                    onPressed: {
                        if (camera.isRecording) {
                            camera.sendRecodingCommand(SiYiCamera.CloseRecording)
                        } else {
                            camera.sendRecodingCommand(SiYiCamera.OpenRecording)
                        }
                    }
                }
                Connections {
                    target: camera
                    function onEnableVideoChanged() {
                        video.source = "qrc:/resources/SiYi/empty.png"
                        if (camera.enableVideo) {
                            if (camera.isRecording) {
                                video.source = "qrc:/resources/SiYi/Stop.svg"
                            } else {
                                video.source = "qrc:/resources/SiYi/Video.png"
                            }
                        }
                    }

                    function onIsRecordingChanged() {
                        video.source = "qrc:/resources/SiYi/empty.png"
                        if (camera.isRecording) {
                            video.source = "qrc:/resources/SiYi/Stop.svg"
                        } else {
                            video.source = "qrc:/resources/SiYi/Video.png"
                        }
                    }
                }
            }

            Image {
                // 远景
                id: far
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                source: farMA.pressed ? "qrc:/resources/SiYi/farGreen.svg" : "qrc:/resources/SiYi/far.svg"
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                cache: false
                visible: expended ? camera.enableFocus : false
                MouseArea {
                    id: farMA
                    anchors.fill: parent
                    onPressed: {
                        camera.focus(1)
                        farTimer.start()
                    }
                    onReleased: {
                        farTimer.stop()
                        camera.focus(0)
                    }
                }
                Timer {
                    id: farTimer
                    interval: 100
                    repeat: false
                    running: false
                    onTriggered: {
                        camera.focus(1)
                        farTimer.start()
                    }
                }
            }

            Image {
                // 近景
                id: neer
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                source: neerMA.pressed ? "qrc:/resources/SiYi/neerGreen.svg" : "qrc:/resources/SiYi/neer.svg"
                anchors.verticalCenter: parent.verticalCenter
                fillMode: Image.PreserveAspectFit
                cache: false
                visible: expended ? camera.enableFocus : false
                MouseArea {
                    id: neerMA
                    anchors.fill: parent
                    onPressed: {
                        camera.focus(-1)
                        neerTimer.start()
                    }
                    onReleased: {
                        neerTimer.stop()
                        camera.focus(0)
                    }
                }
                Timer {
                    id: neerTimer
                    interval: 100
                    repeat: false
                    running: false
                    onTriggered: {
                        camera.focus(-1)
                        neerTimer.start()
                    }
                }
            }
            Image {
                // AI模块状态设置：0关闭，1开启
                id: aiControl
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                source: camera.aiModeOn ? (camera.isTracking ? "qrc:/resources/SiYi/AiRed.svg" : "qrc:/resources/SiYi/AiGreen.svg") : aiControlMouseArea.pressed ? "qrc:/resources/SiYi/AiGreen.svg" : "qrc:/resources/SiYi/Ai.svg"
                fillMode: Image.PreserveAspectFit
                cache: false
                anchors.verticalCenter: parent.verticalCenter
                visible: expended ? camera.enableAi : false
                MouseArea {
                    id: aiControlMouseArea
                    anchors.fill: parent
                    onClicked: {
                        if (camera.aiModeOn) {
                            if (camera.isTracking) {
                                camera.setTrackingTarget(false, 0, 0)
                            } else {
                                camera.setAiModel(SiYiCamera.AiModeOff)
                            }
                        } else {
                            camera.setAiModel(SiYiCamera.AiModeOn)
                        }
                    }
                }
            }
            Image {
                // 激光测距状态设置：0关闭，1开启
                id: laserDistance
                sourceSize.width: btText.width
                sourceSize.height: btText.width
                anchors.verticalCenter: parent.verticalCenter
                visible: expended ? camera.enableLaser : false
                source: {
                    if (laserDistanceMouseArea.containsMouse) {
                        return "qrc:/resources/SiYi/LaserDistanceGreen.svg"
                    }

                    if (camera.laserStateOn) {
                        return "qrc:/resources/SiYi/LaserDistanceGreen.svg"
                    } else {
                        if (laserDistanceMouseArea.pressed) {
                            return "qrc:/resources/SiYi/LaserDistanceGreen.svg"
                        } else {
                            return "qrc:/resources/SiYi/LaserDistance.svg"
                        }
                    }
                }
                fillMode: Image.PreserveAspectFit
                cache: false
                MouseArea {
                    id: laserDistanceMouseArea
                    anchors.fill: parent
                    onClicked: {
                        console.info("Set laser state: ", camera.laserStateOn ? "OFF" : "ON")
                        camera.setLaserState(
                                    camera.laserStateOn ? SiYiCamera.LaserStateOff : SiYiCamera.LaserStateOn)
                    }
                }

                Rectangle {
                    width: infoRow.width + 20
                    height: infoRow.height + 20
                    visible: camera.laserStateOn
                    anchors.left: parent.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    GridLayout {
                        id: infoRow
                        columns: 2
                        anchors.centerIn: parent
                        QGCLabel {
                            font.pixelSize: 48
                            text: qsTr("激光测距: ") + camera.cookedLaserDistance + "m"
                            color: "black"
                            Layout.columnSpan: 2
                            anchors.verticalCenter: parent.verticalAlignment
                        }
                        QGCLabel {
                            color: "black"
                            text: "x:" + camera.laserCoordsX
                            font.pixelSize: 36
                            anchors.verticalCenter: parent.verticalAlignment
                        }
                        QGCLabel {
                            color: "black"
                            text: "y:" + camera.laserCoordsY
                            font.pixelSize: 36
                            anchors.verticalCenter: parent.verticalAlignment
                        }
                    }
                }
            }
        }
    }
    Image {
        source: "qrc:/resources/SiYi/+.svg"
        x: camera.laserCoordsX * root.width / camera.resolutionW
        y: camera.laserCoordsY * root.height / camera.resolutionH
        sourceSize.width: btText.width
        sourceSize.height: btText.width
        visible: camera.laserStateOn
    }
}

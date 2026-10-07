/*
 * Slider do Windows 11: trilho fino, parte preenchida na cor de destaque e
 * bolinha com anel; o miolo cresce ao passar o mouse e encolhe ao arrastar.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import "impl"

T.Slider {
    id: control

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitHandleWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitHandleHeight + topPadding + bottomPadding)

    padding: 0
    hoverEnabled: true
    snapMode: T.Slider.SnapOnRelease

    readonly property Colors colors: Colors { text: Kirigami.Theme.textColor; accent: Kirigami.Theme.highlightColor }

    handle: Rectangle {
        x: control.leftPadding + (control.horizontal ? control.visualPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : control.visualPosition * (control.availableHeight - height))
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: Qt.tint(Kirigami.Theme.backgroundColor, control.colors.layer(0.08))
        border.width: 1
        border.color: control.colors.stroke

        Rectangle {
            anchors.centerIn: parent
            readonly property real diameter: control.pressed ? 10 : (control.hovered ? 14 : 12)
            width: diameter
            height: diameter
            radius: height / 2
            color: control.enabled ? Kirigami.Theme.highlightColor : control.colors.layer(0.36)
            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        FocusRing {
            visible: control.visualFocus
            baseRadius: 10
        }
    }

    background: Item {
        implicitWidth: control.horizontal ? 200 : 20
        implicitHeight: control.horizontal ? 20 : 200

        Rectangle { // trilho
            x: control.leftPadding + (control.horizontal ? 0 : (control.availableWidth - width) / 2)
            y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : 0)
            width: control.horizontal ? control.availableWidth : 4
            height: control.horizontal ? 4 : control.availableHeight
            radius: 2
            color: control.colors.track
        }
        Rectangle { // parte preenchida
            readonly property real filled: control.horizontal
                ? control.visualPosition * (control.availableWidth - control.handle.width) + control.handle.width / 2
                : (1 - control.visualPosition) * (control.availableHeight - control.handle.height) + control.handle.height / 2
            x: control.leftPadding + (control.horizontal ? (control.mirrored ? control.availableWidth - filled : 0) : (control.availableWidth - width) / 2)
            y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : control.availableHeight - filled)
            width: control.horizontal ? filled : 4
            height: control.horizontal ? 4 : filled
            radius: 2
            color: control.enabled ? Kirigami.Theme.highlightColor : control.colors.layer(0.36)
        }

        // a roda do mouse anda de passo em passo (wheelEnabled não respeita o stepSize)
        MouseArea {
            property int wheelDelta: 0
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                const last = control.value;
                wheelDelta += (wheel.angleDelta.y || -wheel.angleDelta.x) * (wheel.inverted ? -1 : 1);
                while (wheelDelta >= 120) { wheelDelta -= 120; control.increase(); }
                while (wheelDelta <= -120) { wheelDelta += 120; control.decrease(); }
                if (last !== control.value) {
                    control.moved();
                }
            }
        }
    }
}

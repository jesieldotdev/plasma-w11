/*
 * Barra de progresso do Windows 11: trilho de 1 px e barra de 3 px arredondada;
 * sem valor definido, um trecho corre de um lado ao outro.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import "impl"

T.ProgressBar {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    readonly property Colors colors: Colors { text: Kirigami.Theme.textColor; accent: Kirigami.Theme.highlightColor }

    contentItem: Item {
        implicitWidth: 200
        implicitHeight: 3
        clip: true

        Rectangle {
            visible: !control.indeterminate
            width: control.visualPosition * parent.width
            height: parent.height
            radius: 1.5
            color: control.enabled ? Kirigami.Theme.highlightColor : control.colors.layer(0.36)
        }
        Rectangle {
            id: runner
            visible: control.indeterminate
            width: parent.width * 0.4
            height: parent.height
            radius: 1.5
            color: Kirigami.Theme.highlightColor
            NumberAnimation on x {
                running: control.indeterminate && control.visible
                loops: Animation.Infinite
                from: -runner.width
                to: runner.parent.width
                duration: 1600
                easing.type: Easing.InOutQuad
            }
        }
    }

    background: Item {
        implicitWidth: 200
        implicitHeight: 3
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 1
            color: control.colors.track
            visible: !control.indeterminate
        }
    }
}

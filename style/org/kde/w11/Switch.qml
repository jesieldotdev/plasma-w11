/*
 * Chave do Windows 11: pílula de 40×20 com contorno quando desligada e cheia
 * na cor de destaque quando ligada; a bolinha cresce ao passar o mouse e se
 * estica ao apertar.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import "impl"

T.Switch {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding,
                            implicitIndicatorWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)
    baselineOffset: contentItem ? contentItem.y + contentItem.baselineOffset : 0

    padding: 1
    spacing: 12
    hoverEnabled: true

    readonly property Colors colors: Colors { text: Kirigami.Theme.textColor; accent: Kirigami.Theme.highlightColor }

    Kirigami.MnemonicData.enabled: enabled && visible
    Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.ActionElement
    Kirigami.MnemonicData.label: text
    Mnemonic { control: control; toggles: true }

    indicator: Rectangle {
        id: pill
        x: control.contentItem && control.contentItem.width > 0
           ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
           : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + Math.round((control.availableHeight - height) / 2)
        implicitWidth: 40
        implicitHeight: 20
        radius: 10

        readonly property bool on: control.checked
        color: on ? (control.enabled ? (control.pressed ? Qt.darker(Kirigami.Theme.highlightColor, 1.1)
                                       : control.hovered ? Qt.lighter(Kirigami.Theme.highlightColor, 1.08) : Kirigami.Theme.highlightColor)
                                     : control.colors.layer(0.2))
                  : (control.pressed ? control.colors.fillPressed : control.hovered ? control.colors.fillHover : control.colors.layer(0.02))
        border.width: on ? 0 : 1
        border.color: control.enabled ? control.colors.strokeStrong : control.colors.layer(0.25)
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            id: knob
            readonly property real diameter: control.pressed ? 14 : (control.hovered ? 14 : 12)
            width: control.pressed ? 17 : diameter
            height: diameter
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: pill.on ? parent.width - width - (parent.height - diameter) / 2 : (parent.height - diameter) / 2
            color: pill.on ? control.colors.accentInk
                           : (control.enabled ? Qt.rgba(control.colors.text.r, control.colors.text.g, control.colors.text.b, 0.8) : control.colors.layer(0.35))
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 120 } }
            Behavior on height { NumberAnimation { duration: 120 } }
        }

        FocusRing {
            visible: control.visualFocus
            baseRadius: 10
        }
    }

    contentItem: IndicatorLabel { control: control }
}

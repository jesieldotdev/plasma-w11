/*
 * Botão de opção do Windows 11: círculo com contorno; marcado, vira um anel
 * grosso na cor de destaque com o miolo claro, que cresce ao passar o mouse.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import "impl"

T.RadioButton {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding,
                            implicitIndicatorWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)
    baselineOffset: contentItem ? contentItem.y + contentItem.baselineOffset : 0

    padding: 1
    spacing: 8
    hoverEnabled: true

    readonly property Colors colors: Colors { text: Kirigami.Theme.textColor; accent: Kirigami.Theme.highlightColor }

    Kirigami.MnemonicData.enabled: enabled && visible
    Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.ActionElement
    Kirigami.MnemonicData.label: text
    Mnemonic { control: control; toggles: true }

    indicator: Rectangle {
        x: control.contentItem && control.contentItem.width > 0
           ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
           : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + Math.round((control.availableHeight - height) / 2)
        implicitWidth: 20
        implicitHeight: 20
        radius: 10
        color: control.checked ? (control.enabled ? Kirigami.Theme.highlightColor : control.colors.layer(0.2))
                               : (control.pressed ? control.colors.fillPressed : control.hovered ? control.colors.fillHover : control.colors.layer(0.02))
        border.width: control.checked ? 0 : 1
        border.color: control.enabled ? control.colors.strokeStrong : control.colors.layer(0.25)

        Rectangle {
            anchors.centerIn: parent
            readonly property real diameter: !control.checked ? (control.pressed ? 10 : 0)
                                         : control.pressed ? 8 : (control.hovered ? 12 : 10)
            visible: diameter > 0
            width: diameter
            height: diameter
            radius: height / 2
            color: control.checked ? control.colors.accentInk : control.colors.layer(0.8)
            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        FocusRing {
            visible: control.visualFocus
            baseRadius: 10
        }
    }

    contentItem: IndicatorLabel { control: control }
}

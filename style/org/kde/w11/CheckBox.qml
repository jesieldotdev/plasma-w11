/*
 * Caixa de seleção do Windows 11: quadrado de cantos arredondados; marcada,
 * fica cheia na cor de destaque com o visto (ou o traço, se parcial).
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import "impl"

T.CheckBox {
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
        id: box
        x: control.contentItem && control.contentItem.width > 0
           ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding)
           : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + Math.round((control.availableHeight - height) / 2)
        implicitWidth: 20
        implicitHeight: 20
        radius: 4

        readonly property bool on: control.checkState !== Qt.Unchecked
        color: on ? (control.enabled ? (control.pressed ? Qt.darker(Kirigami.Theme.highlightColor, 1.1)
                                        : control.hovered ? Qt.lighter(Kirigami.Theme.highlightColor, 1.08) : Kirigami.Theme.highlightColor)
                                     : control.colors.layer(0.2))
                  : (control.pressed ? control.colors.fillPressed : control.hovered ? control.colors.fillHover : control.colors.layer(0.02))
        border.width: on ? 0 : 1
        border.color: control.enabled ? control.colors.strokeStrong : control.colors.layer(0.25)

        Canvas {
            id: mark
            anchors.fill: parent
            visible: box.on
            readonly property bool partial: control.checkState === Qt.PartiallyChecked
            readonly property color ink: control.colors.accentInk
            onPartialChanged: requestPaint()
            onInkChanged: requestPaint()
            onVisibleChanged: requestPaint()
            onPaint: {
                const g = getContext("2d");
                g.reset();
                g.strokeStyle = ink;
                g.lineWidth = 1.6;
                g.lineCap = "round";
                g.lineJoin = "round";
                g.beginPath();
                if (partial) {
                    g.moveTo(6, 10); g.lineTo(14, 10);
                } else {
                    g.moveTo(5.5, 10.5); g.lineTo(8.5, 13.5); g.lineTo(14.5, 6.5);
                }
                g.stroke();
            }
        }

        FocusRing {
            visible: control.visualFocus
            baseRadius: 4
        }
    }

    contentItem: IndicatorLabel { control: control }
}

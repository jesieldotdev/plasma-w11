/*
 * Botão do Windows 11: 32 px de altura, cantos de 4 px, preenchimento leve
 * com borda fina; o botão padrão (e o marcado) fica na cor de destaque.
 * Plano (flat), só aparece ao passar o mouse, como os da barra de ferramentas.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import "impl"

T.Button {
    id: control

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    leftPadding: display === T.AbstractButton.IconOnly ? 8 : 12
    rightPadding: leftPadding
    topPadding: 5
    bottomPadding: 6
    spacing: 8
    hoverEnabled: Qt.styleHints.useHoverEffects

    icon.width: Kirigami.Units.iconSizes.sizeForLabels
    icon.height: Kirigami.Units.iconSizes.sizeForLabels

    readonly property Colors colors: Colors { text: Kirigami.Theme.textColor; accent: Kirigami.Theme.highlightColor }
    readonly property bool accent: (highlighted || Accessible.defaultButton || (checkable && checked)) && !flat
    readonly property bool menu: Accessible.role === Accessible.ButtonMenu

    Kirigami.MnemonicData.enabled: enabled && visible
    Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.ActionElement
    Kirigami.MnemonicData.label: display !== T.AbstractButton.IconOnly ? text : ""
    Mnemonic { control: control }

    contentItem: RowLayout {
        spacing: control.spacing
        readonly property color ink: control.accent ? control.colors.accentInk : Kirigami.Theme.textColor
        opacity: control.enabled ? (control.down && !control.accent ? 0.8 : 1) : 0.45

        Item { Layout.fillWidth: true }
        Kirigami.Icon {
            visible: control.display !== T.AbstractButton.TextOnly && source.toString().length > 0
            source: control.icon.name !== "" ? control.icon.name : control.icon.source
            Layout.preferredWidth: control.icon.width
            Layout.preferredHeight: control.icon.height
            color: Qt.colorEqual(control.icon.color, "transparent") ? parent.ink : control.icon.color
            isMask: control.accent
        }
        Text {
            visible: control.display !== T.AbstractButton.IconOnly && text.length > 0
            text: control.Kirigami.MnemonicData.richTextLabel
            textFormat: Text.StyledText
            font: control.font
            color: parent.ink
            elide: Text.ElideRight
            Layout.fillWidth: implicitWidth > control.availableWidth
            horizontalAlignment: Text.AlignHCenter
        }
        Canvas { // seta do botão que abre um menu
            visible: control.menu
            Layout.preferredWidth: 10
            Layout.preferredHeight: 10
            readonly property color ink: parent.ink
            onInkChanged: requestPaint()
            onPaint: {
                const g = getContext("2d");
                g.reset();
                g.strokeStyle = ink;
                g.lineWidth = 1.2;
                g.lineCap = "round";
                g.lineJoin = "round";
                g.beginPath();
                g.moveTo(1, 3.5); g.lineTo(5, 7.5); g.lineTo(9, 3.5);
                g.stroke();
            }
        }
        Item { Layout.fillWidth: true }
    }

    background: Rectangle {
        implicitWidth: control.display === T.AbstractButton.IconOnly ? 32 : 96
        implicitHeight: 32
        radius: 4
        color: control.accent
               ? (!control.enabled ? control.colors.layer(0.2)
                  : control.down ? Qt.darker(Kirigami.Theme.highlightColor, 1.12)
                  : control.hovered ? Qt.lighter(Kirigami.Theme.highlightColor, 1.08) : Kirigami.Theme.highlightColor)
               : control.flat
                 ? (control.down ? control.colors.fillPressed : (control.hovered || (control.checkable && control.checked)) ? control.colors.fillHover : "transparent")
                 : (!control.enabled ? control.colors.fillDisabled : control.down ? control.colors.fillPressed
                    : control.hovered ? control.colors.fillHover : control.colors.fill)
        border.width: control.flat || control.accent ? 0 : 1
        border.color: control.colors.stroke

        // a borda de baixo um pouco mais forte, como no Fluent
        Rectangle {
            visible: !control.flat && control.enabled && !control.down
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 3; rightMargin: 3 }
            height: 1
            color: control.accent ? Qt.rgba(0, 0, 0, 0.18) : control.colors.layer(0.04)
        }

        FocusRing {
            visible: control.visualFocus
            baseRadius: 4
        }
    }
}

/*
 * Caixa de texto do Windows 11: fundo leve, cantos de 4 px e linha embaixo,
 * que vira 2 px na cor de destaque quando está digitando. O comportamento
 * (menu de contexto, corretor, etc.) é o do campo do KDE.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.desktop as KDE
import "impl"

KDE.TextField {
    id: control

    readonly property Colors colors: Colors { text: Kirigami.Theme.textColor; accent: Kirigami.Theme.highlightColor }

    leftPadding: 11
    rightPadding: 11
    topPadding: 6
    bottomPadding: 7

    background: Rectangle {
        implicitWidth: 160
        implicitHeight: 32
        radius: 4
        color: !control.enabled ? control.colors.fillDisabled
               : control.activeFocus ? Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.7)
               : control.hovered ? control.colors.fillHover : control.colors.fill
        border.width: 1
        border.color: control.colors.stroke

        Rectangle { // linha de baixo
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 1; rightMargin: 1 }
            height: control.activeFocus ? 2 : 1
            radius: control.activeFocus ? 1 : 0
            color: control.activeFocus ? Kirigami.Theme.highlightColor : control.colors.layer(0.45)
        }
    }
}

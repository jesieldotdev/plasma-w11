/*
 * Caixa de seleção (dropdown) do Windows 11: igual a um botão, com a seta à
 * direita; a lista abre por cima da caixa, com o item atual alinhado a ela e
 * marcado pela barrinha na cor de destaque.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Window
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami
import "impl"

T.ComboBox {
    id: control

    Kirigami.Theme.colorSet: editable ? Kirigami.Theme.View : Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    hoverEnabled: true
    wheelEnabled: true
    leftPadding: 11 + (iconName.length > 0 ? 24 : 0)
    rightPadding: 36
    topPadding: 5
    bottomPadding: 6

    readonly property Colors colors: Colors { text: Kirigami.Theme.textColor; accent: Kirigami.Theme.highlightColor }
    readonly property string iconName: Kirigami.StyleHints.iconName || Kirigami.StyleHints.iconSource || ""
    readonly property int rowHeight: 36

    // largura do texto mais comprido, para a caixa não pular ao trocar
    property real widestText: 0
    onCountChanged: {
        let w = 0;
        for (let i = 0; i < count; ++i) {
            w = Math.max(w, metrics.boundingRect(textAt(i)).width);
        }
        widestText = w;
    }
    FontMetrics { id: metrics; font: control.font }

    contentItem: T.TextField {
        implicitWidth: Math.max(control.widestText, 60)
        padding: 0
        text: control.editable ? control.editText : control.displayText
        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        focus: true
        inputMethodHints: control.inputMethodHints
        validator: control.validator
        selectByMouse: true
        color: Kirigami.Theme.textColor
        selectionColor: Kirigami.Theme.highlightColor
        selectedTextColor: Kirigami.Theme.highlightedTextColor
        font: control.font
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        opacity: control.enabled ? 1 : 0.45
        renderType: Screen.devicePixelRatio % 1 !== 0 ? Text.QtRendering : Text.NativeRendering
    }

    indicator: Canvas {
        x: control.mirrored ? 12 : control.width - width - 12
        y: (control.height - height) / 2
        width: 12
        height: 12
        opacity: control.enabled ? 0.8 : 0.35
        readonly property color ink: Kirigami.Theme.textColor
        readonly property real drop: control.pressed ? 1.5 : 0 // a seta desce um pouco ao apertar
        onInkChanged: requestPaint()
        onDropChanged: requestPaint()
        onPaint: {
            const g = getContext("2d");
            g.reset();
            g.strokeStyle = ink;
            g.lineWidth = 1.2;
            g.lineCap = "round";
            g.lineJoin = "round";
            g.beginPath();
            g.moveTo(2, 4 + drop); g.lineTo(6, 8 + drop); g.lineTo(10, 4 + drop);
            g.stroke();
        }
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 32
        radius: 4
        color: !control.enabled ? control.colors.fillDisabled
               : control.editable && control.activeFocus ? Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.7)
               : control.pressed ? control.colors.fillPressed
               : control.hovered ? control.colors.fillHover
               : control.flat ? "transparent" : control.colors.fill
        border.width: control.flat && !control.hovered ? 0 : 1
        border.color: control.colors.stroke

        Kirigami.Icon {
            visible: control.iconName.length > 0
            source: control.iconName
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: Kirigami.Units.iconSizes.sizeForLabels
            height: width
        }
        Rectangle { // linha de baixo: a do campo de texto quando editável
            visible: control.editable
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 1; rightMargin: 1 }
            height: control.activeFocus ? 2 : 1
            color: control.activeFocus ? Kirigami.Theme.highlightColor : control.colors.layer(0.45)
        }
        FocusRing {
            visible: control.visualFocus && !control.editable
            baseRadius: 4
        }
    }

    delegate: T.ItemDelegate {
        id: row
        required property int index
        width: ListView.view ? ListView.view.width : implicitWidth
        implicitWidth: label.implicitWidth + 40
        implicitHeight: control.rowHeight
        highlighted: control.highlightedIndex === index
        hoverEnabled: true

        readonly property bool current: control.currentIndex === index

        contentItem: Text {
            id: label
            leftPadding: 12
            text: control.textAt(row.index)
            font: control.font
            color: Kirigami.Theme.textColor
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: 4
            color: row.pressed ? control.colors.fillPressed
                   : (row.highlighted || row.hovered) ? control.colors.fillHover
                   : row.current ? control.colors.fill : "transparent"
            Rectangle { // barrinha do item escolhido
                visible: row.current
                x: 0
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: row.pressed ? 10 : 16
                radius: 1.5
                color: Kirigami.Theme.highlightColor
            }
        }
    }

    popup: T.Popup {
        // abre por cima: o item atual fica em cima da caixa, como no Windows
        // (lista comprida, que rola: abre embaixo)
        readonly property bool scrolls: control.count > 15
        y: scrolls ? control.height + 2 : control.height / 2 - control.rowHeight / 2 - topPadding - Math.max(0, control.currentIndex) * control.rowHeight
        x: -1
        width: Math.max(control.width + 2, list.contentItem.childrenRect.width)
        implicitHeight: Math.min(list.contentHeight + topPadding + bottomPadding, 15 * control.rowHeight)
        padding: 3
        margins: 8

        Kirigami.Theme.colorSet: Kirigami.Theme.View
        Kirigami.Theme.inherit: false

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
            NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: 160; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 90 }
        }

        contentItem: ListView {
            id: list
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollIndicator.vertical: T.ScrollIndicator {}
            Component.onCompleted: positionViewAtIndex(Math.max(0, control.currentIndex), ListView.Contain)
        }

        background: Kirigami.ShadowedRectangle {
            radius: 8
            color: Qt.tint(Kirigami.Theme.backgroundColor, control.colors.layer(0.04))
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.35)
            shadow.size: 18
            shadow.yOffset: 6
            shadow.color: Qt.rgba(0, 0, 0, 0.35)
        }
    }
}

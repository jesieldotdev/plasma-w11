// Anel de foco do teclado: contorno branco de 2 px por fora do controle
import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    property real baseRadius: 4
    anchors.fill: parent
    anchors.margins: -3
    radius: baseRadius + 3
    color: "transparent"
    border.width: 2
    border.color: Kirigami.Theme.textColor
}

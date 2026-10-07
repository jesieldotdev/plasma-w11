// Cores do Fluent a partir do tema do KDE: camadas de texto translúcido sobre o fundo
import QtQuick
import org.kde.kirigami as Kirigami

QtObject {
    property color text: "white"
    function layer(a) { return Qt.rgba(text.r, text.g, text.b, a); }
    readonly property color fill: layer(0.06)
    readonly property color fillHover: layer(0.085)
    readonly property color fillPressed: layer(0.035)
    readonly property color fillDisabled: layer(0.04)
    readonly property color stroke: layer(0.09)
    readonly property color strokeStrong: layer(0.6)
    readonly property color track: layer(0.55)
    // texto/miolo por cima da cor de destaque: preto se ela for clara, branco se for escura
    property color accent: "#0078d4"
    readonly property color accentInk: contrast(accent)
    function contrast(c) {
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.6 ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1);
    }
}

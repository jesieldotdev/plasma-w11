// Texto ao lado da bolinha/caixa/chave
import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

Text {
    required property T.AbstractButton control
    property FontMetrics fontMetrics: FontMetrics { font: control.font }
    topPadding: Math.max(0, (control.implicitIndicatorHeight - fontMetrics.height) / 2)
    bottomPadding: topPadding
    leftPadding: control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0
    rightPadding: control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0
    opacity: control.enabled ? 1 : 0.45
    text: control.Kirigami.MnemonicData.richTextLabel
    textFormat: Text.StyledText
    font: control.font
    color: Kirigami.Theme.textColor
    elide: Text.ElideRight
    wrapMode: Text.Wrap
    visible: control.text
    horizontalAlignment: Text.AlignLeft
    verticalAlignment: Text.AlignVCenter
}

// Atalho Alt+letra do rótulo, como no estilo do KDE
import QtQuick
import QtQuick.Templates as T
import org.kde.kirigami as Kirigami

Shortcut {
    required property T.AbstractButton control
    property bool toggles: false
    enabled: !(RegExp(/\&[^\&]/).test(control.text))
    sequence: control.Kirigami.MnemonicData.sequence
    onActivated: {
        if (typeof control.animateClick === "function") {
            control.animateClick();
        } else if (toggles) {
            control.toggle();
        } else {
            control.clicked();
        }
    }
}

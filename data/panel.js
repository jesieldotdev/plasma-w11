// Ajusta o painel criado pelo layout do Windows Modern (roda via evaluateScript).
// O instalador define LAUNCHERS antes deste código (atalhos da barra anterior).
panels().forEach(function (p) {
    p.opacity = "translucent";
    p.widgets().forEach(function (w) {
        if (w.type == "org.kde.windowsmodern.systemtray") {
            // seta à esquerda, ordem normal dos ícones; bateria sempre visível
            w.currentConfigGroup = ["General"];
            w.writeConfig("reverseIconOrder", true);
            w.writeConfig("shownItems", ["org.kde.plasma.battery"]);
        } else if (w.type == "org.kde.windowsmodern.digitalclock") {
            // hora e data do mesmo tamanho, Segoe UI 9, 12 h (AM/PM)
            w.currentConfigGroup = ["Appearance"];
            w.writeConfig("autoFontAndSize", "false");
            w.writeConfig("fontFamily", "Segoe UI Variable");
            w.writeConfig("fontSize", "9");
            w.writeConfig("fontWeight", "50");
            w.writeConfig("use24hFormat", "0");
        } else if (w.type == "org.kde.plasma.icontasks" && LAUNCHERS) {
            w.currentConfigGroup = ["General"];
            w.writeConfig("launchers", LAUNCHERS);
        }
    });
});

#!/usr/bin/env bash
# Cria o tema do Plasma Windows-11-dark a partir do Windows-modern-dark:
#  - sem os ícones próprios que passam por cima do tema de ícones na bandeja;
#  - painel translúcido mais escuro (acrílico do Windows 11).
set -euo pipefail
source "$(dirname "$0")/lib.sh"

SRC="$THEMES/Windows-modern-dark"; DST="$THEMES/Windows-11-dark"
[ -d "$SRC" ] || die "tema Windows-modern-dark não instalado."
rm -rf "$DST"; cp -a "$SRC" "$DST"
sed -i 's/^Name=.*/Name=Windows 11 Dark/; s/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=Windows-11-dark/' "$DST/metadata.desktop"
for i in audio battery network klipper device preferences media; do rm -f "$DST/icons/$i.svg"; done
sed -i 's/opacity:0.6;fill:#1C1C1C/opacity:0.8;fill:#1C1C1C/g' "$DST/translucent/widgets/panel-background.svg"
rm -f "$HOME"/.cache/plasma_theme_*.kcache

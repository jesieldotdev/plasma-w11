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
# o fundo do painel do tema original é XML inválido (style="" duplicado nas sombras):
# o Qt não desenha nada e a barra fica só com o desfoque, sem a camada escura do acrílico.
# Mantém o style que esconde a sombra e descarta o outro.
python3 - "$DST/widgets/panel-background.svg" "$DST/translucent/widgets/panel-background.svg" <<'PY'
import re, sys
def fix(tag):
    t = tag.group(0)
    if t.count(' style="') < 2:
        return t
    m = re.search(r'(id="[^"]*")\s+(style="[^"]*")', t)
    t = re.sub(r'\s+style="[^"]*"', '', t)
    return t.replace(m.group(1), m.group(1) + ' ' + m.group(2), 1)
for f in sys.argv[1:]:
    s = open(f).read()
    open(f, 'w').write(re.sub(r'<[^!?>][^>]*>', fix, s))
PY
sed -i 's/opacity:0.6;fill:#1C1C1C/opacity:0.5;fill:#1C1C1C/g' "$DST/translucent/widgets/panel-background.svg"
# linha fina e clara no topo da barra, como no Windows 11 (1 px na borda de cima do elemento "top")
sed -i 's|\(transform="matrix(0.37500096,0,0,1.9999988,52.874957,-1814.7233)">\)|\1<rect x="19" y="910.36218" width="32" height="0.5" style="fill:#ffffff;opacity:0.12;stroke:none" />|' "$DST/translucent/widgets/panel-background.svg"
rm -f "$HOME"/.cache/plasma_theme_*.kcache

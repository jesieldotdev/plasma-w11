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
# cor de destaque: o tema segue a do sistema (Configurações › Cores), como no Windows.
# Sem o "colors" próprio, o Plasma usa o esquema de cores do sistema com o destaque escolhido;
# e o azul escrito direto nos SVGs vira a classe ColorScheme-Highlight, que o Plasma recolore.
rm -f "$DST/colors"
python3 - "$DST" <<'PY'
import pathlib, re, sys
ACCENT = re.compile(r'#(?:4cc2ff|60cdff|0078d4|3daee9|3daee6)\b', re.I)
STYLE = ('<style type="text/css" id="current-color-scheme">'
         '.ColorScheme-Text { color:#ffffff; } .ColorScheme-Background { color:#202020; } '
         '.ColorScheme-Highlight { color:#4cc2ff; } .ColorScheme-ViewText { color:#ffffff; } '
         '.ColorScheme-ViewBackground { color:#202020; } .ColorScheme-ButtonText { color:#ffffff; } '
         '.ColorScheme-ButtonBackground { color:#2d2d2d; } .ColorScheme-ButtonFocus { color:#4cc2ff; } '
         '.ColorScheme-PositiveText { color:#6ccb5f; } .ColorScheme-NeutralText { color:#fce100; } '
         '.ColorScheme-NegativeText { color:#ff99a4; }</style>')

def fix(tag):
    t = tag.group(0)
    if t.startswith(('<style', '<svg', '</')) or not ACCENT.search(t):
        return t
    t = re.sub(r'(?<![-\w])color:\s*#[0-9a-fA-F]{3,6};?', '', t)          # "color:" fixo venceria a classe
    t = ACCENT.sub('currentColor', t)
    if 'ColorScheme-' in t:  # classe enfeite (ex.: ViewHover com o azul fixo): vira a do destaque
        return re.sub(r'ColorScheme-\w+', 'ColorScheme-Highlight', t)
    if re.search(r'\sclass="', t):
        return re.sub(r'\sclass="', ' class="ColorScheme-Highlight ', t, count=1)
    return re.sub(r'^<([\w:]+)', r'<\1 class="ColorScheme-Highlight"', t, count=1)

for f in pathlib.Path(sys.argv[1]).rglob('*.svg'):
    s = f.read_text(errors='ignore')
    body = re.sub(r'<[^!?>][^>]*>', fix, s)
    if body == s:
        continue
    if 'id="current-color-scheme"' not in body:
        body = re.sub(r'(<svg\b[^>]*>)', r'\1' + STYLE, body, count=1)
    f.write_text(body)
PY
rm -f "$HOME"/.cache/plasma_theme_*.kcache

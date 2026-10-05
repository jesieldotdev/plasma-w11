# Gera um tema de ícones com os glyphs da Segoe Fluent Icons (fonte do Windows 11)
# para os nomes que a bandeja do Plasma usa. Herda do windows-modern para o resto.
import os, re, sys
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen

FONT, SRC, OUT = sys.argv[1:4]
font = TTFont(FONT); gs = font.getGlyphSet(); cmap = font.getBestCmap()

def path(cp):
    pen = SVGPathPen(gs); gs[cmap[cp]].draw(pen); return pen.getCommands()

from fontTools.pens.boundsPen import BoundsPen
def bounds(cps):
    b = None
    for cp in cps:
        bp = BoundsPen(gs); gs[cmap[cp]].draw(bp); x0, y0, x1, y1 = bp.bounds
        b = (x0, y0, x1, y1) if b is None else (min(b[0], x0), min(b[1], y0), max(b[2], x1), max(b[3], y1))
    return b

# Caixa óptica comum: todo ícone é centralizado e cabe em BOX_W x BOX_H (unidades da fonte),
# assim glyphs altos (área de transferência, play) não ficam maiores que os largos (Wi-Fi, bateria).
BOX_W, BOX_H = 2048, 1760
def svg(layers, ref=None):
    x0, y0, x1, y1 = bounds(ref or [cp for cp, _ in layers])
    k = min(BOX_W / (x1 - x0), BOX_H / (y1 - y0))
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    tr = f'matrix({k:.4f} 0 0 {-k:.4f} {1024 - k * cx:.2f} {1024 + k * cy:.2f})'
    body = ''.join(f'<path class="ColorScheme-Text" fill="currentColor" opacity="{o}" '
                   f'transform="{tr}" d="{path(cp)}"/>' for cp, o in layers)
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="-160 -160 2368 2368">'
            '<style id="current-color-scheme">.ColorScheme-Text{color:#ffffff;}</style>' + body + '</svg>')

WIFI = [0xE872, 0xE873, 0xE874, 0xE701]          # 1, 2, 3 barras, cheio
def wifi(level): return svg([(0xE701, 0.3), (WIFI[level], 1)], [0xE701]) if level < 3 else svg([(0xE701, 1)])
def bat(pct, charging):
    i = max(0, min(10, round(pct / 10)))
    return svg([((0xEBAB if charging else 0xEBA0) + i, 1)], [0xEBA0, 0xEBB5])

def icon_for(name):
    n = re.sub(r'-(symbolic|panel)$', '', name)
    m = re.fullmatch(r'network-wireless-(\d+)(-locked)?', n)
    if m: return wifi({0: 0, 20: 0, 40: 1, 60: 2, 80: 2, 100: 3}[int(m[1])])
    m = re.fullmatch(r'network-wireless(?:-secure)?-signal-(none|weak|low|ok|good|excellent)', n)
    if m: return wifi({'none': 0, 'weak': 0, 'low': 1, 'ok': 2, 'good': 2, 'excellent': 3}[m[1]])
    if n in ('network-wireless', 'network-wireless-connected', 'network-wireless-hotspot'): return wifi(3)
    if n in ('network-wireless-offline', 'network-wireless-disconnected', 'network-offline',
             'network-wired-disconnected', 'network-wired-no-route', 'network-wired-unavailable'):
        return svg([(0xF384, 1)])
    if n.startswith('network-wireless-acquiring'): return wifi(0)
    if n.startswith('network-wired'): return svg([(0xE839, 1)])
    if re.fullmatch(r'audio-volume-(muted.*|off)', n): return svg([(0xE74F, 1)], [0xE995, 0xE74F])
    if n == 'audio-volume-low-zero': return svg([(0xE992, 1)], [0xE995, 0xE74F])
    for k, cp in (('high', 0xE995), ('medium', 0xE994), ('low', 0xE993)):
        if n == f'audio-volume-{k}': return svg([(cp, 1)], [0xE995, 0xE74F])
    m = re.fullmatch(r'battery-(\d{3})(-charging|-charged)?', n)
    if m: return bat(int(m[1]), bool(m[2]))
    m = re.fullmatch(r'battery-(empty|caution|low|medium|good|full)(-charging|-charged)?', n)
    if m: return bat({'empty': 0, 'caution': 10, 'low': 20, 'medium': 50, 'good': 70, 'full': 100}[m[1]], bool(m[2]))
    if n in ('battery-full-charged', 'battery_charged', 'battery-100-charged'): return bat(100, True)
    if n in ('bluetooth-disabled', 'bluetooth-offline', 'bluetooth-inactive'): return svg([(0xE702, 0.45)])
    if n.startswith('bluetooth'): return svg([(0xE702, 1)])
    # brilho baixo = sol meio preenchido (E793); o resto, sol cheio (E706)
    if re.fullmatch(r'(display-)?brightness-low|low-brightness', n): return svg([(0xE793, 1)])
    if n.startswith('brightness') or n.startswith('video-display-brightness') or n.startswith('display-brightness') \
            or n == 'high-brightness': return svg([(0xE706, 1)])
    if n == 'klipper': return svg([(0xE77F, 1)])
    # Na tomada a bateria do Plasma mostra o perfil de energia; o Windows mostra a bateria carregando
    if n.startswith('battery-profile') or n.startswith('power-profile'): return bat(100, True)
    if n.startswith('redshift-status-on') or n == 'night-light': return svg([(0xE708, 1)])
    if n.startswith('redshift-status-off') or n == 'night-light-disabled': return svg([(0xE708, 0.45)])
    if n in ('media-playback-start', 'media-playback-playing'): return svg([(0xE768, 1)])
    if n in ('media-playback-pause', 'media-playback-paused'): return svg([(0xE769, 1)])
    if n in ('media-removable', 'drive-removable-media', 'drive-removable-media-usb', 'device-notifier'):
        return svg([(0xE88E, 1)])
    return None

os.makedirs(f'{OUT}/status', exist_ok=True)
names = sorted(f[:-4] for f in os.listdir(f'{SRC}/status') if f.endswith('.svg'))
extra = ['power-profile-performance-symbolic', 'power-profile-balanced-symbolic', 'power-profile-power-saver-symbolic',
         'battery-profile-balanced', 'media-playback-start', 'media-playback-start-symbolic', 'media-playback-playing',
         'media-playback-paused', 'media-playback-pause', 'media-playback-pause-symbolic', 'night-light', 'night-light-disabled',
         'network-offline', 'network-wireless-disconnected', 'device-notifier', 'video-display-brightness',
         'video-display-brightness-symbolic', 'audio-volume-low-zero', 'audio-volume-low-zero-symbolic']
count = 0
for name in sorted(set(names + extra)):
    s = icon_for(name)
    if s:
        open(f'{OUT}/status/{name}.svg', 'w').write(s); count += 1
open(f'{OUT}/index.theme', 'w').write(
    '[Icon Theme]\nName=Windows 11 Fluent\nComment=windows-modern + ícones da bandeja da Segoe Fluent Icons\n'
    'Inherits=windows-modern,breeze-dark,hicolor\nFollowsColorScheme=true\nDirectories=status\n\n'
    '[status]\nContext=Status\nType=Scalable\nSize=22\nMinSize=8\nMaxSize=512\n')
print(count, 'ícones')

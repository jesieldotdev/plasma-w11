#!/usr/bin/env python3
"""Deixa o Dolphin como o Explorador do Windows 11 abrindo em "Este Computador".

- painel lateral: "Este Computador" (thispc:/) logo depois de "Início";
- o Dolphin abre sempre em thispc:/ (sem restaurar as abas da última vez);
- exibição de thispc:/: ícones com miniaturas, agrupado por tipo (Pastas /
  Unidades e dispositivos). Para isso o Dolphin precisa lembrar a exibição
  por pasta (GlobalViewProps=false), como o Explorador; as outras pastas
  continuam começando com a exibição global de antes.
Pode rodar de novo sem duplicar nada.
"""
import base64, hashlib, os, subprocess
import xml.etree.ElementTree as ET

HOME = os.path.expanduser('~')
URL = 'thispc:/'


def kw(group, key, value):
    subprocess.run(['kwriteconfig6', '--file', 'dolphinrc', '--group', group, '--key', key, value], check=True)


def places():
    path = f'{HOME}/.local/share/user-places.xbel'
    if not os.path.exists(path):
        return  # o Dolphin cria o arquivo na primeira vez; rode de novo depois
    ns = {'bookmark': 'http://www.freedesktop.org/standards/desktop-bookmarks',
          'kdepriv': 'http://www.kde.org/kdepriv', 'mime': 'http://www.freedesktop.org/standards/shared-mime-info'}
    for k, v in ns.items():
        ET.register_namespace(k, v)
    tree = ET.parse(path)
    root = tree.getroot()
    if any(b.get('href') == URL for b in root.iter('bookmark')):
        return
    bm = ET.Element('bookmark', href=URL)
    ET.SubElement(bm, 'title').text = 'Este Computador'
    info = ET.SubElement(bm, 'info')
    meta = ET.SubElement(info, 'metadata', owner='http://freedesktop.org')
    ET.SubElement(meta, '{%s}icon' % ns['bookmark'], name='computer')
    meta2 = ET.SubElement(info, 'metadata', owner='http://www.kde.org')
    ET.SubElement(meta2, 'ID').text = 'thispc-este-computador'
    children = list(root)
    home = next((i for i, b in enumerate(children)
                 if b.tag == 'bookmark' and b.get('href') == 'file://' + HOME), None)
    root.insert(home + 1 if home is not None else len(children), bm)
    tree.write(path, encoding='utf-8', xml_declaration=True)


def view_props():
    props = ('[Dolphin]\nVersion=4\nViewMode=0\nPreviewsShown=true\nSortRole=text\nSortOrder=0\n'
             'GroupRole=type\nGroupedSorting=true\nSortFoldersFirst=false\nTimestamp=2030,1,1,0,0,0\n')
    base = f'{HOME}/.local/share/dolphin/view_properties/remote/'
    # o Dolphin usa sha1(url) em base64; a forma exata da url varia, grava as possíveis
    for u in ('thispc:/', 'thispc:', 'thispc://', 'thispc:///', 'thispc:/.', 'thispc:/./'):
        h = base64.b64encode(hashlib.sha1(u.encode()).digest()).decode().replace('/', '-')
        os.makedirs(base + h, exist_ok=True)
        subprocess.run(['setfattr', '-n', 'user.kde.fm.viewproperties#1', '-v', props, base + h], check=True)


kw('General', 'GlobalViewProps', 'false')
kw('General', 'HomeUrl', URL)
kw('General', 'RememberOpenedTabs', 'false')
places()
view_props()
print('Dolphin configurado: abre em Este Computador')

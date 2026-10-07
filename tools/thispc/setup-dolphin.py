#!/usr/bin/env python3
"""Deixa o Dolphin como o Explorador do Windows 11 abrindo em "Este Computador".

- painel lateral compacto (ícones de 16 px), sem Recentes/Etiquetas/Pesquisar por,
  com "Este Computador" (thispc:/) depois das pastas, como no Windows;
- barra de ferramentas do Explorador (← → ↑, caminho, atualizar, pesquisa) e
  barra de status em largura total;
- o Dolphin abre sempre em thispc:/ (sem restaurar as abas da última vez);
- pastas em lista (Detalhes), como o padrão do Windows;
- exibição de thispc:/ (no Dolphin sem o patch): ícones com miniaturas,
  agrupado por tipo (Pastas / Unidades e dispositivos);
- uma exibição só para todas as pastas (GlobalViewProps), que não se perde ao
  trocar de pasta.
Pode rodar de novo sem duplicar nada.
"""
import base64, hashlib, os, shutil, subprocess, time
import xml.etree.ElementTree as ET

HOME = os.path.expanduser('~')
URL = 'thispc:/'
HERE = os.path.dirname(os.path.abspath(__file__))


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
    # grupos que o Explorador não tem
    info0 = root.find('info')
    meta0 = info0.find('metadata') if info0 is not None else None
    if meta0 is not None:
        for group in ('RecentlySaved', 'Tags', 'SearchFor'):
            tag = f'GroupState-{group}-IsHidden'
            el = meta0.find(tag)
            if el is None:
                el = ET.SubElement(meta0, tag)
            el.text = 'true'
    bm = next((b for b in root.findall('bookmark') if b.get('href') == URL), None)
    if bm is not None:
        root.remove(bm)  # reposiciona (versões antigas punham logo depois de Início)
    else:
        bm = ET.Element('bookmark', href=URL)
        ET.SubElement(bm, 'title').text = 'Este Computador'
        info = ET.SubElement(bm, 'info')
        meta = ET.SubElement(info, 'metadata', owner='http://freedesktop.org')
        ET.SubElement(meta, '{%s}icon' % ns['bookmark'], name='computer')
        meta2 = ET.SubElement(info, 'metadata', owner='http://www.kde.org')
        ET.SubElement(meta2, 'ID').text = 'thispc-este-computador'
    place_after_folders(root, bm)
    tree.write(path, encoding='utf-8', xml_declaration=True)


def place_after_folders(root, bm):
    """Depois da última pasta da pasta pessoal (Vídeos...), antes da Lixeira."""
    children = list(root)
    last = None
    for i, b in enumerate(children):
        if b.tag == 'bookmark' and (b.get('href') or '').startswith('file://' + HOME):
            last = i
    root.insert(last + 1 if last is not None else len(children), bm)


def view_props():
    props = ('[Dolphin]\nVersion=4\nViewMode=0\nPreviewsShown=true\nSortRole=text\nSortOrder=0\n'
             'GroupRole=type\nGroupedSorting=true\nSortFoldersFirst=false\nTimestamp=2030,1,1,0,0,0\n')
    base = f'{HOME}/.local/share/dolphin/view_properties/remote/'
    # o Dolphin usa sha1(url) em base64; a forma exata da url varia, grava as possíveis
    for u in ('thispc:/', 'thispc:', 'thispc://', 'thispc:///', 'thispc:/.', 'thispc:/./'):
        h = base64.b64encode(hashlib.sha1(u.encode()).digest()).decode().replace('/', '-')
        os.makedirs(base + h, exist_ok=True)
        subprocess.run(['setfattr', '-n', 'user.kde.fm.viewproperties#1', '-v', props, base + h], check=True)


def default_list_view():
    """Padrão do Explorador: lista (Detalhes) por nome, sem grupos, colunas do Windows."""
    path = f'{HOME}/.local/share/dolphin/view_properties/global'
    os.makedirs(path, exist_ok=True)
    old = subprocess.run(['getfattr', '--only-values', '-n', 'user.kde.fm.viewproperties#1', path],
                         capture_output=True, text=True).stdout
    hidden = 'HiddenFilesShown=true' in old  # mantém a escolha de mostrar ocultos
    now = time.strftime('%Y,%m,%d,%H,%M,%S').replace(',0', ',')
    props = ('[Dolphin]\nVersion=4\nViewMode=1\nSortRole=text\nSortOrder=0\nGroupedSorting=false\n'
             'SortFoldersFirst=true\nVisibleRoles=Details_text,Details_modificationtime,Details_type,Details_size\n'
             f'Timestamp={now}\n' + ('\n[Settings]\nHiddenFilesShown=true\n' if hidden else ''))
    subprocess.run(['setfattr', '-n', 'user.kde.fm.viewproperties#1', '-v', props, path], check=True)
    kw('General', 'ViewPropsTimestamp', now)   # pastas já vistas também passam a usar a lista
    kw('DetailsMode', 'ExpandableFolders', 'false')


# uma exibição para todas as pastas: escolher lista/ícones vale em todo lugar
# (o Este Computador do dolphin-w11 é uma página própria e não depende disso)
kw('General', 'GlobalViewProps', 'true')
kw('General', 'HomeUrl', URL)
kw('General', 'RememberOpenedTabs', 'false')
kw('General', 'ShowStatusBar', '1')          # largura total, como o Explorador
kw('PlacesPanel', 'IconSize', '16')
ui = f'{HOME}/.local/share/kxmlgui5/dolphin'
os.makedirs(ui, exist_ok=True)
shutil.copy(os.path.join(HERE, '..', '..', 'data', 'dolphin', 'dolphinui.rc'), f'{ui}/dolphinui.rc')
places()
view_props()
default_list_view()
print('Dolphin configurado: abre em Este Computador')

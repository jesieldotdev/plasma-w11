#!/usr/bin/env bash
# Plasma W11 — deixa o KDE Plasma 6 com a cara do Windows 11.
#
#   ./install.sh                     instala tudo (pergunta o mínimo)
#   ./install.sh --windows /caminho  usa esta pasta Windows (com Fonts/, Cursors/, Media/)
#   ./install.sh --no-windows        não procura o Windows (sem ícones Fluent, cursor e sons originais)
#   ./install.sh --no-rounded        não instala as bordas arredondadas (COPR)
#   ./install.sh --skip-deps         não instala pacotes (já instalados)
#
# Antes de mexer em qualquer coisa salva o visual atual; ./uninstall.sh volta a ele.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$HERE/scripts/lib.sh"

WIN_DIR=""; USE_WINDOWS=1; ROUNDED=1; DEPS=1
while [ $# -gt 0 ]; do
    case "$1" in
        --windows) WIN_DIR="$2"; shift ;;
        --no-windows) USE_WINDOWS=0 ;;
        --no-rounded) ROUNDED=0 ;;
        --skip-deps) DEPS=0 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "opção desconhecida: $1 (veja --help)" ;;
    esac
    shift
done

# ── 0. verificações ──────────────────────────────────────────────────
command -v plasmashell >/dev/null || die "KDE Plasma não encontrado."
PLASMA_VER=$(plasmashell --version | awk '{print $2}')
[ "${PLASMA_VER%%.*}" = 6 ] || die "precisa do Plasma 6 (encontrado: $PLASMA_VER)."
qdbus-qt6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 || die "rode dentro de uma sessão Plasma em execução."
mkdir -p "$STATE" "$BIN"
info "Plasma W11 — Plasma $PLASMA_VER"

# ── 1. backup do visual atual ────────────────────────────────────────
bash "$HERE/scripts/backup.sh"

# atalhos fixados na barra de tarefas atual (reaplicados no painel novo)
LAUNCHERS=$(plasma_eval 'var l=""; panels().forEach(function(p){ p.widgets().forEach(function(w){
    if (!l && (w.type=="org.kde.plasma.icontasks"||w.type=="org.kde.plasma.taskmanager")) {
        w.currentConfigGroup=["General"]; l=String(w.readConfig("launchers","")); } }); }); print(l)' || true)

# ── 2. dependências ──────────────────────────────────────────────────
if [ "$DEPS" = 1 ]; then
    if command -v dnf >/dev/null; then
        info "Instalando dependências (dnf)"
        as_root dnf -y -q install git kvantum ImageMagick gettext python3-pyside6 kdialog \
            gcc-c++ cmake extra-cmake-modules qt6-qtbase-devel qt6-qtdeclarative-devel \
            kf6-kpackage-devel kf6-kconfig-devel kf6-ki18n-devel kf6-kcoreaddons-devel \
            kf6-kwindowsystem-devel kf6-kio-devel kf6-kiconthemes-devel kf6-kitemmodels-devel \
            kf6-kservice-devel kf6-kxmlgui-devel kf6-kjobwidgets-devel kf6-kcmutils-devel \
            libplasma-devel plasma-workspace-devel plasma-workspace-libs
        if [ "$ROUNDED" = 1 ]; then
            step "Bordas arredondadas (COPR matinlotfali/KDE-Rounded-Corners)"
            as_root dnf -y -q copr enable matinlotfali/KDE-Rounded-Corners
            as_root dnf -y -q install kwin-effect-roundcorners || { warn "efeito de bordas indisponível para este KWin"; ROUNDED=0; }
        fi
    else
        warn "não é Fedora: instale as dependências listadas no README e rode com --skip-deps."
    fi
fi

# ── 3. KDE-Windows-Modern (versão fixa) + nossos patches ─────────────
info "Baixando KDE-Windows-Modern ($UPSTREAM_COMMIT)"
UP="$STATE/upstream"
if [ ! -d "$UP/.git" ]; then
    git clone -q "$UPSTREAM_URL" "$UP"
fi
git -C "$UP" fetch -q origin "$UPSTREAM_COMMIT" 2>/dev/null || git -C "$UP" fetch -q origin
git -C "$UP" reset -q --hard "$UPSTREAM_COMMIT"
git -C "$UP" clean -qfdx -e build
git -C "$UP" apply "$HERE/patches/windows-modern.patch"
step "Patches aplicados (menu com categorias, relógio, bandeja com arrastar e soltar)"

info "Instalando temas, ícones, applets e tela de bloqueio"
for c in themes icons showdesk startmenu digitalclock sessionlock layout lookfeel; do
    step "$c"
    WM_BATCH=1 bash "$UP/scripts/install-$c.sh" >/dev/null
done

# ── 4. bandeja (C++) ─────────────────────────────────────────────────
info "Compilando a bandeja"
TRAY="$UP/plasma/applets/org.kde.windowsmodern.systemtray"
cmake -S "$TRAY" -B "$STATE/build-systray" -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$STATE/build-systray" --parallel "$(nproc)" >/dev/null
QT_PLUGINS=$(pkg-config --variable=plugindir Qt6Core 2>/dev/null || echo /usr/lib64/qt6/plugins)
as_root install -m 755 "$STATE/build-systray/lib/plasma/applets/org.kde.windowsmodern.systemtray.so" "$QT_PLUGINS/plasma/applets/"
as_root rm -rf /usr/share/plasma/plasmoids/org.kde.windowsmodern.systemtray

# ── 5. traduções ─────────────────────────────────────────────────────
info "Traduções dos applets"
for po in "$HERE"/locale/*/startmenu.po; do
    lang=$(basename "$(dirname "$po")")
    mkdir -p "$LOCALE_DIR/$lang/LC_MESSAGES"
    msgfmt -o "$LOCALE_DIR/$lang/LC_MESSAGES/plasma_applet_org.kde.windowsmodern.startmenu.mo" "$po"
done
# o relógio do tema é um fork do relógio do Plasma: usa o catálogo oficial dele
for mo in /usr/share/locale/*/LC_MESSAGES/plasma_applet_org.kde.plasma.digitalclock.mo; do
    lang=$(basename "$(dirname "$(dirname "$mo")")")
    mkdir -p "$LOCALE_DIR/$lang/LC_MESSAGES"
    cp "$mo" "$LOCALE_DIR/$lang/LC_MESSAGES/plasma_applet_org.kde.windowsmodern.digitalclock.mo"
done

# ── 6. arquivos do Windows (fonte de ícones, cursores, sons, Segoe UI) ─
HAVE_FLUENT=0; HAVE_CURSORS=0; HAVE_SOUNDS=0
if [ "$USE_WINDOWS" = 1 ]; then
    [ -n "$WIN_DIR" ] || WIN_DIR=$(find_windows || true)
    if [ -n "$WIN_DIR" ] && [ -d "$WIN_DIR" ]; then
        info "Usando os arquivos do Windows em $WIN_DIR"
        PY=$(venv_python)
        if ! fc-list | grep -q "Segoe UI Variable" && [ -f "$WIN_DIR/Fonts/SegUIVar.ttf" ]; then
            step "Fonte Segoe UI Variable"
            mkdir -p "$HOME/.local/share/fonts/Segoe"
            cp "$WIN_DIR/Fonts/SegUIVar.ttf" "$HOME/.local/share/fonts/Segoe/"
            fc-cache -f >/dev/null
        fi
        if [ -f "$WIN_DIR/Fonts/SegoeIcons.ttf" ]; then
            step "Ícones da bandeja (Segoe Fluent Icons)"
            cp "$WIN_DIR/Fonts/SegoeIcons.ttf" "$STATE/SegoeIcons.ttf"
            "$PY" "$HERE/tools/fluent_icons.py" "$STATE/SegoeIcons.ttf" "$ICONS/windows-modern" "$ICONS/Windows-11-Fluent" >/dev/null && HAVE_FLUENT=1
        fi
        step "Cursores Aero"
        bash "$HERE/tools/windows-cursors.sh" "$WIN_DIR" "$PY" >/dev/null && HAVE_CURSORS=1
        step "Sons"
        bash "$HERE/tools/windows-sounds.sh" "$WIN_DIR" >/dev/null && HAVE_SOUNDS=1
        unmount_windows
    else
        warn "Windows não encontrado: sem ícones Fluent, cursor e sons originais (use --windows <pasta>)."
    fi
fi

# ── 7. tema do Plasma Windows-11-dark ────────────────────────────────
info "Tema do Plasma Windows-11-dark"
bash "$HERE/scripts/make-plasma-theme.sh"

# ── 8. utilitários "Ícones do painel" e "Configurações da barra de tarefas" ─
mkdir -p "$HOME/.local/share/applications"
for t in icones-painel barra-de-tarefas; do
    install -m 755 "$HERE/tools/$t" "$BIN/$t"
    sed "s|@BIN@|$BIN|" "$HERE/data/$t.desktop" > "$HOME/.local/share/applications/$t.desktop"
done
kbuildsycoca6 >/dev/null 2>&1 || true

# ── 9. aplicar ───────────────────────────────────────────────────────
info "Aplicando o visual"
plasma-apply-lookandfeel -a org.kde.windowsmodern.dark --resetLayout >/dev/null
bash "$UP/scripts/set-wallpaper.sh" >/dev/null 2>&1 || true
# plasma-apply-lookandfeel grava o nome do esquema mas pode deixar as cores vazias
plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
plasma-apply-colorscheme WindowsModernDark >/dev/null
plasma-apply-desktoptheme Windows-11-dark >/dev/null
kw --file kdeglobals --group KDE --key widgetStyle kvantum-dark
kw --file kwinrc --group org.kde.kdecoration2 --key BorderSize Tiny
kw --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false

if fc-list | grep -q "Segoe UI Variable"; then
    F='Segoe UI Variable,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular'
    for k in font menuFont toolBarFont; do kw --file kdeglobals --group General --key "$k" "$F"; done
    kw --file kdeglobals --group General --key smallestReadableFont 'Segoe UI Variable,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular'
    kw --file kdeglobals --group WM --key activeFont 'Segoe UI Variable,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular'
fi

ICON_THEME=windows-modern
[ "$HAVE_FLUENT" = 1 ] && ICON_THEME=Windows-11-Fluent
[ -f "$ICONS/Windows-11-Custom/index.theme" ] && ICON_THEME=Windows-11-Custom
/usr/libexec/plasma-changeicons "$ICON_THEME" >/dev/null 2>&1 || kw --file kdeglobals --group Icons --key Theme "$ICON_THEME"
[ "$HAVE_CURSORS" = 1 ] && plasma-apply-cursortheme Windows-11-cursors >/dev/null
if [ "$HAVE_SOUNDS" = 1 ]; then
    kw --file kdeglobals --group Sounds --key Theme Windows-11
    kw --file kdeglobals --group Sounds --key Enable true
fi

# "Sons do sistema": canal próprio (loopback por função) para sons de notificação,
# controlado pela bandeja; vale mesmo quando o app define o próprio volume
mkdir -p "$HOME/.config/wireplumber/wireplumber.conf.d"
cp "$HERE/data/wireplumber-sons-do-sistema.conf" "$HOME/.config/wireplumber/wireplumber.conf.d/60-sons-do-sistema.conf"
systemctl --user restart wireplumber.service 2>/dev/null || true

# acrílico do painel: desfoque forte com granulação
kw --file kwinrc --group Effect-blur --key BlurStrength 15
kw --file kwinrc --group Effect-blur --key NoiseStrength 3
if [ "$ROUNDED" = 1 ] && [ -f "$QT_PLUGINS/kwin/effects/plugins/kwin4_effect_shapecorners.so" ]; then
    while IFS='=' read -r k v; do kw --file kwinrc --group Round-Corners --key "$k" "$v"; done < "$HERE/data/round-corners.conf"
    kw --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled true
fi
qdbus-qt6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
qdbus-qt6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect kwin4_effect_shapecorners >/dev/null 2>&1 || true

# ── 10. painel ───────────────────────────────────────────────────────
info "Configurando o painel"
restart_shell
plasma_eval "var LAUNCHERS = $(printf '%s' "$LAUNCHERS" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))');
$(cat "$HERE/data/panel.js")" >/dev/null
rm -f "$HOME/.cache/icon-cache.kcache"
restart_shell

echo
info "Pronto!"
echo "  • Saia e entre de novo na sessão para a fonte do título das janelas e o cursor pegarem em tudo."
echo "  • Para trocar ícones da bandeja: menu Iniciar → \"Ícones do painel\" (ou botão direito num ícone)."
echo "  • Para voltar ao visual anterior: ./uninstall.sh"

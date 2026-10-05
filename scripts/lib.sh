# shellcheck shell=bash
# Funções comuns do instalador do Plasma W11.

UPSTREAM_URL="https://github.com/Jeysef/KDE-Windows-Modern"
UPSTREAM_COMMIT="7ef6bfe99a472f2fc7fa473383eda50f411a8840"

STATE="${XDG_DATA_HOME:-$HOME/.local/share}/plasma-w11"   # clone, build, venv, backups
ICONS="$HOME/.local/share/icons"
THEMES="$HOME/.local/share/plasma/desktoptheme"
PLASMOIDS="$HOME/.local/share/plasma/plasmoids"
LOCALE_DIR="$HOME/.local/share/locale"
BIN="$HOME/.local/bin"

B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; N=$'\033[0m'
info() { echo "${G}==>${N} ${B}$*${N}"; }
step() { echo "${C}  ->${N} $*"; }
warn() { echo "${Y}==> aviso:${N} $*" >&2; }
die()  { echo "${R}==> erro:${N} $*" >&2; exit 1; }

kw() { kwriteconfig6 "$@"; }
kr() { kreadconfig6 "$@"; }

# sudo: no terminal pede a senha normalmente; fora dele usa o askpass gráfico do KDE.
SUDO_READY=0
need_sudo() {
    [ "$SUDO_READY" = 1 ] && return 0
    if [ -t 0 ]; then
        sudo -v || die "sudo é necessário para este passo."
    else
        export SUDO_ASKPASS="${SUDO_ASKPASS:-/usr/bin/ksshaskpass}"
        sudo -A -v || die "sudo é necessário para este passo."
    fi
    SUDO_READY=1
    # mantém a credencial viva durante a instalação
    ( while kill -0 $$ 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done ) &
}
as_root() { need_sudo; sudo -n "$@"; }

plasma_eval() { qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$1"; }

# O systemd limita a 3 reinícios por minuto e depois desiste (start-limit-hit).
restart_shell() {
    systemctl --user reset-failed plasma-plasmashell.service 2>/dev/null || true
    systemctl --user restart plasma-plasmashell.service
    for _ in $(seq 1 30); do
        qdbus-qt6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break
        sleep 0.5
    done
    sleep 2
}

# Procura uma instalação do Windows (C:\Windows) e imprime o caminho da pasta Windows.
# Partições NTFS desmontadas são montadas só leitura via udisks (sem sudo).
MOUNTED_BY_US=()
find_windows() {
    local dev mp
    for mp in $(findmnt -rn -t ntfs3,ntfs,fuseblk -o TARGET 2>/dev/null); do
        [ -f "$mp/Windows/Fonts/SegoeIcons.ttf" ] && { echo "$mp/Windows"; return 0; }
    done
    for dev in $(lsblk -rpno NAME,FSTYPE | awk '$2=="ntfs"{print $1}'); do
        findmnt -rn "$dev" >/dev/null && continue
        udisksctl mount -b "$dev" -o ro >/dev/null 2>&1 || continue
        mp=$(findmnt -rn -o TARGET "$dev")
        if [ -f "$mp/Windows/Fonts/SegoeIcons.ttf" ]; then
            MOUNTED_BY_US+=("$dev")
            echo "$mp/Windows"
            return 0
        fi
        udisksctl unmount -b "$dev" >/dev/null 2>&1 || true
    done
    return 1
}
unmount_windows() {
    local dev
    for dev in "${MOUNTED_BY_US[@]}"; do udisksctl unmount -b "$dev" >/dev/null 2>&1 || true; done
}

venv_python() {
    if [ ! -x "$STATE/venv/bin/python" ]; then
        step "Criando ambiente Python (win2xcur, fonttools)"
        python3 -m venv "$STATE/venv"
        "$STATE/venv/bin/pip" install -q --disable-pip-version-check win2xcur fonttools
    fi
    echo "$STATE/venv/bin/python"
}

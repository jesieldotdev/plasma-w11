#!/usr/bin/env bash
# Plasma W11 — volta ao visual de antes da instalação.
#
#   ./uninstall.sh            restaura o backup mais recente
#   ./uninstall.sh --purge    restaura e também apaga os arquivos instalados
#                             (temas, ícones, cursor, sons, utilitário, bandeja)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/scripts/lib.sh"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

BK="$STATE/backups/latest"
[ -x "$BK/restore.sh" ] || die "nenhum backup encontrado em $STATE/backups."
info "Restaurando $(readlink -f "$BK")"
bash "$BK/restore.sh"

if [ "$PURGE" = 1 ]; then
    info "Apagando os arquivos instalados"
    UP="$STATE/upstream"
    for c in themes icons; do [ -d "$UP" ] && bash "$UP/uninstall.sh" "$c" >/dev/null 2>&1 || true; done
    for p in org.kde.windowsmodern.startmenu org.kde.windowsmodern.digitalclock org.kde.windowsmodern.showdesktop; do
        kpackagetool6 -t Plasma/Applet -r "$p" >/dev/null 2>&1 || rm -rf "$PLASMOIDS/$p"
    done
    rm -rf "$THEMES/Windows-11-dark" "$ICONS/Windows-11-Fluent" "$ICONS/Windows-11-Custom" \
           "$ICONS/Windows-11-cursors" "$HOME/.local/share/sounds/Windows-11" \
           "$BIN/icones-painel" "$HOME/.local/share/applications/icones-painel.desktop"
    find "$LOCALE_DIR" -name 'plasma_applet_org.kde.windowsmodern.*.mo' -delete 2>/dev/null || true
    QT_PLUGINS=$(pkg-config --variable=plugindir Qt6Core 2>/dev/null || echo /usr/lib64/qt6/plugins)
    as_root rm -f "$QT_PLUGINS/plasma/applets/org.kde.windowsmodern.systemtray.so"
    restart_shell
    echo "Os backups continuam em $STATE/backups (apague à mão se quiser)."
fi
info "Pronto."

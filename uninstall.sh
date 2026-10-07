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
# o estilo dos controles QML deixa de valer na próxima sessão
rm -f "$HOME/.config/plasma-workspace/env/plasma-w11-qml-style.sh"
# cor de destaque: para o serviço e devolve o tema original do Kvantum
systemctl --user disable --now plasma-w11-destaque.service >/dev/null 2>&1 || true
rm -f "$HOME/.config/systemd/user/plasma-w11-destaque.service" "$BIN/acompanhar-destaque"
KV="$HOME/.config/Kvantum"
if [ "$(kreadconfig6 --file "$KV/kvantum.kvconfig" --group General --key theme 2>/dev/null)" = Windows-11 ]; then
    kwriteconfig6 --file "$KV/kvantum.kvconfig" --group General --key theme Windows-modern
fi
rm -rf "$KV/Windows-11"

if [ "$PURGE" = 1 ]; then
    info "Apagando os arquivos instalados"
    UP="$STATE/upstream"
    for c in themes icons; do [ -d "$UP" ] && bash "$UP/uninstall.sh" "$c" >/dev/null 2>&1 || true; done
    for p in org.kde.windowsmodern.startmenu org.kde.windowsmodern.digitalclock org.kde.windowsmodern.showdesktop; do
        kpackagetool6 -t Plasma/Applet -r "$p" >/dev/null 2>&1 || rm -rf "$PLASMOIDS/$p"
    done
    rm -rf "$THEMES/Windows-11-dark" "$ICONS/Windows-11-Fluent" "$ICONS/Windows-11-Custom" \
           "$ICONS/Windows-11-cursors" "$HOME/.local/share/sounds/Windows-11" \
           "$BIN/icones-painel" "$HOME/.local/share/applications/icones-painel.desktop" \
           "$BIN/barra-de-tarefas" "$HOME/.local/share/applications/barra-de-tarefas.desktop" \
           "$HOME/.config/wireplumber/wireplumber.conf.d/60-sons-do-sistema.conf" \
           "$STATE/qml"
    systemctl --user restart wireplumber.service 2>/dev/null || true
    find "$LOCALE_DIR" -name 'plasma_applet_org.kde.windowsmodern.*.mo' -delete 2>/dev/null || true
    QT_PLUGINS=$(qtpaths6 --plugin-dir 2>/dev/null || true)          # pkg-config pode devolver vazio sem erro
    [ -n "$QT_PLUGINS" ] || QT_PLUGINS=$(pkg-config --variable=plugindir Qt6Core 2>/dev/null || true)
    [ -n "$QT_PLUGINS" ] || QT_PLUGINS=/usr/lib64/qt6/plugins
    as_root rm -f "$QT_PLUGINS/plasma/applets/org.kde.windowsmodern.systemtray.so"
    [ -x "$STATE/dolphin-w11/uninstall.sh" ] && bash "$STATE/dolphin-w11/uninstall.sh" || true
    rm -rf "$STATE/dolphin-w11"
    [ -x "$STATE/settings-w11/uninstall.sh" ] && bash "$STATE/settings-w11/uninstall.sh" || true
    rm -rf "$STATE/settings-w11"
    restart_shell
    echo "Os backups continuam em $STATE/backups (apague à mão se quiser)."
fi
info "Pronto."

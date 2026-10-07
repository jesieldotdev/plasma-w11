#!/usr/bin/env bash
# Salva o visual atual em $STATE/backups/<data> e gera restore.sh lá dentro.
set -euo pipefail
source "$(dirname "$0")/lib.sh"

BK="$STATE/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK/config"
info "Salvando o visual atual em $BK"

FILES="kdeglobals kwinrc plasmarc kcminputrc konsolerc plasma-org.kde.plasma.desktop-appletsrc plasmashellrc
kscreenlockerrc kwinrulesrc ksplashrc gtkrc gtkrc-2.0 xsettingsd kded6rc kded_device_automounterrc"
DIRS="Kvantum gtk-3.0 gtk-4.0 kdedefaults"
for f in $FILES; do [ -e "$HOME/.config/$f" ] && cp -a "$HOME/.config/$f" "$BK/config/"; done
for d in $DIRS; do [ -d "$HOME/.config/$d" ] && cp -a "$HOME/.config/$d" "$BK/config/"; done
[ -e "$HOME/.gtkrc-2.0" ] && cp -a "$HOME/.gtkrc-2.0" "$BK/dot-gtkrc-2.0"
# a tela de bloqueio do tema é um overlay do shell do Plasma; anota se já existia
[ -d "$HOME/.local/share/plasma/shells/org.kde.plasma.desktop" ] && touch "$BK/had-shell-overlay"

COLORS=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)
CURSOR=$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme)
ROUNDED=$(kreadconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled)

cat > "$BK/restore.sh" <<EOF
#!/usr/bin/env bash
# Volta ao visual salvo em $(date '+%F %R').
set -e
BK="$BK"
for f in $FILES; do
  [ -e "\$BK/config/\$f" ] && cp -a "\$BK/config/\$f" "\$HOME/.config/"
done
for d in $DIRS; do
  [ -d "\$BK/config/\$d" ] && { rm -rf "\$HOME/.config/\$d"; cp -a "\$BK/config/\$d" "\$HOME/.config/"; }
done
[ -e "\$BK/dot-gtkrc-2.0" ] && cp -a "\$BK/dot-gtkrc-2.0" "\$HOME/.gtkrc-2.0"
[ -e "\$BK/had-shell-overlay" ] || rm -rf "\$HOME/.local/share/plasma/shells/org.kde.plasma.desktop"
# kdeglobals já traz o esquema de cores, mas o Plasma só reaplica as cores assim:
plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
[ -n "$COLORS" ] && plasma-apply-colorscheme "$COLORS" >/dev/null 2>&1 || true
[ -n "$CURSOR" ] && plasma-apply-cursortheme "$CURSOR" >/dev/null 2>&1 || true
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled "${ROUNDED:-false}"
qdbus-qt6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
systemctl --user reset-failed plasma-plasmashell.service 2>/dev/null || true
systemctl --user restart plasma-plasmashell.service
echo "Visual anterior restaurado. Feche e reabra os apps (ou saia e entre na sessão)."
EOF
chmod +x "$BK/restore.sh"
ln -sfn "$BK" "$STATE/backups/latest"

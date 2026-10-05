#!/usr/bin/env bash
# Monta um tema de sons freedesktop com os sons originais do Windows 11 (C:\Windows\Media).
# Uso: windows-sounds.sh <pasta Windows> [destino]
set -euo pipefail
WIN="$1"; OUT="${2:-$HOME/.local/share/sounds/Windows-11}"
SRC="$WIN/Media"
[ -d "$SRC" ] || { echo "Pasta de sons não encontrada: $SRC" >&2; exit 1; }

rm -rf "$OUT"; mkdir -p "$OUT/stereo"
cat > "$OUT/index.theme" <<'EOF'
[Sound Theme]
Name=Windows 11
Comment=Sons originais do Windows 11
Inherits=ocean,freedesktop
Directories=stereo

[stereo]
OutputProfile=stereo
EOF

# evento freedesktop <- som do esquema padrão do Windows 11
while IFS='|' read -r event file; do
    [ -f "$SRC/$file.wav" ] && cp "$SRC/$file.wav" "$OUT/stereo/$event.wav"
done <<'EOF'
bell|Windows Background
bell-window-system|Windows Background
audio-volume-change|Windows Background
dialog-information|Windows Background
dialog-warning|Windows Background
dialog-question|Windows Background
dialog-error|Windows Foreground
message|Windows Notify System Generic
message-highlight|Windows Notify System Generic
complete|Windows Notify System Generic
message-new-instant|Windows Notify Messaging
message-new-email|Windows Notify Email
alarm-clock-elapsed|Windows Notify Calendar
device-added|Windows Hardware Insert
device-removed|Windows Hardware Remove
device-fail|Windows Hardware Fail
power-plug|Windows Hardware Insert
power-unplug|Windows Hardware Remove
battery-low|Windows Battery Low
battery-caution|Windows Battery Critical
desktop-login|Windows Logon
desktop-logout|Windows Logoff Sound
theme-demo|Windows Logon
trash-empty|Windows Recycle
printer-complete|Windows Print complete
EOF
echo "$OUT"

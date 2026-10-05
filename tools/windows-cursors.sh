#!/usr/bin/env bash
# Converte os cursores Aero originais do Windows 11 (C:\Windows\Cursors) para Xcursor.
# Uso: windows-cursors.sh <pasta Windows> <venv python> [destino]
set -euo pipefail
WIN="$1"; PY="$2"; OUT="${3:-$HOME/.local/share/icons/Windows-11-cursors}"
SRC="$WIN/Cursors"
[ -d "$SRC" ] || { echo "Pasta de cursores não encontrada: $SRC" >&2; exit 1; }
W2X="$(dirname "$PY")/win2xcur"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# nome do tema <- arquivo do Windows (cada .cur já traz 32 a 128 px)
declare -A MAP=(
    [arrow]=aero_arrow.cur [help]=aero_helpsel.cur [appstarting]=aero_working.ani [wait]=aero_busy.ani
    [crosshair]=cross_r.cur [ibeam]=beam_r.cur [nwpen]=aero_pen.cur [no]=aero_unavail.cur
    [sizens]=aero_ns.cur [sizewe]=aero_ew.cur [sizenwse]=aero_nwse.cur [sizenesw]=aero_nesw.cur
    [sizeall]=aero_move.cur [uparrow]=aero_up.cur [hand]=aero_link.cur [pin]=aero_pin.cur [person]=aero_person.cur
)
files=()
for f in "${MAP[@]}"; do [ -f "$SRC/$f" ] && files+=("$SRC/$f"); done
"$W2X" "${files[@]}" -o "$TMP" >/dev/null

rm -rf "$OUT"; mkdir -p "$OUT/cursors"; cd "$OUT/cursors"
for name in "${!MAP[@]}"; do
    f="${MAP[$name]%.*}"
    [ -f "$TMP/$f" ] && install -m 644 "$TMP/$f" "$name"
done

# apelidos X11/CSS -> cursor
L() { local t=$1; shift; [ -e "$t" ] || return 0; for n in "$@"; do [ -e "$n" ] || ln -s "$t" "$n"; done; }
L arrow default left_ptr top_left_arrow left-arrow right_ptr context-menu
L hand pointer hand1 hand2 pointing_hand openhand closedhand grab grabbing dnd-move dnd-none 9d800788f1b08800ae810202380a0822 e29285e634086352946a0e7090d73106
L ibeam text xterm vertical-text
L wait watch
L appstarting progress left_ptr_watch half-busy 08e8e1c95fe2fc01f976f1e063a24ccd 3ecb610c1bf2410f44200f48c40d3599
L help question_arrow whats_this d9ce0ab605698f320427677b458ad60b 5c6cd98b3f3ebcb1f9c7f1c204630408
L crosshair cross tcross cell plus color-picker
L no not-allowed forbidden circle crossed_circle no-drop 03b6e0fcb3499374a867c041f52298f0
L sizens ns-resize n-resize s-resize row-resize size_ver v_double_arrow sb_v_double_arrow top_side bottom_side split_v 00008160000006810000408080010102
L sizewe ew-resize e-resize w-resize col-resize size_hor h_double_arrow sb_h_double_arrow left_side right_side split_h 028006030e0e7ebffc7f7070c0600140
L sizenwse nwse-resize nw-resize se-resize size_fdiag bd_double_arrow top_left_corner bottom_right_corner c7088f0f3e6c8088236ef8e1e3e70000
L sizenesw nesw-resize ne-resize sw-resize size_bdiag fd_double_arrow top_right_corner bottom_left_corner fcf1c3c7cd4491d801f1e1c78f100000
L sizeall move all-scroll fleur size_all 4498f0e0c1937ffe01fd06f973665830 9081237383d90e509aa00f00170e968f
L uparrow up-arrow center_ptr up_arrow sb_up_arrow
L nwpen pencil draft
L pin alias link copy dnd-link dnd-copy 3085a0e285430894940527032f8b26df 640fb0e74195791501fd1ed57b41487f 1081e37283d90000800003c07f3ef6bf 6407b0e94181790501fd1e167b474872

cat > "$OUT/index.theme" <<'EOF'
[Icon Theme]
Name=Windows 11 Cursors
Comment=Cursores Aero originais do Windows 11, convertidos com win2xcur
EOF
echo "$OUT"

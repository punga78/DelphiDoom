#!/bin/sh
# Builds the parity driver of the issue #125 (Team Arena menus) with the gcc of w64devkit.
#   build.sh [output folder]
# Nothing of Quake III is retyped. The driver compiles, unchanged:
#   code/ui/ui_shared.c              the menu / item parser, Item_RunScript and its handlers
#   code/botlib/l_script.c, l_precomp.c, l_memory.c   the precompiler behind the trap_PC_* calls
#   code/game/q_shared.c, q_math.c   Q_stricmp, COM_ParseExt, va ...
# and two files of line ranges cut out of the sources (read only):
#   ui_main_original.inc     Asset_Parse, UI_ParseMenu, Load_Menu, UI_LoadMenus of code/ui/ui_main.c
#   tr_font_original.inc     readInt/readFloat and RE_RegisterFont (the .dat branch; BUILD_FREETYPE is off
#                            as in the shipped renderer) of code/renderer/tr_font.c
# -mlong-double-64: the token values of l_script.c are long double; MSVC, which built the original
# game, has a 64 bit long double. -ffp-contract=off keeps each float operation rounded on its own.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
rng() { # rng <file> <first function line pattern> <next function line pattern>
  A=$(grep -n "$2" "$1" | head -1 | cut -d: -f1)
  B=$(grep -n "$3" "$1" | head -1 | cut -d: -f1)
  sed -n "${A},$((B - 1))p" "$1"
}
{
  rng "$CODE/ui/ui_main.c" '^qboolean Asset_Parse' '^void Font_Report'
  rng "$CODE/ui/ui_main.c" '^void UI_ParseMenu' '^void UI_Load()'
} > "$OUT/ui_main_original.inc"
{
  sed -n '/^static int fdOffset;/,/^void R_InitFreeType/p' "$CODE/renderer/tr_font.c" | sed '$d'
} > "$OUT/tr_font_original.inc"
# the registered font table of tr_font.c has to be declared before RE_RegisterFont
{
  echo '#define MAX_FONTS 6'
  echo 'static int registeredFontCount = 0;'
  echo 'static fontInfo_t registeredFont[MAX_FONTS];'
  cat "$OUT/tr_font_original.inc"
} > "$OUT/tr_font_original2.inc"
mv "$OUT/tr_font_original2.inc" "$OUT/tr_font_original.inc"
cp "$HERE/stubs.c" "$HERE/uiparse.c" "$OUT/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -mlong-double-64 -std=gnu89 -DBOTLIB -DMISSIONPACK \
  -I"$OUT" -I"$CODE/ui" -I"$CODE/game" -I"$CODE/botlib" \
  -o "$OUT/uiparse.exe" \
  "$OUT/uiparse.c" "$OUT/stubs.c" "$CODE/ui/ui_shared.c" \
  "$CODE/botlib/l_script.c" "$CODE/botlib/l_precomp.c" "$CODE/botlib/l_memory.c" \
  "$CODE/game/q_shared.c" -lm
echo "built in $OUT"

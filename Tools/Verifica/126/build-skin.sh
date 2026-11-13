#!/bin/sh
# Builds the parity driver of the skins and of the files of a player model (issue #126, second slice).
#   build-skin.sh [output folder]
# Compiles, unchanged, line ranges of (read only):
#   renderer/tr_image.c  CommaParse, RE_RegisterSkin, R_InitSkins, R_GetSkinByHandle
#   cgame/cg_players.c   CG_FileExists, CG_FindClientModelFile, CG_FindClientHeadFile
#   game/q_shared.c      the whole file (Com_sprintf, Q_strncpyz, Q_strlwr, Q_stricmp)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
A=$(grep -n '^static char \*CommaParse' "$CODE/renderer/tr_image.c" | head -1 | cut -d: -f1)
B=$(grep -n '^void.R_SkinList_f' "$CODE/renderer/tr_image.c" | head -1 | cut -d: -f1)
sed -n "${A},$((B - 6))p" "$CODE/renderer/tr_image.c" > "$OUT/skin_original.inc"
A=$(grep -n '^static qboolean.CG_FileExists' "$CODE/cgame/cg_players.c" | head -1 | cut -d: -f1)
B=$(grep -n '^static qboolean.CG_RegisterClientSkin' "$CODE/cgame/cg_players.c" | head -1 | cut -d: -f1)
sed -n "${A},$((B - 6))p" "$CODE/cgame/cg_players.c" > "$OUT/finder_original.inc"
{ sed -n "97,110p;544,551p" "$CODE/game/bg_public.h"; } > "$OUT/types_original.inc"
cp "$HERE/stubs.h" "$HERE/q3skin.c" "$OUT/"
"$KIT/gcc.exe" -O1 -w -std=gnu89 \
  -I"$OUT" -I"$CODE/game" -I"$CODE/qcommon" \
  -o "$OUT/q3skin.exe" "$OUT/q3skin.c" "$CODE/game/q_shared.c" -lm
echo "built in $OUT"

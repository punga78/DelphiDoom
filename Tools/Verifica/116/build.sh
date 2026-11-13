#!/bin/sh
# Builds the parity tool of the issue #116 (BSP of Quake III Arena) with the gcc of w64devkit,
# writes the BSPs it needs and the golden file.
#   build.sh [output folder]
# The algorithms are not retyped: bsp_original.inc is made of line ranges of
# Reference/quake3/code/qcommon/qfiles.h (the BSP structs), renderer/tr_local.h (srfGridMesh_t),
# game/q_shared.h and q_math.c (vector functions) and renderer/tr_curve.c; bsp_world.inc of
# renderer/tr_bsp.c (R_ColorShiftLightingBytes, ParseMesh, R_MergedWidthPoints ..
# R_StitchAllPatches, R_FixSharedVertexLodError). All read only. -ffp-contract=off keeps every
# float operation rounded on its own, as the 32 bit float code of the original assumes.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
BSP=$CODE/renderer/tr_bsp.c
line() { grep -n "$1" "$2" | head -1 | cut -d: -f1; }
{
  sed -n '36p;312p;315p' "$CODE/qcommon/qfiles.h"
  FIRST=$(( $(line 'fileofs, filelen' "$CODE/qcommon/qfiles.h") - 1 ))
  LAST=$(line '} dsurface_t;' "$CODE/qcommon/qfiles.h")
  sed -n "${FIRST},${LAST}p" "$CODE/qcommon/qfiles.h"
  sed -n '569,593p' "$CODE/renderer/tr_local.h"
  sed -n '672,678p;713,717p' "$CODE/game/q_shared.h"
  sed -n '1065,1135p' "$CODE/game/q_math.c"
  START=$(line '^static void LerpDrawVert' "$CODE/renderer/tr_curve.c")
  sed -n "${START},\$p" "$CODE/renderer/tr_curve.c"
} > "$OUT/bsp_original.inc"
{
  sed -n "$(line '^static.*void R_ColorShiftLightingBytes' "$BSP"),126p" "$BSP"
  PARSE=$(line '^static void ParseMesh' "$BSP")
  TRISURF=$(line '^static void ParseTriSurf' "$BSP")
  sed -n "${PARSE},$((TRISURF - 6))p" "$BSP"
  MERGED=$(line '^int R_MergedWidthPoints' "$BSP")
  MOVE=$(line '^R_MovePatchSurfacesToHunk' "$BSP")
  sed -n "$((MERGED - 7)),$((MOVE - 3))p" "$BSP"
} > "$OUT/bsp_world.inc"
# second slice: the loaders of lightmaps, light grid and nodes (R_LoadLightmaps, R_LoadLightGrid,
# R_SetParent, R_LoadNodesAndLeafs), also cut out of tr_bsp.c: a block ends at its first "}" in column 0
block() { awk -v s="$1" 'NR>=s { print } NR>=s && /^}/ { exit }' "$BSP"; }
{
  H=$(line '^static void HSVtoRGB' "$BSP")
  block "$H"
  L=$(line '^#define.LIGHTMAP_SIZE' "$BSP")
  sed -n "${L}p" "$BSP"
  block "$(line '^static.void R_LoadLightmaps' "$BSP")"
  block "$(line 'R_SetParent (mnode_t' "$BSP")"
  block "$(line 'R_LoadNodesAndLeafs (lump_t' "$BSP")"
  block "$(line '^void R_LoadLightGrid' "$BSP")"
} > "$OUT/bsp_load.inc"
sed -n '664,688p' "$CODE/renderer/tr_local.h" > "$OUT/bsp_nodes.inc"
cp "$HERE/stubs.h" "$HERE/bspgen.c" "$OUT/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -o "$OUT/bspgen.exe" "$OUT/bspgen.c" -lm
echo "built in $OUT"

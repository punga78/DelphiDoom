#!/bin/sh
# Builds the parity tool of the issue #117 (patch subdivision) with the gcc of w64devkit.
#   build.sh [output folder]
# The algorithm is not retyped: grid_original.inc is made of line ranges of
# Reference/quake3/code/renderer/tr_curve.c, code/game/q_shared.h (inline vector
# functions) and q_math.c (ClearBounds .. VectorNormalize2), plus the structs of
# qfiles.h and tr_local.h (all read only). -ffp-contract=off keeps every float
# operation rounded on its own, as the 32 bit float code of the original assumes.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"
{
  sed -n '449,455p' "$CODE/qcommon/qfiles.h"
  sed -n '569,593p' "$CODE/renderer/tr_local.h"
  sed -n '672,678p;713,717p' "$CODE/game/q_shared.h"
  sed -n '1065,1135p' "$CODE/game/q_math.c"
  START=$(grep -n '^static void LerpDrawVert' "$CODE/renderer/tr_curve.c" | cut -d: -f1)
  sed -n "${START},\$p" "$CODE/renderer/tr_curve.c"
} > "$OUT/grid_original.inc"
cp "$HERE/stubs.h" "$HERE/gridgen.c" "$OUT/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -o "$OUT/gridgen.exe" "$OUT/gridgen.c" -lm
echo "built in $OUT"

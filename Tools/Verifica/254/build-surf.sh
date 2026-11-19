#!/bin/sh
# Builds surfgen.exe (issue #254, renderer phase R1b) and writes the golden of the surface functions:
#   build-surf.sh <work folder> <cases.txt> [map.bsp] > Tests/Data/Q3Render/surf.golden.txt
# renderer/tr_surface.c and renderer/tr_curve.c of Quake III are compiled as they are (surfgen.c includes tr_bsp.c for
# ParseMesh, R_StitchAllPatches and R_FixSharedVertexLodError) with game/q_math.c and q_shared.c. gcc of w64devkit, 32 bit
# with SSE (-mfpmath=sse, no contraction), -D__STRICT_ANSI__ for M_PI as a float (see build-front.sh). Paths absolute.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
CASES=$2
MAP=$3
mkdir -p "$OUT"
cd "$OUT"
"$KIT/gcc" -m32 -msse2 -mfpmath=sse -ffp-contract=off -O0 -fwrapv -w -std=gnu99 -D__STRICT_ANSI__ -DWIN32 -D_WIN32 -DC_ONLY -I"$CODE/renderer" \
  -o surfgen.exe "$HERE/surfgen.c" "$CODE/renderer/tr_surface.c" "$CODE/renderer/tr_curve.c" "$CODE/game/q_math.c" \
  "$CODE/game/q_shared.c" -lm
./surfgen.exe "$CASES" $MAP

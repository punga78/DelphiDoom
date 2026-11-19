#!/bin/sh
# Builds surfgen.exe (issue #254, renderer phase R1b) and writes the golden of the surface functions:
#   build-surf.sh <work folder> <cases.txt> [map.bsp] > Tests/Data/Q3Render/surf.golden.txt
# renderer/tr_surface.c, tr_curve.c, tr_shade_calc.c and tr_noise.c of Quake III are compiled as they are, surfgen.c
# includes tr_bsp.c (ParseMesh, R_StitchAllPatches, R_FixSharedVertexLodError), tr_sky.c and tr_shade.c (so
# ProjectDlightTexture and RB_FogPass of the shading file run for real) with game/q_math.c and q_shared.c. The only
# change to an original is tr_shade_calc.c: the 32 bit x86 assembler of myftol is cut out (surfgen.c has the C one, a
# truncation). gcc of w64devkit, 32 bit with SSE (-mfpmath=sse, no contraction), -D__STRICT_ANSI__ for M_PI as a
# float (see build-front.sh). Paths absolute.
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
awk '/^#if id386 && !\( \(defined __linux__/ { skip = 1 } skip && /^#endif/ { skip = 0; next } !skip' "$CODE/renderer/tr_shade_calc.c" > tr_shade_calc_c.c
"$KIT/gcc" -m32 -msse2 -mfpmath=sse -ffp-contract=off -O0 -fwrapv -w -std=gnu99 -D__STRICT_ANSI__ -DWIN32 -D_WIN32 -DC_ONLY -I"$CODE/renderer" \
  -o surfgen.exe "$HERE/surfgen.c" "$CODE/renderer/tr_surface.c" "$CODE/renderer/tr_curve.c" tr_shade_calc_c.c \
  "$CODE/renderer/tr_noise.c" "$CODE/game/q_math.c" "$CODE/game/q_shared.c" -lm
./surfgen.exe "$CASES" $MAP

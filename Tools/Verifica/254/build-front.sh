#!/bin/sh
# Builds frontgen.exe (issue #254, renderer phase R1) and writes the golden of the front end:
#   build-front.sh <work folder> <map.bsp> <views.txt> > Tests/Data/Q3Render/front.golden.txt
# renderer/tr_main.c and renderer/tr_world.c of Quake III are compiled as they are, with game/q_math.c; frontgen.c
# loads the BSP and gives them the rest of the renderer (see its comment). gcc of w64devkit, 32 bit with SSE
# (-mfpmath=sse, no contraction): every float operation is rounded to a float, as the Delphi port does.
# -D__STRICT_ANSI__ keeps math.h of mingw from redefining M_PI as a double after q_shared.h made it a float constant:
# the original (MSVC) has the float one, and the angle of the frustum and of the projection depends on it.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
MAP=$2
VIEWS=$3
mkdir -p "$OUT"
cd "$OUT"
"$KIT/gcc" -m32 -msse2 -mfpmath=sse -ffp-contract=off -O0 -fwrapv -w -std=gnu99 -D__STRICT_ANSI__ -DWIN32 -D_WIN32 -DC_ONLY -I"$CODE/renderer" \
  -o frontgen.exe "$HERE/frontgen.c" "$CODE/renderer/tr_main.c" "$CODE/renderer/tr_world.c" "$CODE/game/q_math.c" \
  "$CODE/game/q_shared.c"
./frontgen.exe "$MAP" "$VIEWS"

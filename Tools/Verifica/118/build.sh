#!/bin/sh
# Builds the parity tool of the issue #118 (collision model of Quake III Arena) with the gcc of
# w64devkit and writes the golden file and the sample BSPs.
#   build.sh [output folder]
# The algorithms are not retyped: the folder qcommon/ of the output is made of COPIES of
# cm_load.c, cm_test.c, cm_trace.c, cm_local.h, cm_polylib.h, cm_public.h of
# Reference/quake3/code/qcommon (read only), plus qcommon.h (stub) and game/q_shared.h (wrapper
# of the real one, with the float M_PI that MSVC gets). game/q_math.c is copied there too, so that it
# includes that wrapper, and compiled as it is.
# cm_patch.c and cm_polylib.c are compiled as they are too (the patch collision of the issue #118).
# -ffp-contract=off keeps every float operation rounded
# on its own, as the 32 bit float code of the original assumes.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT/qcommon" "$OUT/game"
for f in cm_load.c cm_test.c cm_trace.c cm_patch.c cm_polylib.c cm_patch.h cm_local.h cm_polylib.h cm_public.h; do
  cp "$CODE/qcommon/$f" "$OUT/qcommon/$f"
done
# the path as gcc wants it (C:/...): cygpath if there is one, else DELPHIDOOM_ROOT has to be written that way
CODE_MIXED=$(cygpath -m "$CODE" 2>/dev/null || echo "$CODE")
cp "$CODE/qcommon/qfiles.h" "$OUT/qcommon/qfiles.h"
cp "$HERE/qcommon.h" "$OUT/qcommon/qcommon.h"
cat > "$OUT/game/q_shared.h" <<EOF
/* wrapper: the real q_shared.h, with the float M_PI that q_shared.h defines when math.h has none */
#include <math.h>
#undef M_PI
#include "$CODE_MIXED/game/q_shared.h"
EOF
cp "$CODE/game/q_math.c" "$OUT/game/q_math.c"
cp "$HERE/stubs.c" "$HERE/cmgen.c" "$OUT/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -DC_ONLY -DNDEBUG -I"$OUT" -I"$CODE/game" -o "$OUT/cmgen.exe" \
  "$OUT/cmgen.c" "$OUT/stubs.c" "$OUT/qcommon/cm_load.c" "$OUT/qcommon/cm_test.c" \
  "$OUT/qcommon/cm_trace.c" "$OUT/qcommon/cm_patch.c" "$OUT/qcommon/cm_polylib.c" "$OUT/game/q_math.c" -lm
echo "built in $OUT"

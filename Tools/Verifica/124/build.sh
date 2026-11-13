#!/bin/sh
# Builds the parity tool of the issue #124 (bot chat of Quake III Arena) with the gcc of w64devkit.
#   build.sh [output folder]
# The algorithms are not retyped: the REAL code/botlib/be_ai_chat.c, l_script.c and l_precomp.c (and
# their headers, and game/be_ai_chat.h) are copied unchanged into <out>/work, together with the
# lines 315-381 of code/game/q_shared.c (COM_Compress, which LoadScriptFile applies to every file);
# stub/ replaces everything else (q_shared.h, botlib.h, the memory, the library variables, the log).
# Reference/quake3 is read only.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
WORK=$OUT/work
mkdir -p "$WORK/botlib" "$WORK/game"
cp "$HERE/stub/game/"*.h "$WORK/game/"
cp "$HERE/stub/botlib/"*.h "$WORK/botlib/"
cp "$CODE/game/be_ai_chat.h" "$WORK/game/"
for f in be_ai_chat.c l_script.c l_script.h l_precomp.c l_precomp.h; do cp "$CODE/botlib/$f" "$WORK/botlib/"; done
sed -n '315,381p' "$CODE/game/q_shared.c" > "$WORK/comcompress.inc"
cp "$HERE/chatgen.c" "$WORK/"
# -ffp-contract=off: every float operation is rounded on its own
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -D_USE_32BIT_TIME_T -Wno-error=incompatible-pointer-types -DBOTLIB -I"$WORK" -I"$WORK/botlib" \
  -o "$OUT/chatgen.exe" "$WORK/chatgen.c" "$WORK/botlib/l_script.c" "$WORK/botlib/l_precomp.c" -lm
echo "built in $OUT"

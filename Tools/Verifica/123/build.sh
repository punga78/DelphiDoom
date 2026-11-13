#!/bin/sh
# Builds the parity tool of the issue #123 (characters, fuzzy weights and weapons of the bots of Quake III
# Arena) with the gcc of w64devkit.
#   build.sh [output folder]
# The algorithms are not retyped: the REAL code/botlib/be_ai_char.c, be_ai_weight.c, be_ai_weap.c,
# l_struct.c, l_libvar.c, l_script.c and l_precomp.c (and their headers, and game/be_ai_char.h and
# game/be_ai_weap.h) are copied into <out>/work, together with the lines 315-381 of code/game/q_shared.c
# (COM_Compress, which LoadScriptFile applies to every file). Two things are added to the copies and nothing
# else: include guards around every header (the headers of the original have none and the three .c files are
# one translation unit in botgen.c), and in be_ai_weap.c the macros WEAPON_OFS/PROJECTILE_OFS, which cast a
# pointer to int, are written with offsetof (a 64 bit compiler does not accept the cast in an initializer; the
# value is the same). stub/ replaces everything else (q_shared.h, botlib.h, the memory, the log).
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
guard() {
  # guard <source> <destination>
  name=$(basename "$1" | tr '.a-z' '_A-Z')
  { echo "#ifndef REAL_$name"; echo "#define REAL_$name"; cat "$1"; echo; echo "#endif"; } > "$2"
}
for f in be_ai_weight.h l_struct.h l_libvar.h l_script.h l_precomp.h l_utils.h; do guard "$CODE/botlib/$f" "$WORK/botlib/$f"; done
for f in be_ai_char.h be_ai_weap.h; do guard "$CODE/game/$f" "$WORK/game/$f"; done
for f in be_ai_char.c be_ai_weight.c be_ai_weap.c l_struct.c l_libvar.c l_script.c l_precomp.c; do cp "$CODE/botlib/$f" "$WORK/botlib/"; done
# offsetof in the two macros (the only change of a .c file)
sed -i 's/#define WEAPON_OFS(x) .*/#define WEAPON_OFS(x) ((int)offsetof(weaponinfo_t, x))/; s/#define PROJECTILE_OFS(x) .*/#define PROJECTILE_OFS(x) ((int)offsetof(projectileinfo_t, x))/' "$WORK/botlib/be_ai_weap.c"
sed -i 's/#include "..\/game\/q_shared.h"/#include "..\/game\/q_shared.h"\n#include <stddef.h>/' "$WORK/botlib/be_ai_weap.c"
sed -n '315,381p' "$CODE/game/q_shared.c" > "$WORK/comcompress.inc"
cp "$HERE/botgen.c" "$WORK/"
# -ffp-contract=off: every float operation is rounded on its own
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -D_USE_32BIT_TIME_T -Wno-error=incompatible-pointer-types -DBOTLIB -I"$WORK" -I"$WORK/botlib" \
  -o "$OUT/botgen.exe" "$WORK/botgen.c" "$WORK/botlib/l_struct.c" "$WORK/botlib/l_libvar.c" \
  "$WORK/botlib/l_script.c" "$WORK/botlib/l_precomp.c" -lm
echo "built in $OUT"

#!/bin/sh
# Builds the parity tool of the issue #122 (AAS of Quake III Arena) with the gcc of w64devkit.
#   build.sh [output folder]
# The algorithms are not retyped: the REAL code/botlib/be_aas_file.c and be_aas_sample.c are copied
# unchanged (with aasfile.h) and compiled by aasgen.c, together with line ranges of
#   game/be_aas.h (aas_trace_t, aas_areainfo_t), game/q_math.c (VectorLength, VectorNormalize),
#   botlib/be_aas_main.c (AAS_Error) and botlib/be_aas_reach.c (AAS_AreaReachability and the
#   area predicates AAS_AreaSwim ... AAS_AreaDoNotEnter).
# stub/ replaces everything else. Reference/quake3 is read only.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
WORK=$OUT/work
mkdir -p "$WORK/botlib" "$WORK/game"
cp "$HERE/stub/game/q_shared.h" "$HERE/stub/game/botlib.h" "$WORK/game/"
for f in be_aas_def.h be_aas_funcs.h be_interface.h l_memory.h l_libvar.h l_script.h; do
  cp "$HERE/stub/botlib/$f" "$WORK/botlib/"
done
for f in l_precomp.h l_struct.h l_utils.h; do cp "$HERE/stub/botlib/l_script.h" "$WORK/botlib/$f"; done
for f in be_aas_file.c be_aas_sample.c; do cp "$CODE/botlib/$f" "$WORK/botlib/"; done
# include guards (the real header has none and two of the files include it)
{ echo "#ifndef AASFILE_GUARD"; echo "#define AASFILE_GUARD"; cat "$CODE/botlib/aasfile.h"; echo "#endif"; } > "$WORK/botlib/aasfile.h"
line() { grep -n "$1" "$2" | head -1 | cut -d: -f1; }
{
  sed -n "$(line '^typedef struct aas_trace_s' "$CODE/game/be_aas.h"),$(line '} aas_trace_t;' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
  sed -n "$(line '^typedef struct aas_areainfo_s' "$CODE/game/be_aas.h"),$(line '} aas_areainfo_t;' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
} > "$WORK/game/be_aas.h.tmp"
{ echo "#ifndef BEAAS_GUARD"; echo "#define BEAAS_GUARD"; cat "$WORK/game/be_aas.h.tmp"; echo "#endif"; } > "$WORK/game/be_aas.h"
{
  sed -n "$(line '^vec_t VectorLength' "$CODE/game/q_math.c"),$(( $(line '^vec_t VectorLength' "$CODE/game/q_math.c") + 2 ))p" "$CODE/game/q_math.c"
  START=$(line '^vec_t VectorNormalize( vec3_t v )' "$CODE/game/q_math.c")
  sed -n "${START},$(( START + 15 ))p" "$CODE/game/q_math.c"
} > "$WORK/vmath.inc"
sed -n "$(line '^void QDECL AAS_Error' "$CODE/botlib/be_aas_main.c"),$(( $(line '^void QDECL AAS_Error' "$CODE/botlib/be_aas_main.c") + 9 ))p" "$CODE/botlib/be_aas_main.c" > "$WORK/aaserror.inc"
{
  R=$CODE/botlib/be_aas_reach.c
  sed -n "$(line '^int AAS_AreaReachability' "$R"),$(( $(line '^int AAS_AreaReachability' "$R") + 8 ))p" "$R"
  S=$(line '^int AAS_AreaSwim' "$R")
  E=$(line '^int AAS_AreaDoNotEnter' "$R")
  sed -n "${S},$(( E + 3 ))p" "$R"
} > "$WORK/areareach.inc"
cp "$HERE/aasgen.c" "$WORK/"
# -ffp-contract=off: every float operation is rounded on its own, as the SSE code of the original
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -DBOTLIB -I"$WORK" -I"$WORK/botlib" -o "$OUT/aasgen.exe" "$WORK/aasgen.c" -lm
echo "built in $OUT"

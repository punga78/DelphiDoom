#!/bin/sh
# Builds the parity tool of the clustering and of the optimizer of Quake III Arena (issue #122) with the gcc of w64devkit.
#   build.sh [output folder]
# The REAL code/botlib/be_aas_file.c, be_aas_sample.c, be_aas_cluster.c and be_aas_optimize.c are copied UNCHANGED (with
# aasfile.h) and compiled by clustergen.c, together with line ranges of game/be_aas.h, game/q_math.c, botlib/be_aas_main.c
# (AAS_Error) and botlib/be_aas_reach.c (AAS_AreaReachability and the area predicates). ../stub/, ../route/stub/ and
# the lines below replace everything else. Reference/quake3 is read only.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
PARENT=$(cd "$HERE/.." && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
WORK=$OUT/work
mkdir -p "$WORK/botlib" "$WORK/game"
cp "$PARENT/stub/game/q_shared.h" "$PARENT/stub/game/botlib.h" "$WORK/game/"
for f in be_aas_funcs.h be_interface.h l_memory.h l_libvar.h l_script.h; do
  cp "$PARENT/stub/botlib/$f" "$WORK/botlib/"
done
cp "$PARENT/route/stub/botlib/be_aas_def.h" "$WORK/botlib/"
for f in l_precomp.h l_struct.h l_utils.h; do cp "$PARENT/stub/botlib/l_script.h" "$WORK/botlib/$f"; done
echo "unsigned short CRC_ProcessString(unsigned char *data, int length);" > "$WORK/botlib/l_crc.h"
echo "void QDECL Log_Write(char *fmt, ...);" > "$WORK/botlib/l_log.h"
for f in be_aas_file.c be_aas_sample.c be_aas_cluster.c be_aas_optimize.c; do cp "$CODE/botlib/$f" "$WORK/botlib/"; done
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
  sed -n "$(line '^int AAS_AreaCrouch' "$R"),$(( $(line '^int AAS_AreaCrouch' "$R") + 4 ))p" "$R"
  S=$(line '^int AAS_AreaSwim' "$R")
  E=$(line '^int AAS_AreaDoNotEnter' "$R")
  sed -n "${S},$(( E + 3 ))p" "$R"
} > "$WORK/areareach.inc"
cp "$HERE/clustergen.c" "$WORK/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -DBOTLIB -I"$WORK" -I"$WORK/botlib" -o "$OUT/clustergen.exe" "$WORK/clustergen.c" -lm
echo "built in $OUT"

#!/bin/sh
# Builds the parity tool of the reachabilities of Quake III Arena (issue #122) with the gcc of w64devkit.
#   build.sh [output folder]
# The REAL code/botlib/be_aas_file.c, be_aas_sample.c, be_aas_move.c and be_aas_reach.c are copied unchanged (with aasfile.h) and
# compiled by reachgen.c, together with line ranges of game/be_aas.h, game/q_math.c and botlib/be_aas_main.c (AAS_Error,
# AAS_ProjectPointOntoVector). ../stub/, ../route/stub/ and stub/ replace everything else. Reference/quake3 is read only.
# No change to the real code (the zeroing of the reachabilities is done by reachgen.c before AAS_InitReachability).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
PARENT=$(cd "$HERE/.." && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
WORK=$OUT/work
mkdir -p "$WORK/botlib" "$WORK/game"
cp "$PARENT/stub/game/q_shared.h" "$WORK/game/"
cp "$HERE/stub/game/botlib.h" "$WORK/game/"
for f in be_aas_funcs.h be_interface.h l_memory.h l_libvar.h l_script.h; do
  cp "$PARENT/stub/botlib/$f" "$WORK/botlib/"
done
cp "$PARENT/route/stub/botlib/be_aas_def.h" "$WORK/botlib/"
for f in l_precomp.h l_struct.h l_utils.h; do cp "$PARENT/stub/botlib/l_script.h" "$WORK/botlib/$f"; done
echo "unsigned short CRC_ProcessString(unsigned char *data, int length);" > "$WORK/botlib/l_crc.h"
echo "void QDECL Log_Write(char *fmt, ...);" > "$WORK/botlib/l_log.h"
for f in be_aas_file.c be_aas_sample.c be_aas_move.c be_aas_reach.c; do cp "$CODE/botlib/$f" "$WORK/botlib/"; done
{ echo "#ifndef AASFILE_GUARD"; echo "#define AASFILE_GUARD"; cat "$CODE/botlib/aasfile.h"; echo "#endif"; } > "$WORK/botlib/aasfile.h"
line() { grep -n "$1" "$2" | head -1 | cut -d: -f1; }
{
  sed -n "$(line '^typedef struct aas_trace_s' "$CODE/game/be_aas.h"),$(line '} aas_trace_t;' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
  sed -n "$(line '^typedef struct aas_areainfo_s' "$CODE/game/be_aas.h"),$(line '} aas_areainfo_t;' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
  sed -n "$(line '^typedef struct aas_altroutegoal_s' "$CODE/game/be_aas.h"),$(line '} aas_altroutegoal_t;' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
  sed -n "$(line '^typedef struct aas_predictroute_s' "$CODE/game/be_aas.h"),$(line '} aas_predictroute_t;' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
  sed -n "$(line '^#define TFL_INVALID' "$CODE/game/be_aas.h"),$(( $(line '^#define TFL_DEFAULT' "$CODE/game/be_aas.h") + 5 ))p" "$CODE/game/be_aas.h"
  sed -n "$(line '^#define ALTROUTEGOAL_ALL' "$CODE/game/be_aas.h"),$(line '^#define ALTROUTEGOAL_VIEWPORTALS' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
  sed -n "$(line '^#define RSE_NONE' "$CODE/game/be_aas.h"),$(line '^#define RSE_ENTERAREA' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
  sed -n "$(line '^#define SE_NONE' "$CODE/game/be_aas.h"),$(line '^#define SE_TOUCHCLUSTERPORTAL' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
  sed -n "$(line '^typedef struct aas_clientmove_s' "$CODE/game/be_aas.h"),$(line '} aas_clientmove_t;' "$CODE/game/be_aas.h")p" "$CODE/game/be_aas.h"
} > "$WORK/game/be_aas.h.tmp"
{ echo "#ifndef BEAAS_GUARD"; echo "#define BEAAS_GUARD"; cat "$WORK/game/be_aas.h.tmp"; echo "#endif"; } > "$WORK/game/be_aas.h"
{
  sed -n "$(line '^vec_t VectorLength' "$CODE/game/q_math.c"),$(( $(line '^vec_t VectorLength' "$CODE/game/q_math.c") + 2 ))p" "$CODE/game/q_math.c"
  START=$(line '^vec_t VectorNormalize( vec3_t v )' "$CODE/game/q_math.c")
  sed -n "${START},$(( START + 15 ))p" "$CODE/game/q_math.c"
} > "$WORK/vmath.inc"
sed -n "$(line '^void QDECL AAS_Error' "$CODE/botlib/be_aas_main.c"),$(( $(line '^void QDECL AAS_Error' "$CODE/botlib/be_aas_main.c") + 9 ))p" "$CODE/botlib/be_aas_main.c" > "$WORK/aaserror.inc"
sed -n "$(line '^void AAS_ProjectPointOntoVector' "$CODE/botlib/be_aas_main.c"),$(( $(line '^void AAS_ProjectPointOntoVector' "$CODE/botlib/be_aas_main.c") + 9 ))p" "$CODE/botlib/be_aas_main.c" > "$WORK/projectpoint.inc"
awk -v s="$(line '^void AngleVectors' "$CODE/game/q_math.c")" 'NR>=s {print} NR>s && /^}/ {exit}' "$CODE/game/q_math.c" > "$WORK/anglevec.inc"
cp "$HERE/reachgen.c" "$WORK/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -Wno-error=implicit-function-declaration -Wno-error=int-conversion -Wno-error=incompatible-pointer-types -DBOTLIB -I"$WORK" -I"$WORK/botlib" -o "$OUT/reachgen.exe" "$WORK/reachgen.c" -lm
echo "built in $OUT"

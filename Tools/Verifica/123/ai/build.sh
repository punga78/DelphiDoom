#!/bin/sh
# Builds the parity tool of the goals, the movement and the genetic selection of the bots of Quake III Arena
# (issue #123) with the gcc of w64devkit.
#   build.sh [output folder]
# The algorithms are not retyped: the REAL code/botlib/be_ai_goal.c, be_ai_move.c, be_ai_gen.c, be_ea.c,
# be_ai_weight.c, be_aas_file.c, be_aas_sample.c, be_aas_route.c, be_aas_routealt.c, be_aas_move.c,
# be_aas_bspq3.c, l_struct.c, l_libvar.c, l_script.c and l_precomp.c are copied into <out>/work (and the headers),
# together with line ranges of game/q_math.c and q_shared.c, game/be_aas.h, botlib/be_aas_main.c and be_aas_reach.c.
# What changes in the copies is declared here and nowhere else:
#   - include guards around every header (the headers of the original have none);
#   - be_aas_route.c: the three changes of ../../122/route/build.sh (reachnum = 0, startareatraveltimes[4096], the
#     areaupdate table made for the larger of the two numbers);
#   - be_ai_move.c: BotClearMoveResult clears the whole result (the original leaves weapon, movedir and
#     ideal_viewangles as the stack had them and BotTravel_BFGJump reads ideal_viewangles before writing it);
#     BotResetLastAvoidReach reads avoidreachtries[latest] (the original reads avoidreachtries[MAX_AVOIDREACH],
#     one past the array); BotSetBrushModelTypes checks modelnum >= MAX_MODELS (the original writes
#     modeltypes[MAX_MODELS]).
# stub/ replaces everything else (q_shared.h, botlib.h, the memory, the log, the file system of the tool).
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
cp "$HERE/../../122/route/stub/botlib/be_aas_def.h" "$WORK/botlib/"
guard() {
  # guard <source> <destination>
  name=$(basename "$1" | tr '.a-z' '_A-Z')
  { echo "#ifndef REAL_$name"; echo "#define REAL_$name"; cat "$1"; echo; echo "#endif"; } > "$2"
}
for f in aasfile.h l_script.h l_precomp.h l_struct.h l_libvar.h l_utils.h be_ai_weight.h be_aas_bsp.h; do guard "$CODE/botlib/$f" "$WORK/botlib/$f"; done
for f in be_aas.h be_ai_goal.h be_ai_move.h be_ai_gen.h be_ea.h; do guard "$CODE/game/$f" "$WORK/game/$f"; done
echo "unsigned short CRC_ProcessString(unsigned char *data, int length);" > "$WORK/botlib/l_crc.h"
for f in be_aas_file.c be_aas_sample.c be_aas_route.c be_aas_routealt.c be_aas_move.c be_aas_bspq3.c be_ai_goal.c be_ai_move.c be_ai_gen.c be_ea.c be_ai_weight.c l_struct.c l_libvar.c l_script.c l_precomp.c; do
  cp "$CODE/botlib/$f" "$WORK/botlib/"
done
sed -i 's/^\tint traveltime, reachnum;/\tint traveltime, reachnum = 0;/' "$WORK/botlib/be_aas_route.c"
sed -i 's/startareatraveltimes\[128\]/startareatraveltimes[4096]/' "$WORK/botlib/be_aas_route.c"
sed -i 's/maxreachabilityareas \* sizeof(aas_routingupdate_t)/(maxreachabilityareas > aasworld.numareas ? maxreachabilityareas : aasworld.numareas) * sizeof(aas_routingupdate_t)/' "$WORK/botlib/be_aas_route.c"
# be_ai_move.c: the three changes (see above)
sed -i 's/^\tmoveresult->failure = qfalse;/\tCom_Memset(moveresult, 0, sizeof(bot_moveresult_t));\n\tmoveresult->failure = qfalse;/' "$WORK/botlib/be_ai_move.c"
sed -i 's/if (ms->avoidreachtries\[i\] > 0) ms->avoidreachtries\[latest\]--;/if (ms->avoidreachtries[latest] > 0) ms->avoidreachtries[latest]--;/' "$WORK/botlib/be_ai_move.c"
sed -i 's/if (modelnum < 0 || modelnum > MAX_MODELS)/if (modelnum < 0 || modelnum >= MAX_MODELS)/' "$WORK/botlib/be_ai_move.c"
line() { grep -n "$1" "$2" | head -1 | cut -d: -f1; }
M=$CODE/game/q_math.c
{
  # each function from its first line to the first line that is just "}"
  for P in '^vec_t VectorLength( const' '^vec_t VectorNormalize( vec3_t v )' '^vec_t VectorNormalize2' '^void vectoangles' '^void AngleVectors'; do
    awk -v s="$(line "$P" "$M")" 'NR>=s {print} NR>=s && /^}/ {exit}' "$M"
  done
} > "$WORK/vmath.inc"
sed -n '315,381p' "$CODE/game/q_shared.c" > "$WORK/comcompress.inc"
sed -n "$(line '^void QDECL AAS_Error' "$CODE/botlib/be_aas_main.c"),$(( $(line '^void QDECL AAS_Error' "$CODE/botlib/be_aas_main.c") + 9 ))p" "$CODE/botlib/be_aas_main.c" > "$WORK/aaserror.inc"
sed -n "$(line '^void AAS_ProjectPointOntoVector' "$CODE/botlib/be_aas_main.c"),$(( $(line '^void AAS_ProjectPointOntoVector' "$CODE/botlib/be_aas_main.c") + 9 ))p" "$CODE/botlib/be_aas_main.c" > "$WORK/projectpoint.inc"
{
  R=$CODE/botlib/be_aas_reach.c
  sed -n "$(line '^int AAS_AreaReachability' "$R"),$(( $(line '^int AAS_AreaReachability' "$R") + 8 ))p" "$R"
  sed -n "$(line '^int AAS_AreaCrouch' "$R"),$(( $(line '^int AAS_AreaCrouch' "$R") + 4 ))p" "$R"
  S=$(line '^int AAS_AreaSwim' "$R")
  E=$(line '^int AAS_AreaDoNotEnter' "$R")
  sed -n "${S},$(( E + 3 ))p" "$R"
} > "$WORK/areareach.inc"
cp "$HERE/aigen.c" "$HERE/commands.inc" "$WORK/"
# -ffp-contract=off: every float operation is rounded on its own
"$KIT/gcc.exe" -O1 -g -w -ffp-contract=off -D_USE_32BIT_TIME_T -Wno-error=incompatible-pointer-types -DBOTLIB \
  -I"$WORK" -I"$WORK/botlib" -o "$OUT/aigen.exe" "$WORK/aigen.c" "$WORK/botlib/l_struct.c" \
  "$WORK/botlib/l_libvar.c" "$WORK/botlib/l_script.c" "$WORK/botlib/l_precomp.c" -lm
echo "built in $OUT"

#!/bin/sh
# Runs the initialisation of the 12 .qvm of OpenArena 0.8.8 on the virtual machine of Quake III
# (qvmrun_v2.exe, built by build.sh in the same folder) and prints the golden of the test
# DelphiDoom.Tests.Qvm.OpenArena.
#   openarena.sh <folder of build.sh> > Tests/Data/Qvm/openarena.golden.txt
# The files are extracted from the pk3 into <folder>/oa (nothing of OpenArena goes to the repository:
# the golden has only return values, counts and fingerprints, and the texts the modules print).
set -e
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
OA=$ROOT/Reference/openarena/openarena-0.8.8
OUT=$1
cd "$OUT"
: > oa.scenarios.txt
for pak in baseoa/pak0 baseoa/pak6-patch085 baseoa/pak6-patch088 missionpack/mp-pak0; do
  name=$(basename $pak)
  mkdir -p "oa/$name"
  unzip -o -q "$OA/$pak.pk3" 'vm/*.qvm' -d "oa/$name"
  {
    # GAME_INIT( levelTime, randomSeed, restart )
    echo "scenario $name/qagame game oa/$name/vm/qagame.qvm -"
    echo "trace off"
    echo "call 0 1000 12345 0"
    echo "mem"
    echo "end"
    # CG_INIT( serverMessageNum, serverCommandSequence, clientNum )
    echo "scenario $name/cgame cgame oa/$name/vm/cgame.qvm -"
    echo "trace off"
    echo "call 0 0 0 0"
    echo "mem"
    echo "end"
    # UI_GETAPIVERSION, then UI_INIT
    echo "scenario $name/ui ui oa/$name/vm/ui.qvm -"
    echo "trace off"
    echo "call 0"
    echo "call 1"
    echo "mem"
    echo "end"
  } >> oa.scenarios.txt
done
./qvmrun_v2.exe run oa.scenarios.txt

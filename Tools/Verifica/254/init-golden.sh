#!/bin/sh
# Issue #254: the initialisation of the 12 .qvm of OpenArena 0.8.8 on the virtual machine of Quake III, with
# a host that answers memset and memcpy as sv_game.c, cl_cgame.c and cl_ui.c do (return 0: the stub of
# Tools\Verifica\120 returns the destination). Nothing else of the driver changes (the same qvmrun.c, patched
# in a copy with sed). Writes Tests/Data/Q3Host/init.golden.txt.
#   init-golden.sh <work folder> > Tests/Data/Q3Host/init.golden.txt
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=$1
mkdir -p "$OUT"
sh "$HERE/../120/build.sh" "$OUT" > /dev/null
cd "$OUT"
# the two returns after "case 100" (memset) and "case 101" (memcpy)
awk '
  /case 100:/ { m = 1 }
  /case 101:/ { m = 1 }
  m == 1 && /return args\[1\];/ { sub(/return args\[1\];/, "return 0;"); m = 0 }
  { print }
' qvmrun.c > qvmrun_real.c
if cmp -s qvmrun.c qvmrun_real.c; then echo "patch did not apply" >&2; exit 1; fi
"$KIT/gcc.exe" -O1 -std=gnu99 -w -fpermissive -ffp-contract=off -msse2 -mfpmath=sse -DVM_MAGIC=0x12721445 \
  -o qvmrun_real.exe qvmrun_real.c
sed 's/qvmrun_v2.exe/qvmrun_real.exe/' "$HERE/../120/openarena.sh" > oa_real.sh
sh oa_real.sh "$OUT"

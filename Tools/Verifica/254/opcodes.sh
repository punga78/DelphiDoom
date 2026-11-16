#!/bin/sh
# Issue #254: the numbers of the system calls of Quake III (the traps of game, cgame and ui) as the C
# compiler sees them. Writes, on the standard output, the golden Tests/Data/Q3Host/opcodes.golden.txt:
#   <enum> <NAME> <value>
# The names are taken from the real headers (game/g_public.h, cgame/cg_public.h, ui/ui_public.h, read only)
# with awk; the values are printed by a program compiled with the real headers (gcc of w64devkit).
#   opcodes.sh <work folder> > Tests/Data/Q3Host/opcodes.golden.txt
set -e
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
Q3=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=$1
mkdir -p "$OUT"
cd "$OUT"

# the members of an enum (file, type), without comments and values
names() {
  awk -v type="$2" '
    /typedef enum/ { buf = ""; on = 1; next }
    on && $0 ~ ("^} " type ";") { print buf; exit }
    on == 1 { sub(/\/\/.*/, ""); buf = buf " " $0 }
  ' "$1" | sed 's/\/\*[^*]*\*\///g' | tr ',' '\n' | sed 's/=.*//; s/[[:space:]]//g' | grep -v '^$'
}

# a program that prints "<enum> <name> <value>" for every member (program, header, enums...)
emit() {
  prog=$1
  hdr=$2
  shift 2
  {
    echo '#include "q_shared.h"'
    echo '#include "bg_public.h"'
    echo "#include \"$(basename $hdr)\""
    echo '#include <stdio.h>'
    echo 'int main(void) {'
    for e in "$@"; do
      for n in $(names "$hdr" "$e"); do
        echo "  printf(\"$e $n %d\\n\", (int)$n);"
      done
    done
    echo '  return 0; }'
  } > $prog.c
}

emit opg "$Q3/game/g_public.h" gameImport_t gameExport_t
emit opc "$Q3/cgame/cg_public.h" cgameImport_t cgameExport_t
emit opu "$Q3/ui/ui_public.h" uiImport_t uiExport_t
# the traps game shares with the engine (memset ... ceil) are in qcommon.h, not in g_public.h
emit opq "$Q3/qcommon/qcommon.h" sharedTraps_t
for p in opg opc opu opq; do
  "$KIT/gcc.exe" -m32 -w -I"$Q3/game" -I"$Q3/cgame" -I"$Q3/ui" -I"$Q3/qcommon" -o $p.exe $p.c
  ./$p.exe
done

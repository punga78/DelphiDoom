#!/bin/sh
# Builds the parity driver of the issue #120 (virtual machine of Quake III) with the gcc of w64devkit.
#   build.sh [output folder]
# Nothing of Quake III is retyped. vm_original.inc is made of (read only):
#   qcommon/vm_local.h, qcommon/vm.c, qcommon/vm_interpreted.c   whole, without their #include lines
#   game/q_shared.c    COM_StripExtension, COM_Parse, SkipWhitespace, COM_ParseExt, Q_strncpyz,
#                      Q_stricmpn, Q_stricmp, Com_sprintf and the three variables of the parser
# Two programs: qvmrun.exe (VM_MAGIC 0x12721444, Quake III 1.32) and qvmrun_v2.exe, the same text
# with -DVM_MAGIC=0x12721445 (the VM_MAGIC_VER2 of ioquake3: the files of OpenArena), and
# qvmrun_o2.exe (-O2, for the speed).
# -ffp-contract=off keeps every float operation rounded on its own (SSE).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
QCOMMON=$ROOT/Reference/quake3/code/qcommon
GAME=$ROOT/Reference/quake3/code/game
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"

# prints the function whose first line matches the pattern, up to the first line "}"
extract() {
  awk -v re="$2" 'p == 0 && $0 ~ re { p = 1 } p == 1 { print } p == 1 && /^}/ { exit }' "$1"
}

{
  grep -v '^#include' "$QCOMMON/vm_local.h"
  echo 'static	char	com_token[MAX_TOKEN_CHARS];'
  echo 'static	int		com_lines;'
  extract "$GAME/q_shared.c" '^void COM_StripExtension'
  extract "$GAME/q_shared.c" '^char [*]COM_Parse[(]'
  extract "$GAME/q_shared.c" '^static char [*]SkipWhitespace'
  extract "$GAME/q_shared.c" '^char [*]COM_ParseExt'
  extract "$GAME/q_shared.c" '^void Q_strncpyz'
  extract "$GAME/q_shared.c" '^int Q_stricmpn'
  extract "$GAME/q_shared.c" '^int Q_stricmp '
  extract "$GAME/q_shared.c" '^void QDECL Com_sprintf'
  grep -v '^#include' "$QCOMMON/vm.c"
  grep -v '^#include' "$QCOMMON/vm_interpreted.c"
} > "$OUT/vm_original.inc"

# the whole files must be there
grep -q '^int	VM_CallInterpreted' "$OUT/vm_original.inc"
grep -q '^vm_t [*]VM_Create' "$OUT/vm_original.inc"
grep -q '^void VM_PrepareInterpreter' "$OUT/vm_original.inc"

cp "$HERE/stubs.h" "$HERE/qvmrun.c" "$OUT/"
# The gcc of w64devkit makes 32 bit x86 programs. The floats are computed with the SSE instructions, as
# every 64 bit program does; qvmrun_x87.exe is the same driver with the x87 unit (what the compilers of
# 1999 used), to see where the two differ: only in which NaN comes out of an operation on NaN.
FLAGS="-std=gnu99 -w -fpermissive -ffp-contract=off -msse2 -mfpmath=sse"
X87FLAGS="-std=gnu99 -w -fpermissive -ffp-contract=off -mfpmath=387"
"$KIT/gcc.exe" -O1 $FLAGS -o "$OUT/qvmrun.exe" "$OUT/qvmrun.c"
"$KIT/gcc.exe" -O1 $FLAGS -DVM_MAGIC=0x12721445 -o "$OUT/qvmrun_v2.exe" "$OUT/qvmrun.c"
"$KIT/gcc.exe" -O2 $FLAGS -o "$OUT/qvmrun_o2.exe" "$OUT/qvmrun.c"
"$KIT/gcc.exe" -O1 $X87FLAGS -o "$OUT/qvmrun_x87.exe" "$OUT/qvmrun.c"
echo "built in $OUT"

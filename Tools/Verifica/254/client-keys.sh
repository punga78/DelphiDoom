#!/bin/sh
# Issue #254, fase 2c: Tests/Data/Q3Host/keys.golden.txt = the key names of the real cl_keys.c (the table and
# Key_StringToKeynum / Key_KeynumToString are cut out of the file and compiled as they are; gcc -m32 of w64devkit).
#   client-keys.sh <work folder> > Tests/Data/Q3Host/keys.golden.txt
# The table of DelphiDoom.Q3Host.Client.KeyNames.pas is written from the T lines by client-keys-pascal.sh.
set -e
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
Q3=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=$1
mkdir -p "$OUT"
cd "$OUT"
START=$(grep -n '^typedef struct {$' "$Q3/client/cl_keys.c" | head -1 | cut -d: -f1)
# the keyname_t typedef is the first typedef after the key array declarations; take from it to the end of the table
TABLE_FIRST=$(grep -n '^} keyname_t;' "$Q3/client/cl_keys.c" | cut -d: -f1)
TABLE_LAST=$(grep -n '^	{NULL,0}' "$Q3/client/cl_keys.c" | cut -d: -f1)
S2K=$(grep -n '^int Key_StringToKeynum' "$Q3/client/cl_keys.c" | cut -d: -f1)
K2S=$(grep -n '^char \*Key_KeynumToString' "$Q3/client/cl_keys.c" | cut -d: -f1)
K2S_END=$(awk -v s="$K2S" 'NR > s && /^}/ { print NR; exit }' "$Q3/client/cl_keys.c")
{
  echo "typedef struct {"
  echo "	char	*name;"
  echo "	int		keynum;"
  echo "} keyname_t;"
  sed -n "$((TABLE_FIRST + 1)),$((TABLE_LAST + 1))p" "$Q3/client/cl_keys.c"
  sed -n "${S2K},${K2S_END}p" "$Q3/client/cl_keys.c"
} > keys-extract.inc
"$KIT/gcc.exe" -m32 -w -I"$Q3/ui" -I. -o client-keys.exe "$HERE/client-keys.c"
./client-keys.exe

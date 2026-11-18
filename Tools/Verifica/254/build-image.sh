#!/bin/sh
# Builds imagegen.exe (issue #254, renderer phase R0) and writes the golden of the image readers:
#   build-image.sh <work folder> [files...] > Tests/Data/Q3Render/image.golden.txt
# With no files it decodes the corpus of the repository (Tests/Data/IdImages/tga/*.tga and Tests/Data/Q3Render/tga/
# *.tga as TGA, Tests/Data/Jpeg/encoder-*.jpg as JPEG); otherwise the arguments are tga:<file> or jpg:<file>. LoadTGA and LoadJPG are cut out of renderer/tr_image.c of Quake III by function (awk: from
# the first line of the function to its closing brace); jpeg-6 is the one of Quake III. gcc of w64devkit, 32 bit
# (-m32) with the x87 for the float DCT: the Win32 build of the original (MSVC) computes in the same registers.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CODE=$ROOT/Reference/quake3/code
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
shift || true
mkdir -p "$OUT/jpeg-6" "$OUT/renderer"
cp "$CODE"/jpeg-6/*.c "$CODE"/jpeg-6/*.h "$OUT/jpeg-6/"
cat > "$OUT/renderer/tr_local.h" <<'EOF'
/* the part of tr_local.h that the files of jpeg-6 and tr_image.c use */
#ifndef TR_LOCAL_STUB
#define TR_LOCAL_STUB
typedef unsigned char byte;
typedef enum { qfalse, qtrue } qboolean;
#define ERR_FATAL 0
#define ERR_DROP 1
#define PRINT_ALL 0
#define PRINT_DEVELOPER 1
#define PRINT_WARNING 2
#define LittleShort(x) (x)
typedef struct {
	void (*Printf)(int printLevel, const char *fmt, ...);
	void (*Error)(int errorLevel, const char *fmt, ...);
	void *(*Malloc)(int bytes);
	void (*Free)(void *buf);
	int (*FS_ReadFile)(const char *qpath, void **buffer);
	void (*FS_FreeFile)(void *buffer);
} refimport_t;
extern refimport_t ri;
#endif
EOF
# TargaHeader of qfiles.h and the two functions of tr_image.c, as they are
sed -n '95,101p' "$CODE/qcommon/qfiles.h" > "$OUT/q3_typedefs.inc"
{
  awk 'NR>=1121 { print } NR>=1121 && /^}/ { exit }' "$CODE/renderer/tr_image.c"
  echo
  awk 'NR>=1360 { print } NR>=1360 && /^}/ { exit }' "$CODE/renderer/tr_image.c"
} > "$OUT/q3_image_real.inc"
cd "$OUT"
SOURCES="jcomapi jdapimin jdapistd jdatasrc jdcoefct jdcolor jddctmgr jdhuff jdinput jdmainct jdmarker jdmaster jdpostct jdsample jdtrans jerror jidctflt jidctfst jidctint jidctred jmemmgr jmemnobs jutils jquant1 jquant2 jdmerge"
FILES=""
for s in $SOURCES; do FILES="$FILES jpeg-6/$s.c"; done
"$KIT/gcc" -m32 -mfpmath=387 -O0 -fwrapv -w -I. -I"$OUT" -o imagegen.exe "$HERE/imagegen.c" $FILES
if [ $# -eq 0 ]; then
  # a Windows program does not know the /c/ paths of the shell
  REPO=$(cd "$HERE/../../.." && (cygpath -m "$(pwd)" 2>/dev/null || pwd))
  set --
  for f in "$REPO"/Tests/Data/IdImages/tga/*.tga "$REPO"/Tests/Data/Q3Render/tga/*.tga; do
    [ -f "$f" ] && set -- "$@" "tga:$f"
  done
  for f in "$REPO"/Tests/Data/Jpeg/encoder-*.jpg; do
    [ -f "$f" ] && set -- "$@" "jpg:$f"
  done
fi
./imagegen.exe "$@"

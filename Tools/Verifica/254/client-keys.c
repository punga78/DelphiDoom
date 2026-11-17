/* Issue #254 (fase 2c): the key names of Quake III (keynames[], Key_StringToKeynum, Key_KeynumToString of
   cl_keys.c) compiled unchanged. client-keys.sh cuts the table and the two functions out of the real file into
   keys-extract.inc and compiles this program with the real keycodes.h.
   T lines: the table; N lines: Key_KeynumToString for -2..257; S lines: Key_StringToKeynum of a list of texts. */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "keycodes.h"
typedef int qboolean;
#define qfalse 0
#define qtrue 1
/* Q_stricmp of q_shared.c compares as lowercase ASCII */
static int Q_stricmp(const char *a, const char *b) {
  for (;; a++, b++) {
    int x = (unsigned char)*a, y = (unsigned char)*b;
    if (x >= 'A' && x <= 'Z') x += 32;
    if (y >= 'A' && y <= 'Z') y += 32;
    if (x != y) return x < y ? -1 : 1;
    if (!x) return 0;
  }
}
#include "keys-extract.inc"
int main(void) {
  keyname_t *kn;
  int i;
  static const char *texts[] = { "", "a", "A", "0", ";", "0x41", "0xzz", "0x4", "0x411", "0XFF", "0xff", "tab", "Tab",
    "TAB", "BOGUS", "semicolon", "kp_5", "mouse1", "JOY32", "AUX16", "f12", "ctrl", "\"", " ", 0 };
  for (kn = keynames; kn->name; kn++)
    printf("T %s %d\n", kn->name, kn->keynum);
  for (i = -2; i <= 257; i++)
    printf("N %d %s\n", i, Key_KeynumToString(i));
  for (i = 0; texts[i]; i++)
    printf("S [%s] %d\n", texts[i], Key_StringToKeynum((char *)texts[i]));
  for (kn = keynames; kn->name; kn++)
    printf("S [%s] %d\n", kn->name, Key_StringToKeynum(kn->name));
  return 0; }

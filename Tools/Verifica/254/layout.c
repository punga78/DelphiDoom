/* Issue #254 (fase 2b): the layout in memory of the structures the system calls of Quake III share with the
   module (the data of the program), as the real headers give it (gcc -m32). Compiled by layout.sh. */
#include "q_shared.h"
#include "bg_public.h"
#include "g_public.h"
#include <stdio.h>
#include <stddef.h>
#define O(t, f) printf(#t "." #f " %d\n", (int)offsetof(t, f))
#define S(t) printf("sizeof " #t " %d\n", (int)sizeof(t))
int main(void) {
  S(sharedEntity_t); S(entityState_t); S(entityShared_t); S(trace_t); S(cplane_t); S(vmCvar_t); S(usercmd_t); S(qtime_t);
  O(entityState_t, number); O(entityState_t, eFlags); O(entityState_t, origin); O(entityState_t, angles);
  O(entityState_t, modelindex); O(entityState_t, solid);
  O(sharedEntity_t, s); O(sharedEntity_t, r);
  O(entityShared_t, linked); O(entityShared_t, linkcount); O(entityShared_t, svFlags); O(entityShared_t, singleClient);
  O(entityShared_t, bmodel); O(entityShared_t, mins); O(entityShared_t, maxs); O(entityShared_t, contents);
  O(entityShared_t, absmin); O(entityShared_t, absmax); O(entityShared_t, currentOrigin);
  O(entityShared_t, currentAngles); O(entityShared_t, ownerNum);
  O(trace_t, allsolid); O(trace_t, startsolid); O(trace_t, fraction); O(trace_t, endpos); O(trace_t, plane);
  O(trace_t, surfaceFlags); O(trace_t, contents); O(trace_t, entityNum);
  O(cplane_t, dist); O(cplane_t, type); O(cplane_t, signbits);
  O(vmCvar_t, handle); O(vmCvar_t, modificationCount); O(vmCvar_t, value); O(vmCvar_t, integer); O(vmCvar_t, string);
  O(qtime_t, tm_sec); O(qtime_t, tm_isdst);
  printf("const MAX_GENTITIES %d\nconst ENTITYNUM_NONE %d\nconst ENTITYNUM_WORLD %d\nconst MAX_CONFIGSTRINGS %d\n",
    MAX_GENTITIES, ENTITYNUM_NONE, ENTITYNUM_WORLD, MAX_CONFIGSTRINGS);
  printf("const MAX_CLIENTS %d\nconst SOLID_BMODEL %d\nconst SVF_CAPSULE %d\nconst SVF_BOT %d\nconst MAX_CVAR_VALUE_STRING %d\n",
    MAX_CLIENTS, SOLID_BMODEL, SVF_CAPSULE, SVF_BOT, MAX_CVAR_VALUE_STRING);
  return 0; }

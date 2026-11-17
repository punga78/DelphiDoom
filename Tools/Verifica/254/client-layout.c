/* Issue #254 (fase 2c): the layout in memory of the structures cgame and ui share with the host (snapshot_t,
   gameState_t, uiClientState_t, glconfig_t, pc_token_t), as the real headers give it (gcc -m32).
   Compiled by client-layout.sh. */
#include "q_shared.h"
#include "bg_public.h"
#include "tr_types.h"
#include "cg_public.h"
#include "ui_public.h"
#include "botlib.h"
#include "qcommon.h"
#include <stdio.h>
#include <stddef.h>
#define O(t, f) printf(#t "." #f " %d\n", (int)offsetof(t, f))
#define S(t) printf("sizeof " #t " %d\n", (int)sizeof(t))
int main(void) {
  S(gameState_t); S(snapshot_t); S(playerState_t); S(entityState_t); S(usercmd_t); S(uiClientState_t); S(glconfig_t);
  S(pc_token_t);
  O(gameState_t, stringOffsets); O(gameState_t, stringData); O(gameState_t, dataCount);
  O(snapshot_t, snapFlags); O(snapshot_t, ping); O(snapshot_t, serverTime); O(snapshot_t, areamask); O(snapshot_t, ps);
  O(snapshot_t, numEntities); O(snapshot_t, entities); O(snapshot_t, numServerCommands);
  O(snapshot_t, serverCommandSequence);
  O(playerState_t, clientNum);
  O(uiClientState_t, connState); O(uiClientState_t, connectPacketCount); O(uiClientState_t, clientNum);
  O(uiClientState_t, servername); O(uiClientState_t, updateInfoString); O(uiClientState_t, messageString);
  O(glconfig_t, renderer_string); O(glconfig_t, vendor_string); O(glconfig_t, version_string);
  O(glconfig_t, extensions_string); O(glconfig_t, maxTextureSize); O(glconfig_t, maxActiveTextures);
  O(glconfig_t, colorBits); O(glconfig_t, depthBits); O(glconfig_t, stencilBits); O(glconfig_t, driverType);
  O(glconfig_t, hardwareType); O(glconfig_t, deviceSupportsGamma); O(glconfig_t, textureCompression);
  O(glconfig_t, textureEnvAddAvailable); O(glconfig_t, vidWidth); O(glconfig_t, vidHeight);
  O(glconfig_t, windowAspect); O(glconfig_t, displayFrequency); O(glconfig_t, isFullscreen);
  O(glconfig_t, stereoEnabled); O(glconfig_t, smpActive);
  O(pc_token_t, type); O(pc_token_t, subtype); O(pc_token_t, intvalue); O(pc_token_t, floatvalue); O(pc_token_t, string);
  printf("const MAX_CONFIGSTRINGS %d\nconst MAX_GAMESTATE_CHARS %d\nconst MAX_ENTITIES_IN_SNAPSHOT %d\n",
    MAX_CONFIGSTRINGS, MAX_GAMESTATE_CHARS, MAX_ENTITIES_IN_SNAPSHOT);
  printf("const MAX_MAP_AREA_BYTES %d\nconst MAX_QPATH %d\nconst MAX_STRING_CHARS %d\nconst BIG_INFO_STRING %d\n",
    MAX_MAP_AREA_BYTES, MAX_QPATH, MAX_STRING_CHARS, BIG_INFO_STRING);
  printf("const MAX_NAME_LENGTH %d\nconst MAX_TOKENLENGTH %d\nconst MAX_OSPATH %d\nconst MAX_RELIABLE_COMMANDS %d\n",
    MAX_NAME_LENGTH, MAX_TOKENLENGTH, MAX_OSPATH, MAX_RELIABLE_COMMANDS);
  return 0; }

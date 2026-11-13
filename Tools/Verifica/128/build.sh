#!/bin/sh
# Builds the parity driver of the issue #128 (sound of Quake III) with the gcc of w64devkit.
#   build.sh [output folder]
# Nothing of Quake III is retyped. snd_original.inc is made of whole functions of (read only):
#   game/q_math.c     DistanceSquared, VectorNormalize, VectorRotate
#   game/q_shared.h   VectorLengthSquared
#   client/snd_mix.c  S_WriteLinearBlastStereo16 (the C version), S_TransferStereo16,
#                     S_TransferPaintBuffer, S_PaintChannelFrom16, S_PaintChannels
#   client/snd_mem.c  ResampleSfx
#   client/snd_dma.c  S_SpatializeOrigin, S_ChannelFree/Malloc/Setup, S_StartSound,
#                     S_StartLocalSound, S_ClearSoundBuffer, S_StopLoopingSound,
#                     S_ClearLoopingSounds, S_AddLoopingSound, S_AddRealLoopingSound,
#                     S_AddLoopSounds, S_RawSamples, S_UpdateEntityPosition, S_Respatialize,
#                     S_ScanChannelStarts, S_GetSoundtime, S_Update_
# Two defects of S_StartSound are patched with sed (checked below), because they read past
# the array: ch[i] on a pointer that is also advanced, and the test on ch after the loops.
# -ffp-contract=off keeps every float operation rounded on its own (SSE).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=${DELPHIDOOM_ROOT:-/c/Progetti/DelphiDoom}
CLIENT=$ROOT/Reference/quake3/code/client
GAME=$ROOT/Reference/quake3/code/game
KIT=$ROOT/Reference/_dati/_strumenti/w64devkit/w64devkit/bin
OUT=${1:-$HERE/out}
mkdir -p "$OUT"

# prints the function whose first line matches the pattern, up to the first line "}"
extract() {
  awk -v re="$2" 'p == 0 && $0 ~ re { p = 1 } p == 1 { print } p == 1 && /^}/ { exit }' "$1"
}

{
  extract "$GAME/q_math.c" '^vec_t DistanceSquared'
  extract "$GAME/q_math.c" '^vec_t VectorNormalize[(]'
  extract "$GAME/q_math.c" '^void VectorRotate'
  extract "$GAME/q_shared.h" '^static ID_INLINE vec_t VectorLengthSquared'
  extract "$CLIENT/snd_mix.c" '^void S_WriteLinearBlastStereo16 [(]void[)]'
  extract "$CLIENT/snd_mix.c" '^void S_TransferStereo16'
  extract "$CLIENT/snd_mix.c" '^void S_TransferPaintBuffer'
  extract "$CLIENT/snd_mix.c" '^static void S_PaintChannelFrom16'
  extract "$CLIENT/snd_mix.c" '^void S_PaintChannels'
  extract "$CLIENT/snd_mem.c" '^static void ResampleSfx[(]'
  extract "$CLIENT/snd_dma.c" '^void S_SpatializeOrigin'
  extract "$CLIENT/snd_dma.c" '^void S_ChannelFree'
  extract "$CLIENT/snd_dma.c" '^channel_t[*]'
  extract "$CLIENT/snd_dma.c" '^void S_ChannelSetup'
  extract "$CLIENT/snd_dma.c" '^void S_StartSound[(]' > "$OUT/startsound.tmp"
  sed -e 's/ch\[i\]\.entnum == entityNum && ch\[i\]\.thesfx == sfx/ch->entnum == entityNum \&\& ch->thesfx == sfx/' \
      -e 's/time - ch\[i\]\.allocTime/time - ch->allocTime/' \
      -e 's/if (ch->entnum == listener_number) {/ch = s_channels; if (1) {/' "$OUT/startsound.tmp"
  extract "$CLIENT/snd_dma.c" '^void S_StartLocalSound'
  extract "$CLIENT/snd_dma.c" '^void S_ClearSoundBuffer'
  extract "$CLIENT/snd_dma.c" '^void S_StopAllSounds[(]void[)] [{]'
  extract "$CLIENT/snd_dma.c" '^void S_StopLoopingSound'
  extract "$CLIENT/snd_dma.c" '^void S_ClearLoopingSounds'
  extract "$CLIENT/snd_dma.c" '^void S_AddLoopingSound'
  extract "$CLIENT/snd_dma.c" '^void S_AddRealLoopingSound'
  extract "$CLIENT/snd_dma.c" '^void S_AddLoopSounds'
  extract "$CLIENT/snd_dma.c" '^void S_RawSamples'
  extract "$CLIENT/snd_dma.c" '^void S_UpdateEntityPosition'
  extract "$CLIENT/snd_dma.c" '^void S_Respatialize'
  extract "$CLIENT/snd_dma.c" '^qboolean S_ScanChannelStarts'
  extract "$CLIENT/snd_dma.c" '^void S_GetSoundtime'
  extract "$CLIENT/snd_dma.c" '^void S_Update_[(]void[)]'
} > "$OUT/snd_original.inc"
rm -f "$OUT/startsound.tmp"

# the patches must have been applied
grep -q 'ch->entnum == entityNum && ch->thesfx == sfx' "$OUT/snd_original.inc"
grep -q 'time - ch->allocTime' "$OUT/snd_original.inc"
grep -q 'ch = s_channels; if (1) {' "$OUT/snd_original.inc"

cp "$HERE/stubs.h" "$HERE/q3snd.c" "$OUT/"
"$KIT/gcc.exe" -O1 -w -ffp-contract=off -o "$OUT/q3snd.exe" "$OUT/q3snd.c"
echo "built in $OUT"

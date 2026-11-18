//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//    The not so system specific sound interface.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit s_sound;

interface

uses
  d_delphi,
  DelphiDoom.Audio.Intf,
  p_mobj_h;

type
  /// <summary>Makes the player of the sound effects; false: no sound card, only handles</summary>
  TSfxPlayerFactory = reference to function(AWithDevice: Boolean): ISfxPlayer;

const
  MP3MAGIC = $1A33504D; //"MP3"<EOF>

type
  // The song that S_DoChangeMusic gives to the music player for an external mp3 file
  mp3header_t = packed record
    ID: LongWord; // MP3MAGIC "MP3" 0x1A
    Stream: TDStream;
    foo: array[0..1] of LongWord;
  end;
  Pmp3header_t = ^mp3header_t;

var
// These are not used, but should be (menu).
// Maximum volume of a sound effect.
// Internal default is max out of 0-15.
  snd_SfxVolume: integer = 15;

// Maximum volume of music. Useless so far.
  snd_MusicVolume: integer = 15;

{$IFDEF STRIFE}
  snd_VoiceVolume: integer = 15;

{$ENDIF}
// following is set
//  by the defaults code in M_misc:
// number of channels available
  numChannels: integer;
{$IFDEF STRIFE}

var
  disable_voices: boolean = false;
{$ENDIF}

const
  MIN_NUMCHANNELS = 8;
  MAX_NUMCHANNELS = 64;

{$IF DEFINED(HERETIC)}
type
  chaninfo_t = record
    id: integer;
    priority: integer;
    name: string;
    mo: Pmobj_t;
    distance: integer;
  end;
  Pchaninfo_t = ^chaninfo_t;

  soundinfo_t = record
    numchannels: integer;
    musicvolume: integer;
    soundvolume: integer;
    chan: array[0..MAX_NUMCHANNELS - 1] of chaninfo_t;
  end;
  Psoundinfo_t = ^soundinfo_t;

{$ELSEIF DEFINED(HEXEN)}
type
  chaninfo_t = record
    id: integer;
    priority: integer;
    name: string;
    mo: Pmobj_t;
    distance: integer;
  end;
  Pchaninfo_t = ^chaninfo_t;

  soundinfo_t = record
    numchannels: integer;
    musicvolume: integer;
    soundvolume: integer;
    chan: array[0..MAX_NUMCHANNELS - 1] of chaninfo_t;
  end;
  Psoundinfo_t = ^soundinfo_t;

{$ENDIF}
//==============================================================================
//
// S_DefaultMusicForMap
//
//==============================================================================

var
  full_sounds: boolean = true;
  usemp3: boolean;
  preferemp3namesingamedirectory: boolean;
  useexternalwav: boolean;
  preferewavnamesingamedirectory: boolean;
  miditempo: integer = 160;

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TSoundRoutines = class sealed
  public
    //==============================================================================
    //
    // S_ConfigureSound
    //
    // The way to make the player of the sound effects, given by the composition root
    // (ComposeEngine); without it S_InitSoundDevice stops with I_Error.
    //
    //==============================================================================
    class procedure S_ConfigureSound(const AFactory: TSfxPlayerFactory); static;

    //==============================================================================
    //
    // S_ConfigureMusic
    //
    // The player of the music, given by the composition root (ComposeEngine); without it
    // S_InitMusicDevice stops with I_Error.
    //
    //==============================================================================
    class procedure S_ConfigureMusic(const APlayer: IMusicPlayer); static;

    //==============================================================================
    //
    // S_InitSoundDevice
    //
    // Makes the player of the sound effects (without a device with -nosound). Called by
    // I_Init at program start (it was I_InitSound).
    //
    //==============================================================================
    class procedure S_InitSoundDevice; static;

    //==============================================================================
    //
    // S_ShutDownSoundDevice
    //
    // Releases the player of the sound effects and the cache of the samples at program
    // termination (it was I_ShutDownSound).
    //
    //==============================================================================
    class procedure S_ShutDownSoundDevice; static;

    //==============================================================================
    //
    // S_InitMusicDevice
    //
    // Starts the backends of the music (it was I_InitMusic).
    //
    //==============================================================================
    class procedure S_InitMusicDevice; static;

    //==============================================================================
    //
    // S_ShutDownMusicDevice
    //
    // Stops the backends of the music (it was I_ShutDownMusic).
    //
    //==============================================================================
    class procedure S_ShutDownMusicDevice; static;

    //==============================================================================
    //
    // S_ProcessMusic
    //
    // Gives the playing song its time, every frame (it was I_ProcessMusic).
    //
    //==============================================================================
    class procedure S_ProcessMusic; static;

    //==============================================================================
    //
    // S_ConfigureExternalMusic
    //
    // The cache of the external songs (MOD, S3M, IT, XM next to the WAD) is given by the
    // composition root (ComposeEngine); without it S_Init stops with I_Error.
    //
    //==============================================================================
    class procedure S_ConfigureExternalMusic(const ACache: IExternalMusicCache); static;

    //==============================================================================
    // S_Init
    //
    // Initializes sound stuff, including volume
    // Sets channels, SFX and music volume,
    //  allocates channel buffer, sets S_sfx lookup.
    //
    //==============================================================================
{$IF ((DEFINED(DOOM)))}
    class procedure S_Init(sfxVolume: integer; musicVolume: integer); static;

    //==============================================================================
    //
    // S_InitDEHExtraSounds
    //
    //==============================================================================
    class procedure S_InitDEHExtraSounds; static;

{$ENDIF}
{$IF ((NOT ((DEFINED(DOOM)))) AND (DEFINED(STRIFE)))}
    class procedure S_Init(sfxVolume: integer; musicVolume: integer; voiceVolume: integer); static;

{$ENDIF}
{$IF (NOT ((DEFINED(DOOM))) AND NOT ((NOT ((DEFINED(DOOM)))) AND (DEFINED(STRIFE))))}
    class procedure S_Init(sfxVolume: integer; musicVolume: integer); static;

{$ENDIF}
    //==============================================================================
    //
    // S_ShutDownSound
    //
    //==============================================================================
    class procedure S_ShutDownSound; static;

    //==============================================================================
    // S_Start
    //
    // Per level startup code.
    // Kills playing sounds at start of level,
    //  determines music if any, changes music.
    //
    //==============================================================================
    class procedure S_Start; static;

    //==============================================================================
    // S_StartSound
    //
    // Start sound for thing at <origin>
    //  using <sound_id> from sounds.h
    //
    //==============================================================================
    class procedure S_StartSound(origin: pointer; sfx_id: integer); overload; static;

    //==============================================================================
    //
    // S_StartSound
    //
    //==============================================================================
    class procedure S_StartSound(origin: pointer; const sndname: string); overload; static;

    //==============================================================================
    // S_StartSoundAtVolume
    //
    // Will start a sound at a given volume.
    //
    //==============================================================================
    class procedure S_StartSoundAtVolume(origin_p: pointer; sfx_id: integer; volume: integer); static;

{$IF (DEFINED(STRIFE))}
    //==============================================================================
    // S_StartVoice
    //
    // Voice volume
    //
    //==============================================================================
    class procedure S_StartVoice(const sndname: string); static;

    //==============================================================================
    //
    // S_StartVoiceAtVolume
    //
    //==============================================================================
    class procedure S_StartVoiceAtVolume(origin_p: pointer; sfx_id: integer; volume: integer); static;

{$ENDIF}
    //==============================================================================
    //
    // S_UnlinkSound
    //
    //==============================================================================
    class procedure S_UnlinkSound(origin: Pmobj_t); static;

    //==============================================================================
    // S_StopSound
    //
    // Stop sound for thing at <origin>
    //
    //==============================================================================
    class procedure S_StopSound(origin: pointer); static;

{$IF (DEFINED(HEXEN))}
    //==============================================================================
    // S_StopAllSounds
    //
    // Stop all sounds
    //
    //==============================================================================
    class procedure S_StopAllSounds; static;

{$ENDIF}
    //==============================================================================
    // S_StartMusic
    //
    // Start music using <music_id> from sounds.h
    //
    //==============================================================================
    class procedure S_StartMusic(music_id: integer); static;

    //==============================================================================
    // S_ChangeMusic
    //
    // Start music using <music_id> from sounds.h,
    //  and set whether looping
    //
    //==============================================================================
    class procedure S_ChangeMusic(musicnum: integer; looping: boolean); static;

    //==============================================================================
    // S_StopMusic
    //
    // Stops the music fer sure.
    //
    //==============================================================================
    class procedure S_StopMusic; static;

    //==============================================================================
    // S_PauseSound
    //
    // Stop and resume music, during game PAUSE.
    //
    //==============================================================================
    class procedure S_PauseSound; static;

    //==============================================================================
    //
    // S_ResumeSound
    //
    //==============================================================================
    class procedure S_ResumeSound; static;

    //==============================================================================
    // S_UpdateSounds
    //
    // Updates music & sounds
    //
    //==============================================================================
    class procedure S_UpdateSounds(listener_p: pointer); static;

    //==============================================================================
    //
    // S_SetMusicVolume
    //
    //==============================================================================
    class procedure S_SetMusicVolume(volume: integer); static;

    //==============================================================================
    //
    // S_SetSfxVolume
    //
    //==============================================================================
    class procedure S_SetSfxVolume(volume: integer); static;

{$IF (DEFINED(STRIFE))}
    // S_SetVoiceVolume
    //
    //==============================================================================
    class procedure S_SetVoiceVolume(volume: integer); static;

{$ENDIF}
    // S_PrecacheSounds
    //
    //==============================================================================
    class procedure S_PrecacheSounds; static;

{$IF ((DEFINED(HERETIC)))}
    //==============================================================================
    //
    // S_GetChannelInfo
    //
    //==============================================================================
    class procedure S_GetChannelInfo(s: Psoundinfo_t); static;

{$ENDIF}
{$IF ((NOT ((DEFINED(HERETIC)))) AND (DEFINED(HEXEN)))}
    //==============================================================================
    //
    // S_GetChannelInfo
    //
    //==============================================================================
    class procedure S_GetChannelInfo(s: Psoundinfo_t); static;

    //==============================================================================
    //
    // S_GetSoundPlayingInfo
    //
    //==============================================================================
    class function S_GetSoundPlayingInfo(mobj: Pmobj_t; sound_id: integer): boolean; static;

{$ENDIF}
{$IF ((DEFINED(HEXEN) OR DEFINED(STRIFE)))}
    class function S_DefaultMusicForMap(const map: integer): integer; static;

{$ENDIF}
{$IF (NOT ((DEFINED(HEXEN) OR DEFINED(STRIFE))))}
    class function S_DefaultMusicForMap(const episode, map: integer): integer; static;

{$ENDIF}
  end;

implementation

uses
  DelphiDoom.Console.Numbers,
  c_cmds,
  d_player,
  d_think,
  g_game,
  i_system,
  info_h,
  DelphiDoom.Audio.Types,
  DelphiDoom.MapInfo.DefaultMusic,
  DelphiDoom.Audio.SfxAttenuation,
  DelphiDoom.Audio.ChannelPicker,
  DelphiDoom.Audio.ExternalMusicNames,
  m_argv,
  m_fixed,
  m_rnd,
  m_misc,
  p_mobj,
  p_tick,
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  p_local,
  p_maputl,
{$ENDIF}
  r_defs,
  sounddata,
  sounds,
{$IFDEF HEXEN}
  s_sndseq,
{$ENDIF}
  z_zone,
  w_folders,
  w_wad,
  w_pak,
  doomdef,
  r_main,
  tables,
  doomstat;

var
  // given by the composition root (S_ConfigureExternalMusic)
  sound_externalmusic: IExternalMusicCache = nil;
  // given by the composition root (S_ConfigureSound, S_ConfigureMusic)
  sound_sfxfactory: TSfxPlayerFactory = nil;
  sound_music: IMusicPlayer = nil;
  // made by S_InitSoundDevice
  sound_sfx: ISfxPlayer = nil;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TSoundLocalRoutines = class sealed
  public
    class function S_RegisterSong(data: pointer; size: integer): integer; static;
    class function S_GetSfxLumpNum(sfxinfo: Psfxinfo_t): integer; static;
    class function S_StartSfx(id: integer; vol: integer; sep: integer; pitch: integer;
      priority: integer): integer; static;
    class function S_SfxIsPlaying(handle: integer): boolean; static; inline;
    class procedure S_SetUseExternalWav(const newu: boolean); static;
    class function S_ExternalMusicCache: IExternalMusicCache; static;
    class function S_TryLoadExternalMusic(music: Pmusicinfo_t): boolean; static;
    class procedure S_CmdUseMP3(const parm1: string = ''); static;
    class procedure S_CmdUseExternalWav(const parm: string = ''); static;
    class procedure S_CmdMidiTempo(const parm1: string = ''); static;
    class procedure S_DoChangeMusic(music: Pmusicinfo_t; looping: boolean); static;
    class procedure S_StopChannel(cnum: integer); static;
    class function S_AdjustSoundParams(listener: Pmobj_t; source: Pmobj_t;
      vol: Pinteger; sep: Pinteger; pitch: Pinteger): boolean; static;
    class function S_ChannelPriority(ASound: pointer): integer; static;
    class function S_GetChannel(origin: pointer; sfxinfo: Psfxinfo_t): integer; static;
  end;

//==============================================================================
//
// S_ConfigureSound
//
//==============================================================================
class procedure TSoundRoutines.S_ConfigureSound(const AFactory: TSfxPlayerFactory);
begin
  sound_sfxfactory := AFactory;
end;

//==============================================================================
//
// S_ConfigureMusic
//
//==============================================================================
class procedure TSoundRoutines.S_ConfigureMusic(const APlayer: IMusicPlayer);
begin
  sound_music := APlayer;
end;

//==============================================================================
//
// S_InitSoundDevice
//
//==============================================================================
class procedure TSoundRoutines.S_InitSoundDevice;
var
  i: integer;
begin
  if not Assigned(sound_sfxfactory) then
    I_Error('I_InitSound(): the sound was not configured');

  try
    sound_sfx := sound_sfxfactory(M_CheckParm('-nosound') = 0);
  except
    on E: EAudioDeviceException do
      I_Error('%s', [E.Message]);
  end;

  for i := 0 to numsfx - 1 do
    S_sfx[i].data := nil;
end;

//==============================================================================
//
// S_ShutDownSoundDevice
//
//==============================================================================
class procedure TSoundRoutines.S_ShutDownSoundDevice;
begin
  if sound_sfx <> nil then
  begin
    sound_sfx.Shutdown;
    // the cache of the samples goes with the player
    sound_sfx := nil;
  end;

  S_ShutDownSound;
end;

//==============================================================================
//
// S_InitMusicDevice
//
//==============================================================================
class procedure TSoundRoutines.S_InitMusicDevice;
begin
  if sound_music = nil then
    I_Error('I_InitMusic(): the music was not configured');
  sound_music.Initialize;
end;

//==============================================================================
//
// S_ShutDownMusicDevice
//
//==============================================================================
class procedure TSoundRoutines.S_ShutDownMusicDevice;
begin
  if sound_music <> nil then
    sound_music.Shutdown;
end;

//==============================================================================
//
// S_ProcessMusic
//
//==============================================================================
class procedure TSoundRoutines.S_ProcessMusic;
begin
  if sound_music <> nil then
    sound_music.Process;
end;

//==============================================================================
//
// S_RegisterSong
//
// The handle of a song; 0 before the music is configured (as I_RegisterSong did)
//
//==============================================================================
class function TSoundLocalRoutines.S_RegisterSong(data: pointer; size: integer): integer;
begin
  if sound_music <> nil then
    result := sound_music.Register(data, size)
  else
    result := 0;
end;

//==============================================================================
//
// S_GetSfxLumpNum
//
// Retrieve the raw data lump index for a given SFX name (it was I_GetSfxLumpNum).
//
//==============================================================================
class function TSoundLocalRoutines.S_GetSfxLumpNum(sfxinfo: Psfxinfo_t): integer;
var
  namebuf: string;
begin
{$IFNDEF HEXEN}
  // JVAL: 20171216 - Fix links
  if sfxinfo.link <> nil then
    sfxinfo := sfxinfo.link;
{$ENDIF}

  result := -1;

  sprintf(namebuf, 'ds%s', [sfxinfo.name]);
  if Length(namebuf) <= 8 then
    result := TWadRoutines.W_CheckNumForName(namebuf);

  if result = -1 then // JVAL, search without the ds prefix
    result := TWadRoutines.W_CheckNumForName(sfxinfo.name);
end;

//==============================================================================
//
// S_StartSfx
//
// Starts a sound in a channel of the player (it was I_StartSound): a problem of the
// developer is a I_DevError, an impossible state of the player a I_Error. Pitch and
// priority are not used by the mixing, as before.
//
//==============================================================================
class function TSoundLocalRoutines.S_StartSfx(id: integer; vol: integer; sep: integer; pitch: integer;
  priority: integer): integer;
begin
  result := 0;
  if sound_sfx = nil then
    exit;

  try
    result := sound_sfx.Start(id, vol, sep);
  except
    on E: ESfxStartException do
    begin
      I_DevError('%s', [E.Message]);
      result := 0;
    end;
    on E: ESfxFatalException do
      I_Error('%s', [E.Message]);
  end;
end;

//==============================================================================
//
// S_SfxIsPlaying
//
//==============================================================================
class function TSoundLocalRoutines.S_SfxIsPlaying(handle: integer): boolean;
begin
  result := (sound_sfx <> nil) and sound_sfx.IsPlaying(handle);
end;

//==============================================================================
//
// S_SetUseExternalWav
//
// The samples that were read change source: all of them are read again
//
//==============================================================================
class procedure TSoundLocalRoutines.S_SetUseExternalWav(const newu: boolean);
var
  i: integer;
begin
  if newu <> useexternalwav then
  begin
    useexternalwav := newu;
    for i := 0 to numsfx - 1 do
      if S_sfx[i].data <> nil then
      begin
        Z_Free(S_sfx[i].data);
        S_sfx[i].data := nil;
      end;
    if sound_sfx <> nil then
      sound_sfx.ForgetSounds;
  end;
end;

//==============================================================================
//
// S_ConfigureExternalMusic
//
//==============================================================================
class procedure TSoundRoutines.S_ConfigureExternalMusic(const ACache: IExternalMusicCache);
begin
  sound_externalmusic := ACache;
end;

//==============================================================================
//
// S_ExternalMusicCache
//
//==============================================================================
class function TSoundLocalRoutines.S_ExternalMusicCache: IExternalMusicCache;
begin
  if sound_externalmusic = nil then
    I_Error('S_ConfigureExternalMusic() was not called: the external music cannot be loaded');
  result := sound_externalmusic;
end;

//==============================================================================
//
// S_TryLoadExternalMusic
//
// A MOD, S3M, IT or XM file with the name of the lump: the cache finds it and keeps it
//
//==============================================================================
class function TSoundLocalRoutines.S_TryLoadExternalMusic(music: Pmusicinfo_t): boolean;
var
  clip: IExternalMusicClip;
begin
  clip := S_ExternalMusicCache.Find(TWadRoutines.char8tostring(TWadRoutines.W_GetNameForNum(music.lumpnum)));
  if clip = nil then
  begin
    result := false;
    exit;
  end;

  music.data := clip.Data;
  music.handle := S_RegisterSong(music.data, clip.Size);
  result := true;
end;

// Purpose?
const
  snd_prefixen: array[0..11] of AnsiChar =
    ('P', 'P', 'A', 'S', 'S', 'S', 'M', 'M', 'M', 'S', 'S', 'S' );

  S_MAX_VOLUME = 127;

// when to clip out sounds
// Does not fit the large outdoor areas.
  S_CLIPPING_DIST = 1200 * $10000;

// Distance tp origin when sounds should be maxed out.
// This should relate to movement clipping resolution
// (see BLOCKMAP handling).
// Originally: (200*0x10000).
  S_CLOSE_DIST = 160 * $10000;
//  S_CLOSE_DIST = 200 * $10000;

  S_ATTENUATOR = (S_CLIPPING_DIST - S_CLOSE_DIST) div FRACUNIT;

// Adjustable by menu.
  NORM_PITCH = 128;
  NORM_PRIORITY = 64;
  NORM_SEP = 128;

{$IFDEF STRIFE}
  S_PITCH_PERTURB = 1;
{$ENDIF}
  S_STEREO_SWING = 96 * $10000;

type
  channel_t = record
    // sound information (if null, channel avail.)
    sfxinfo: Psfxinfo_t;

    // origin of sound
    origin: pointer;

    // handle of the sound being played
    handle: integer;
  end;
  Pchannel_t = ^channel_t;
  channel_tArray = packed array[0..$FFFF] of channel_t;
  Pchannel_tArray = ^channel_tArray;

// TSfxChannelPicker of Framework\Audio reads the channels as TSfxChannelSlot
{$IF SizeOf(channel_t) <> SizeOf(TSfxChannelSlot)}
  {$MESSAGE ERROR 'channel_t and TSfxChannelSlot must have the same layout'}
{$IFEND}

var
  // The constants and the tables of S_AdjustSoundParams, for TSfxAttenuation
  // (filled by S_Init)
  sound_attenuation: TSfxAttenuationRules;

// the set of channels available
var
  channels: Pchannel_tArray;
  // From Woof: [FG] removed map objects may finish their sounds
  sobjs: Pdegenmobj_tArray;

var
// whether songs are mus_paused
  mus_paused: boolean;

// music currently being played
  mus_playing: Pmusicinfo_t = nil;
  looping_playing: boolean;

//==============================================================================
// S_GetChannel
//
// Internals.
//
//==============================================================================

//==============================================================================
//
// S_AdjustSoundParams
//
//==============================================================================

//==============================================================================
//
// S_StopChannel
//
//==============================================================================

//==============================================================================
//
// S_DoChangeMusic
//
//==============================================================================

//==============================================================================
//
// S_CmdUseMP3
//
//==============================================================================
class procedure TSoundLocalRoutines.S_CmdUseMP3(const parm1: string = '');
var
  newu: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: usemp3 = %s.'#13#10, [truefalseStrings[usemp3]]);
    exit;
  end;

  newu := TConsoleNumbers.EvaluateBoolean(parm1, usemp3);
  if newu <> usemp3 then
  begin
    usemp3 := newu;
    if mus_playing <> nil then
      S_DoChangeMusic(mus_playing, looping_playing);
  end;
  S_CmdUseMP3;
end;

//==============================================================================
//
// S_CmdUseExternalWav
//
//==============================================================================
class procedure TSoundLocalRoutines.S_CmdUseExternalWav(const parm: string = '');
begin
  if parm = '' then
  begin
    printf('Current setting: useexternalwav = %s.'#13#10, [truefalseStrings[useexternalwav]]);
    exit;
  end;

  S_SetUseExternalWav(TConsoleNumbers.EvaluateBoolean(parm, useexternalwav));
  S_CmdUseExternalWav;
end;

//==============================================================================
//
// S_CmdMidiTempo
//
//==============================================================================
class procedure TSoundLocalRoutines.S_CmdMidiTempo(const parm1: string = '');
var
  newt: integer;
begin
  if parm1 = '' then
  begin
    printf('Current setting: miditempo = %d'#13#10, [miditempo]);
    exit;
  end;

  newt := atoi(parm1);
  if (newt > 0) and (newt < 256) then
  begin
    if newt <> miditempo then
    begin
      miditempo := newt;
      if mus_playing <> nil then
        S_DoChangeMusic(mus_playing, looping_playing);
    end;
    S_CmdMidiTempo;
  end
  else
    printf('Specify an integer number in [1..255]'#13#10);

end;

//==============================================================================
// S_Init
//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
//==============================================================================
{$IFDEF STRIFE}
class procedure TSoundRoutines.S_Init(sfxVolume: integer; musicVolume: integer; voiceVolume: integer);
{$ELSE}
class procedure TSoundRoutines.S_Init(sfxVolume: integer; musicVolume: integer);
{$ENDIF}
var
  i: integer;
begin
{$IF DEFINED(DOOM)}
  printf('S_Init: default sfx volume %d'#13#10, [sfxVolume]);
{$ELSEIF DEFINED(STRIFE)}
  printf('S_Init:'#13#10);
  printf('  default sfx volume %d'#13#10, [sfxVolume]);
  printf('  default voice volume %d'#13#10, [voiceVolume]);
  printf('  default music volume %d'#13#10, [musicVolume]);
{$ELSE}
  printf('S_Init:'#13#10);
  printf('  default sfx volume %d'#13#10, [sfxVolume]);
  printf('  default music volume %d'#13#10, [musicVolume]);
{$ENDIF}

  TSoundLocalRoutines.S_ExternalMusicCache.Clear;

  S_SetSfxVolume(sfxVolume);
  // No music with Linux - another dummy.
  S_SetMusicVolume(musicVolume);
{$IFDEF STRIFE}

  S_SetVoiceVolume(voiceVolume);
{$ENDIF}

  sound_attenuation.ClippingDistance := S_CLIPPING_DIST;
  sound_attenuation.CloseDistance := S_CLOSE_DIST;
  sound_attenuation.Attenuator := S_ATTENUATOR;
  sound_attenuation.NormalSeparation := NORM_SEP;
  sound_attenuation.StereoSwing := S_STEREO_SWING;
  sound_attenuation.PointToAngle := @TRendererMain.R_PointToAngle2;
  sound_attenuation.FineSine := PSfxSineTable(finesine);

  // Allocating the internal channels for mixing
  // (the maximum numer of sounds rendered
  // simultaneously) within zone memory.
  if numChannels < MIN_NUMCHANNELS then
    numChannels := MIN_NUMCHANNELS; // JVAL: Set the minimum number of channels

  if numChannels > MAX_NUMCHANNELS then
    numChannels := MAX_NUMCHANNELS; // JVAL: Set the maximum number of channels

  channels := Z_Malloc(numChannels * SizeOf(channel_t), PU_STATIC, nil);
  // From Woof: [FG] removed map objects may finish their sounds
  sobjs := Z_Malloc(numChannels * SizeOf(degenmobj_t), PU_STATIC, nil);

  // Free all channels for use
  for i := 0 to numChannels - 1 do
{$IFDEF HEXEN}
  begin
{$ENDIF}
    channels[i].sfxinfo := nil;
{$IFDEF HEXEN}
    channels[i].origin := nil;
  end;
{$ENDIF}

  // no sounds are playing, and they are not mus_paused
  mus_paused := false;

  // Note that sounds have not been cached (yet).
  for i := 1 to numsfx - 1 do
  begin
    S_sfx[i].lumpnum := -1;
    S_sfx[i].usefulness := -1;
  end;

  C_AddCmd('usemp3', @TSoundLocalRoutines.S_CmdUseMP3);
  C_AddCmd('useexternalwav', @TSoundLocalRoutines.S_CmdUseExternalWav);
  C_AddCmd('miditempo', @TSoundLocalRoutines.S_CmdMidiTempo);
end;

//==============================================================================
//
{$IFDEF DOOM}
// S_InitDEHExtraSounds
//
//==============================================================================
class procedure TSoundRoutines.S_InitDEHExtraSounds;
var
  i: integer;
begin
  // JVAL: 20210109 - DEHEXTRA sounds 500-699
  if M_CheckParm('-NODEHEXTRA') = 0 then
  begin
    for i := 500 to 699 do
    begin
      S_sfx[i].name := 'fre' + IntToStrZfill(3, i - 500);
      S_sfx[i].priority := 127;
      S_sfx[i].lumpnum := -1;
    end;
    numsfx := 700;
  end;
end;

//==============================================================================
//
{$ENDIF}
// S_ShutDownSound
//
//==============================================================================
class procedure TSoundRoutines.S_ShutDownSound;
begin
  S_FreeRandomSoundLists;
  if sound_externalmusic <> nil then
    sound_externalmusic.Clear;
end;

//==============================================================================
//
// S_DefaultMusicForMap
//
//==============================================================================
{$IF DEFINED(HEXEN) OR DEFINED(STRIFE)}
class function TSoundRoutines.S_DefaultMusicForMap(const map: integer): integer;
{$ELSE}
class function TSoundRoutines.S_DefaultMusicForMap(const episode, map: integer): integer;
{$ENDIF}
{$IFNDEF HEXEN}
var
  mapinfomusic: integer;
{$ENDIF}
begin
{$IFNDEF HEXEN}
  mapinfomusic := 0;
  if TGameSession.GameMapInfo <> nil then
    mapinfomusic := TGameSession.GameMapInfo.musicnum;
{$ENDIF}
{$IF DEFINED(HERETIC)}
  result := TDefaultMusic.Heretic(mapinfomusic, episode, map, Ord(mus_e1m1));
{$ELSEIF DEFINED(HEXEN)}
  result := TDefaultMusic.Hexen(map, Ord(mus_map01));
{$ELSEIF DEFINED(STRIFE)}
  result := TDefaultMusic.Strife(mapinfomusic, map);
{$ELSE}
  result := TDefaultMusic.Doom(mapinfomusic, gamemode = commercial, episode, map, Ord(mus_e1m1), Ord(mus_runnin),
    [Ord(mus_e3m4), Ord(mus_e3m2), Ord(mus_e3m3), Ord(mus_e1m5), Ord(mus_e2m7),
     Ord(mus_e2m4), Ord(mus_e2m6), Ord(mus_e2m5), Ord(mus_e1m9)]);
{$ENDIF}end;

//==============================================================================
// S_Start
//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//
//==============================================================================
class procedure TSoundRoutines.S_Start;
var
  cnum: integer;
  mnum: integer;
begin
  // kill all playing sounds at start of level
  //  (trust me - a good idea)
  for cnum := 0 to numChannels - 1 do
    if channels[cnum].sfxinfo <> nil then
      TSoundLocalRoutines.S_StopChannel(cnum);

  // start new music for the level
  mus_paused := false;

{$IF DEFINED(HEXEN) OR DEFINED(STRIFE)}
  mnum := S_DefaultMusicForMap(TGameSession.GameMap);
{$ELSE}
  mnum := S_DefaultMusicForMap(TGameSession.GameEpisode, TGameSession.GameMap);
{$ENDIF}

  S_ChangeMusic(mnum, true);
end;

//==============================================================================
//
// S_StartSoundAtVolume
//
//==============================================================================
class procedure TSoundRoutines.S_StartSoundAtVolume(origin_p: pointer; sfx_id: integer; volume: integer);
var
  rc: boolean;
  sep: integer;
  pitch: integer;
  priority: integer;
  sfx: Psfxinfo_t;
  cnum: integer;
  origin: Pmobj_t;
begin
  origin := Pmobj_t(origin_p);

  // check for bogus sound #
  if (sfx_id < 1) or (sfx_id > numsfx) then
  begin
    I_DevWarning('S_StartSoundAtVolume(): Bad sfx #: %d'#13#10, [sfx_id]);
    exit;
  end;

  sfx := @S_sfx[sfx_id];

  // Initialize sound parameters
{$IFDEF HEXEN}
  pitch := NORM_PITCH;
  priority := sfx.priority;
{$ELSE}
  if sfx.link <> nil then
  begin
    pitch := sfx.pitch;
    priority := sfx.priority;
    volume := volume + sfx.volume;

    if volume < 1 then
      exit;

    if volume > snd_SfxVolume then
      volume := snd_SfxVolume;
  end
  else
  begin
    pitch := NORM_PITCH;
    priority := NORM_PRIORITY;
  end;
{$ENDIF}

  // Check to see if it is audible,
  //  and if not, modify the params
  if (origin <> nil) and (origin <> TGameSession.Players[TGameSession.ConsolePlayer].mo) then
  begin
    rc := TSoundLocalRoutines.S_AdjustSoundParams(TGameSession.Players[TGameSession.ConsolePlayer].mo, origin,
           @volume,
           @sep,
           @pitch);

    if (origin.x = TGameSession.Players[TGameSession.ConsolePlayer].mo.x) and
       (origin.y = TGameSession.Players[TGameSession.ConsolePlayer].mo.y) then
      sep := NORM_SEP;

    if not rc then
      exit;
  end
  else
    sep := NORM_SEP;
{$IF DEFINED(DOOM)}

  // hacks to vary the sfx pitches
  if (sfx_id >= Ord(sfx_sawup)) and
     (sfx_id <= Ord(sfx_sawhit)) then
  begin
    pitch := TSfxAttenuation.PerturbPitch(pitch, M_Random, 15);
  end
  else if (sfx_id <> Ord(sfx_itemup)) and
          (sfx_id <> Ord(sfx_tink)) then
  begin
    pitch := TSfxAttenuation.PerturbPitch(pitch, M_Random, 31);
  end;

  // kill old sound
  S_StopSound(origin);
{$ELSEIF DEFINED(STRIFE)}

  if sfx_id <> Ord(sfx_itemup) then
  begin
    pitch := TSfxAttenuation.PerturbPitch(pitch, M_Random, 31);
  end;

  // kill old sound  [STRIFE] - nope!
//  S_StopSound(origin);
{$ELSE}

  // kill old sound
  S_StopSound(origin);
{$ENDIF}

  // try to find a channel
  cnum := TSoundLocalRoutines.S_GetChannel(origin, sfx);

  if cnum < 0 then
  begin
    I_DevWarning('S_StartSoundAtVolume(): Can not find channel for sfx=%d'#13#10, [sfx_id]);
    exit;
  end;

  //
  // This is supposed to handle the loading/caching.
  // For some odd reason, the caching is done nearly
  //  each time the sound is needed?
  //

  // get lumpnum if necessary
  if sfx.lumpnum < 0 then
  begin
    sfx.lumpnum := TSoundLocalRoutines.S_GetSfxLumpNum(sfx);

    // JVAL
    // Prevent crash, simply don't play the sound
    if sfx.lumpnum < 0 then
    begin
      I_Warning('S_StartSoundAtVolume(): Sfx #: %d not found.'#13#10, [sfx_id]);
      exit;
    end;
  end;

  // increase the usefulness
  if sfx.usefulness < 0 then
    sfx.usefulness := 0; // JVAL ??? original was := 1
  sfx.usefulness := sfx.usefulness + 1;

  // Assigns the handle to one of the channels in the
  //  mix/output buffer.
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  pitch := 127 - (M_Random and 3) + (M_Random and 3);
{$ENDIF}
  channels[cnum].handle := TSoundLocalRoutines.S_StartSfx(sfx_id, volume, sep, pitch, priority);
end;

//==============================================================================
//
// S_StartSound
//
//==============================================================================
class procedure TSoundRoutines.S_StartSound(origin: pointer; sfx_id: integer);
begin
  S_StartSoundAtVolume(origin, sfx_id, snd_SfxVolume);
end;

//==============================================================================
//
// S_StartSound
//
//==============================================================================
class procedure TSoundRoutines.S_StartSound(origin: pointer; const sndname: string);
begin
  S_StartSoundAtVolume(origin, S_GetSoundNumForName(sndname), snd_SfxVolume);
{$IFDEF STRIFE}
end;

//==============================================================================
//
// S_StartVoiceAtVolume
//
//==============================================================================
class procedure TSoundRoutines.S_StartVoiceAtVolume(origin_p: pointer; sfx_id: integer; volume: integer);
var
  rc: boolean;
  sep: integer;
  pitch: integer;
  priority: integer;
  sfx: Psfxinfo_t;
  cnum: integer;
  origin: Pmobj_t;
begin
  if disable_voices then
    exit;

// Disable voices in net game
  if TGameSession.DeathMatch <> 0 then
    exit;

  origin := Pmobj_t(origin_p);

  // check for bogus sound #
  if (sfx_id < 1) or (sfx_id > numsfx) then
  begin
    I_DevWarning('S_StartVoiceAtVolume(): Bad sfx #: %d'#13#10, [sfx_id]);
    exit;
  end;

  sfx := @S_sfx[sfx_id];

  // Initialize sound parameters
  if sfx.link <> nil then
  begin
    pitch := sfx.pitch;
    priority := sfx.priority;
    volume := volume + sfx.volume;

    if volume < 1 then
      exit;

    if volume > snd_VoiceVolume then
      volume := snd_VoiceVolume;
  end
  else
  begin
    pitch := NORM_PITCH;
    priority := sfx.priority;
  end;

  // Check to see if it is audible,
  //  and if not, modify the params
  if (origin <> nil) and (origin <> TGameSession.Players[TGameSession.ConsolePlayer].mo) then
  begin
    rc := TSoundLocalRoutines.S_AdjustSoundParams(TGameSession.Players[TGameSession.ConsolePlayer].mo, origin,
           @volume,
           @sep,
           @pitch);

    if (origin.x = TGameSession.Players[TGameSession.ConsolePlayer].mo.x) and
       (origin.y = TGameSession.Players[TGameSession.ConsolePlayer].mo.y) then
      sep := NORM_SEP;

    if not rc then
      exit;
  end
  else
    sep := NORM_SEP;

  // kill old sound
  S_StopSound(origin);

  // try to find a channel
  cnum := TSoundLocalRoutines.S_GetChannel(origin, sfx);

  if cnum < 0 then
    exit;

  //
  // This is supposed to handle the loading/caching.
  // For some odd reason, the caching is done nearly
  //  each time the sound is needed?
  //

  // get lumpnum if necessary
  if sfx.lumpnum < 0 then
  begin
    sfx.lumpnum := TSoundLocalRoutines.S_GetSfxLumpNum(sfx);

    // JVAL
    // Prevent crash, simply don't play the sound
    if sfx.lumpnum < 0 then
    begin
      I_Warning('S_StartVoiceAtVolume(): Sfx #: %d not found.'#13#10, [sfx_id]);
      exit;
    end;
  end;

  // increase the usefulness
  if sfx.usefulness < 0 then
    sfx.usefulness := 0; // JVAL ??? original was := 1
  sfx.usefulness := sfx.usefulness + 1;

  // Assigns the handle to one of the channels in the
  //  mix/output buffer.
  channels[cnum].handle := TSoundLocalRoutines.S_StartSfx(sfx_id, volume, sep, pitch, priority);
end;

//==============================================================================
//
// S_StartVoice
//
//==============================================================================
class procedure TSoundRoutines.S_StartVoice(const sndname: string);
var
  id: integer;
begin
  if disable_voices then
    exit;

  id := S_GetSoundNumForName(sndname);
  if (id < 0) or (id > numsfx) then
    exit;

  if TWadRoutines.W_CheckNumForName(S_sfx[id].name) < 0 then
    exit;

  S_sfx[id].priority := 2;

  S_StartSoundAtVolume(nil, id, snd_voiceVolume);
{$ENDIF}
end;

//==============================================================================
// S_UnlinkSound
//
// From Woof: [FG] removed map objects may finish their sounds
//
//==============================================================================
class procedure TSoundRoutines.S_UnlinkSound(origin: Pmobj_t);
var
  cnum: integer;
begin
  if origin = nil then
    exit;

  for cnum := 0 to numChannels - 1 do
    if (channels[cnum].sfxinfo <> nil) and (channels[cnum].origin = origin) then
    begin
      sobjs[cnum].x := origin.x;
      sobjs[cnum].y := origin.y;
      sobjs[cnum].z := origin.z;
      channels[cnum].origin := @sobjs[cnum];
      exit;
    end;
end;

//==============================================================================
//
// S_StopSound
//
//==============================================================================
class procedure TSoundRoutines.S_StopSound(origin: pointer);
var
  cnum: integer;
begin
  for cnum := 0 to numChannels - 1 do
  begin
    if (channels[cnum].sfxinfo <> nil) and (channels[cnum].origin = origin) then
    begin
      TSoundLocalRoutines.S_StopChannel(cnum);
      break;
    end;
  end;
end;

//==============================================================================
{$IFDEF HEXEN}
//
// S_StopAllSounds
//
//==============================================================================
class procedure TSoundRoutines.S_StopAllSounds;
var
  i: integer;
begin
  for i := 0 to numChannels - 1 do
    TSoundLocalRoutines.S_StopChannel(i);
end;

//==============================================================================
{$ENDIF}
// S_PauseSound
//
// Stop and resume music, during game PAUSE.
//
//==============================================================================
class procedure TSoundRoutines.S_PauseSound;
begin
  if (mus_playing <> nil) and not mus_paused then
  begin
    if sound_music <> nil then
      sound_music.Pause(mus_playing.handle);
    mus_paused := true;
  end;
end;

//==============================================================================
//
// S_ResumeSound
//
//==============================================================================
class procedure TSoundRoutines.S_ResumeSound;
begin
  if (mus_playing <> nil) and mus_paused then
  begin
    if sound_music <> nil then
      sound_music.Resume(mus_playing.handle);
    mus_paused := false;
  end;
end;

//==============================================================================
// S_UpdateSounds
//
// Updates music & sounds
//
//==============================================================================
class procedure TSoundRoutines.S_UpdateSounds(listener_p: pointer);
var
  audible: boolean;
  cnum: integer;
  volume: integer;
  sep: integer;
  pitch: integer;
{$IFNDEF HEXEN}
  sfx: Psfxinfo_t;
{$ENDIF}
  c: Pchannel_t;
  listener: Pmobj_t;
begin
{$IFDEF HEXEN}
  S_UpdateActiveSequences;

{$ENDIF}
  listener := Pmobj_t(listener_p);

  for cnum := 0 to numChannels - 1 do
  begin
    c := @channels[cnum];
{$IFNDEF HEXEN}
    sfx := c.sfxinfo;
{$ENDIF}

{$IFDEF HEXEN}
    if c.sfxinfo <> nil then
{$ELSE}
    if sfx <> nil then
{$ENDIF}
    begin
      if TSoundLocalRoutines.S_SfxIsPlaying(c.handle) then
      begin
        // initialize parameters
        volume := snd_SfxVolume;
        pitch := NORM_PITCH;
        sep := NORM_SEP;
{$IFNDEF HEXEN}

        if sfx.link <> nil then
        begin
          pitch := sfx.pitch;
          volume := volume + sfx.volume;
          if volume < 1 then
          begin
            TSoundLocalRoutines.S_StopChannel(cnum);
            continue;
          end
          else if volume > snd_SfxVolume then
          begin
            volume := snd_SfxVolume;
          end;
        end;
{$ENDIF}

        // check non-local sounds for distance clipping
        //  or modify their params
        if (c.origin <> nil) and (NativeInt(listener_p) <> NativeInt(c.origin)) then
        begin
          audible := TSoundLocalRoutines.S_AdjustSoundParams(listener, c.origin, @volume, @sep, @pitch);

          if not audible then
          begin
            TSoundLocalRoutines.S_StopChannel(cnum);
          end
          else
            sound_sfx.UpdateParams(c.handle, volume, sep);
        end
      end
      else
      begin
        // if channel is allocated but sound has stopped,
        //  free it
        TSoundLocalRoutines.S_StopChannel(cnum);
      end;
    end;
  end;
end;

//==============================================================================
//
// S_SetMusicVolume
//
//==============================================================================
class procedure TSoundRoutines.S_SetMusicVolume(volume: integer);
begin
  if (volume < 0) or (volume > 15) then
  begin
    I_DevError('S_SetMusicVolume(): Attempt to set music volume at %d', [volume]);
    volume := 8;
  end;

  if sound_music <> nil then
    sound_music.SetVolume(volume);
  snd_MusicVolume := volume;
end;

//==============================================================================
//
// S_SetSfxVolume
//
//==============================================================================
class procedure TSoundRoutines.S_SetSfxVolume(volume: integer);
begin
{$IFDEF DOOM}
  if (volume < 0) or (volume > 15) then
{$ELSE}
  if (volume < 0) or (volume > 127) then
{$ENDIF}
  begin
    I_Warning('S_SetSfxVolume(): Attempt to set sfx volume at %d', [volume]);
{$IFDEF DOOM}
    snd_SfxVolume := 15;
{$ELSE}
    snd_SfxVolume := 64;
{$ENDIF}
  end
  else
    snd_SfxVolume := volume;
{$IFDEF STRIFE}
end;

//==============================================================================
//
// S_SetVoiceVolume
//
//==============================================================================
class procedure TSoundRoutines.S_SetVoiceVolume(volume: integer);
begin
  if (volume < 0) or (volume > 127) then
  begin
    I_Warning('S_SetVoiceVolume(): Attempt to set voice volume at %d', [volume]);
    snd_VoiceVolume := 64;
  end
  else
    snd_VoiceVolume := volume;
{$ENDIF}
end;

//==============================================================================
// S_StartMusic
//
// Starts some music with the music id found in sounds.h.
//
//==============================================================================
class procedure TSoundRoutines.S_StartMusic(music_id: integer);
begin
  S_ChangeMusic(music_id, false);
end;

//==============================================================================
//
// S_DoChangeMusic
//
//==============================================================================
class procedure TSoundLocalRoutines.S_DoChangeMusic(music: Pmusicinfo_t; looping: boolean);
var
  i: integer;
  namebuf: char8_t;
  mp3filename: string;
  mp3header: Pmp3header_t;
  externalmusicfilenames: TArray<string>;
  mp3error: boolean;
begin
  // shutdown old music
  TSoundRoutines.S_StopMusic;

  // get lumpnum if neccessary
{$IFDEF HEXEN}
  if music.lumpnum <= 0 then
{$ELSE}
  if music.lumpnum = 0 then
{$ENDIF}
  begin
{$IF DEFINED(HERETIC)}
    namebuf := TWadRoutines.stringtochar8('MUS_' + music.name);
    music.lumpnum := TWadRoutines.W_CheckNumForName(namebuf);
{$ELSEIF DEFINED(HEXEN)}
    if Length(music.name) <= 4 then
    begin
      namebuf := TWadRoutines.stringtochar8('MUS_' + music.name);
      music.lumpnum := TWadRoutines.W_CheckNumForName(namebuf);
    end;
{$ELSE}
    namebuf := TWadRoutines.stringtochar8('d_' + music.name);
    music.lumpnum := TWadRoutines.W_CheckNumForName(namebuf);
{$ENDIF}
    if music.lumpnum <= 0 then
    begin
{$IF DEFINED(HERETIC)}
      namebuf := TWadRoutines.stringtochar8(music.name);
      music.lumpnum := TWadRoutines.W_GetNumForName(namebuf);
{$ELSEIF DEFINED(HEXEN)}
      namebuf := TWadRoutines.stringtochar8(music.name);
      music.lumpnum := TWadRoutines.W_CheckNumForName(namebuf);
    end;
    if music.lumpnum <= 0 then
    begin
      I_Warning('S_DoChangeMusic(): Can not find music lump for %s, using default'#13#10, [music.mapname]);
      music.name := S_music[Ord(mus_map01)].name;
      music.mapname := S_music[Ord(mus_map01)].mapname;
      music.lumpnum := S_music[Ord(mus_map01)].lumpnum;
      if music.lumpnum <= 0 then
      begin
        namebuf :=  TWadRoutines.stringtochar8(music.name);
        music.lumpnum := TWadRoutines.W_GetNumForName(namebuf);
      end;
{$ELSE}
      namebuf := TWadRoutines.stringtochar8('d_' + music.alias);
      music.lumpnum := TWadRoutines.W_CheckNumForName(namebuf);
      if music.lumpnum <= 0 then
      begin
        namebuf := TWadRoutines.stringtochar8(music.name);
        music.lumpnum := TWadRoutines.W_CheckNumForName(namebuf);
      end;
    end;

    if music.lumpnum <= 0 then
    begin
      namebuf := TWadRoutines.stringtochar8(music.alias);
      music.lumpnum := TWadRoutines.W_GetNumForName(namebuf);
{$ENDIF}
    end;
  end;

  if usemp3 then
  begin
    if music.mp3stream = nil then
    begin

    // JVAL: Create a list with external mp3 filenames to check
    // (TExternalMusicNames of Framework\Audio: map name, song name and aliases)
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
      externalmusicfilenames := TExternalMusicNames.Candidates(music.mapname, music.name,
        '', 'MUS_', false);
{$ELSE}
      externalmusicfilenames := TExternalMusicNames.Candidates(music.mapname, music.name,
        music.alias, 'd_', true);
{$ENDIF}

      for i := 0 to Length(externalmusicfilenames) - 1 do
      begin
        mp3filename := externalmusicfilenames[i];
        if preferemp3namesingamedirectory then
          music.mp3stream := TPakStream.Create(mp3filename, pm_prefered, gamedirectories)
        else
          music.mp3stream := TPakStream.Create(mp3filename, pm_short, '', FOLDER_MUSIC);
        music.mp3stream.OnBeginBusy := I_BeginDiskBusy;
        mp3error := music.mp3stream.IOResult <> 0;
        if mp3error then
          FreeAndNil(music.mp3stream)
        else
          break;
      end;

    end;
  end;

  if usemp3 and (music.mp3stream <> nil) then
  begin
    mp3header := Z_Malloc(SizeOf(mp3header_t), PU_MUSIC, nil);
    mp3header.ID := MP3MAGIC;
    mp3header.Stream := music.mp3stream;
    music.data := mp3header;
    music.handle := S_RegisterSong(music.data, TWadRoutines.W_LumpLength(music.lumpnum));
  end
  else
  begin
    if not S_TryLoadExternalMusic(music) then
    begin
      // load & register it
      music.data := TWadRoutines.W_CacheLumpNum(music.lumpnum, PU_MUSIC);
      music.handle := S_RegisterSong(music.data, TWadRoutines.W_LumpLength(music.lumpnum));
    end;
  end;

  // play it
  if sound_music <> nil then
    sound_music.Play(music.handle, looping);

  mus_playing := music;
  looping_playing := looping;
end;

//==============================================================================
//
// S_ChangeMusic
//
//==============================================================================
class procedure TSoundRoutines.S_ChangeMusic(musicnum: integer; looping: boolean);
var
  music: Pmusicinfo_t;
begin
  if (musicnum <= Ord(mus_None)) or
     (musicnum >= nummusic) then
    I_Error('S_ChangeMusic(): Bad music number %d', [musicnum]);

  music := @S_music[musicnum];

  if mus_playing = music then
    exit;

  if mus_playing <> nil then
    if music.name = mus_playing.name then
      exit;

  TSoundLocalRoutines.S_DoChangeMusic(music, looping);
end;

//==============================================================================
//
// S_StopMusic
//
//==============================================================================
class procedure TSoundRoutines.S_StopMusic;
begin
  if mus_playing <> nil then
  begin
    if mus_paused then
      if sound_music <> nil then
        sound_music.Resume(mus_playing.handle);

    if sound_music <> nil then
      sound_music.Unregister(mus_playing.handle);
    if mus_playing.mp3stream <> nil then
    begin
      FreeAndNil(mus_playing.mp3stream);
      Z_Free(mus_playing.data);
    end
    else
      Z_ChangeTag(mus_playing.data, PU_CACHE);

    mus_playing.data := nil;
    mus_playing := nil;
  end;
end;

//==============================================================================
//
// S_StopChannel
//
//==============================================================================
class procedure TSoundLocalRoutines.S_StopChannel(cnum: integer);
var
  i: integer;
  c: Pchannel_t;
begin
  c := @channels[cnum];

  if c.sfxinfo <> nil then
  begin
    // stop the sound playing
    if S_SfxIsPlaying(c.handle) then
    begin
      sound_sfx.Stop(c.handle);
    end;

    // check to see
    //  if other channels are playing the sound
    for i := 0 to numChannels - 1 do
    begin
      if (cnum <> i) and
         (c.sfxinfo = channels[i].sfxinfo) then
        break;
    end;

    // degrade usefulness of sound data
    c.sfxinfo.usefulness := c.sfxinfo.usefulness - 1;

    c.sfxinfo := nil;
  end;
end;

//==============================================================================
// S_AdjustSoundParams
//
// Changes volume, stereo-separation, and pitch variables
//  from the norm of a sound effect to be played.
// If the sound is not audible, returns a 0.
// Otherwise, modifies parameters and returns 1.
//
//==============================================================================
class function TSoundLocalRoutines.S_AdjustSoundParams(listener: Pmobj_t; source: Pmobj_t;
  vol: Pinteger; sep: Pinteger; pitch: Pinteger): boolean;
var
  fullvolumelevel: boolean;
begin
  // haleyjd 08/12/04: we cannot adjust a sound for a NULL listener
  if listener = nil then
  begin
    result := true;
    exit;
  end;

  // The level of the last boss: nothing is too far to be heard
{$IF DEFINED(DOOM)}
  fullvolumelevel := (TGameSession.GameMap = 8) and G_NeedsCompatibilityMode;
{$ELSEIF DEFINED(HERETIC)}
  fullvolumelevel := TGameSession.GameMap = 8;
{$ELSE}
  fullvolumelevel := false;
{$ENDIF}

  // The rule (distance, clipping, stereo separation, volume) is
  // TSfxAttenuation of Framework\Audio
  result := TSfxAttenuation.Adjust(sound_attenuation, listener.x, listener.y,
    listener.angle + listener.viewangle, source.x, source.y, snd_SfxVolume,
    fullvolumelevel, vol^, sep^);
end;

//==============================================================================
//
// S_ChannelPriority
// The priority of the sound of a channel, for TSfxChannelPicker
//
//==============================================================================
class function TSoundLocalRoutines.S_ChannelPriority(ASound: pointer): integer;
begin
  result := Psfxinfo_t(ASound).priority;
end;

//==============================================================================
//
// S_GetChannel :
//   If none available, return -1.  Otherwise channel #.
//
//==============================================================================
class function TSoundLocalRoutines.S_GetChannel(origin: pointer; sfxinfo: Psfxinfo_t): integer;
var
  choice: TSfxChannelChoice;
  c: Pchannel_t;
begin
  // The choice is TSfxChannelPicker of Framework\Audio: a free channel, the one
  // of the same origin, or one that matters less
  choice := TSfxChannelPicker.Pick(PSfxChannelSlot(channels), numChannels, origin,
    TGameSession.Players[TGameSession.ConsolePlayer].mo, sfxinfo.priority, @S_ChannelPriority);

  if choice.Channel < 0 then
  begin
    // FUCK!  No lower priority.  Sorry, Charlie.
    result := -1;
    exit;
  end;

  if choice.MustStop then
    S_StopChannel(choice.Channel);

  c := @channels[choice.Channel];

  // channel is decided to be cnum.
  c.sfxinfo := sfxinfo;
  c.origin := origin;

  result := choice.Channel;
end;

//==============================================================================
//
{$IF DEFINED(HERETIC)}
// S_GetChannelInfo
//
//==============================================================================
class procedure TSoundRoutines.S_GetChannelInfo(s: Psoundinfo_t);
var
  i: integer;
  c: Pchaninfo_t;
begin
  s.numchannels := numChannels;
  s.musicVolume := snd_MusicVolume;
  s.soundVolume := snd_SfxVolume;
  for i := 0 to numChannels - 1 do
  begin
    c := @s.chan[i];
    if channels[i].sfxinfo <> nil then
    begin
      c.id := channels[i].sfxinfo.lumpnum;  // JVAL: check!
      c.priority := channels[i].sfxinfo.priority;
      c.name := channels[i].sfxinfo.name;
      c.mo := channels[i].origin;
      if c.mo <> nil then
        c.distance := P_AproxDistance(c.mo.x - viewx, c.mo.y - viewy) div FRACUNIT
      else
        c.distance := 0;
      end
    else
    begin
      c.id := 0;
      c.priority := 0;
      c.name := '(NULL)';
      c.mo := nil;
      c.distance := 0;
    end;
  end;
end;

//==============================================================================
//
{$ELSEIF DEFINED(HEXEN)}
// S_GetChannelInfo
//
//==============================================================================
class procedure TSoundRoutines.S_GetChannelInfo(s: Psoundinfo_t);
var
  i: integer;
  c: Pchaninfo_t;
begin
  s.numchannels := numChannels;
  s.musicVolume := snd_MusicVolume;
  s.soundVolume := snd_SfxVolume;
  for i := 0 to numChannels - 1 do
  begin
    c := @s.chan[i];
    if channels[i].sfxinfo <> nil then
    begin
      c.id := channels[i].sfxinfo.lumpnum;  // JVAL: check!
      c.priority := channels[i].sfxinfo.priority;
      c.name := channels[i].sfxinfo.name;
      c.mo := channels[i].origin;
      if c.mo <> nil then
        c.distance := P_AproxDistance(c.mo.x - viewx, c.mo.y - viewy) div FRACUNIT
      else
        c.distance := 0;
      end
    else
    begin
      c.id := 0;
      c.priority := 0;
      c.name := '(NULL)';
      c.mo := nil;
      c.distance := 0;
    end;
  end;
end;

//==============================================================================
//
// S_GetSoundPlayingInfo
//
//==============================================================================
class function TSoundRoutines.S_GetSoundPlayingInfo(mobj: Pmobj_t; sound_id: integer): boolean;
var
  i: integer;
  c_id: integer;
begin
  for i := 0 to numChannels - 1 do
  begin
    if channels[i].origin = mobj then
    begin
      c_id := (NativeInt(channels[i].sfxinfo) - NativeInt(@S_sfx[0])) div SizeOf(sfxinfo_t); // JVAL SOS
      if c_id = sound_id then
        if TSoundLocalRoutines.S_SfxIsPlaying(channels[i].handle) then
        begin
          result := true;
          exit;
        end;
    end;
  end;
  result := false;
end;

//==============================================================================
//
{$ENDIF}
// S_PrecacheSounds
//
//==============================================================================
class procedure TSoundRoutines.S_PrecacheSounds;
var
  hitlist: PBooleanArray;
  i: integer;
  th: Pthinker_t;
  inf: Pmobjinfo_t;
  sndmem: integer;

  procedure Add1(const id: integer);
  begin
    if id > 0 then
      hitlist[id] := true;
  end;

begin
  printf('S_PrecacheSounds()'#13#10);

  hitlist := mallocz(numsfx * SizeOf(boolean));

  th := TTickState.ThinkerCap.next;
  while (th <> nil) and (th <> @TTickState.ThinkerCap) do
  begin
    if @th._function.acp1 = @P_MobjThinker then
    begin
      inf := Pmobj_t(th).info;
      Add1(inf.seesound);
      Add1(inf.attacksound);
      Add1(inf.painsound);
      Add1(inf.deathsound);
      Add1(inf.activesound);
      Add1(inf.meleesound);
      Add1(inf.customsound1);
      Add1(inf.customsound2);
      Add1(inf.customsound3);
      Add1(inf.ripsound);
    end;
    th := th.next;
  end;

  sndmem := 0;
  for i := 1 to numsfx - 1 do
    if hitlist[i] then
    begin
      S_sfx[i].lumpnum := TSoundLocalRoutines.S_GetSfxLumpNum(@S_sfx[i]);
      if S_sfx[i].lumpnum >= 0 then
      begin
        TWadRoutines.W_CacheLumpNum(S_sfx[i].lumpnum, PU_SOUND);
        sndmem := sndmem + TWadRoutines.W_LumpLength(S_sfx[i].lumpnum);
      end;
    end;
  printf('%6d KB memory usage for sound cache'#13#10, [sndmem div 1024]);

  memfree(pointer(hitlist), numsfx * SizeOf(boolean));
end;

end.


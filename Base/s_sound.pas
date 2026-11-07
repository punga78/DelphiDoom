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
  DelphiDoom.Audio.Intf,
  p_mobj_h;

//==============================================================================
//
// S_ConfigureExternalMusic
//
// The cache of the external songs (MOD, S3M, IT, XM next to the WAD) is given by the
// composition root (ComposeEngine); without it S_Init stops with I_Error.
//
//==============================================================================
procedure S_ConfigureExternalMusic(const ACache: IExternalMusicCache);

//==============================================================================
// S_Init
//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
//==============================================================================
{$IF DEFINED(DOOM)}
procedure S_Init(sfxVolume: integer; musicVolume: integer);

//==============================================================================
//
// S_InitDEHExtraSounds
//
//==============================================================================
procedure S_InitDEHExtraSounds;
{$ELSEIF DEFINED(STRIFE)}
procedure S_Init(sfxVolume: integer; musicVolume: integer; voiceVolume: integer);
{$ELSE}
procedure S_Init(sfxVolume: integer; musicVolume: integer);
{$ENDIF}

//==============================================================================
//
// S_ShutDownSound
//
//==============================================================================
procedure S_ShutDownSound;

//==============================================================================
// S_Start
//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//
//==============================================================================
procedure S_Start;

//==============================================================================
// S_StartSound
//
// Start sound for thing at <origin>
//  using <sound_id> from sounds.h
//
//==============================================================================
procedure S_StartSound(origin: pointer; sfx_id: integer); overload;

//==============================================================================
//
// S_StartSound
//
//==============================================================================
procedure S_StartSound(origin: pointer; const sndname: string); overload;

//==============================================================================
// S_StartSoundAtVolume
//
// Will start a sound at a given volume.
//
//==============================================================================
procedure S_StartSoundAtVolume(origin_p: pointer; sfx_id: integer; volume: integer);
{$IFDEF STRIFE}

//==============================================================================
// S_StartVoice
//
// Voice volume
//
//==============================================================================
procedure S_StartVoice(const sndname: string);

//==============================================================================
//
// S_StartVoiceAtVolume
//
//==============================================================================
procedure S_StartVoiceAtVolume(origin_p: pointer; sfx_id: integer; volume: integer);
{$ENDIF}

//==============================================================================
//
// S_UnlinkSound
//
//==============================================================================
procedure S_UnlinkSound(origin: Pmobj_t);

//==============================================================================
// S_StopSound
//
// Stop sound for thing at <origin>
//
//==============================================================================
procedure S_StopSound(origin: pointer);
{$IFDEF HEXEN}

//==============================================================================
// S_StopAllSounds
//
// Stop all sounds
//
//==============================================================================
procedure S_StopAllSounds;
{$ENDIF}

//==============================================================================
// S_StartMusic
//
// Start music using <music_id> from sounds.h
//
//==============================================================================
procedure S_StartMusic(music_id: integer);

//==============================================================================
// S_ChangeMusic
//
// Start music using <music_id> from sounds.h,
//  and set whether looping
//
//==============================================================================
procedure S_ChangeMusic(musicnum: integer; looping: boolean);

//==============================================================================
// S_StopMusic
//
// Stops the music fer sure.
//
//==============================================================================
procedure S_StopMusic;

//==============================================================================
// S_PauseSound
//
// Stop and resume music, during game PAUSE.
//
//==============================================================================
procedure S_PauseSound;

//==============================================================================
//
// S_ResumeSound
//
//==============================================================================
procedure S_ResumeSound;

//==============================================================================
// S_UpdateSounds
//
// Updates music & sounds
//
//==============================================================================
procedure S_UpdateSounds(listener_p: pointer);

//==============================================================================
//
// S_SetMusicVolume
//
//==============================================================================
procedure S_SetMusicVolume(volume: integer);

//==============================================================================
//
// S_SetSfxVolume
//
//==============================================================================
procedure S_SetSfxVolume(volume: integer);

//==============================================================================
//
{$IFDEF STRIFE}
// S_SetVoiceVolume
//
//==============================================================================
procedure S_SetVoiceVolume(volume: integer);

//==============================================================================
//
{$ENDIF}
// S_PrecacheSounds
//
//==============================================================================
procedure S_PrecacheSounds;

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

//==============================================================================
//
// S_GetChannelInfo
//
//==============================================================================
procedure S_GetChannelInfo(s: Psoundinfo_t);

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

//==============================================================================
//
// S_GetChannelInfo
//
//==============================================================================
procedure S_GetChannelInfo(s: Psoundinfo_t);

//==============================================================================
//
// S_GetSoundPlayingInfo
//
//==============================================================================
function S_GetSoundPlayingInfo(mobj: Pmobj_t; sound_id: integer): boolean;

{$ENDIF}
//==============================================================================
//
// S_DefaultMusicForMap
//
//==============================================================================
{$IF DEFINED(HEXEN) OR DEFINED(STRIFE)}
function S_DefaultMusicForMap(const map: integer): integer;
{$ELSE}
function S_DefaultMusicForMap(const episode, map: integer): integer;
{$ENDIF}

var
  full_sounds: boolean = true;
  usemp3: boolean;
  preferemp3namesingamedirectory: boolean;

implementation

uses
  d_delphi,
  c_cmds,
  d_player,
  d_think,
  g_game,
  i_system,
  i_sound,
  i_music,
  info_h,
{$IFDEF DOOM}
  m_argv,
{$ENDIF}
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

//==============================================================================
//
// S_ConfigureExternalMusic
//
//==============================================================================
procedure S_ConfigureExternalMusic(const ACache: IExternalMusicCache);
begin
  sound_externalmusic := ACache;
end;

//==============================================================================
//
// S_ExternalMusicCache
//
//==============================================================================
function S_ExternalMusicCache: IExternalMusicCache;
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
function S_TryLoadExternalMusic(music: Pmusicinfo_t): boolean;
var
  clip: IExternalMusicClip;
begin
  clip := S_ExternalMusicCache.Find(char8tostring(W_GetNameForNum(music.lumpnum)));
  if clip = nil then
  begin
    result := false;
    exit;
  end;

  music.data := clip.Data;
  music.handle := I_RegisterSong(music.data, clip.Size);
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
function S_GetChannel(origin: pointer; sfxinfo: Psfxinfo_t): integer; forward;

//==============================================================================
//
// S_AdjustSoundParams
//
//==============================================================================
function S_AdjustSoundParams(listener: Pmobj_t; source: Pmobj_t;
  vol: Pinteger; sep: Pinteger; pitch: Pinteger): boolean; forward;

//==============================================================================
//
// S_StopChannel
//
//==============================================================================
procedure S_StopChannel(cnum: integer); forward;

//==============================================================================
//
// S_DoChangeMusic
//
//==============================================================================
procedure S_DoChangeMusic(music: Pmusicinfo_t; looping: boolean); forward;

//==============================================================================
//
// S_CmdUseMP3
//
//==============================================================================
procedure S_CmdUseMP3(const parm1: string = '');
var
  newu: boolean;
begin
  if parm1 = '' then
  begin
    printf('Current setting: usemp3 = %s.'#13#10, [truefalseStrings[usemp3]]);
    exit;
  end;

  newu := C_BoolEval(parm1, usemp3);
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
procedure S_CmdUseExternalWav(const parm: string = '');
begin
  if parm = '' then
  begin
    printf('Current setting: useexternalwav = %s.'#13#10, [truefalseStrings[useexternalwav]]);
    exit;
  end;

  I_SetUseExternalWav(C_BoolEval(parm, useexternalwav));
  S_CmdUseExternalWav;
end;

//==============================================================================
//
// S_CmdMidiTempo
//
//==============================================================================
procedure S_CmdMidiTempo(const parm1: string = '');
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
procedure S_Init(sfxVolume: integer; musicVolume: integer; voiceVolume: integer);
{$ELSE}
procedure S_Init(sfxVolume: integer; musicVolume: integer);
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

  S_ExternalMusicCache.Clear;

  // Whatever these did with DMX, these are rather dummies now.
  I_SetChannels;

  S_SetSfxVolume(sfxVolume);
  // No music with Linux - another dummy.
  S_SetMusicVolume(musicVolume);
{$IFDEF STRIFE}

  S_SetVoiceVolume(voiceVolume);
{$ENDIF}

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

  C_AddCmd('usemp3', @S_CmdUseMP3);
  C_AddCmd('useexternalwav', @S_CmdUseExternalWav);
  C_AddCmd('miditempo', @S_CmdMidiTempo);
end;

//==============================================================================
//
{$IFDEF DOOM}
// S_InitDEHExtraSounds
//
//==============================================================================
procedure S_InitDEHExtraSounds;
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
procedure S_ShutDownSound;
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
function S_DefaultMusicForMap(const map: integer): integer;
{$ELSE}
function S_DefaultMusicForMap(const episode, map: integer): integer;
{$ENDIF}
begin
{$IF DEFINED(HERETIC)}
  if (gamemapinfo <> nil) and (gamemapinfo.musicnum > 0) then
    result := gamemapinfo.musicnum
  else if episode < 6 then
  // JVAL: Use DEH files to specify new sounds for E4
    result := Ord(mus_e1m1) + (episode - 1) * 9 + map - 1
  else  // JVAL Game episode > 5 ????
  begin
    case map of
      1: result := Ord(mus_e1m1);
      2: result := Ord(mus_e1m2);
      3: result := Ord(mus_e1m3);
      4: result := Ord(mus_e1m4);
      5: result := Ord(mus_e1m5);
      6: result := Ord(mus_e1m6);
      7: result := Ord(mus_e1m7);
      8: result := Ord(mus_e1m8);
      9: result := Ord(mus_e1m9);
    else
      result := Ord(mus_e1m1); // JVAL ?????
    end;
  end;
{$ELSEIF DEFINED(HEXEN)}
  result := Ord(mus_map01) + map - 1;
{$ELSEIF DEFINED(STRIFE)}
  if (gamemapinfo <> nil) and (gamemapinfo.musicnum > 0) then
    result := gamemapinfo.musicnum
  // [STRIFE] Some interesting math here ;)
  else if map <= 31 then
    result := map + 1
  else
    result := map - 30;
{$ELSE}
  if (gamemapinfo <> nil) and (gamemapinfo.musicnum > 0) then
    result := gamemapinfo.musicnum
  else if gamemode = commercial then
  begin
    if map = 99 then
      result := Ord(mus_runnin)
    else
      result := Ord(mus_runnin) + map - 1;
  end
  else
  begin
    // JVAL: Use DEH files to specify new sounds for E4
    if episode < 5 then
      result := Ord(mus_e1m1) + (episode - 1) * 9 + map - 1
    else  // JVAL Game episode > 4 ????
    begin
      case map of
        1: result := Ord(mus_e3m4); // American   e4m1
        2: result := Ord(mus_e3m2); // Romero     e4m2
        3: result := Ord(mus_e3m3); // Shawn      e4m3
        4: result := Ord(mus_e1m5); // American   e4m4
        5: result := Ord(mus_e2m7); // Tim        e4m5
        6: result := Ord(mus_e2m4); // Romero     e4m6
        7: result := Ord(mus_e2m6); // J.Anderson e4m7 CHIRON.WAD
        8: result := Ord(mus_e2m5); // Shawn      e4m8
        9: result := Ord(mus_e1m9); // Tim        e4m9
      else
        result := Ord(mus_e1m1); // JVAL ?????
      end;
    end;
  end;
{$ENDIF}
end;

//==============================================================================
// S_Start
//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//
//==============================================================================
procedure S_Start;
var
  cnum: integer;
  mnum: integer;
begin
  // kill all playing sounds at start of level
  //  (trust me - a good idea)
  for cnum := 0 to numChannels - 1 do
    if channels[cnum].sfxinfo <> nil then
      S_StopChannel(cnum);

  // start new music for the level
  mus_paused := false;

{$IF DEFINED(HEXEN) OR DEFINED(STRIFE)}
  mnum := S_DefaultMusicForMap(gamemap);
{$ELSE}
  mnum := S_DefaultMusicForMap(gameepisode, gamemap);
{$ENDIF}

  S_ChangeMusic(mnum, true);
end;

//==============================================================================
//
// S_StartSoundAtVolume
//
//==============================================================================
procedure S_StartSoundAtVolume(origin_p: pointer; sfx_id: integer; volume: integer);
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
  if (origin <> nil) and (origin <> players[consoleplayer].mo) then
  begin
    rc := S_AdjustSoundParams(players[consoleplayer].mo, origin,
           @volume,
           @sep,
           @pitch);

    if (origin.x = players[consoleplayer].mo.x) and
       (origin.y = players[consoleplayer].mo.y) then
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
    pitch := pitch + 8 - (M_Random and 15);

    if pitch < 0 then
      pitch := 0
    else if pitch > 255 then
      pitch := 255
  end
  else if (sfx_id <> Ord(sfx_itemup)) and
          (sfx_id <> Ord(sfx_tink)) then
  begin
    pitch := pitch + 16 - (M_Random and 31);

    if pitch < 0 then
      pitch := 0
    else if pitch > 255 then
      pitch := 255;
  end;

  // kill old sound
  S_StopSound(origin);
{$ELSEIF DEFINED(STRIFE)}

  if sfx_id <> Ord(sfx_itemup) then
  begin
    pitch := pitch + 16 - (M_Random and 31);

    if pitch < 0 then
      pitch := 0
    else if pitch > 255 then
      pitch := 255;
  end;

  // kill old sound  [STRIFE] - nope!
//  S_StopSound(origin);
{$ELSE}

  // kill old sound
  S_StopSound(origin);
{$ENDIF}

  // try to find a channel
  cnum := S_GetChannel(origin, sfx);

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
    sfx.lumpnum := I_GetSfxLumpNum(sfx);

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
  channels[cnum].handle := I_StartSound(sfx_id, volume, sep, pitch, priority);
end;

//==============================================================================
//
// S_StartSound
//
//==============================================================================
procedure S_StartSound(origin: pointer; sfx_id: integer);
begin
  S_StartSoundAtVolume(origin, sfx_id, snd_SfxVolume);
end;

//==============================================================================
//
// S_StartSound
//
//==============================================================================
procedure S_StartSound(origin: pointer; const sndname: string);
begin
  S_StartSoundAtVolume(origin, S_GetSoundNumForName(sndname), snd_SfxVolume);
{$IFDEF STRIFE}
end;

//==============================================================================
//
// S_StartVoiceAtVolume
//
//==============================================================================
procedure S_StartVoiceAtVolume(origin_p: pointer; sfx_id: integer; volume: integer);
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
  if deathmatch <> 0 then
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
  if (origin <> nil) and (origin <> players[consoleplayer].mo) then
  begin
    rc := S_AdjustSoundParams(players[consoleplayer].mo, origin,
           @volume,
           @sep,
           @pitch);

    if (origin.x = players[consoleplayer].mo.x) and
       (origin.y = players[consoleplayer].mo.y) then
      sep := NORM_SEP;

    if not rc then
      exit;
  end
  else
    sep := NORM_SEP;

  // kill old sound
  S_StopSound(origin);

  // try to find a channel
  cnum := S_GetChannel(origin, sfx);

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
    sfx.lumpnum := I_GetSfxLumpNum(sfx);

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
  channels[cnum].handle := I_StartSound(sfx_id, volume, sep, pitch, priority);
end;

//==============================================================================
//
// S_StartVoice
//
//==============================================================================
procedure S_StartVoice(const sndname: string);
var
  id: integer;
begin
  if disable_voices then
    exit;

  id := S_GetSoundNumForName(sndname);
  if (id < 0) or (id > numsfx) then
    exit;

  if W_CheckNumForName(S_sfx[id].name) < 0 then
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
procedure S_UnlinkSound(origin: Pmobj_t);
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
procedure S_StopSound(origin: pointer);
var
  cnum: integer;
begin
  for cnum := 0 to numChannels - 1 do
  begin
    if (channels[cnum].sfxinfo <> nil) and (channels[cnum].origin = origin) then
    begin
      S_StopChannel(cnum);
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
procedure S_StopAllSounds;
var
  i: integer;
begin
  for i := 0 to numChannels - 1 do
    S_StopChannel(i);
end;

//==============================================================================
{$ENDIF}
// S_PauseSound
//
// Stop and resume music, during game PAUSE.
//
//==============================================================================
procedure S_PauseSound;
begin
  if (mus_playing <> nil) and not mus_paused then
  begin
    I_PauseSong(mus_playing.handle);
    mus_paused := true;
  end;
end;

//==============================================================================
//
// S_ResumeSound
//
//==============================================================================
procedure S_ResumeSound;
begin
  if (mus_playing <> nil) and mus_paused then
  begin
    I_ResumeSong(mus_playing.handle);
    mus_paused := false;
  end;
end;

//==============================================================================
// S_UpdateSounds
//
// Updates music & sounds
//
//==============================================================================
procedure S_UpdateSounds(listener_p: pointer);
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
      if I_SoundIsPlaying(c.handle) then
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
            S_StopChannel(cnum);
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
        if (c.origin <> nil) and (integer(listener_p) <> integer(c.origin)) then
        begin
          audible := S_AdjustSoundParams(listener, c.origin, @volume, @sep, @pitch);

          if not audible then
          begin
            S_StopChannel(cnum);
          end
          else
            I_UpdateSoundParams(c.handle, volume, sep, pitch);
        end
      end
      else
      begin
        // if channel is allocated but sound has stopped,
        //  free it
        S_StopChannel(cnum);
      end;
    end;
  end;
end;

//==============================================================================
//
// S_SetMusicVolume
//
//==============================================================================
procedure S_SetMusicVolume(volume: integer);
begin
  if (volume < 0) or (volume > 15) then
  begin
    I_DevError('S_SetMusicVolume(): Attempt to set music volume at %d', [volume]);
    volume := 8;
  end;

  I_SetMusicVolume(volume);
  snd_MusicVolume := volume;
end;

//==============================================================================
//
// S_SetSfxVolume
//
//==============================================================================
procedure S_SetSfxVolume(volume: integer);
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
procedure S_SetVoiceVolume(volume: integer);
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
procedure S_StartMusic(music_id: integer);
begin
  S_ChangeMusic(music_id, false);
end;

//==============================================================================
//
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
// S_GetListFromAlias
//
//==============================================================================
function S_GetListFromAlias(const s: string): TDStringList;
var
  stmp: string;
  i: integer;
begin
  result := TDStringList.Create;
  if s <> '' then
  begin
    stmp := '';
    for i := 1 to Length(s) do
      if s[i] in [' ', ','] then
        stmp := stmp + #13#10
      else
        stmp := stmp + toupper(s[i]);
    result.Text := stmp;
    for i := result.count - 1 downto 0 do
      if result.strings[i] = '' then
        result.Delete(i);
  end;
end;

//==============================================================================
//
{$ENDIF}
// S_DoChangeMusic
//
//==============================================================================
procedure S_DoChangeMusic(music: Pmusicinfo_t; looping: boolean);
var
  i: integer;
  namebuf: char8_t;
  mp3filename: string;
  mp3header: Pmp3header_t;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  externalmusicfilenames: TDStringList;
{$ELSE}
  aliases, externalmusicfilenames: TDStringList;
{$ENDIF}
  mp3error: boolean;
begin
  // shutdown old music
  S_StopMusic;

  // get lumpnum if neccessary
{$IFDEF HEXEN}
  if music.lumpnum <= 0 then
{$ELSE}
  if music.lumpnum = 0 then
{$ENDIF}
  begin
{$IF DEFINED(HERETIC)}
    namebuf := stringtochar8('MUS_' + music.name);
    music.lumpnum := W_CheckNumForName(namebuf);
{$ELSEIF DEFINED(HEXEN)}
    if Length(music.name) <= 4 then
    begin
      namebuf := stringtochar8('MUS_' + music.name);
      music.lumpnum := W_CheckNumForName(namebuf);
    end;
{$ELSE}
    namebuf := stringtochar8('d_' + music.name);
    music.lumpnum := W_CheckNumForName(namebuf);
{$ENDIF}
    if music.lumpnum <= 0 then
    begin
{$IF DEFINED(HERETIC)}
      namebuf := stringtochar8(music.name);
      music.lumpnum := W_GetNumForName(namebuf);
{$ELSEIF DEFINED(HEXEN)}
      namebuf := stringtochar8(music.name);
      music.lumpnum := W_CheckNumForName(namebuf);
    end;
    if music.lumpnum <= 0 then
    begin
      I_Warning('S_DoChangeMusic(): Can not find music lump for %s, using default'#13#10, [music.mapname]);
      music.name := S_music[Ord(mus_map01)].name;
      music.mapname := S_music[Ord(mus_map01)].mapname;
      music.lumpnum := S_music[Ord(mus_map01)].lumpnum;
      if music.lumpnum <= 0 then
      begin
        namebuf :=  stringtochar8(music.name);
        music.lumpnum := W_GetNumForName(namebuf);
      end;
{$ELSE}
      namebuf := stringtochar8('d_' + music.alias);
      music.lumpnum := W_CheckNumForName(namebuf);
      if music.lumpnum <= 0 then
      begin
        namebuf := stringtochar8(music.name);
        music.lumpnum := W_CheckNumForName(namebuf);
      end;
    end;

    if music.lumpnum <= 0 then
    begin
      namebuf := stringtochar8(music.alias);
      music.lumpnum := W_GetNumForName(namebuf);
{$ENDIF}
    end;
  end;

  if usemp3 then
  begin
    if music.mp3stream = nil then
    begin

    // JVAL: Create a list with external mp3 filenames to check
      externalmusicfilenames := TDStringList.Create;
      if music.mapname <> '' then
      begin
        externalmusicfilenames.Add(music.mapname + '.mp3');
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
        externalmusicfilenames.Add('MUS_' + music.mapname + '.mp3');
{$ELSE}
        externalmusicfilenames.Add('d_' + music.mapname + '.mp3');
{$ENDIF}
      end;
      externalmusicfilenames.Add(music.name + '.mp3');
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
      externalmusicfilenames.Add('MUS_' + music.name + '.mp3');
{$ELSE}
      externalmusicfilenames.Add('d_' + music.name + '.mp3');

    // JVAL: Add aliases in check list
      aliases := S_GetListFromAlias(music.alias);
      for i := 0 to aliases.Count - 1 do
      begin
        externalmusicfilenames.Add(aliases.strings[i] + '.mp3');
        externalmusicfilenames.Add('d_' + aliases.strings[i] + '.mp3');
      end;
      aliases.Free;
{$ENDIF}

      for i := 0 to externalmusicfilenames.Count - 1 do
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

      externalmusicfilenames.Free;

    end;
  end;

  if usemp3 and (music.mp3stream <> nil) then
  begin
    mp3header := Z_Malloc(SizeOf(mp3header_t), PU_MUSIC, nil);
    mp3header.ID := MP3MAGIC;
    mp3header.Stream := music.mp3stream;
    music.data := mp3header;
    music.handle := I_RegisterSong(music.data, W_LumpLength(music.lumpnum));
  end
  else
  begin
    if not S_TryLoadExternalMusic(music) then
    begin
      // load & register it
      music.data := W_CacheLumpNum(music.lumpnum, PU_MUSIC);
      music.handle := I_RegisterSong(music.data, W_LumpLength(music.lumpnum));
    end;
  end;

  // play it
  I_PlaySong(music.handle, looping);

  mus_playing := music;
  looping_playing := looping;
end;

//==============================================================================
//
// S_ChangeMusic
//
//==============================================================================
procedure S_ChangeMusic(musicnum: integer; looping: boolean);
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

  S_DoChangeMusic(music, looping);
end;

//==============================================================================
//
// S_StopMusic
//
//==============================================================================
procedure S_StopMusic;
begin
  if mus_playing <> nil then
  begin
    if mus_paused then
      I_ResumeSong(mus_playing.handle);

    I_UnRegisterSong(mus_playing.handle);
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
procedure S_StopChannel(cnum: integer);
var
  i: integer;
  c: Pchannel_t;
begin
  c := @channels[cnum];

  if c.sfxinfo <> nil then
  begin
    // stop the sound playing
    if I_SoundIsPlaying(c.handle) then
    begin
      I_StopSound(c.handle);
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
function S_AdjustSoundParams(listener: Pmobj_t; source: Pmobj_t;
  vol: Pinteger; sep: Pinteger; pitch: Pinteger): boolean;
var
  approx_dist: fixed_t;
  adx: fixed_t;
  ady: fixed_t;
  ad: fixed_t;
  angle: angle_t;
  langle: angle_t;
begin
  // haleyjd 08/12/04: we cannot adjust a sound for a NULL listener
  if listener = nil then
  begin
    result := true;
    exit;
  end;

  // calculate the distance to sound origin
  //  and clip it if necessary
  adx := abs(listener.x - source.x);
  ady := abs(listener.y - source.y);

  if adx < ady then
    ad := adx
  else
    ad := ady;
  // From _GG1_ p.428. Appox. eucledian distance fast.
  approx_dist := adx + ady - ad div 2;

  // killough 11/98: handle zero-distance as special case
  if approx_dist = 0 then
  begin
    sep^ := NORM_SEP;
    vol^ := snd_SfxVolume;
    result := vol^ > 0;
    exit;
  end;

{$IF DEFINED(DOOM)}
  if ((gamemap <> 8) or not G_NeedsCompatibilityMode) and
     (approx_dist > S_CLIPPING_DIST) then
{$ELSEIF DEFINED(HERETIC)}
  if (gamemap <> 8) and
     (approx_dist > S_CLIPPING_DIST) then
{$ELSE}
  if approx_dist > S_CLIPPING_DIST then
{$ENDIF}
  begin
    result := false;
    exit;
  end;

  // angle of source to listener
  angle := R_PointToAngle2(listener.x, listener.y, source.x, source.y);

  langle := listener.angle + listener.viewangle;
  if angle > langle then
    angle := angle - langle
  else
    angle := angle + ($ffffffff - langle);

  {$IFDEF FPC}
  angle := angle div ANGLETOFINEUNIT;
  {$ELSE}
  angle := angle shr ANGLETOFINESHIFT;
  {$ENDIF}

  // stereo separation
  sep^ := NORM_SEP - (FixedMul(S_STEREO_SWING, finesine[angle]) div FRACUNIT);

  // volume calculation
  if approx_dist < S_CLOSE_DIST then
  begin
    vol^ := snd_SfxVolume;
{$IF DEFINED(DOOM)}
  end
  else if (gamemap = 8) and G_NeedsCompatibilityMode then
  begin
    if approx_dist > S_CLIPPING_DIST then
      approx_dist := S_CLIPPING_DIST;

    vol^ := 15 + ((snd_SfxVolume - 15) *
      ((S_CLIPPING_DIST - approx_dist) div FRACUNIT)) div S_ATTENUATOR;
{$ELSEIF DEFINED(HERETIC)}
  end
  else if gamemap = 8 then
  begin
    if approx_dist > S_CLIPPING_DIST then
      approx_dist := S_CLIPPING_DIST;

    vol^ := 15 + ((snd_SfxVolume - 15) *
      ((S_CLIPPING_DIST - approx_dist) div FRACUNIT)) div S_ATTENUATOR;
{$ENDIF}
  end
  else
  begin
    // distance effect
    vol^ := (snd_SfxVolume * ((S_CLIPPING_DIST - approx_dist) div FRACUNIT)) div
              S_ATTENUATOR;
  end;

  result := vol^ > 0;
end;

//==============================================================================
//
// S_GetChannel :
//   If none available, return -1.  Otherwise channel #.
//
//==============================================================================
function S_GetChannel(origin: pointer; sfxinfo: Psfxinfo_t): integer;
var
  // channel number to use
  cnum: integer;
  c: Pchannel_t;
  listener: pointer;
begin
  // Find an open channel
  cnum := 0;
  while cnum < numChannels do
  begin
    if channels[cnum].sfxinfo = nil then
      break
    else if (origin <> nil) and (channels[cnum].origin = origin) then
    begin
      S_StopChannel(cnum);
      break;
    end;
    inc(cnum);
  end;

  // None available
  if cnum = numChannels then
  begin
    // Look for lower priority
    cnum := 0;
    while cnum < numChannels do
    begin
      if channels[cnum].sfxinfo.priority > sfxinfo.priority then
        break;
      inc(cnum);
    end;

    if cnum = numChannels then
    begin
      cnum := 0;
      while cnum < numChannels do
      begin
        if channels[cnum].sfxinfo.priority = sfxinfo.priority then
          break;
        inc(cnum);
      end;
    end;

    if cnum = numChannels then
    begin
      listener := players[consoleplayer].mo;
      if (origin = listener) or (origin = nil) then
      begin
        cnum := 0;
        while cnum < numChannels do
        begin
          if (channels[cnum].origin <> nil) and (channels[cnum].origin <> listener) then
            break;
          inc(cnum);
        end;
      end;
    end;

    if cnum = numChannels then
    begin
      // FUCK!  No lower priority.  Sorry, Charlie.
      result := -1;
      exit;
    end
    else
    begin
      // Otherwise, kick out lower priority.
      S_StopChannel(cnum);
    end;
  end;

  c := @channels[cnum];

  // channel is decided to be cnum.
  c.sfxinfo := sfxinfo;
  c.origin := origin;

  result := cnum;
end;

//==============================================================================
//
{$IF DEFINED(HERETIC)}
// S_GetChannelInfo
//
//==============================================================================
procedure S_GetChannelInfo(s: Psoundinfo_t);
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
procedure S_GetChannelInfo(s: Psoundinfo_t);
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
function S_GetSoundPlayingInfo(mobj: Pmobj_t; sound_id: integer): boolean;
var
  i: integer;
  c_id: integer;
begin
  for i := 0 to numChannels - 1 do
  begin
    if channels[i].origin = mobj then
    begin
      c_id := (integer(channels[i].sfxinfo) - integer(@S_sfx[0])) div SizeOf(sfxinfo_t); // JVAL SOS
      if c_id = sound_id then
        if I_SoundIsPlaying(channels[i].handle) then
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
procedure S_PrecacheSounds;
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

  th := thinkercap.next;
  while (th <> nil) and (th <> @thinkercap) do
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
      S_sfx[i].lumpnum := I_GetSfxLumpNum(@S_sfx[i]);
      if S_sfx[i].lumpnum >= 0 then
      begin
        W_CacheLumpNum(S_sfx[i].lumpnum, PU_SOUND);
        sndmem := sndmem + W_LumpLength(S_sfx[i].lumpnum);
      end;
    end;
  printf('%6d KB memory usage for sound cache'#13#10, [sndmem div 1024]);

  memfree(pointer(hitlist), numsfx * SizeOf(boolean));
end;

end.


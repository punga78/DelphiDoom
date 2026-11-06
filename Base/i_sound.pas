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
//   System interface, sound.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit i_sound;

interface

uses
  sounddata,
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf;

//==============================================================================
// I_InitSound
//
// Init at program start...
//
//==============================================================================
procedure I_InitSound;

//==============================================================================
// I_ShutDownSound
//
// ... shut down and relase at program termination.
//
//==============================================================================
procedure I_ShutDownSound;

//==============================================================================
// I_SetChannels
//
//  SFX I/O
//
// Initialize channels?
//
//==============================================================================
procedure I_SetChannels;

//==============================================================================
// I_GetSfxLumpNum
//
// Get raw data lump index for sound descriptor.
//
//==============================================================================
function I_GetSfxLumpNum(sfxinfo: Psfxinfo_t): integer;

//==============================================================================
// I_StartSound
//
// Starts a sound in a particular sound channel.
//
//==============================================================================
function I_StartSound(id: integer; vol: integer; sep: integer;
  pitch: integer; priority: integer): integer;

//==============================================================================
// I_StopSound
//
// Stops a sound channel.
//
//==============================================================================
procedure I_StopSound(handle: integer);

//==============================================================================
// I_SoundIsPlaying
//
// Called by S_*() functions
//  to see if a channel is still playing.
// Returns 0 if no longer playing, 1 if playing.
//
//==============================================================================
function I_SoundIsPlaying(handle: integer): boolean;

//==============================================================================
// I_UpdateSoundParams
//
// Updates the volume, separation,
//  and pitch of a sound channel.
//
//==============================================================================
procedure I_UpdateSoundParams(handle: integer; vol: integer; sep: integer;
  pitch: integer);

var
  useexternalwav: boolean;
  preferewavnamesingamedirectory: boolean;

//==============================================================================
//
// I_SetUseExternalWav
//
//==============================================================================
procedure I_SetUseExternalWav(const newu: boolean);

type
  /// <summary>Makes the player of the sound effects; false: no sound card, only handles</summary>
  TSfxPlayerFactory = reference to function(AWithDevice: Boolean): ISfxPlayer;

//==============================================================================
//
// I_ConfigureSound
// Gives the unit the way to make its player. The composition root calls it
//
//==============================================================================
procedure I_ConfigureSound(const AFactory: TSfxPlayerFactory);

//==============================================================================
//
// I_GetSfxSample
// The sample of a sound effect, cached if it was not
//
//==============================================================================
function I_GetSfxSample(const id: integer): TSfxSample;

//==============================================================================
//
// I_DiscardExternalSfx
// The external sample of a sound caused a problem: it will not be used again
//
//==============================================================================
procedure I_DiscardExternalSfx(const id: integer);

//==============================================================================
//
// I_StoreSfxAverageBytes
//
//==============================================================================
procedure I_StoreSfxAverageBytes(const id: integer; const avgbytes: LongWord);

//==============================================================================
//
// I_SfxName
//
//==============================================================================
function I_SfxName(const id: integer): string;

implementation

uses
  d_delphi,
{$IFNDEF DLL}
  DelphiDoom.Audio.SoundLibrary, // JVAL: 20210117 - Search for various sound formats
{$ENDIF}
  MMSystem,
  z_zone,
  m_argv,
  i_system,
  s_sound,
  w_wad,
  w_folders,
  w_pak,
  doomdef;

type
  wavestatus_t = (ws_nowave, ws_internalwave, ws_externalwave, ws_wavefailed);

  soundparam_t = record
    length: integer;
    offset: integer;
    wavformat: word;
    freq: LongWord;
    avgfreq: LongWord;
    samples: byte;
    channels: byte;
    wavestatus: wavestatus_t;
  end;
  Psoundparam_t = ^soundparam_t;

  soundparam_tArray = array[0..$FFFF] of soundparam_t;
  Psoundparam_tArray = ^soundparam_tArray;

var
  soundparams: Psoundparam_tArray = nil;
  numsoundparams: integer = 0;

//==============================================================================
//
// GetSoundParam
//
//==============================================================================
function GetSoundParam(id: integer): Psoundparam_t;
var
  oldsize: integer;
begin
  if id >= numsoundparams then
  begin
    oldsize := numsoundparams * SizeOf(soundparam_t);
    numsoundparams := id + 1;
    realloc(pointer(soundparams), oldsize, numsoundparams * SizeOf(soundparam_t));
    soundparams[id].wavestatus := ws_nowave;
  end;
  result := @soundparams[id];
end;

type
  soundheader_t = record
    filler1: word;
    freq: word;
  end;
  Psoundheader_t = ^soundheader_t;

//==============================================================================
// I_GetSfxLumpNum
//
// Retrieve the raw data lump index
//  for a given SFX name.
//
//==============================================================================
function I_GetSfxLumpNum(sfxinfo: Psfxinfo_t): integer;
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
    result := W_CheckNumForName(namebuf);

  if result = -1 then // JVAL, search without the ds prefix
    result := W_CheckNumForName(sfxinfo.name);
end;

// This function loads the sound data from the WAD lump,
//  for single sound.
//
const
  CS_RIFF = $46464952;  // RIFF in HEX
  CS_WAVE = $45564157;  // WAVE in HEX
  CS_fmt  = $20746D66;  // fmt' ' in HEX
  CS_data = $61746164;  // data in HEX

{$IFNDEF DLL}
const
  CS_fLac = 1130450022; // fLac
  CS_OggS = 1399285583; // OggS
  CS_CVoc = 1634038339; // Crea
{$ENDIF}

//==============================================================================
//
// I_CacheSFX
//
//==============================================================================
procedure I_CacheSFX(const sfxid: integer);
var
  name: string;
  sfx: Psfxinfo_t;
  lump: integer;
  strm: TDStream;
  wavfilename: string;
  externalwavfilenames: TDStringList;
  foundwav: boolean;
  wavformat: TWAVEFORMATEX;
  i: integer;
  l: LongWord;
  len: integer;
  datalen: integer;
  dwtype: LongWord;
  dwlen: integer;
  donefmt, donedata: boolean;
  PLData, PLData2: PLongWordArray;
  plwhat: integer;
  sparm: Psoundparam_t;
begin
  sfx := @S_sfx[sfxid];
  if sfx.data <> nil then
    exit;

  sparm := GetSoundParam(sfxid);

  strm := nil;
  foundwav := false;

  if useexternalwav and (sparm.wavestatus <> ws_wavefailed) then
  begin
    // JVAL: 20210117 - Search for various sound formats
{$IFNDEF DLL}
    foundwav := Audiolib_SearchSoundPAK(sfx.name, strm, 0);

    if not foundwav then
{$ENDIF}
    begin
      // JVAL: Create a list with external wav filenames to check
      externalwavfilenames := TDStringList.Create;
      externalwavfilenames.Add('ds%s.wav', [sfx.name]);
      externalwavfilenames.Add('%s.wav', [sfx.name]);

      for i := 0 to externalwavfilenames.Count - 1 do
      begin
        wavfilename := externalwavfilenames[i];
        if preferewavnamesingamedirectory then
          strm := TPakStream.Create(wavfilename, pm_prefered, gamedirectories)
        else
          strm := TPakStream.Create(wavfilename, pm_short, '', FOLDER_SOUNDS);
        strm.OnBeginBusy := I_BeginDiskBusy;
        foundwav := strm.IOResult = 0;
        if foundwav then
          break
        else
          strm.Free;
      end;

      externalwavfilenames.Free;

    end;
  end;

  datalen := 0;
  donefmt := false;
  donedata := false;
  if foundwav then
  begin
    repeat
      if strm.Size < 8 + SizeOf(TWAVEFORMATEX) then
      begin
        I_Warning('CacheSFX(): Sound %s.wav has invalid size'#13#10, [sfx.name]);
        foundwav := false;
        break;
      end;

      strm.Seek(0, sFromBeginning);
      strm.Read(l, SizeOf(LongWord));
      if l <> CS_RIFF then
      begin
        I_Warning('CacheSFX(): Sound %s.wav has invalid header'#13#10, [sfx.name]);
        foundwav := false;
        break;
      end;

      strm.Read(datalen, SizeOf(integer));
      strm.Read(l, SizeOf(LongWord));
      if l <> CS_WAVE then
      begin
        I_Warning('CacheSFX(): Sound %s.wav has not the WAVE file indicator'#13#10, [sfx.name]);
        foundwav := false;
        break;
      end;

      while strm.Position < strm.Size - 8 do
      begin
        strm.Read(dwtype, SizeOf(LongWord));
        strm.Read(dwlen, SizeOf(LongWord));
        if dwtype = CS_fmt then
        begin
          if (dwlen < SizeOf(TWAVEFORMAT)) and not donefmt then
          begin
            I_Warning('CacheSFX(): Sound %s.wav has invalid fmt CHUNK'#13#10, [sfx.name]);
            foundwav := false;
            break;
          end;
          donefmt := true;
          strm.Read(wavformat, SizeOf(TWAVEFORMATEX));
          if wavformat.wFormatTag <> WAVE_FORMAT_PCM then
          begin
            I_Warning('CacheSFX(): Sound %s.wav is not a WAV file'#13#10, [sfx.name]);
            foundwav := false;
            break;
          end;

          strm.Seek(dwlen - SizeOf(TWAVEFORMATEX), sFromCurrent);
          sparm.wavformat := wavformat.wFormatTag;
          sparm.freq := wavformat.nSamplesPerSec;
          sparm.avgfreq := wavformat.nAvgBytesPerSec;
          sparm.samples := wavformat.wBitsPerSample;
          sparm.channels := wavformat.nChannels;
        end
        else if (dwtype = CS_data) and not donedata then
        begin
          if dwlen > strm.Size - strm.Position then
          begin
            I_Warning('CacheSFX(): Sound %s.wav has invalid data CHUNK'#13#10, [sfx.name]);
            foundwav := false;
            break;
          end;
          donedata := true;
          sparm.length := dwlen;
          sfx.data := Z_Malloc(dwlen, PU_SOUND, @sfx.data);
          strm.Read(sfx.data^, dwlen);
          sparm.offset := 0;
        end
        else
          strm.Seek(-6, sFromCurrent);
        if donefmt and donedata then
        begin
          sparm.wavestatus := ws_externalwave;
          break;
        end;
      end;

    until true;
    strm.Free;
  end;

  if not foundwav then
  begin

    if sfx.lumpnum = -1 then
    begin
      // Get the sound data from the WAD, allocate lump
      //  in zone memory.
      sprintf(name, 'ds%s', [sfx.name]);

      // Now, there is a severe problem with the
      //  sound handling, in it is not (yet/anymore)
      //  gamemode aware. That means, sounds from
      //  DOOM II will be requested even with DOOM
      //  shareware.
      // The sound list is wired into sounds.c,
      //  which sets the external variable.
      // I do not do runtime patches to that
      //  variable. Instead, we will use a
      //  default sound for replacement.
      lump := -1;
      if Length(name) <= 8 then
        lump := W_CheckNumForName(name);

      if lump = -1 then // JVAL Search without the DS prefix
      begin
        name := sfx.name;
        lump := W_CheckNumForName(name);
      end;

      if lump = -1 then
        sfx.lumpnum := W_GetNumForName('dspistol')
      else
        sfx.lumpnum := lump;
    end;

    sfx.data := W_CacheLumpNum(sfx.lumpnum, PU_SOUND);
    len := W_LumpLength(sfx.lumpnum);
    PLData := sfx.data;
{$IFNDEF DLL}
    if (PLData[0] = CS_fLac) or (PLData[0] = CS_OggS) or (PLData[0] = CS_CVoc) then
      if Audiolib_DecodeSoundWAD(sfx.data, len, @sfx.data, len, 1) then
        PLData := sfx.data;
{$ENDIF}
    PLData2 := PLongWordArray(Integer(PLData) + 2);
    if PLData[0] = CS_RIFF then // WAVE Sound inside WAD as lump
    begin

      repeat
        if len < 8 + SizeOf(TWAVEFORMATEX) then
        begin
          I_Warning('CacheSFX(): Sound %s has invalid size'#13#10, [sfx.name]);
          break;
        end;

        i := 1;
        datalen := PLData[i];
        inc(i);
        if PLData[i] <> CS_WAVE then
        begin
          I_Warning('CacheSFX(): Sound %s has not the WAVE file indicator'#13#10, [sfx.name]);
          break;
        end;

        while i < (len div 4) - 2 do
        begin
          dwtype := PLData[i];
          if (dwtype <> CS_fmt) and (dwtype <> CS_data) then
          begin
            dwtype := PLData2[i];
            dwlen := PLData2[i + 1];
            plwhat := 2;
          end
          else
          begin
            dwlen := PLData[i + 1];
            plwhat := 1;
          end;
          i := i + 2;
          if (dwtype = CS_fmt) and not donefmt then
          begin
            if dwlen < SizeOf(TWAVEFORMAT) then
            begin
              I_Warning('CacheSFX(): Sound %s has invalid fmt CHUNK'#13#10, [sfx.name]);
              break;
            end;
            donefmt := true;
            memcpy(@wavformat, @PLData[i], SizeOf(TWAVEFORMATEX));
            if wavformat.wFormatTag <> WAVE_FORMAT_PCM then
            begin
              I_Warning('CacheSFX(): Sound %s is not a WAV file'#13#10, [sfx.name]);
              break;
            end;

            i := i + dwlen div 4; // JVAL: skip WAVEFORMAT record
            sparm.wavformat := wavformat.wFormatTag;
            sparm.freq := wavformat.nSamplesPerSec;
            sparm.avgfreq := wavformat.nAvgBytesPerSec;
            sparm.samples := wavformat.wBitsPerSample;
            sparm.channels := wavformat.nChannels;
          end
          else if (dwtype = CS_data) and not donedata then
          begin
            if dwlen > len - i * 4 then
            begin
              I_Warning('CacheSFX(): Sound %s has invalid data CHUNK'#13#10, [sfx.name]);
              break;
            end;
            donedata := true;
            sparm.length := dwlen;
            sparm.offSet := i * 4;
            if plwhat = 2 then
              sparm.offset := sparm.offset + 2;
          end
          else
            dec(i);
          if donefmt and donedata then
          begin
            sparm.wavestatus := ws_internalwave;
            break;
          end;
        end;

      until true;

/////////////////////

    end
    else
    begin
      sparm.length := len;
      sparm.wavformat := WAVE_FORMAT_PCM;
      sparm.freq := Psoundheader_t(sfx.data).freq;
      sparm.avgfreq := Psoundheader_t(sfx.data).freq;
      sparm.samples := 8;
      sparm.channels := 1;
      sparm.offset := 8;
    end;
  end;
end;

//==============================================================================
// I_SetChannels
//
// SFX API
// Note: this was called by S_Init.
// However, whatever they did in the
// old DPMS based DOS version, this
// were simply dummies in the Linux
// version.
// See soundserver initdata().
//
//==============================================================================
procedure I_SetChannels;
begin
end;

//==============================================================================
//
// I_SetSfxVolume
//
//==============================================================================
procedure I_SetSfxVolume(volume: integer);
begin
  // Identical to DOS.
  // Basically, this should propagate
  //  the menu/config file setting
  //  to the state variable used in
  //  the mixing.
  snd_SfxVolume := volume;
end;

var
  // given by the composition root (I_ConfigureSound)
  sfx_factory: TSfxPlayerFactory = nil;
  sfx_player: ISfxPlayer = nil;

//==============================================================================
//
// I_ConfigureSound
//
//==============================================================================
procedure I_ConfigureSound(const AFactory: TSfxPlayerFactory);
begin
  sfx_factory := AFactory;
end;

//==============================================================================
//
// I_GetSfxSample
//
//==============================================================================
function I_GetSfxSample(const id: integer): TSfxSample;
var
  sparm: Psoundparam_t;
begin
  I_CacheSFX(id);
  sparm := GetSoundParam(id);
  result.Format.Tag := sparm.wavformat;
  result.Format.Channels := sparm.channels;
  result.Format.SamplesPerSecond := sparm.freq;
  result.Format.AverageBytesPerSecond := sparm.avgfreq;
  result.Format.BitsPerSample := sparm.samples;
  result.Data := System.PByte(S_sfx[id].data);
  result.Offset := sparm.offset;
  result.Length := sparm.length;
  result.IsExternal := sparm.wavestatus = ws_externalwave;
end;

//==============================================================================
//
// I_DiscardExternalSfx
//
//==============================================================================
procedure I_DiscardExternalSfx(const id: integer);
begin
  GetSoundParam(id).wavestatus := ws_wavefailed;
  Z_Free(S_sfx[id].data);
  S_sfx[id].data := nil;
end;

//==============================================================================
//
// I_StoreSfxAverageBytes
//
//==============================================================================
procedure I_StoreSfxAverageBytes(const id: integer; const avgbytes: LongWord);
begin
  GetSoundParam(id).avgfreq := avgbytes;
end;

//==============================================================================
//
// I_SfxName
//
//==============================================================================
function I_SfxName(const id: integer): string;
begin
  result := S_sfx[id].name;
end;

//==============================================================================
// I_StartSound
//
// Starting a sound means adding it
//  to the current list of active sounds
//  in the internal channels.
// As the SFX info struct contains
//  e.g. a pointer to the raw data,
//  it is ignored.
// As our sound handling does not handle
//  priority, it is ignored.
// Pitching (that is, increased speed of playback)
//  is set, but currently not used by mixing.
//
//==============================================================================
function I_StartSound(id: integer; vol: integer; sep: integer;
  pitch: integer; priority: integer): integer;
begin
  result := 0;
  if sfx_player = nil then
    exit;

  try
    result := sfx_player.Start(id, vol, sep);
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
// I_StopSound
//
//==============================================================================
procedure I_StopSound(handle: integer);
begin
  if sfx_player <> nil then
    sfx_player.Stop(handle);
end;

//==============================================================================
//
// I_SoundIsPlaying
//
//==============================================================================
function I_SoundIsPlaying(handle: integer): boolean;
begin
  result := (sfx_player <> nil) and sfx_player.IsPlaying(handle);
end;

//==============================================================================
//
// I_UpdateSoundParams
//
//==============================================================================
procedure I_UpdateSoundParams(handle: integer; vol: integer; sep: integer;
  pitch: integer);
begin
  if sfx_player <> nil then
    sfx_player.UpdateParams(handle, vol, sep);
end;

//==============================================================================
//
// I_ShutDownSound
//
//==============================================================================
procedure I_ShutDownSound;
begin
  if sfx_player <> nil then
  begin
    sfx_player.Shutdown;
    sfx_player := nil;
  end;

  memfree(pointer(soundparams), numsoundparams * SizeOf(soundparam_t));

  S_ShutDownSound;
end;

//==============================================================================
//
// I_InitSound
//
//==============================================================================
procedure I_InitSound;
var
  i: integer;
begin
  if not Assigned(sfx_factory) then
    I_Error('I_InitSound(): the sound was not configured');

  try
    sfx_player := sfx_factory(M_CheckParm('-nosound') = 0);
  except
    on E: EAudioDeviceException do
      I_Error('%s', [E.Message]);
  end;

  for i := 0 to numsfx - 1 do
    S_sfx[i].data := nil;
end;

//==============================================================================
//
// I_SetUseExternalWav
//
//==============================================================================
procedure I_SetUseExternalWav(const newu: boolean);
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
    if sfx_player <> nil then
      sfx_player.ForgetSounds;
  end;
end;

end.
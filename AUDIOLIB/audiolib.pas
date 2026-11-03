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
//   Ogg, flac, etc sounds.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit audiolib;

interface

uses
  d_delphi;

//==============================================================================
//
// Audiolib_SearchSoundPAK
//
//==============================================================================
function Audiolib_SearchSoundPAK(const sndname: string; var streamout: TDStream;
  const normalize: integer): boolean;

//==============================================================================
//
// Audiolib_DecodeSoundWAD
//
//==============================================================================
function Audiolib_DecodeSoundWAD(memin: Pointer; meminsize: integer;
  memout: PPointer; var memoutsize: integer; const normalize: integer): boolean;

implementation

uses
  doomdef,
  i_system,
  i_sound,
  DelphiDoom.Sndfile.Intf,
  DelphiDoom.Audio.SoundConverter,
  w_folders,
  w_pak,
  z_zone;

//==============================================================================
//
// Audiolib_SearchSoundPAK
//
//==============================================================================
function Audiolib_SearchSoundPAK(const sndname: string; var streamout: TDStream;
  const normalize: integer): boolean;
var
  streamin: TPakStream;
  externalsoundfilenames: TDStringList;
  i: integer;
  foundsound: boolean;
  soundfilename: string;
  source: pointer;
  sourcesize: integer;
  wav: TArray<Byte>;
begin
  externalsoundfilenames := TDStringList.Create;
  externalsoundfilenames.Add('%s.ogg', [sndname]);
  externalsoundfilenames.Add('%s.oga', [sndname]);
  externalsoundfilenames.Add('%s.flac', [sndname]);
  externalsoundfilenames.Add('%s.voc', [sndname]);
  externalsoundfilenames.Add('%s.au', [sndname]);
  externalsoundfilenames.Add('%s.snd', [sndname]);
  externalsoundfilenames.Add('ds%s.ogg', [sndname]);
  externalsoundfilenames.Add('ds%s.oga', [sndname]);
  externalsoundfilenames.Add('ds%s.flac', [sndname]);
  externalsoundfilenames.Add('ds%s.voc', [sndname]);
  externalsoundfilenames.Add('ds%s.au', [sndname]);
  externalsoundfilenames.Add('ds%s.snd', [sndname]);

  foundsound := false;
  streamin := nil;

  for i := 0 to externalsoundfilenames.Count - 1 do
  begin
    soundfilename := externalsoundfilenames[i];
    if preferewavnamesingamedirectory then
      streamin := TPakStream.Create(soundfilename, pm_prefered, gamedirectories)
    else
      streamin := TPakStream.Create(soundfilename, pm_short, '', FOLDER_SOUNDS);
    streamin.OnBeginBusy := I_BeginDiskBusy;
    foundsound := streamin.IOResult = 0;
    if foundsound then
      break
    else
      streamin.Free;
  end;

  externalsoundfilenames.Free;

  streamout := nil;
  if not foundsound then
  begin
    Result := false;
    Exit;
  end;

  sourcesize := streamin.Size;
  source := malloc(sourcesize);
  try
    streamin.Seek(0, sFromBeginning);
    streamin.Read(source^, sourcesize);
    try
      wav := TSoundConverter.ToWav(source, sourcesize, normalize <> 0);
    except
      on ESndfileException do
        wav := nil;
    end;
  finally
    memfree(source, sourcesize);
    streamin.Free;
  end;

  Result := Length(wav) > 0;
  if not Result then
    Exit;

  streamout := TDMemoryStream.Create;
  streamout.OnBeginBusy := I_BeginDiskBusy;
  streamout.Write(wav[0], Length(wav));
  streamout.Seek(0, sFromBeginning);
  printf('Audiolib_SearchSoundPAK(): Found external sound %s'#13#10, [soundfilename]);
end;

//==============================================================================
//
// Audiolib_DecodeSoundWAD
//
//==============================================================================
function Audiolib_DecodeSoundWAD(memin: Pointer; meminsize: integer;
  memout: PPointer; var memoutsize: integer; const normalize: integer): boolean;
var
  wav: TArray<Byte>;
begin
  try
    wav := TSoundConverter.ToWav(memin, meminsize, normalize <> 0);
  except
    on ESndfileException do
      wav := nil;
  end;

  Result := Length(wav) > 0;
  if not Result then
  begin
    memout^ := nil;
    memoutsize := 0;
    Exit;
  end;

  memoutsize := Length(wav);
  memout^ := Z_Malloc(memoutsize, PU_SOUND, memout);
  Move(wav[0], memout^^, memoutsize);
end;

end.


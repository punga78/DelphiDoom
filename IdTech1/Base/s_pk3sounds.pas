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
// DESCRIPTION:
//  Use wav sounds inside PK3 without a WAD corresponding alias
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit s_pk3sounds;

interface

uses
  DelphiDoom.Platform.Intf;

//==============================================================================
//
// S_ConfigurePK3Sounds
//
// The temporary files where the WAD of the sounds of the PK3 goes, given by the
// composition root (ComposeEngine); without them W_InitPK3Sounds stops with I_Error.
//
//==============================================================================
procedure S_ConfigurePK3Sounds(const ATempFiles: ITempFiles);

//==============================================================================
//
// W_InitPK3Sounds
//
//==============================================================================
procedure W_InitPK3Sounds;

implementation

uses
  d_delphi,
  i_system,
  m_argv,
  DelphiDoom.MathCore.Sha1,
  DelphiDoom.Audio.Pk3SoundNames,
  w_pak,
  w_wad,
  w_wadwriter;

var
  s_names: TPk3SoundNames;
  // given by the composition root (S_ConfigurePK3Sounds)
  s_tempfiles: ITempFiles = nil;

//==============================================================================
//
// S_ConfigurePK3Sounds
//
//==============================================================================
procedure S_ConfigurePK3Sounds(const ATempFiles: ITempFiles);
begin
  s_tempfiles := ATempFiles;
end;

const
  DSSTUBLUMP: array[0..149] of Byte = (
    $03, $00, $11, $2B, $8E, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80,
    $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80, $80
  );

//==============================================================================
//
// S_AddFileName
//
//==============================================================================
procedure S_AddFileName(const filename: string);
begin
  s_names.AddFile(filename);
end;

//==============================================================================
//
// W_InitPK3Sounds
//
//==============================================================================
procedure W_InitPK3Sounds;
var
  wad: TWADWriter;
  wadfilename: string;
  i: integer;
  mem: TDMemoryStream;
  lumpnames: TArray<string>;
begin
  if s_tempfiles = nil then
    I_Error('W_InitPK3Sounds(): the temporary files were not configured');

  s_names := TPk3SoundNames.Create(
    function(const AName: string): Integer
    begin
      Result := TWadRoutines.W_CheckNumForName(AName);
    end);

  PAK_FileNameIterator(@S_AddFileName);

  lumpnames := s_names.Names;
  if Length(lumpnames) > 0 then
  begin
    wad := TWadWriter.Create;

    for i := 0 to Length(lumpnames) - 1 do
      wad.AddData(lumpnames[i], @DSSTUBLUMP, SizeOf(DSSTUBLUMP));

    mem := TDMemoryStream.Create;

    wad.SaveToStream(mem);

    wadfilename := M_SaveFileName('DATA\');
    MkDir(wadfilename);
    wadfilename := wadfilename + 'TMP\';
    MkDir(wadfilename);
    wadfilename := wadfilename + 'pk3sounds_' + readablestring(TSha1.ToRawString(TSha1.Calculate(mem.memory^, mem.Size))) + '.wad';
    mem.Free;

    wad.SaveToFile(wadfilename);

    wad.Free;

    TWadRoutines.W_RuntimeLoad(wadfilename, F_ORIGIN_WAD);

    s_tempfiles.Declare(wadfilename);
  end;

  s_names.Free;
end;

end.

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
//  Speed Haste: the race in a saved game. The saved game of the engine and
//  p_saveg do not change: the state of the race goes in a file beside each
//  one, <saved game>.speed (TRacingSaveGameCodec of Libs\Racing).
//  G_ConfigureSaveGameExtension (g_game) calls SH_SaveGame after the engine has
//  written its file and SH_LoadGame after it has read its own and built the
//  level again.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit speed_saveg;

interface

//==============================================================================
//
// SH_SaveGame
//
//==============================================================================
procedure SH_SaveGame(const filename: string);

//==============================================================================
//
// SH_LoadGame
//
//==============================================================================
procedure SH_LoadGame(const filename: string);

//==============================================================================
//
// SH_ScriptSaveGame, SH_ScriptLoadGame
// The steps "save" and "load" of a script of commands (-autoscript)
//
//==============================================================================
procedure SH_ScriptSaveGame(slot: integer);

procedure SH_ScriptLoadGame(slot: integer);

implementation

uses
  SysUtils,
  Classes,
  g_game,
  speed_race,
  DelphiDoom.Racing.SaveGameCodec;

const
  SIDE_FILE_EXTENSION = '.speed';

//==============================================================================
//
// SH_SaveGame
//
//==============================================================================
procedure SH_SaveGame(const filename: string);
var
  bytes: TBytes;
  stream: TFileStream;
begin
  if SH_Race = nil then
    exit;
  bytes := TRacingSaveGameCodec.Encode(SH_Race, SH_Random);
  stream := TFileStream.Create(filename + SIDE_FILE_EXTENSION, fmCreate);
  try
    stream.WriteBuffer(bytes[0], Length(bytes));
  finally
    stream.Free;
  end;
end;

//==============================================================================
//
// SH_LoadGame
//
//==============================================================================
procedure SH_LoadGame(const filename: string);
var
  bytes: TBytes;
  stream: TFileStream;
  name: string;
begin
  if SH_Race = nil then
    exit;
  name := filename + SIDE_FILE_EXTENSION;
  // the objects of the saved game are the ones of the race now: the cars take them again, and the
  // thinker that the engine freed with the others goes back to the head of the list
  SH_RebindCars;
  SH_AddRaceThinker;
  if not FileExists(name) then
  begin
    SH_RaceLog('Speed Haste: the saved game has no state of the race (' + name + '): the race starts again');
    exit;
  end;
  stream := TFileStream.Create(name, fmOpenRead or fmShareDenyNone);
  try
    SetLength(bytes, stream.Size);
    if Length(bytes) > 0 then
      stream.ReadBuffer(bytes[0], Length(bytes));
  finally
    stream.Free;
  end;
  if not TRacingSaveGameCodec.Decode(SH_Race, bytes, SH_Random) then
    SH_RaceLog('Speed Haste: the state of the race in ' + name + ' is not of this level: the race starts again');
end;

//==============================================================================
//
// SH_ScriptSaveGame
//
//==============================================================================
procedure SH_ScriptSaveGame(slot: integer);
begin
  G_SaveGame(slot, 'AUTOSCRIPT');
end;

//==============================================================================
//
// SH_ScriptLoadGame
//
//==============================================================================
procedure SH_ScriptLoadGame(slot: integer);
begin
  G_LoadGame(IntToStr(slot));
end;

end.

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
//  Radix: the table of the ten best pilots and the name of the pilot
//  (radix_score.pas of Rad-X and the pilot name of its d_player/m_defs).
//  The rules (order, insertion, file format) are TRadixScoreTable of
//  IdTech1\Radix; this unit keeps the table of the game, its file and the scores
//  of the levels flown (Rad-X had them in player_t.scores).
//  Differences from Rad-X: the name of the pilot is in a file of its own
//  beside the scores (Rad-X had it in the configuration file); the scores of
//  the levels are not in the saved games.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit radix_score;

interface

uses
  DelphiDoom.Radix.Debriefing,
  DelphiDoom.Radix.Score.Table;

const
  PILOTNAMESIZE = RADIX_PILOT_NAME_SIZE;

  SCOREPOSITIONTEXT: array[1..RADIX_SCORE_COUNT] of string = (
    '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th');

var
  // 8 bit text: it goes in the file of the scores
  pilotname: AnsiString = '';

//==============================================================================
//
// RX_LoadScoreTable
// The table and the name of the pilot from their files (nothing if they are
// not there)
//
//==============================================================================
procedure RX_LoadScoreTable;

//==============================================================================
//
// RX_SaveScoreTable
//
//==============================================================================
procedure RX_SaveScoreTable;

//==============================================================================
//
// RX_SavePilotName
//
//==============================================================================
procedure RX_SavePilotName;

//==============================================================================
//
// RX_ScoreTable
// The table of the game (made empty at the first call)
//
//==============================================================================
function RX_ScoreTable: TRadixScoreTable;

//==============================================================================
//
// RX_ClearLevelScores
// A new game: the pilot has flown no level yet
//
//==============================================================================
procedure RX_ClearLevelScores;

//==============================================================================
//
// RX_StoreLevelScore
// The marks of the level that has just ended. With update the pilot is put in
// the table (and the table is saved) if the sum of the levels of the episode
// is good enough: the place taken, or TRadixScoreTable.NO_POSITION
//
//==============================================================================
function RX_StoreLevelScore(const score: TRadixDebriefingScore; const epi, map, skill: integer;
  const update: boolean): integer;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  d_delphi,
  i_system,
  m_argv,
  m_base,
  DelphiDoom.Radix.Types;

const
  MAXEPISODES = 3;
  PILOTFILEEXT = '.pilot';
  SCOREFILEEXT = '.sco';

var
  scoretable: TRadixScoreTable = nil;
  levelscores: array[1..MAXEPISODES, 1..TRadixScoreTable.LEVELS_PER_EPISODE] of integer;

//==============================================================================
//
// RX_ScoreTable
//
//==============================================================================
function RX_ScoreTable: TRadixScoreTable;
begin
  if scoretable = nil then
    scoretable := TRadixScoreTable.Create;
  result := scoretable;
end;

//==============================================================================
//
// RX_LoadScoreTable
//
//==============================================================================
procedure RX_LoadScoreTable;
var
  fname: string;
  bad: integer;
  name: TBytes;
begin
  RX_ScoreTable.Clear;
  fname := M_SaveFileName(APPNAME + SCOREFILEEXT);
  if fexists(fname) then
    try
      bad := RX_ScoreTable.Decode(System.IOUtils.TFile.ReadAllBytes(fname));
      if bad > 0 then
        I_Warning('RX_LoadScoreTable(): %d scores of file %s failed validation and were deleted'#13#10, [bad, fname]);
    except
      on e: ERadixException do
        I_Warning('RX_LoadScoreTable(): Invalid score table file %s (%s)'#13#10, [fname, e.Message]);
      on e: EInOutError do
        I_Warning('RX_LoadScoreTable(): Could not read file %s (%s)'#13#10, [fname, e.Message]);
      on e: EFOpenError do
        I_Warning('RX_LoadScoreTable(): Could not read file %s (%s)'#13#10, [fname, e.Message]);
    end;

  fname := M_SaveFileName(APPNAME + PILOTFILEEXT);
  if fexists(fname) then
    try
      name := System.IOUtils.TFile.ReadAllBytes(fname);
      if Length(name) > PILOTNAMESIZE then
        SetLength(name, PILOTNAMESIZE);
      SetString(pilotname, PAnsiChar(name), Length(name));
    except
      on e: EInOutError do
        I_Warning('RX_LoadScoreTable(): Could not read file %s (%s)'#13#10, [fname, e.Message]);
      on e: EFOpenError do
        I_Warning('RX_LoadScoreTable(): Could not read file %s (%s)'#13#10, [fname, e.Message]);
    end;
end;

//==============================================================================
//
// RX_WriteFile
//
//==============================================================================
procedure RX_WriteFile(const fname: string; const bytes: TBytes);
begin
  try
    System.IOUtils.TFile.WriteAllBytes(fname, bytes);
  except
    on e: EInOutError do
      I_Warning('RX_SaveScoreTable(): Could not write file %s (%s)'#13#10, [fname, e.Message]);
    on e: EFCreateError do
      I_Warning('RX_SaveScoreTable(): Could not write file %s (%s)'#13#10, [fname, e.Message]);
  end;
end;

//==============================================================================
//
// RX_SaveScoreTable
//
//==============================================================================
procedure RX_SaveScoreTable;
begin
  RX_WriteFile(M_SaveFileName(APPNAME + SCOREFILEEXT), RX_ScoreTable.Encode);
end;

//==============================================================================
//
// RX_SavePilotName
//
//==============================================================================
procedure RX_SavePilotName;
begin
  RX_WriteFile(M_SaveFileName(APPNAME + PILOTFILEEXT), BytesOf(pilotname));
end;

//==============================================================================
//
// RX_ClearLevelScores
//
//==============================================================================
procedure RX_ClearLevelScores;
begin
  ZeroMemory(@levelscores, SizeOf(levelscores));
end;

//==============================================================================
//
// RX_StoreLevelScore
//
//==============================================================================
function RX_StoreLevelScore(const score: TRadixDebriefingScore; const epi, map, skill: integer;
  const update: boolean): integer;
var
  total: integer;
  i: integer;
begin
  result := TRadixScoreTable.NO_POSITION;
  if not IsIntegerInRange(epi, 1, MAXEPISODES) or
     not IsIntegerInRange(map, 1, TRadixScoreTable.LEVELS_PER_EPISODE) then
    exit;

  levelscores[epi, map] := TRadixScoreTable.LevelScore(score);
  if not update then
    exit;

  total := 0;
  for i := 1 to TRadixScoreTable.LEVELS_PER_EPISODE do
    total := total + levelscores[epi, i];

  result := RX_ScoreTable.Add(pilotname, epi, map, skill, total);
  if result <> TRadixScoreTable.NO_POSITION then
  begin
    printf('RX_UpdateScoreTable(): Player "%s", achieved %s position in score table.'#13#10,
      [string(pilotname), SCOREPOSITIONTEXT[result]]);
    RX_SaveScoreTable;
  end;
end;

initialization

finalization
  scoretable.Free;

end.

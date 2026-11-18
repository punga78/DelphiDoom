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
//  Speed Haste: the screens after the race (speed_intermission of the fork):
//  the result of the race with the times of the laps, the ten best laps of
//  the track and the ten best races of the same number of laps. WI_ConfigureReplacement
//  (wi_stuff) puts these three procedures in the place of the intermission of
//  Doom (SPEEDH.JCL has none of its pictures). The key of use or of fire goes
//  to the next screen, and after the last one back to the title.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit speed_intermission;

interface

uses
  d_player;

//==============================================================================
// SH_Intermission_Start
//
// Setup for the screens of the result.
//
//==============================================================================
procedure SH_Intermission_Start(wbstartstruct: Pwbstartstruct_t);

//==============================================================================
// SH_Intermission_Ticker
//
// Called by main loop
//
//==============================================================================
procedure SH_Intermission_Ticker;

//==============================================================================
// SH_Intermission_Drawer
//
// Called by main loop, draws the screen into the screen buffer.
//
//==============================================================================
procedure SH_Intermission_Drawer;

implementation

uses
  SysUtils,
  d_delphi,
  doomdef,
  d_main,
  d_event,
  z_zone,
  g_game,
  v_data,
  v_video,
  w_wad,
  speed_race,
  speed_text,
  DelphiDoom.Racing.Types,
  DelphiDoom.Racing.Intf,
  DelphiDoom.Racing.CarData,
  DelphiDoom.Racing.TextFormat,
  DelphiDoom.Speed.MapInfoReader;

const
  STAGE_RESULT = 0;
  STAGE_CLASSIFICATION = 1;
  STAGE_LAP_RECORDS = 2;
  STAGE_COURSE_RECORDS = 3;
  STAGE_CHAMPIONSHIP = 4;
  // the key that ended the level is still down in the first tics
  INPUT_DELAY_TICS = TICRATE div 2;
  MAPDATA_LUMP = 'MAPDATA';
  MAP_LUMP_SPAN = 13;
  LABEL_FONT = SPEED_FONT_A;
  VALUE_FONT = SPEED_FONT_B;

type
  championshipcourse_t = record
    done: boolean;
    position: integer;
    time: integer;
  end;

var
  in_tic: integer = 0;
  in_stage: integer = 0;
  in_stage_tic: integer = 0;
  in_score: TRacingScore;
  in_hasscore: boolean = false;
  in_struct: Pwbstartstruct_t = nil;
  // what the player did in the courses of the championship so far
  champion: array[1..RACING_MAX_MAPS] of championshipcourse_t;

//==============================================================================
//
// SH_IsChampionship
//
//==============================================================================
function SH_IsChampionship: boolean;
begin
  Result := (SH_RaceSettings <> nil) and (SH_RaceSettings.GameType = TRacingGameType.Championship);
end;

//==============================================================================
//
// SH_LastStage
// The screens: the result, the classification, the lap records and the course records, and for a
// championship its table
//
//==============================================================================
function SH_LastStage: integer;
begin
  if SH_IsChampionship then
    Result := STAGE_CHAMPIONSHIP
  else
    Result := STAGE_COURSE_RECORDS;
end;

//==============================================================================
//
// SH_ChampionshipGoesOn
// A championship goes on to the next course when the data have it
//
//==============================================================================
function SH_ChampionshipGoesOn: boolean;
begin
  Result := SH_IsChampionship and (W_CheckNumForName(Format('E%dM%d', [in_score.Episode, in_score.Map + 1])) >= 0);
end;

//==============================================================================
//
// SH_MapNameOf
// The name of the course in the lump MAPDATA of the level of the result
//
//==============================================================================
function SH_MapNameOf(const episode, map: integer): string;
var
  lump, i: integer;
  data: PAnsiChar;
  text: AnsiString;
  mapname: string;
begin
  mapname := Format('E%dM%d', [episode, map]);
  Result := mapname;
  lump := W_CheckNumForName(mapname);
  if lump < 0 then
    exit;
  for i := lump + 1 to lump + MAP_LUMP_SPAN - 1 do
    if i < W_NumLumps then
      if SameText(char8tostring(W_GetNameForNum(i)), MAPDATA_LUMP) then
      begin
        SetLength(text, W_LumpLength(i));
        if Length(text) > 0 then
        begin
          data := W_CacheLumpNum(i, PU_STATIC);
          Move(data^, text[1], Length(text));
          Z_Free(data);
          Result := TSpeedMapInfoReader.Parse(string(text)).Name;
        end;
        exit;
      end;
end;

//==============================================================================
//
// SH_Intermission_Start
//
//==============================================================================
procedure SH_Intermission_Start(wbstartstruct: Pwbstartstruct_t);
begin
  in_tic := 0;
  in_stage := STAGE_RESULT;
  in_stage_tic := 0;
  in_hasscore := false;
  if SH_Race <> nil then
    if SH_Race.HasFinalScore then
    begin
      in_score := SH_Race.FinalScore;
      in_hasscore := true;
    end;
  in_struct := wbstartstruct;
  if in_hasscore and SH_IsChampionship and (in_score.Map >= 1) and (in_score.Map <= RACING_MAX_MAPS) then
  begin
    // a championship begins at its first course: the table of before is forgotten
    if in_score.Map = 1 then
      ZeroMemory(@champion, SizeOf(champion));
    champion[in_score.Map].done := true;
    champion[in_score.Map].position := in_score.RacePosition;
    champion[in_score.Map].time := in_score.TotalTime;
  end;
  // the table has already taken the result when the race ended
  SH_SaveRecords;
end;

//==============================================================================
//
// SH_Intermission_Next
//
//==============================================================================
procedure SH_Intermission_Next;
begin
  if (in_stage < SH_LastStage) and in_hasscore then
  begin
    inc(in_stage);
    in_stage_tic := 0;
  end
  else if in_hasscore and SH_ChampionshipGoesOn and (in_struct <> nil) then
  begin
    // the next course of the championship: the level after this one
    printf('SH_Intermission_Next: the next course of the championship'#13#10);
    in_struct.next := in_score.Map;
    G_WorldDone;
  end
  else
  begin
    printf('SH_Intermission_Next: back to the title'#13#10);
    TMainRoutines.D_StartTitle;
  end;
end;

//==============================================================================
//
// SH_Intermission_Ticker
//
//==============================================================================
procedure SH_Intermission_Ticker;
var
  i: integer;
  player: Pplayer_t;
begin
  inc(in_tic);
  inc(in_stage_tic);
  if in_tic <= INPUT_DELAY_TICS then
    exit;
  for i := 0 to MAXPLAYERS - 1 do
  begin
    player := @TGameSession.Players[i];
    if TGameSession.PlayerInGame[i] then
      if (player.cmd.buttons and BT_ATTACK <> 0) or (player.cmd.buttons and BT_USE <> 0) then
      begin
        // one press, one screen
        if in_stage_tic > INPUT_DELAY_TICS then
          SH_Intermission_Next;
        exit;
      end;
  end;
end;

//==============================================================================
//
// SH_DrawCourse
//
//==============================================================================
procedure SH_DrawCourse(const y: integer);
var
  x: integer;
begin
  x := SH_DrawText(18, y, 'Course: ', LABEL_FONT, SCN_TMP);
  x := SH_DrawText(x, y, SH_MapNameOf(in_score.Episode, in_score.Map), VALUE_FONT, SCN_TMP);
  x := SH_DrawText(x, y, ' (', LABEL_FONT, SCN_TMP);
  x := SH_DrawText(x, y, Format('E%dM%d', [in_score.Episode, in_score.Map]), VALUE_FONT, SCN_TMP);
  SH_DrawText(x, y, ')', LABEL_FONT, SCN_TMP);
end;

//==============================================================================
//
// SH_DrawResult
//
//==============================================================================
procedure SH_DrawResult;
var
  x, i: integer;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RESU');
  if not in_hasscore then
  begin
    SH_DrawTextCenter(160, 90, 'No race to show', LABEL_FONT, SCN_TMP);
    exit;
  end;
  SH_DrawCourse(55);

  x := SH_DrawText(18, 65, 'Player: ', LABEL_FONT, SCN_TMP);
  x := SH_DrawText(x, 65, 'PILOT', VALUE_FONT, SCN_TMP);
  x := SH_DrawText(x, 65, '  Rank: ', LABEL_FONT, SCN_TMP);
  SH_DrawText(x, 65, TRacingTextFormat.RacePosition(in_score.RacePosition), VALUE_FONT, SCN_TMP);

  x := SH_DrawText(18, 75, 'Car: ', LABEL_FONT, SCN_TMP);
  SH_DrawText(x, 75, RACING_CAR_DATA[in_score.CarInfo].Name, VALUE_FONT, SCN_TMP);

  x := SH_DrawText(18, 85, 'Total time: ', LABEL_FONT, SCN_TMP);
  x := SH_DrawText(x, 85, TRacingTextFormat.TicsToTime(in_score.TotalTime), VALUE_FONT, SCN_TMP);
  x := SH_DrawText(x, 85, ' (', LABEL_FONT, SCN_TMP);
  x := SH_DrawText(x, 85, Format('%d Laps', [in_score.NumLaps]), VALUE_FONT, SCN_TMP);
  SH_DrawText(x, 85, ')', LABEL_FONT, SCN_TMP);

  for i := 0 to in_score.NumLaps - 1 do
  begin
    x := SH_DrawText(18, 95 + 10 * i, Format('Lap #%d: ', [i + 1]), LABEL_FONT, SCN_TMP);
    SH_DrawText(x, 95 + 10 * i, TRacingTextFormat.TicsToTime(in_score.LapTimes[i]), VALUE_FONT, SCN_TMP);
  end;
end;

//==============================================================================
//
// SH_DrawTable
// The ten lines of a table of the best times
//
//==============================================================================
procedure SH_DrawTable(const items: PRacingScoreItems);
var
  i, y: integer;
begin
  for i := 0 to RACING_SCORES_PER_TABLE - 1 do
  begin
    y := 80 + 10 * i;
    SH_DrawTextRight(30, y, IntToStr(i + 1), LABEL_FONT, SCN_TMP);
    if items[i].Time > 0 then
    begin
      SH_DrawText(36, y, string(items[i].DriverName), VALUE_FONT, SCN_TMP);
      SH_DrawText(122, y, RACING_CAR_DATA[items[i].CarId].Name, VALUE_FONT, SCN_TMP);
      SH_DrawTextRight(300, y, TRacingTextFormat.TicsToTime(items[i].Time), VALUE_FONT, SCN_TMP);
    end;
  end;
end;

//==============================================================================
//
// SH_DrawRecords
//
//==============================================================================
procedure SH_DrawRecords(const course: boolean);
var
  x: integer;
  cartype: TRacingCarType;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RECO');
  if not in_hasscore then
    exit;
  SH_DrawCourse(55);
  cartype := RACING_CAR_DATA[in_score.CarInfo].CarType;
  if cartype = TRacingCarType.Formula then
    x := SH_DrawText(18, 65, 'Formula 1: ', LABEL_FONT, SCN_TMP)
  else if cartype = TRacingCarType.Stock then
    x := SH_DrawText(18, 65, 'Stock car: ', LABEL_FONT, SCN_TMP)
  else
    exit;
  if not course then
  begin
    SH_DrawText(x, 65, 'lap records', VALUE_FONT, SCN_TMP);
    SH_DrawTable(@SH_ScoreTable.Records.LapRecords[in_score.Episode, in_score.Map, cartype]);
  end
  else
  begin
    x := SH_DrawText(x, 65, 'course records ', VALUE_FONT, SCN_TMP);
    SH_DrawText(x, 65, Format('(%d Laps)', [in_score.NumLaps]), LABEL_FONT, SCN_TMP);
    SH_DrawTable(@SH_ScoreTable.Records.CourseRecords[in_score.NumLaps][in_score.Episode, in_score.Map, cartype]);
  end;
end;

//==============================================================================
//
// SH_DrawChampionship
// The courses of the championship that have been raced: the rank and the time of the player
//
//==============================================================================
procedure SH_DrawChampionship;
var
  i, y, total: integer;
  name: string;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RECO');
  SH_DrawTextCenter(160, 28, 'Championship', LABEL_FONT, SCN_TMP);
  SH_DrawText(18, 55, 'Course', LABEL_FONT, SCN_TMP);
  SH_DrawText(165, 55, 'Rank', LABEL_FONT, SCN_TMP);
  SH_DrawText(232, 55, 'Time', LABEL_FONT, SCN_TMP);
  total := 0;
  y := 68;
  for i := 1 to RACING_MAX_MAPS do
    if champion[i].done then
    begin
      name := SH_MapNameOf(in_score.Episode, i);
      if Length(name) > 20 then
        SetLength(name, 20);
      SH_DrawText(18, y, IntToStr(i) + ' ' + name, VALUE_FONT, SCN_TMP);
      SH_DrawTextRight(215, y, TRacingTextFormat.RacePosition(champion[i].position), VALUE_FONT, SCN_TMP);
      SH_DrawText(232, y,TRacingTextFormat.TicsToTime(champion[i].time), VALUE_FONT, SCN_TMP);
      total := total + champion[i].time;
      y := y + 10;
    end;
  SH_DrawText(18, y + 6, 'Total time', LABEL_FONT, SCN_TMP);
  SH_DrawText(232, y + 6,TRacingTextFormat.TicsToTime(total), LABEL_FONT, SCN_TMP);
end;

//==============================================================================
//
// SH_DrawClassification
// All the cars of the race, first to last, with the time of those that finished
//
//==============================================================================
procedure SH_DrawClassification;
var
  i, y, font: integer;
  standings: TArray<TRacingPositionItem>;
  car: PRacingCarState;
  text: string;
begin
  V_DrawPatchFullScreenTMP320x200('MBG_RECO');
  SH_DrawTextCenter(160, 8, 'Race classification', LABEL_FONT, SCN_TMP);
  if SH_Race = nil then
    exit;
  standings := SH_Race.Standings;
  for i := 0 to High(standings) do
  begin
    car := SH_Race.Cars[standings[i].Index];
    y := 26 + i * 8;
    if car.IsPlayer then
      font := LABEL_FONT
    else
      font := VALUE_FONT;
    SH_DrawTextRight(22, y, IntToStr(i + 1), font, SCN_TMP);
    SH_DrawText(28, y, RACING_CAR_DATA[car.CarInfo].Name, font, SCN_TMP);
    if car.IsPlayer then
      SH_DrawText(130, y, 'YOU', LABEL_FONT, SCN_TMP);
    if standings[i].FinishTime > 0 then
      text := TRacingTextFormat.TicsToTime(standings[i].FinishTime)
    else
      text := Format('lap %d', [car.LapsCompleted + 1]);
    SH_DrawTextRight(300, y, text, font, SCN_TMP);
  end;
end;

//==============================================================================
//
// SH_Intermission_Drawer
//
//==============================================================================
procedure SH_Intermission_Drawer;
begin
  case in_stage of
    STAGE_CLASSIFICATION: SH_DrawClassification;
    STAGE_CHAMPIONSHIP: SH_DrawChampionship;
    STAGE_LAP_RECORDS: SH_DrawRecords(false);
    STAGE_COURSE_RECORDS: SH_DrawRecords(true);
  else
    SH_DrawResult;
  end;
  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
  V_FullScreenStretch;
end;

end.

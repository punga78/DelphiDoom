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
//  Speed Haste: a log of the race for the tests at runtime (-speedstate file).
//  Every second of the game (35 tics) a line says the tic, the state of the
//  race and, for each car, the position in the race, the laps, where it is and
//  how fast it goes. Nothing without the option.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit speed_statelog;

interface

uses
  DelphiDoom.Racing.Types,
  DelphiDoom.Racing.RaceController;

//==============================================================================
//
// SH_StateLogTick
// To call once at every tic of a level, after the race has ticked
//
//==============================================================================
procedure SH_StateLogTick(const controller: TRacingRaceController);

//==============================================================================
//
// SH_StateLogPath
// The points of the path of the level, one line each: the tool that writes the
// scripts of a race reads them
//
//==============================================================================
procedure SH_StateLogPath(const path: TArray<TRacingPathThing>);

implementation

uses
  SysUtils,
  d_delphi,
  m_argv,
  p_tick,
  DelphiDoom.Racing.CarData;

const
  STATELOG_OPTION = '-speedstate';
  LOG_PERIOD = 35;

var
  statelog_checked: boolean = false;
  statelog_open: boolean = false;
  statelog_file: TextFile;
  statelog_lasttic: integer = -1;

//==============================================================================
//
// SH_StateLogOpen
//
//==============================================================================
procedure SH_StateLogOpen;
var
  p: integer;
begin
  statelog_checked := true;
  p := M_CheckParm(STATELOG_OPTION);
  if (p <= 0) or (p >= myargc - 1) then
    exit;
  AssignFile(statelog_file, myargv[p + 1]);
  {$I-}
  Rewrite(statelog_file);
  {$I+}
  statelog_open := IOResult = 0;
end;

//==============================================================================
//
// SH_StateLogTick
//
//==============================================================================
procedure SH_StateLogTick(const controller: TRacingRaceController);
var
  i: integer;
  line: string;
  car: PRacingCarState;
begin
  if not statelog_checked then
    SH_StateLogOpen;
  if not statelog_open then
    exit;
  if (leveltime mod LOG_PERIOD <> 0) or (leveltime = statelog_lasttic) then
    exit;
  statelog_lasttic := leveltime;

  line := Format('tic %d', [leveltime]);
  for i := 0 to controller.Count - 1 do
  begin
    car := controller.Cars[i];
    line := line + Format(' | %s%d p%d l%d x%d y%d v%d g%d', [
      decide(car.IsPlayer, 'P', 'c'), i, car.RacePosition, car.LapsCompleted,
      car.X div 65536, car.Y div 65536, car.EngineSpeed div RACING_KMH_TO_FIXED, car.Gear]);
  end;
  writeln(statelog_file, line);
  flush(statelog_file);
end;

//==============================================================================
//
// SH_StateLogPath
//
//==============================================================================
procedure SH_StateLogPath(const path: TArray<TRacingPathThing>);
var
  i: integer;
begin
  if not statelog_checked then
    SH_StateLogOpen;
  if not statelog_open then
    exit;
  for i := 0 to High(path) do
    writeln(statelog_file, Format('path %d x %d y %d angle %d speed %d', [i, path[i].X, path[i].Y,
      path[i].Angle, path[i].Speed]));
  flush(statelog_file);
end;

end.

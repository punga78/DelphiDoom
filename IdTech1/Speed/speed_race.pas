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
//  Speed Haste: the race on the engine of Doom (SH_InitRace, SH_InitLevelCars,
//  SH_MoveCarAI and SH_MoveCarPlayer of the fork). The code of Doom is not
//  touched and mobj_t does not grow: the state of every car is the one of
//  TRacingRaceController (Games\Racing), and a thinker of the level that sits at
//  the HEAD of the thinker list does at every tic
//   - copy the position of the object of each car into its state,
//   - tick the race (the drivers, the physics, the positions, the lights),
//   - put the momentum and the angle back into the objects.
//  It runs after P_PlayerThink (that has already added the walking thrust and
//  turned the player: both are overwritten here) and before the thinkers of the
//  objects, that move the cars with the collisions of Doom: the order of the
//  fork, where SH_MoveCarAI came first in P_MobjThinker.
//
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit speed_race;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Racing.Types,
  DelphiDoom.Racing.Intf,
  DelphiDoom.Racing.RaceController,
  DelphiDoom.Engine.Speed.RaceEvents;

//==============================================================================
//
// SH_ConfigureRace
// Gives the race its log and its random numbers (ComposeEngine, once)
//
//==============================================================================
procedure SH_ConfigureRace(const log: ILog; const random: IGameRandom);

//==============================================================================
//
// SH_StartLevel
// The level has been loaded: builds the race of the circuit from the points of
// its path, makes the cars of the starting grid, and adds the thinker
//
//==============================================================================
procedure SH_StartLevel(const path: TArray<TRacingPathThing>);

//==============================================================================
//
// SH_EndLevel
// Forgets the race of the level (the objects go with the level)
//
//==============================================================================
procedure SH_EndLevel;

//==============================================================================
//
// SH_Race
// The controller of the race of this level, nil when there is none
//
//==============================================================================
function SH_Race: TRacingRaceController;

//==============================================================================
//
// SH_RaceEvents
// What the display needs to know about the race (nil when there is none)
//
//==============================================================================
function SH_RaceEvents: TEngineSpeedRaceEvents;

//==============================================================================
//
// SH_RaceSettings
// The laps, the time and the state of the race of this level (nil when there is none)
//
//==============================================================================
function SH_RaceSettings: IRacingRaceState;

//==============================================================================
//
// SH_Random
// The random numbers of the race (the saved game keeps where they are)
//
//==============================================================================
function SH_Random: IGameRandom;

//==============================================================================
//
// SH_ScoreTable
// The table of the best times (the file SPEED.REC of the data folder)
//
//==============================================================================
function SH_ScoreTable: IRacingScoreTable;

//==============================================================================
//
// SH_SaveRecords
// Writes the table of the best times to its file
//
//==============================================================================
procedure SH_SaveRecords;

//==============================================================================
//
// SH_RebindCars
// The objects of the cars after a saved game has been loaded (the engine made them again): the player
// has its own, the cars of the computer take the objects of the grid in the order of the thinkers
//
//==============================================================================
procedure SH_RebindCars;

//==============================================================================
//
// SH_AddRaceThinker
// Puts the thinker of the race at the head of the list when the level does not have it
//
//==============================================================================
procedure SH_AddRaceThinker;

//==============================================================================
//
// SH_RaceLog
// A line in the log of the game
//
//==============================================================================
procedure SH_RaceLog(const text: string);

implementation

uses
  SysUtils,
  Classes,
  d_delphi,
  doomdef,
  doomdata,
  d_player,
  d_think,
  d_ticcmd,
  g_game,
  m_argv,
  m_fixed,
  tables,
  info_common,
  info_h,
  p_mobj_h,
  p_mobj,
  p_tick,
  w_wad,
  z_zone,
  DelphiDoom.Racing.Factory,
  DelphiDoom.Racing.PlayerEventRelay,
  DelphiDoom.Racing.CarData,
  DelphiDoom.MathCore.Types,
  DelphiDoom.Engine.Speed.Geometry,
  DelphiDoom.Engine.Speed.Effects,
  speed_controls,
  speed_statelog;

const
  LAPS_OPTION = '-laps';
  CAR_OPTION = '-car';
  MANUAL_OPTION = '-manual';
  PRACTICE_OPTION = '-practice';
  DEFAULT_LAPS = 2;
  DEFAULT_PLAYER_CAR = 1;
  GROUND_LUMP_FORMAT = 'FMAP%.2d';
  RECORDS_FILE = 'SPEED.REC';

type
  speedrace_t = record
    thinker: thinker_t;
  end;
  Pspeedrace_t = ^speedrace_t;

var
  race_log: ILog = nil;
  race_random: IGameRandom = nil;
  // the objects and the services of the race of this level
  race_controller: TRacingRaceController = nil;
  race_events: IRacingRaceEvents = nil;
  race_events_object: TEngineSpeedRaceEvents = nil;
  race_effects: IRacingEffects = nil;
  race_effects_object: TEngineSpeedEffects = nil;
  race_settings: IRacingRaceSettings = nil;
  race_scores: IRacingScoreTable = nil;
  race_cars: array[0..RACING_MAX_CARS - 1] of Pmobj_t;
  // the ground map is a lump of the level: the zone keeps it until the level ends
  race_ground_map: System.PByte = nil;
  // -speedcrash tic: the tic of the level at which the thinker writes through a nil pointer, -1 for never
  race_crashtic: integer = -1;
  race_crashpointer: pointer = nil;

//==============================================================================
//
// SH_ConfigureRace
//
//==============================================================================
procedure SH_ConfigureRace(const log: ILog; const random: IGameRandom);
begin
  race_log := log;
  race_random := random;
end;

//==============================================================================
//
// SH_Race
//
//==============================================================================
function SH_Race: TRacingRaceController;
begin
  Result := race_controller;
end;

//==============================================================================
//
// SH_RaceSettings
//
//==============================================================================
function SH_RaceSettings: IRacingRaceState;
begin
  Result := race_settings;
end;

//==============================================================================
//
// SH_Random
//
//==============================================================================
function SH_Random: IGameRandom;
begin
  Result := race_random;
end;

//==============================================================================
//
// SH_LoadRecords
// The file of the records, if there is one that has the right size
//
//==============================================================================
procedure SH_LoadRecords;
var
  stream: TFileStream;
  bytes: TBytes;
  fname: string;
begin
  race_scores := TRacingFactory.CreateScoreTable;
  fname := M_SaveFileName(RECORDS_FILE);
  if not FileExists(fname) then
    exit;
  stream := TFileStream.Create(fname, fmOpenRead or fmShareDenyNone);
  try
    SetLength(bytes, stream.Size);
    if Length(bytes) > 0 then
      stream.ReadBuffer(bytes[0], Length(bytes));
  finally
    stream.Free;
  end;
  if not race_scores.LoadFromBytes(bytes) then
    race_log.Warning(Format('Speed Haste: %s has the wrong size, the records are cleared'#13#10, [fname]));
end;

//==============================================================================
//
// SH_ScoreTable
//
//==============================================================================
function SH_ScoreTable: IRacingScoreTable;
begin
  if race_scores = nil then
    SH_LoadRecords;
  Result := race_scores;
end;

//==============================================================================
//
// SH_SaveRecords
//
//==============================================================================
procedure SH_SaveRecords;
var
  stream: TFileStream;
  bytes: TBytes;
begin
  if race_scores = nil then
    exit;
  bytes := race_scores.SaveToBytes;
  stream := TFileStream.Create(M_SaveFileName(RECORDS_FILE), fmCreate);
  try
    stream.WriteBuffer(bytes[0], Length(bytes));
  finally
    stream.Free;
  end;
end;

//==============================================================================
//
// SH_RaceEvents
//
//==============================================================================
function SH_RaceEvents: TEngineSpeedRaceEvents;
begin
  Result := race_events_object;
end;

//==============================================================================
//
// SH_EndLevel
//
//==============================================================================
procedure SH_EndLevel;
begin
  FreeAndNil(race_controller);
  race_events := nil;
  race_events_object := nil;
  race_effects := nil;
  race_effects_object := nil;
  race_settings := nil;
  race_ground_map := nil;
  ZeroMemory(@race_cars, SizeOf(race_cars));
end;

//==============================================================================
//
// SH_ToRacingSkill
// The skill of the level, for the computer drivers
//
//==============================================================================
function SH_ToRacingSkill: TRacingSkill;
begin
  case TGameSession.GameSkill of
    sk_baby: Result := TRacingSkill.Baby;
    sk_easy: Result := TRacingSkill.Easy;
    sk_medium: Result := TRacingSkill.Medium;
    sk_hard: Result := TRacingSkill.Hard;
  else
    Result := TRacingSkill.Nightmare;
  end;
end;

//==============================================================================
//
// SH_ParmInt
//
//==============================================================================
function SH_ParmInt(const option: string; const default: integer): integer;
var
  p: integer;
begin
  Result := default;
  p := M_CheckParm(option);
  if (p > 0) and (p < myargc - 1) then
    Result := StrToIntDef(myargv[p + 1], default);
end;

//==============================================================================
//
// SH_ControllerPlayerInput
// What the console player asks of the car at this tic
//
//==============================================================================
function SH_ControllerPlayerInput: TRacingPlayerInput;
var
  cmd: Pticcmd_t;
begin
  cmd := @players[TGameSession.ConsolePlayer].cmd;
  Result.AngleTurn := cmd.angleturn;
  Result.ForwardMove := cmd.forwardmove;
  // the transmission is automatic: the gear buttons are not read yet
  Result.Buttons := 0;
  if cmd.jump_crouch and SHCMD_GEARUP <> 0 then
    Result.Buttons := Result.Buttons or RACING_BUTTON_GEAR_UP
  else if cmd.jump_crouch and SHCMD_GEARDOWN <> 0 then
    Result.Buttons := Result.Buttons or RACING_BUTTON_GEAR_DOWN;
end;

//==============================================================================
//
// T_SpeedRace
//
//==============================================================================
procedure T_SpeedRace(race: Pspeedrace_t);
var
  i: integer;
  mo: Pmobj_t;
  car: PRacingCarState;
  think: Pthinker_t;
begin
  if race_controller = nil then
    exit;

  // a test of the report of the exceptions of the loop (-speedcrash tic): a real access violation
  if (race_crashtic >= 0) and (TTickState.LevelTime = race_crashtic) then
    PInteger(race_crashpointer)^ := 1;

  for i := 0 to race_controller.Count - 1 do
  begin
    mo := race_cars[i];
    if mo = nil then
      continue;
    car := race_controller.Cars[i];
    car.X := mo.x;
    car.Y := mo.y;
    car.Z := mo.z;
  end;

  race_controller.Tick(TTickState.LevelTime, SH_ControllerPlayerInput);

  for i := 0 to race_controller.Count - 1 do
  begin
    mo := race_cars[i];
    if mo = nil then
      continue;
    car := race_controller.Cars[i];
    mo.momx := car.MomentumX;
    mo.momy := car.MomentumY;
    mo.angle := car.Angle;
  end;

  SH_StateLogTick(race_controller);
end;

//==============================================================================
//
// SH_AddRaceThinker
// At the head of the list, before the objects (see the description of the unit)
//
//==============================================================================
procedure SH_AddRaceThinker;
var
  race: Pspeedrace_t;
  think: Pthinker_t;
begin
  think := TTickState.ThinkerCap.next;
  while think <> @TTickState.ThinkerCap do
  begin
    if @think._function.acp1 = @T_SpeedRace then
      exit;
    think := think.next;
  end;

  race := Z_Malloc(SizeOf(speedrace_t), PU_LEVSPEC, nil);
  P_AddThinker(@race.thinker);
  race.thinker._function.acp1 := @T_SpeedRace;
  // out of the tail, in after the head
  race.thinker.prev.next := race.thinker.next;
  race.thinker.next.prev := race.thinker.prev;
  race.thinker.next := TTickState.ThinkerCap.next;
  race.thinker.prev := @TTickState.ThinkerCap;
  TTickState.ThinkerCap.next.prev := @race.thinker;
  TTickState.ThinkerCap.next := @race.thinker;
end;

//==============================================================================
//
// SH_FindCarMobj
// The object of the car that has a key (nil when there is none)
//
//==============================================================================
function SH_FindCarMobj(key: cardinal): pointer;
var
  i: integer;
begin
  Result := nil;
  for i := 0 to RACING_MAX_CARS - 1 do
    if (race_cars[i] <> nil) and (race_cars[i].key = key) then
    begin
      Result := race_cars[i];
      exit;
    end;
end;

//==============================================================================
//
// SH_RaceLog
//
//==============================================================================
procedure SH_RaceLog(const text: string);
begin
  if race_log <> nil then
    race_log.Info(text + #13#10);
end;

//==============================================================================
//
// SH_RebindCars
//
//==============================================================================
procedure SH_RebindCars;
var
  think: Pthinker_t;
  mo: Pmobj_t;
  aicars: array[0..RACING_MAX_CARS - 1] of Pmobj_t;
  aicount, i, nextai: integer;
begin
  if race_controller = nil then
    exit;
  aicount := 0;
  think := TTickState.ThinkerCap.next;
  while think <> @TTickState.ThinkerCap do
  begin
    if @think._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(think);
      if (mo.info.doomednum = 241) and (aicount < RACING_MAX_CARS) then
      begin
        aicars[aicount] := mo;
        inc(aicount);
      end;
    end;
    think := think.next;
  end;
  ZeroMemory(@race_cars, SizeOf(race_cars));
  nextai := 0;
  for i := 0 to race_controller.Count - 1 do
    if race_controller.Cars[i].IsPlayer then
      race_cars[i] := players[TGameSession.ConsolePlayer].mo
    else if nextai < aicount then
    begin
      race_cars[i] := aicars[nextai];
      inc(nextai);
    end;
end;

//==============================================================================
//
// SH_NewCar
// The state of a car at the start of the race: on its place of the grid, behind
// the line (the first crossing of it is the start: -1 laps)
//
//==============================================================================
procedure SH_NewCar(const mo: Pmobj_t; const track: IRacingTrack; const carinfo: integer;
  const carid: integer; const isplayer: boolean; var car: TRacingCarState);
var
  pth: PRacingPath;
begin
  ZeroMemory(@car, SizeOf(car));
  car.X := mo.x;
  car.Y := mo.y;
  car.Z := mo.z;
  car.OldX := mo.x;
  car.OldY := mo.y;
  car.Angle := mo.angle;
  car.CarInfo := carinfo;
  car.CarId := carid;
  car.Key := mo.key;
  car.IsPlayer := isplayer;
  car.LapsCompleted := -1;
  pth := track.GetPath(track.GetNextPath(car.X, car.Y));
  car.CurrentPath := pth.Id;
  car.PreviousPath := pth.Previous;
  car.DestinationAngle := pth.Angle;
  car.DestinationSpeed := pth.Speed;
end;

//==============================================================================
//
// SH_StartLevel
//
//==============================================================================
procedure SH_StartLevel(const path: TArray<TRacingPathThing>);
var
  points: TArray<TRacingPathPoint>;
  i, count, lump, playercar, carid: integer;
  ground: IRacingGround;
  geometry: IRacingGeometry;
  track: IRacingTrack;
  physics: IRacingPhysics;
  aidriver: IRacingDriver;
  relay: TRacingPlayerEventRelay;
  relayref: IRacingPlayerEvents;
  think: Pthinker_t;
  mo: Pmobj_t;
  aicars: array[0..RACING_MAX_CARS - 1] of Pmobj_t;
  aicount: integer;
  carids: TArray<Integer>;
  state: TRacingCarState;
  player: Pplayer_t;
begin
  SH_EndLevel;
  if (Length(path) = 0) or (race_random = nil) or (race_log = nil) then
    exit;

  race_crashtic := SH_ParmInt('-speedcrash', -1);
  race_settings := TRacingFactory.CreateRaceState;
  race_settings.SetNumLaps(SH_ParmInt(LAPS_OPTION, speed_laps));
  if (M_CheckParm(MANUAL_OPTION) > 0) or (speed_transmission = 1) then
    race_settings.SetTransmissionType(RACING_TRANSMISSION_MANUAL)
  else
    race_settings.SetTransmissionType(RACING_TRANSMISSION_AUTOMATIC);
  race_settings.SetCarType(TRacingCarType.Any);
  if M_CheckParm(PRACTICE_OPTION) > 0 then
    race_settings.SetGameType(TRacingGameType.Practice)
  else
    race_settings.SetGameType(TRacingGameType(speed_gametype));
  race_settings.SetSkill(SH_ToRacingSkill);
  race_settings.SetEpisode(TGameSession.GameEpisode);
  race_settings.SetMap(TGameSession.GameMap);
  race_settings.SetStatus(TRacingStatus.Waiting);

  SetLength(points, Length(path));
  for i := 0 to High(path) do
  begin
    points[i].X := path[i].X * FRACUNIT;
    points[i].Y := path[i].Y * FRACUNIT;
    // the things of the map face a multiple of 45 degrees
    points[i].Angle := TAngle(ANG45 * (path[i].Angle div 45));
    points[i].Speed := path[i].Speed;
  end;

  geometry := TEngineSpeedGeometry.Create;
  race_effects_object := TEngineSpeedEffects.Create(SH_FindCarMobj);
  race_effects := race_effects_object;
  race_events_object := TEngineSpeedRaceEvents.Create(race_log, SH_FindCarMobj);
  race_events := race_events_object;

  ground := TRacingFactory.CreateGround(race_random);
  lump := W_CheckNumForName(Format(GROUND_LUMP_FORMAT, [TGameSession.GameMap - 1]));
  if lump >= 0 then
  begin
    race_ground_map := System.PByte(W_CacheLumpNum(lump, PU_LEVEL));
    ground.SetMap(race_ground_map, W_LumpLength(lump));
  end
  else
    race_log.Warning('Speed Haste: the level has no map of the ground: the cars drive on asphalt'#13#10);

  track := TRacingFactory.CreateTrack(race_settings, geometry);
  track.Load(points);
  physics := TRacingFactory.CreatePhysics(race_settings, ground, geometry,
    TRacingFactory.CreateParticles(ground, race_settings, race_effects),
    TRacingFactory.CreateCarSounds(race_effects), track);
  aidriver := TRacingFactory.CreateAiDriver(race_settings, track, geometry);
  relay := TRacingPlayerEventRelay.Create;
  relayref := relay;
  if race_scores = nil then
    SH_LoadRecords;
  race_controller := TRacingRaceController.Create(race_settings, track, physics, aidriver,
    TRacingFactory.CreatePlayerDriver(race_settings, track, aidriver, relayref), relay,
    race_events, race_scores, 'PILOT');

  // the places of the grid: the objects that the actors of the map made for the things 241
  aicount := 0;
  think := TTickState.ThinkerCap.next;
  while think <> @TTickState.ThinkerCap do
  begin
    if @think._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(think);
      if (mo.info.doomednum = 241) and (aicount < RACING_MAX_CARS - 1) then
      begin
        aicars[aicount] := mo;
        inc(aicount);
      end;
    end;
    think := think.next;
  end;

  player := @players[TGameSession.ConsolePlayer];
  playercar := SH_ParmInt(CAR_OPTION, speed_car);
  if (playercar < 0) or (playercar >= RACING_CAR_COUNT) then
    playercar := DEFAULT_PLAYER_CAR;
  carids := TRacingFactory.CreateGridAssigner(race_random).Assign(aicount, TRacingCarType.Any, [playercar]);

  count := 0;
  if playeringame[TGameSession.ConsolePlayer] and (player.mo <> nil) then
  begin
    SH_NewCar(player.mo, track, playercar, 0, true, state);
    race_controller.AddCar(state);
    race_cars[count] := player.mo;
    inc(count);
  end;
  for i := 0 to aicount - 1 do
  begin
    mo := aicars[i];
    carid := carids[i];
    SH_NewCar(mo, track, carid, count, false, state);
    race_controller.AddCar(state);
    race_cars[count] := mo;
    // the picture of the car: the state after the first one, one for each car
    P_SetMobjState(mo, statenum_t(mo.info.spawnstate + carid));
    inc(count);
  end;

  SH_StateLogPath(path);
  SH_AddRaceThinker;
  race_log.Info(Format('Speed Haste: %d cars on the grid, %d laps, car of the player %d (%s)'#13#10,
    [count, race_settings.NumLaps, playercar, RACING_CAR_DATA[playercar].Name]));
end;

end.

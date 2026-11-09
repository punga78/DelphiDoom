{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed32 - a race of the computer on the tracks of the game      }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.RaceSimulation;

// Positions are 16.16 fixed point and wrap as in the engine
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Intf, DelphiDoom.GameData.Intf;

type
  /// <summary>What a simulated race needs to know</summary>
  TSpeedRaceOptions = record
    /// <summary>The level: E1M1 is the first (1..8)</summary>
    Level: Integer;
    Laps: Integer;
    /// <summary>The cars of the grid (at most the starting positions of the level, and 19)</summary>
    CarCount: Integer;
    /// <summary>The longest race, in tics</summary>
    MaxTics: Integer;
  end;

  /// <summary>
  ///   A race of cars driven by the computer on a level of the WAD that the translator of Speed Haste
  ///   made: the path and the starting positions from the lumps THINGS and PATH, the ground from the flat
  ///   of the circuit, and the library of the racing (Libs\Racing) for everything else. There is no engine:
  ///   the cars do not meet walls or each other and there is no sound; the point is to run the rules of
  ///   the race on the real data and see that the cars go round the track
  /// </summary>
  TSpeedRaceSimulation = class
  strict private
    FWad: IGameWadComposer;
    FRandom: IGameRandom;
    function FindLump(const AName: string; AFrom: Integer): Integer;
  public
    constructor Create(const AWad: IGameWadComposer; const ARandom: IGameRandom);
    /// <summary>Runs the race and writes a report; gives True if every car completed the laps</summary>
    function Run(const AOptions: TSpeedRaceOptions; ALines: TStrings): Boolean;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf,
  DelphiDoom.Racing.CarData, DelphiDoom.Racing.Factory, DelphiDoom.Racing.PathReader,
  DelphiDoom.Speed.Sim.Geometry, DelphiDoom.Speed.Sim.Effects;

const
  START_DELAY_TICS = 3 * RACING_TICKS_PER_SECOND;
  REPORT_EVERY_TICS = 10 * RACING_TICKS_PER_SECOND;
  POSITIONS_EVERY_TICS = 5;
  LEVEL_SEARCH_LIMIT = 24;
  STAR_POSITION_THING = 241;
  THING_SIZE = 10;

type
  TStarPosition = record
    X, Y, Angle: Integer;
  end;

{ TSpeedRaceSimulation }

constructor TSpeedRaceSimulation.Create(const AWad: IGameWadComposer; const ARandom: IGameRandom);
begin
  inherited Create;
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FWad := AWad;
  FRandom := ARandom;
end;

function TSpeedRaceSimulation.FindLump(const AName: string; AFrom: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := AFrom + 1 to AFrom + LEVEL_SEARCH_LIMIT do
    if (LIndex < FWad.Count) and SameText(FWad.LumpNames[LIndex], AName) then
      Exit(LIndex);
  Result := -1;
end;

function TSpeedRaceSimulation.Run(const AOptions: TSpeedRaceOptions; ALines: TStrings): Boolean;
var
  LMarker, LThingsIndex, LPathIndex, LGroundIndex, LIndex, LTic, LCar, LCount, LStarCount: Integer;
  LThings, LPathBytes, LGroundBytes: TBytes;
  LPathThings: TArray<TRacingPathThing>;
  LStars: TArray<TStarPosition>;
  LPoints: TArray<TRacingPathPoint>;
  LCarIds: TArray<Integer>;
  LCars: TArray<TRacingCarState>;
  LInputs: TArray<TRacingPositionInput>;
  LItems: TArray<TRacingPositionItem>;
  LCommand: TRacingDrivingCommand;
  LRace: IRacingRaceSettings;
  LGeometry: TSpeedSimGeometry;
  LGeometryReference: IRacingGeometry;
  LEffects: TSpeedSimEffects;
  LEffectsReference: IRacingEffects;
  LGround: IRacingGround;
  LTrack: IRacingTrack;
  LPhysics: IRacingPhysics;
  LDriver: IRacingDriver;
  LLine: string;
  LFinished: Integer;
  LTimes: TRacingLapTimes;
  LBestLap, LLapIndex: Integer;

  procedure UpdatePositions;
  var
    LEach: Integer;
  begin
    for LEach := 0 to LCount - 1 do
    begin
      LInputs[LEach].Key := LCars[LEach].Key;
      LInputs[LEach].CarInfo := LCars[LEach].CarInfo;
      LInputs[LEach].LapsCompleted := LCars[LEach].LapsCompleted;
      LInputs[LEach].CurrentPath := LCars[LEach].CurrentPath;
      LInputs[LEach].X := LCars[LEach].X;
      LInputs[LEach].Y := LCars[LEach].Y;
    end;
    LItems := LTrack.CalculatePositions(LInputs);
    for LEach := 0 to High(LItems) do
      LCars[LItems[LEach].Index].RacePosition := LEach + 1;
  end;

begin
  Result := False;
  LMarker := FWad.IndexOf('E1M' + IntToStr(AOptions.Level));
  if LMarker < 0 then
  begin
    ALines.Add(Format('The level E1M%d is not in the data', [AOptions.Level]));
    Exit;
  end;
  LThingsIndex := FindLump('THINGS', LMarker);
  LPathIndex := FindLump('PATH', LMarker);
  if (LThingsIndex < 0) or (LPathIndex < 0) then
  begin
    ALines.Add(Format('The level E1M%d has no THINGS or no PATH lump', [AOptions.Level]));
    Exit;
  end;
  LThings := FWad.LumpData[LThingsIndex];
  LPathBytes := FWad.LumpData[LPathIndex];

  LPathThings := TRacingPathReader.FromLumps(LThings, LPathBytes);
  SetLength(LPoints, Length(LPathThings));
  for LIndex := 0 to High(LPathThings) do
  begin
    LPoints[LIndex].X := LPathThings[LIndex].X * FIXED_ONE;
    LPoints[LIndex].Y := LPathThings[LIndex].Y * FIXED_ONE;
    // The things of the map face a multiple of 45 degrees
    LPoints[LIndex].Angle := TAngle(ANG45 * (LPathThings[LIndex].Angle div 45));
    LPoints[LIndex].Speed := LPathThings[LIndex].Speed;
  end;

  LStarCount := 0;
  SetLength(LStars, Length(LThings) div THING_SIZE);
  for LIndex := 0 to Length(LThings) div THING_SIZE - 1 do
    if PWord(@LThings[LIndex * THING_SIZE + 6])^ = STAR_POSITION_THING then
    begin
      LStars[LStarCount].X := PSmallInt(@LThings[LIndex * THING_SIZE])^;
      LStars[LStarCount].Y := PSmallInt(@LThings[LIndex * THING_SIZE + 2])^;
      LStars[LStarCount].Angle := PSmallInt(@LThings[LIndex * THING_SIZE + 4])^;
      Inc(LStarCount);
    end;
  ALines.Add(Format('E1M%d: %d points of the path, %d starting positions', [AOptions.Level, Length(LPoints), LStarCount]));
  if (Length(LPoints) = 0) or (LStarCount = 0) then
  begin
    ALines.Add('Nothing to race on');
    Exit;
  end;

  LRace := TRacingFactory.CreateRaceState;
  LRace.SetNumLaps(AOptions.Laps);
  LRace.SetCarType(TRacingCarType.Any);
  LRace.SetSkill(TRacingSkill.Medium);
  LRace.SetEpisode(1);
  LRace.SetMap(AOptions.Level);
  LRace.SetStatus(TRacingStatus.Waiting);

  LGeometry := TSpeedSimGeometry.Create;
  LGeometryReference := LGeometry;
  LEffects := TSpeedSimEffects.Create;
  LEffectsReference := LEffects;
  LGround := TRacingFactory.CreateGround(FRandom);
  LGroundIndex := FWad.IndexOf('FMAP' + Format('%.2d', [AOptions.Level - 1]));
  if LGroundIndex >= 0 then
  begin
    LGroundBytes := FWad.LumpData[LGroundIndex];
    if Length(LGroundBytes) > 0 then
      LGround.SetMap(@LGroundBytes[0], Length(LGroundBytes));
  end;
  ALines.Add(Format('Ground: %d bytes (a map of the ground is %d)', [Length(LGroundBytes), RACING_GROUND_BYTES]));

  LTrack := TRacingFactory.CreateTrack(LRace, LGeometryReference);
  LTrack.Load(LPoints);
  LPhysics := TRacingFactory.CreatePhysics(LRace, LGround, LGeometryReference,
    TRacingFactory.CreateParticles(LGround, LRace, LEffectsReference),
    TRacingFactory.CreateCarSounds(LEffectsReference), LTrack);
  LDriver := TRacingFactory.CreateAiDriver(LRace, LTrack, LGeometryReference);

  LCount := AOptions.CarCount;
  if LCount > LStarCount then
    LCount := LStarCount;
  if LCount >= RACING_MAX_CARS then
    LCount := RACING_MAX_CARS - 1;
  LCarIds := TRacingFactory.CreateGridAssigner(FRandom).Assign(LCount, TRacingCarType.Any, []);
  SetLength(LCars, LCount);
  SetLength(LInputs, LCount);
  for LCar := 0 to LCount - 1 do
  begin
    FillChar(LCars[LCar], SizeOf(TRacingCarState), 0);
    LCars[LCar].X := LStars[LCar].X * FIXED_ONE;
    LCars[LCar].Y := LStars[LCar].Y * FIXED_ONE;
    LCars[LCar].OldX := LCars[LCar].X;
    LCars[LCar].OldY := LCars[LCar].Y;
    LCars[LCar].Angle := TAngle(ANG45 * (LStars[LCar].Angle div 45));
    LCars[LCar].CarInfo := LCarIds[LCar];
    LCars[LCar].CarId := LCar;
    LCars[LCar].Key := Cardinal(1000 + LCar);
    LCars[LCar].CurrentPath := LTrack.GetPath(LTrack.GetNextPath(LCars[LCar].X, LCars[LCar].Y)).Id;
    LCars[LCar].PreviousPath := LTrack.GetPath(LCars[LCar].CurrentPath).Previous;
    LCars[LCar].DestinationAngle := LTrack.GetPath(LCars[LCar].CurrentPath).Angle;
    LCars[LCar].DestinationSpeed := LTrack.GetPath(LCars[LCar].CurrentPath).Speed;
    LCars[LCar].Gear := 0;
    // The grid is behind the line: the first crossing of it is the start (the engine spawns the cars with -1)
    LCars[LCar].LapsCompleted := -1;
  end;
  ALines.Add(Format('%d cars, %d laps', [LCount, AOptions.Laps]));
  LGeometry.ViewX := LCars[0].X;
  LGeometry.ViewY := LCars[0].Y;

  LFinished := 0;
  for LTic := 0 to AOptions.MaxTics - 1 do
  begin
    if LTic = START_DELAY_TICS then
      LRace.SetStatus(TRacingStatus.Racing);
    LRace.SetLevelTime(LTic);
    if LTic >= START_DELAY_TICS then
      LRace.SetRaceTime(LTic - START_DELAY_TICS);

    for LCar := 0 to LCount - 1 do
    begin
      LDriver.BuildCommand(LCars[LCar], LCommand);
      LPhysics.Execute(LCars[LCar], LCommand);
      LCars[LCar].OldX := LCars[LCar].X;
      LCars[LCar].OldY := LCars[LCar].Y;
      LCars[LCar].X := LCars[LCar].X + LCars[LCar].MomentumX;
      LCars[LCar].Y := LCars[LCar].Y + LCars[LCar].MomentumY;
    end;

    if LTic mod POSITIONS_EVERY_TICS = 0 then
      UpdatePositions;

    LFinished := 0;
    for LCar := 0 to LCount - 1 do
      if LCars[LCar].LapsCompleted >= AOptions.Laps then
        Inc(LFinished);

    if (LTic mod REPORT_EVERY_TICS = 0) and (LTic > 0) then
    begin
      LLine := Format('%4ds', [LTic div RACING_TICKS_PER_SECOND]);
      for LIndex := 0 to High(LItems) do
        LLine := LLine + Format('  %d:%s(%d)', [LIndex + 1, RACING_CAR_DATA[LCars[LItems[LIndex].Index].CarInfo].Name,
          LCars[LItems[LIndex].Index].LapsCompleted]);
      ALines.Add(LLine);
    end;

    if LFinished = LCount then
      Break;
  end;

  UpdatePositions;
  ALines.Add(Format('%d of %d cars completed %d laps after %d tics; particles %d, engine sounds %d, brake sounds %d',
    [LFinished, LCount, AOptions.Laps, LTic, LEffects.Particles, LEffects.EngineSounds, LEffects.BrakeSounds]));
  for LIndex := 0 to High(LItems) do
  begin
    LCar := LItems[LIndex].Index;
    LTrack.GetLapTimes(LCars[LCar], LTimes);
    LBestLap := 0;
    for LLapIndex := 0 to AOptions.Laps - 1 do
      if (LTimes[LLapIndex] > 0) and ((LBestLap = 0) or (LTimes[LLapIndex] < LBestLap)) then
        LBestLap := LTimes[LLapIndex];
    ALines.Add(Format('%2d. %-16s laps %d, finish %d tics, best lap %d tics', [LIndex + 1,
      RACING_CAR_DATA[LCars[LCar].CarInfo].Name, LCars[LCar].LapsCompleted, LItems[LIndex].FinishTime, LBestLap]));
  end;
  Result := LFinished = Length(LCars);
end;

end.

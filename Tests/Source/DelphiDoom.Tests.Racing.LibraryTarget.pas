{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the racing library - the scenarios on the library      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.LibraryTarget;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Intf,
  DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf, DelphiDoom.Tests.Racing.Scenarios,
  DelphiDoom.Tests.Racing.Fakes;

type
  /// <summary>The scenarios of the parity run on the racing library</summary>
  TRacingLibraryTarget = class(TInterfacedObject, IRacingScenarioTarget)
  strict private
    FRace: IRacingRaceSettings;
    FRandom: IGameRandom;
    FGeometry: TFakeRacingGeometry;
    FGeometryRef: IRacingGeometry;
    FEffects: TFakeRacingEffects;
    FEffectsRef: IRacingEffects;
    FEvents: TFakeRacingPlayerEvents;
    FEventsRef: IRacingPlayerEvents;
    FGround: IRacingGround;
    FTrack: IRacingTrack;
    FPhysics: IRacingPhysics;
    FAiDriver: IRacingDriver;
    FPlayerDriver: IRacingPlayerDriver;
    FScores: IRacingScoreTable;
  public
    constructor Create;
    procedure Reset(const ASetup: TRacingScenarioSetup);
    procedure SetGround(AMap: PByte; ASize: Integer);
    procedure SetClocks(ARaceTime, ALevelTime: Integer);
    procedure SetStatus(AStatus: TRacingStatus);
    procedure SetView(AX, AY: Integer);
    function LoadTrack(const APoints: array of TRacingPathPoint): Boolean;
    procedure DescribeTrack(ALines: TStrings);
    function NextPath(AX, AY: Integer): Integer;
    procedure MoveCar(var ACar: TRacingCarState; var APlayer: TRacingPlayerState;
      const AInput: TRacingPlayerInput; AKind: TRacingDriverKind);
    function Positions(const ACars: array of TRacingPositionInput): TArray<TRacingPositionItem>;
    procedure LapTimes(const ACar: TRacingCarState; out ATimes: TRacingLapTimes);
    function PlayerScore: TRacingScore;
    function EffectLog: TStrings;
    function GroundType(AX, AY: Integer): Integer;
    function Slip(AX, AY: Integer): Integer;
    function SlipCalculation(AForce: Integer; ASlip: Byte): Integer;
    procedure ScoreClear;
    procedure ScoreUpdate(const AScore: TRacingScore; const AName: string; ASkill: TRacingSkill);
    function ScoreCheck(AEpisode, AMap: Integer; ACarType: TRacingCarType; ATime: Integer): Boolean;
    function ScoreBytes: TBytes;
    function ScoreItemSize: Integer;
    function Grid(AStartCount: Integer; ACarType: TRacingCarType; const APlayerCars: array of Integer): TArray<Integer>;
  end;

implementation

uses
  DelphiDoom.MathCore.Factory, DelphiDoom.Racing.Factory, DelphiDoom.Racing.Ground;

{ TRacingLibraryTarget }

constructor TRacingLibraryTarget.Create;
begin
  inherited Create;
  Reset(Default(TRacingScenarioSetup));
end;

procedure TRacingLibraryTarget.Reset(const ASetup: TRacingScenarioSetup);
begin
  FRace := TRacingFactory.CreateRaceState;
  FRace.SetNumLaps(ASetup.Laps);
  FRace.SetSkill(ASetup.Skill);
  FRace.SetTransmissionType(ASetup.Transmission);
  FRace.SetStatus(ASetup.Status);
  FRace.SetCarType(ASetup.CarType);
  FRace.SetEpisode(ASetup.Episode);
  FRace.SetMap(ASetup.Map);

  FRandom := TMathCoreFactory.CreateGameRandom;
  FRandom.SystemSeed := ASetup.Seed mod 256;
  FRandom.SystemIndex := (ASetup.Seed * 37) mod 10007;

  FGeometry := TFakeRacingGeometry.Create;
  FGeometryRef := FGeometry;
  FEffects := TFakeRacingEffects.Create;
  FEffectsRef := FEffects;
  FEvents := TFakeRacingPlayerEvents.Create;
  FEventsRef := FEvents;

  FGround := TRacingFactory.CreateGround(FRandom);
  FTrack := TRacingFactory.CreateTrack(FRace, FGeometryRef);
  FPhysics := TRacingFactory.CreatePhysics(FRace, FGround, FGeometryRef,
    TRacingFactory.CreateParticles(FGround, FRace, FEffectsRef),
    TRacingFactory.CreateCarSounds(FEffectsRef), FTrack);
  FAiDriver := TRacingFactory.CreateAiDriver(FRace, FTrack, FGeometryRef);
  FPlayerDriver := TRacingFactory.CreatePlayerDriver(FRace, FTrack, FAiDriver, FEventsRef);
  FScores := TRacingFactory.CreateScoreTable;
end;

procedure TRacingLibraryTarget.SetGround(AMap: PByte; ASize: Integer);
begin
  FGround.SetMap(AMap, ASize);
end;

procedure TRacingLibraryTarget.SetClocks(ARaceTime, ALevelTime: Integer);
begin
  FRace.SetRaceTime(ARaceTime);
  FRace.SetLevelTime(ALevelTime);
end;

procedure TRacingLibraryTarget.SetStatus(AStatus: TRacingStatus);
begin
  FRace.SetStatus(AStatus);
end;

procedure TRacingLibraryTarget.SetView(AX, AY: Integer);
begin
  FGeometry.ViewX := AX;
  FGeometry.ViewY := AY;
end;

function TRacingLibraryTarget.LoadTrack(const APoints: array of TRacingPathPoint): Boolean;
begin
  Result := FTrack.Load(APoints);
end;

procedure TRacingLibraryTarget.DescribeTrack(ALines: TStrings);
var
  LIndex, LCar, LLap: Integer;
  LPath: PRacingPath;
  LVisits: Int64;
begin
  for LIndex := 0 to FTrack.PathCount - 1 do
  begin
    LPath := FTrack.GetPath(LIndex);
    LVisits := 0;
    for LCar := 0 to RACING_CAR_COUNT - 1 do
      for LLap := 0 to RACING_MAX_LAPS do
        LVisits := LVisits + LPath.Visits[LCar][LLap].EnterTime + LPath.Visits[LCar][LLap].ExitTime +
          LPath.Visits[LCar][LLap].VisitLap;
    ALines.Add(Format('%d id=%d x=%d y=%d a=%d s=%d p=%d n=%d dn=%d dh=%d v=%d',
      [LIndex, LPath.Id, LPath.X, LPath.Y, Integer(LPath.Angle), LPath.Speed, LPath.Previous,
       LPath.Next, LPath.DistanceToNext, LPath.DistanceToHere, LVisits]));
  end;
end;

function TRacingLibraryTarget.NextPath(AX, AY: Integer): Integer;
begin
  Result := FTrack.GetNextPath(AX, AY);
end;

procedure TRacingLibraryTarget.MoveCar(var ACar: TRacingCarState; var APlayer: TRacingPlayerState;
  const AInput: TRacingPlayerInput; AKind: TRacingDriverKind);
var
  LCommand: TRacingDrivingCommand;
begin
  ACar.IsPlayer := AKind = TRacingDriverKind.Person;
  if ACar.IsPlayer then
    FPlayerDriver.BuildCommand(ACar, APlayer, AInput, LCommand)
  else
    FAiDriver.BuildCommand(ACar, LCommand);
  FPhysics.Execute(ACar, LCommand);
end;

function TRacingLibraryTarget.Positions(const ACars: array of TRacingPositionInput): TArray<TRacingPositionItem>;
begin
  Result := FTrack.CalculatePositions(ACars);
end;

procedure TRacingLibraryTarget.LapTimes(const ACar: TRacingCarState; out ATimes: TRacingLapTimes);
begin
  FTrack.GetLapTimes(ACar, ATimes);
end;

function TRacingLibraryTarget.PlayerScore: TRacingScore;
begin
  Result := FEvents.Score;
end;

function TRacingLibraryTarget.EffectLog: TStrings;
begin
  Result := FEffects.Log;
end;

function TRacingLibraryTarget.GroundType(AX, AY: Integer): Integer;
begin
  Result := Ord(FGround.GroundTypeAt(AX, AY));
end;

function TRacingLibraryTarget.Slip(AX, AY: Integer): Integer;
begin
  Result := FGround.SlipperFactorAt(AX, AY);
end;

function TRacingLibraryTarget.SlipCalculation(AForce: Integer; ASlip: Byte): Integer;
begin
  Result := TRacingGround.SlipCalculation(AForce, ASlip);
end;

procedure TRacingLibraryTarget.ScoreClear;
begin
  FScores.Clear;
end;

procedure TRacingLibraryTarget.ScoreUpdate(const AScore: TRacingScore; const AName: string;
  ASkill: TRacingSkill);
begin
  FScores.Update(AScore, AName, ASkill);
end;

function TRacingLibraryTarget.ScoreCheck(AEpisode, AMap: Integer; ACarType: TRacingCarType;
  ATime: Integer): Boolean;
begin
  Result := FScores.CheckLapRecord(AEpisode, AMap, ACarType, ATime);
end;

function TRacingLibraryTarget.ScoreBytes: TBytes;
begin
  Result := FScores.SaveToBytes;
end;

function TRacingLibraryTarget.ScoreItemSize: Integer;
begin
  Result := SizeOf(TRacingScoreItem);
end;

function TRacingLibraryTarget.Grid(AStartCount: Integer; ACarType: TRacingCarType;
  const APlayerCars: array of Integer): TArray<Integer>;
begin
  Result := TRacingFactory.CreateGridAssigner(FRandom).Assign(AStartCount, ACarType, APlayerCars);
end;

end.

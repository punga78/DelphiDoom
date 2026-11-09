{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the racing library - the fakes of the game             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.Fakes;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Intf,
  DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>The geometry of the scenarios: the view is a point that the test sets</summary>
  TFakeRacingGeometry = class(TInterfacedObject, IRacingGeometry)
  strict private
    FViewX: Integer;
    FViewY: Integer;
  public
    function PointToAngle(AX1, AY1, AX2, AY2: TFixed): TAngle;
    function ApproximateDistanceFromView(AX, AY: TFixed): TFixed;
    property ViewX: Integer read FViewX write FViewX;
    property ViewY: Integer read FViewY write FViewY;
  end;

  /// <summary>Writes what the cars make appear and hear as lines of text</summary>
  TFakeRacingEffects = class(TInterfacedObject, IRacingEffects)
  strict private
    FLog: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SpawnParticle(AKind: TRacingParticleKind; AX, AY, AZ, AMomentumX, AMomentumY: TFixed);
    function PlayEngineSound(AFormula: Boolean; AFraction: Integer): Integer;
    function PlayBrakeSound(AX, AY, AZ: TFixed): Integer;
    property Log: TStringList read FLog;
  end;

  /// <summary>Keeps the last result of the player and counts the laps</summary>
  TFakeRacingPlayerEvents = class(TInterfacedObject, IRacingPlayerEvents)
  strict private
    FScore: TRacingScore;
    FLapsCompleted: Integer;
    FScoresChanged: Integer;
  public
    procedure LapCompleted(const AScore: TRacingScore);
    procedure ScoreChanged(const AScore: TRacingScore);
    property Score: TRacingScore read FScore;
    property LapsCompleted: Integer read FLapsCompleted;
    property ScoresChanged: Integer read FScoresChanged;
  end;

  /// <summary>All the pieces of the library, assembled with the fakes, for the tests of one class</summary>
  TRacingTestWorld = class
  strict private
    FGeometryObject: TFakeRacingGeometry;
    FEffectsObject: TFakeRacingEffects;
    FEventsObject: TFakeRacingPlayerEvents;
  public
    Race: IRacingRaceSettings;
    Random: IGameRandom;
    Geometry: IRacingGeometry;
    Effects: IRacingEffects;
    Events: IRacingPlayerEvents;
    Ground: IRacingGround;
    Track: IRacingTrack;
    Particles: IRacingParticles;
    Sounds: IRacingCarSounds;
    Physics: IRacingPhysics;
    ComputerDriver: IRacingDriver;
    PlayerDriver: IRacingPlayerDriver;
    constructor Create;
    /// <summary>The race starts: the cars move</summary>
    procedure StartRace;
    /// <summary>A circle of 8 points around (4000, 4000)</summary>
    procedure LoadSimpleTrack;
    property EffectLog: TFakeRacingEffects read FEffectsObject;
    property EventLog: TFakeRacingPlayerEvents read FEventsObject;
    property GeometryObject: TFakeRacingGeometry read FGeometryObject;
  end;

implementation

uses
  DelphiDoom.MathCore.Factory, DelphiDoom.Racing.Factory, DelphiDoom.Tests.Racing.Scenarios;

{ TFakeRacingGeometry }

function TFakeRacingGeometry.PointToAngle(AX1, AY1, AX2, AY2: TFixed): TAngle;
begin
  Result := TRacingScenarios.PointToAngle(AX1, AY1, AX2, AY2);
end;

function TFakeRacingGeometry.ApproximateDistanceFromView(AX, AY: TFixed): TFixed;
begin
  Result := TRacingScenarios.ApproximateDistance(FViewX - AX, FViewY - AY);
end;

{ TFakeRacingEffects }

constructor TFakeRacingEffects.Create;
begin
  inherited Create;
  FLog := TStringList.Create;
end;

destructor TFakeRacingEffects.Destroy;
begin
  FLog.Free;
  inherited Destroy;
end;

procedure TFakeRacingEffects.SpawnParticle(AKind: TRacingParticleKind; AX, AY, AZ, AMomentumX,
  AMomentumY: TFixed);
const
  KIND_NAMES: array[TRacingParticleKind] of string = ('spark', 'smoke', 'grass', 'dirt', 'sand');
begin
  FLog.Add(TRacingScenarios.FormatParticle(KIND_NAMES[AKind], AX, AY, AZ, AMomentumX, AMomentumY));
end;

function TFakeRacingEffects.PlayEngineSound(AFormula: Boolean; AFraction: Integer): Integer;
var
  LNumber: Integer;
begin
  LNumber := TRacingScenarios.EngineSoundBase(AFormula) + AFraction;
  FLog.Add(TRacingScenarios.FormatEngineSound(LNumber));
  Result := TRacingScenarios.SoundDuration(LNumber);
end;

function TFakeRacingEffects.PlayBrakeSound(AX, AY, AZ: TFixed): Integer;
begin
  FLog.Add(TRacingScenarios.FormatBrakeSound(TRacingScenarios.BrakeSoundNumber, AX, AY, AZ));
  Result := TRacingScenarios.SoundDuration(TRacingScenarios.BrakeSoundNumber);
end;

{ TFakeRacingPlayerEvents }

procedure TFakeRacingPlayerEvents.LapCompleted(const AScore: TRacingScore);
begin
  FScore := AScore;
  Inc(FLapsCompleted);
end;

procedure TFakeRacingPlayerEvents.ScoreChanged(const AScore: TRacingScore);
begin
  FScore := AScore;
  Inc(FScoresChanged);
end;

{ TRacingTestWorld }

constructor TRacingTestWorld.Create;
begin
  inherited Create;
  Race := TRacingFactory.CreateRaceState;
  Race.SetNumLaps(3);
  Race.SetCarType(TRacingCarType.Any);
  Race.SetEpisode(1);
  Race.SetMap(2);
  Random := TMathCoreFactory.CreateGameRandom;
  FGeometryObject := TFakeRacingGeometry.Create;
  Geometry := FGeometryObject;
  FEffectsObject := TFakeRacingEffects.Create;
  Effects := FEffectsObject;
  FEventsObject := TFakeRacingPlayerEvents.Create;
  Events := FEventsObject;
  Ground := TRacingFactory.CreateGround(Random);
  Track := TRacingFactory.CreateTrack(Race, Geometry);
  Particles := TRacingFactory.CreateParticles(Ground, Race, Effects);
  Sounds := TRacingFactory.CreateCarSounds(Effects);
  Physics := TRacingFactory.CreatePhysics(Race, Ground, Geometry, Particles, Sounds, Track);
  ComputerDriver := TRacingFactory.CreateAiDriver(Race, Track, Geometry);
  PlayerDriver := TRacingFactory.CreatePlayerDriver(Race, Track, ComputerDriver, Events);
end;

procedure TRacingTestWorld.StartRace;
begin
  Race.SetStatus(TRacingStatus.Racing);
end;

procedure TRacingTestWorld.LoadSimpleTrack;
begin
  Track.Load(TRacingScenarios.Circuit(8, 1000, False));
end;

end.

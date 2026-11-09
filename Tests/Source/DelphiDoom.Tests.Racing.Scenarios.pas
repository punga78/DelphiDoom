{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the racing library - the scenarios of the parity       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.Scenarios;

// The scenarios are the same for the old code (compiled in a harness outside the repository, see
// Tools\Verifica\168\Racing) and for the library: both run them through IRacingScenarioTarget and
// give the lines of Tests\Data\Racing\racing.golden.txt

{$Q-}
{$R-}
{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types;

type
  TRacingDriverKind = (Computer, Person);

  /// <summary>How a scenario sets the world before it runs</summary>
  TRacingScenarioSetup = record
    Laps: Integer;
    Skill: TRacingSkill;
    Transmission: Integer;
    Status: TRacingStatus;
    CarType: TRacingCarType;
    Episode: Integer;
    Map: Integer;
    Seed: Integer;
  end;

  /// <summary>What the scenarios need of the code under test: the old code in the harness, the library in the tests</summary>
  IRacingScenarioTarget = interface
    ['{2E8A41D6-7C93-4B05-A1F8-6D3E90C5B742}']
    /// <summary>A new world: race settings, random numbers from the seed, no ground and no track, empty logs</summary>
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
    /// <summary>The lines of what the cars made appear and hear since the last time it was cleared</summary>
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

  /// <summary>A hash of numbers (FNV-1a, 32 bit)</summary>
  TRacingFingerprint = record
  strict private
    FValue: Cardinal;
  public
    procedure Start;
    procedure AddBytes(const AData; ASize: Integer);
    procedure AddInteger(AValue: Integer);
    procedure AddInt64(AValue: Int64);
    procedure AddDouble(AValue: Double);
    procedure AddString(const AValue: string);
    procedure AddCar(const ACar: TRacingCarState);
    procedure AddScore(const AScore: TRacingScore);
    property Value: Cardinal read FValue;
  end;

  /// <summary>The scenarios and the pieces that the old code and the library share (the fake world)</summary>
  TRacingScenarios = class
  public
    /// <summary>The angle of the direction from the first point to the second (the fake geometry that both sides use)</summary>
    class function PointToAngle(AX1, AY1, AX2, AY2: Integer): Cardinal; static;
    /// <summary>The approximate distance of the old P_AproxDistance for a 32 bit map</summary>
    class function ApproximateDistance(ADeltaX, ADeltaY: Integer): Integer; static;
    /// <summary>How many tics a sound lasts, for the number that the sound has in the fake world</summary>
    class function SoundDuration(ASoundNumber: Integer): Integer; static;
    /// <summary>The first number of the engine sound of the formula cars and of the stock cars, and of the brakes</summary>
    class function EngineSoundBase(AFormula: Boolean): Integer; static;
    class function BrakeSoundNumber: Integer; static;
    class function FormatParticle(const AKind: string; AX, AY, AZ, AMomentumX, AMomentumY: Integer): string; static;
    class function FormatEngineSound(ASoundNumber: Integer): string; static;
    class function FormatBrakeSound(ASoundNumber, AX, AY, AZ: Integer): string; static;
    /// <summary>The 4096 x 4096 map of the ground of the scenarios (stripes of every kind of ground)</summary>
    class function GroundMap: PByte; static;
    class function NewCar(ACarInfo, AX, AY: Integer; AAngle: Cardinal): TRacingCarState; static;
    /// <summary>The points of a circuit of the given number of points; a shuffled one is listed out of order</summary>
    class function Circuit(ACount: Integer; ARadius: Integer; AShuffled: Boolean): TArray<TRacingPathPoint>; static;
    /// <summary>All the scenarios, one line (or a few) for each</summary>
    class procedure Run(const ATarget: IRacingScenarioTarget; ALines: TStrings); static;
  end;

implementation

uses
  System.Math, DelphiDoom.MathCore.Intf;

const
  CAR_SAMPLE_PHYSICS: array[0..3] of Integer = (0, 7, 20, 33);
  CAR_SAMPLE_RACE: array[0..7] of Integer = (3, 11, 19, 20, 27, 34, 39, 15);

var
  GGroundMap: TBytes;

type
  TLcg = record
    State: Cardinal;
    procedure Start(ASeed: Cardinal);
    function Next(ARange: Integer): Integer;
  end;

{ TLcg }

procedure TLcg.Start(ASeed: Cardinal);
begin
  State := ASeed * 2654435761 + 12345;
end;

function TLcg.Next(ARange: Integer): Integer;
begin
  State := State * 1664525 + 1013904223;
  Result := Integer((State shr 8) mod Cardinal(ARange));
end;

{ TRacingFingerprint }

procedure TRacingFingerprint.Start;
begin
  FValue := 2166136261;
end;

procedure TRacingFingerprint.AddBytes(const AData; ASize: Integer);
var
  LIndex: Integer;
  LByte: PByte;
begin
  LByte := @AData;
  for LIndex := 0 to ASize - 1 do
  begin
    FValue := (FValue xor LByte^) * 16777619;
    Inc(LByte);
  end;
end;

procedure TRacingFingerprint.AddInteger(AValue: Integer);
begin
  AddBytes(AValue, SizeOf(AValue));
end;

procedure TRacingFingerprint.AddInt64(AValue: Int64);
begin
  AddBytes(AValue, SizeOf(AValue));
end;

procedure TRacingFingerprint.AddDouble(AValue: Double);
begin
  AddBytes(AValue, SizeOf(AValue));
end;

procedure TRacingFingerprint.AddString(const AValue: string);
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes(AValue);
  if Length(LBytes) > 0 then
    AddBytes(LBytes[0], Length(LBytes));
  AddInteger(Length(LBytes));
end;

procedure TRacingFingerprint.AddCar(const ACar: TRacingCarState);
var
  LIndex: Integer;
begin
  AddInteger(ACar.X);
  AddInteger(ACar.Y);
  AddInteger(ACar.Z);
  AddInteger(ACar.OldX);
  AddInteger(ACar.OldY);
  AddInteger(Integer(ACar.Angle));
  AddInteger(ACar.MomentumX);
  AddInteger(ACar.MomentumY);
  AddInteger(ACar.EngineSpeed);
  AddInteger(ACar.CarInfo);
  AddInteger(ACar.CarId);
  AddInteger(Integer(ACar.DestinationAngle));
  AddInteger(ACar.DestinationSpeed);
  AddInteger(ACar.CurrentPath);
  AddInteger(ACar.PreviousPath);
  AddInteger(ACar.LapsCompleted);
  AddInteger(ACar.RacePosition);
  AddInteger(ACar.NextParticle);
  for LIndex := 0 to 3 do
    AddDouble(ACar.TireDistance[LIndex]);
  AddInteger(ACar.TireAngle);
  AddInteger(ACar.SoundCountdown);
  AddInteger(ACar.CarTurn);
  AddInteger(ACar.CarAccelerate);
  AddInteger(ACar.CarDecelerate);
  AddInteger(ACar.CarBrake);
  AddInteger(ACar.BrakeSoundCountdown);
  AddInteger(ACar.BrakeSoundX);
  AddInteger(ACar.BrakeSoundY);
  AddInteger(ACar.BrakeSoundZ);
  AddInteger(ACar.Rpm);
  AddInteger(ACar.Gear);
  AddInteger(ACar.DestinationGear);
  AddInteger(ACar.GearTics);
  AddInteger(ACar.NextGearTics);
  AddInteger(ACar.DriftAngle);
end;

procedure TRacingFingerprint.AddScore(const AScore: TRacingScore);
var
  LIndex: Integer;
begin
  AddInteger(AScore.Episode);
  AddInteger(AScore.Map);
  AddInteger(AScore.NumLaps);
  AddInteger(AScore.CarInfo);
  AddInteger(AScore.RacePosition);
  for LIndex := 0 to RACING_MAX_LAPS - 1 do
    AddInteger(AScore.LapTimes[LIndex]);
  AddInteger(AScore.TotalTime);
end;

{ TRacingScenarios }

class function TRacingScenarios.PointToAngle(AX1, AY1, AX2, AY2: Integer): Cardinal;
var
  LAngle: Double;
begin
  LAngle := ArcTan2(AY2 - AY1, AX2 - AX1);
  if LAngle < 0 then
    LAngle := LAngle + 2 * Pi;
  Result := Cardinal(Int64(Round(LAngle / (2 * Pi) * 4294967296.0)));
end;

class function TRacingScenarios.ApproximateDistance(ADeltaX, ADeltaY: Integer): Integer;
begin
  ADeltaX := Abs(ADeltaX);
  ADeltaY := Abs(ADeltaY);
  if ADeltaX < ADeltaY then
    Result := ADeltaX + ADeltaY - (ADeltaX shr 1)
  else
    Result := ADeltaX + ADeltaY - (ADeltaY shr 1);
end;

class function TRacingScenarios.SoundDuration(ASoundNumber: Integer): Integer;
begin
  Result := 4 + (ASoundNumber * 7) mod 19;
end;

class function TRacingScenarios.EngineSoundBase(AFormula: Boolean): Integer;
begin
  if AFormula then
    Result := 300
  else
    Result := 320;
end;

class function TRacingScenarios.BrakeSoundNumber: Integer;
begin
  Result := 340;
end;

class function TRacingScenarios.FormatParticle(const AKind: string; AX, AY, AZ, AMomentumX,
  AMomentumY: Integer): string;
begin
  Result := Format('P %s %d %d %d %d %d', [AKind, AX, AY, AZ, AMomentumX, AMomentumY]);
end;

class function TRacingScenarios.FormatEngineSound(ASoundNumber: Integer): string;
begin
  Result := Format('E %d', [ASoundNumber]);
end;

class function TRacingScenarios.FormatBrakeSound(ASoundNumber, AX, AY, AZ: Integer): string;
begin
  Result := Format('B %d %d %d %d', [ASoundNumber, AX, AY, AZ]);
end;

class function TRacingScenarios.GroundMap: PByte;
var
  LRow, LColumn, LKind: Integer;
begin
  if Length(GGroundMap) = 0 then
  begin
    SetLength(GGroundMap, RACING_GROUND_BYTES);
    for LRow := 0 to RACING_GROUND_SIZE - 1 do
      for LColumn := 0 to RACING_GROUND_SIZE - 1 do
      begin
        LKind := ((LColumn div 128) + (LRow div 256)) mod 7;
        case LKind of
          0, 2, 5: GGroundMap[LRow * RACING_GROUND_SIZE + LColumn] := 160 + (LColumn mod 32);
          1: GGroundMap[LRow * RACING_GROUND_SIZE + LColumn] := 64 + (LRow mod 16);
          3: GGroundMap[LRow * RACING_GROUND_SIZE + LColumn] := 128 + (LColumn mod 16);
          4: GGroundMap[LRow * RACING_GROUND_SIZE + LColumn] := 48 + (LRow mod 16);
        else
          GGroundMap[LRow * RACING_GROUND_SIZE + LColumn] := 7;
        end;
      end;
  end;
  Result := @GGroundMap[0];
end;

class function TRacingScenarios.NewCar(ACarInfo, AX, AY: Integer; AAngle: Cardinal): TRacingCarState;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.CarInfo := ACarInfo;
  Result.X := AX;
  Result.Y := AY;
  Result.OldX := AX;
  Result.OldY := AY;
  Result.Angle := AAngle;
  Result.Key := Cardinal(1000 + ACarInfo);
end;

class function TRacingScenarios.Circuit(ACount, ARadius: Integer; AShuffled: Boolean): TArray<TRacingPathPoint>;
var
  LIndex, LSource: Integer;
  LAngle: Double;
  LLcg: TLcg;
begin
  SetLength(Result, ACount);
  LLcg.Start(ACount * 31 + ARadius);
  for LIndex := 0 to ACount - 1 do
  begin
    LSource := LIndex;
    if AShuffled then
      LSource := (LIndex * 5 + 3) mod ACount;
    LAngle := 2 * Pi * LSource / ACount;
    Result[LIndex].X := (4000 + Round(ARadius * Cos(LAngle))) * FIXED_ONE;
    Result[LIndex].Y := (4000 + Round(ARadius * Sin(LAngle))) * FIXED_ONE;
    Result[LIndex].Angle := Cardinal(Int64(Round((LAngle + Pi / 2) / (2 * Pi) * 4294967296.0)));
    Result[LIndex].Speed := 60 + LLcg.Next(190);
  end;
end;

procedure RunPhysics(const ATarget: IRacingScenarioTarget; ALines: TStrings);
const
  SKILLS: array[0..2] of TRacingSkill = (TRacingSkill.Baby, TRacingSkill.Medium, TRacingSkill.Nightmare);
var
  LCarIndex, LSkillIndex, LMode, LGround, LTic: Integer;
  LSetup: TRacingScenarioSetup;
  LCar: TRacingCarState;
  LPlayer: TRacingPlayerState;
  LInput: TRacingPlayerInput;
  LKind: TRacingDriverKind;
  LPoints: TArray<TRacingPathPoint>;
  LHash, LChunk: TRacingFingerprint;
  LLcg: TLcg;
  LLine: Integer;
  LText: string;
begin
  LPoints := TRacingScenarios.Circuit(24, 2400, False);
  for LCarIndex := 0 to High(CAR_SAMPLE_PHYSICS) do
    for LSkillIndex := 0 to High(SKILLS) do
      for LMode := 0 to 2 do
        for LGround := 0 to 1 do
        begin
          FillChar(LSetup, SizeOf(LSetup), 0);
          LSetup.Laps := 3;
          LSetup.Skill := SKILLS[LSkillIndex];
          LSetup.Transmission := Ord(LMode = 1);
          LSetup.Status := TRacingStatus.Waiting;
          LSetup.CarType := TRacingCarType.Any;
          LSetup.Episode := 1;
          LSetup.Map := 3;
          LSetup.Seed := 17 + LCarIndex * 40 + LSkillIndex * 9 + LMode * 3 + LGround;
          ATarget.Reset(LSetup);
          if LGround = 1 then
            ATarget.SetGround(TRacingScenarios.GroundMap, RACING_GROUND_BYTES)
          else
            ATarget.SetGround(nil, 0);
          ATarget.SetView(LPoints[0].X, LPoints[0].Y);
          ATarget.LoadTrack(LPoints);
          LCar := TRacingScenarios.NewCar(CAR_SAMPLE_PHYSICS[LCarIndex], LPoints[0].X, LPoints[0].Y, LPoints[0].Angle);
          LCar.CurrentPath := 0;
          LCar.Gear := 0;
          FillChar(LPlayer, SizeOf(LPlayer), 0);
          LKind := TRacingDriverKind.Computer;
          if LMode <> 2 then
            LKind := TRacingDriverKind.Person;
          LLcg.Start(LSetup.Seed);
          LHash.Start;
          LChunk.Start;
          LText := '';
          FillChar(LInput, SizeOf(LInput), 0);
          for LTic := 0 to 449 do
          begin
            if LTic = 3 then
              ATarget.SetStatus(TRacingStatus.Racing);
            if LTic mod 20 = 0 then
            begin
              LInput.ForwardMove := LLcg.Next(3) - 1;
              if LLcg.Next(4) <> 0 then
                LInput.ForwardMove := 1;
              LInput.AngleTurn := (LLcg.Next(81) - 40) * 8;
              LInput.Buttons := LLcg.Next(3);
            end
            else if LTic mod 3 = 0 then
              LInput.Buttons := LLcg.Next(3);
            if LTic > 3 then
              ATarget.SetClocks(LTic - 3, LTic)
            else
              ATarget.SetClocks(0, LTic);
            ATarget.EffectLog.Clear;
            ATarget.MoveCar(LCar, LPlayer, LInput, LKind);
            LHash.AddCar(LCar);
            LChunk.AddCar(LCar);
            for LLine := 0 to ATarget.EffectLog.Count - 1 do
            begin
              LHash.AddString(ATarget.EffectLog[LLine]);
              LChunk.AddString(ATarget.EffectLog[LLine]);
            end;
            if LKind = TRacingDriverKind.Person then
            begin
              LHash.AddScore(ATarget.PlayerScore);
              LChunk.AddScore(ATarget.PlayerScore);
            end;
            LCar.OldX := LCar.X;
            LCar.OldY := LCar.Y;
            LCar.X := LCar.X + LCar.MomentumX;
            LCar.Y := LCar.Y + LCar.MomentumY;
            if LTic mod 150 = 149 then
            begin
              LText := LText + Format(' %.8x', [LChunk.Value]);
              LChunk.Start;
            end;
          end;
          ALines.Add(Format('physics car=%d skill=%d mode=%d ground=%d chunks%s total=%.8x end gear=%d rpm=%d speed=%d laps=%d',
            [CAR_SAMPLE_PHYSICS[LCarIndex], Ord(SKILLS[LSkillIndex]), LMode, LGround, LText, LHash.Value,
             LCar.Gear, LCar.Rpm, LCar.EngineSpeed, LCar.LapsCompleted]));
        end;
end;

procedure RunTracks(const ATarget: IRacingScenarioTarget; ALines: TStrings);
const
  COUNTS: array[0..2] of Integer = (24, 40, 12);
var
  LVariant, LProbe: Integer;
  LPoints: TArray<TRacingPathPoint>;
  LDescription: TStringList;
  LSetup: TRacingScenarioSetup;
  LHash: TRacingFingerprint;
  LLcg: TLcg;
begin
  LDescription := TStringList.Create;
  try
    for LVariant := 0 to 2 do
    begin
      LPoints := TRacingScenarios.Circuit(COUNTS[LVariant], 1500 + LVariant * 300, LVariant = 2);
      FillChar(LSetup, SizeOf(LSetup), 0);
      LSetup.Laps := 3;
      LSetup.Skill := TRacingSkill.Medium;
      LSetup.Status := TRacingStatus.Racing;
      LSetup.CarType := TRacingCarType.Any;
      LSetup.Seed := 5 + LVariant;
      ATarget.Reset(LSetup);
      ALines.Add(Format('track variant=%d loaded=%s', [LVariant, BoolToStr(ATarget.LoadTrack(LPoints), True)]));
      LDescription.Clear;
      ATarget.DescribeTrack(LDescription);
      LHash.Start;
      for LProbe := 0 to LDescription.Count - 1 do
        LHash.AddString(LDescription[LProbe]);
      ALines.Add(Format('track variant=%d description lines=%d hash=%.8x first=%s',
        [LVariant, LDescription.Count, LHash.Value, LDescription[0]]));

      LLcg.Start(LVariant + 90);
      LHash.Start;
      for LProbe := 0 to 199 do
        LHash.AddInteger(ATarget.NextPath((4000 + LLcg.Next(4000) - 2000) * FIXED_ONE,
          (4000 + LLcg.Next(4000) - 2000) * FIXED_ONE));
      // A probe exactly on a point goes to the next one
      for LProbe := 0 to High(LPoints) do
        LHash.AddInteger(ATarget.NextPath(LPoints[LProbe].X, LPoints[LProbe].Y));
      ALines.Add(Format('track variant=%d nextpath hash=%.8x', [LVariant, LHash.Value]));
    end;
  finally
    LDescription.Free;
  end;
end;

procedure RunRaces(const ATarget: IRacingScenarioTarget; ALines: TStrings);
const
  SKILLS: array[0..1] of TRacingSkill = (TRacingSkill.Easy, TRacingSkill.Hard);
  COUNTS: array[0..2] of Integer = (24, 40, 12);
  MAX_TICS = 4800;
var
  LSkillIndex, LVariant, LCarIndex, LTic, LPlace, LLine: Integer;
  LPoints: TArray<TRacingPathPoint>;
  LSetup: TRacingScenarioSetup;
  LCars: array[0..7] of TRacingCarState;
  LPlayers: array[0..7] of TRacingPlayerState;
  LInput: TRacingPlayerInput;
  LKind: TRacingDriverKind;
  LHash, LPositionHash: TRacingFingerprint;
  LInputs: array[0..7] of TRacingPositionInput;
  LItems: TArray<TRacingPositionItem>;
  LTimes: TRacingLapTimes;
  LLcg: TLcg;
  LStartPath, LCount: Integer;
  LText: string;
begin
  for LSkillIndex := 0 to High(SKILLS) do
    for LVariant := 0 to 2 do
    begin
      LPoints := TRacingScenarios.Circuit(COUNTS[LVariant], 2000 + LVariant * 200, LVariant = 2);
      LCount := Length(LPoints);
      FillChar(LSetup, SizeOf(LSetup), 0);
      LSetup.Laps := 1;
      LSetup.Skill := SKILLS[LSkillIndex];
      LSetup.Status := TRacingStatus.Racing;
      LSetup.CarType := TRacingCarType.Any;
      LSetup.Episode := 2;
      LSetup.Map := 5;
      LSetup.Seed := 70 + LSkillIndex * 5 + LVariant;
      ATarget.Reset(LSetup);
      ATarget.SetGround(TRacingScenarios.GroundMap, RACING_GROUND_BYTES);
      ATarget.SetView(LPoints[0].X, LPoints[0].Y);
      ATarget.LoadTrack(LPoints);

      for LCarIndex := 0 to High(LCars) do
      begin
        LStartPath := (LCount - 1 - LCarIndex * 2 + LCount) mod LCount;
        LCars[LCarIndex] := TRacingScenarios.NewCar(CAR_SAMPLE_RACE[LCarIndex], LPoints[LStartPath].X,
          LPoints[LStartPath].Y, LPoints[LStartPath].Angle);
        LCars[LCarIndex].CurrentPath := LStartPath;
        LCars[LCarIndex].PreviousPath := (LStartPath + LCount - 1) mod LCount;
        LCars[LCarIndex].LapsCompleted := 0;
        LCars[LCarIndex].IsPlayer := LCarIndex = 0;
        FillChar(LPlayers[LCarIndex], SizeOf(LPlayers[LCarIndex]), 0);
      end;

      LLcg.Start(LSetup.Seed);
      LHash.Start;
      LPositionHash.Start;
      LText := '';
      FillChar(LInput, SizeOf(LInput), 0);
      for LTic := 0 to MAX_TICS - 1 do
      begin
        ATarget.SetClocks(LTic, LTic);
        if LTic mod 25 = 0 then
        begin
          LInput.ForwardMove := 1;
          LInput.AngleTurn := (LLcg.Next(21) - 10) * 4;
          LInput.Buttons := LLcg.Next(3);
        end;
        for LCarIndex := 0 to High(LCars) do
        begin
          if LCarIndex = 0 then
            LKind := TRacingDriverKind.Person
          else
            LKind := TRacingDriverKind.Computer;
          ATarget.EffectLog.Clear;
          ATarget.MoveCar(LCars[LCarIndex], LPlayers[LCarIndex], LInput, LKind);
          LHash.AddCar(LCars[LCarIndex]);
          for LLine := 0 to ATarget.EffectLog.Count - 1 do
            LHash.AddString(ATarget.EffectLog[LLine]);
          if LCarIndex = 0 then
            LHash.AddScore(ATarget.PlayerScore);
          LCars[LCarIndex].OldX := LCars[LCarIndex].X;
          LCars[LCarIndex].OldY := LCars[LCarIndex].Y;
          LCars[LCarIndex].X := LCars[LCarIndex].X + LCars[LCarIndex].MomentumX;
          LCars[LCarIndex].Y := LCars[LCarIndex].Y + LCars[LCarIndex].MomentumY;
        end;

        if LTic mod 5 = 4 then
        begin
          for LCarIndex := 0 to High(LCars) do
          begin
            LInputs[LCarIndex].Key := LCars[LCarIndex].Key;
            LInputs[LCarIndex].CarInfo := LCars[LCarIndex].CarInfo;
            LInputs[LCarIndex].LapsCompleted := LCars[LCarIndex].LapsCompleted;
            LInputs[LCarIndex].CurrentPath := LCars[LCarIndex].CurrentPath;
            LInputs[LCarIndex].X := LCars[LCarIndex].X;
            LInputs[LCarIndex].Y := LCars[LCarIndex].Y;
          end;
          LItems := ATarget.Positions(LInputs);
          for LPlace := 0 to High(LItems) do
          begin
            LPositionHash.AddInteger(LItems[LPlace].Index);
            LPositionHash.AddInteger(Integer(LItems[LPlace].Key));
            LPositionHash.AddInt64(LItems[LPlace].TotalDistance);
            LPositionHash.AddInteger(LItems[LPlace].LapsCompleted);
            LPositionHash.AddInteger(LItems[LPlace].FinishTime);
            LCars[LItems[LPlace].Index].RacePosition := LPlace + 1;
          end;
        end;

        if LTic mod 1200 = 1199 then
          LText := LText + Format(' %.8x', [LHash.Value]);
      end;

      LHash.AddString('laps');
      for LCarIndex := 0 to High(LCars) do
      begin
        ATarget.LapTimes(LCars[LCarIndex], LTimes);
        for LPlace := 0 to RACING_MAX_LAPS - 1 do
          LHash.AddInteger(LTimes[LPlace]);
      end;
      ALines.Add(Format('race skill=%d variant=%d chunks%s total=%.8x positions=%.8x laps=%d,%d,%d,%d,%d,%d,%d,%d',
        [Ord(SKILLS[LSkillIndex]), LVariant, LText, LHash.Value, LPositionHash.Value,
         LCars[0].LapsCompleted, LCars[1].LapsCompleted, LCars[2].LapsCompleted, LCars[3].LapsCompleted,
         LCars[4].LapsCompleted, LCars[5].LapsCompleted, LCars[6].LapsCompleted, LCars[7].LapsCompleted]));
      ATarget.LapTimes(LCars[3], LTimes);
      ALines.Add(Format('race skill=%d variant=%d car3 laptimes=%d,%d,%d first positions=%d,%d,%d',
        [Ord(SKILLS[LSkillIndex]), LVariant, LTimes[0], LTimes[1], LTimes[2],
         LCars[0].RacePosition, LCars[1].RacePosition, LCars[2].RacePosition]));
    end;
end;

procedure RunGround(const ATarget: IRacingScenarioTarget; ALines: TStrings);
var
  LSetup: TRacingScenarioSetup;
  LHash: TRacingFingerprint;
  LLcg: TLcg;
  LProbe, LX, LY: Integer;
begin
  FillChar(LSetup, SizeOf(LSetup), 0);
  LSetup.Seed := 123;
  ATarget.Reset(LSetup);
  ATarget.SetGround(TRacingScenarios.GroundMap, RACING_GROUND_BYTES);
  LLcg.Start(99);
  LHash.Start;
  for LProbe := 0 to 599 do
  begin
    LX := (LLcg.Next(12000) - 2000) * FIXED_ONE + LLcg.Next(FIXED_ONE);
    LY := (LLcg.Next(12000) - 2000) * FIXED_ONE + LLcg.Next(FIXED_ONE);
    LHash.AddInteger(ATarget.GroundType(LX, LY));
    LHash.AddInteger(ATarget.Slip(LX, LY));
  end;
  ALines.Add(Format('ground map probes hash=%.8x', [LHash.Value]));

  // A map of another size is only asphalt
  ATarget.SetGround(TRacingScenarios.GroundMap, RACING_GROUND_BYTES - 1);
  LHash.Start;
  for LProbe := 0 to 99 do
  begin
    LX := (LLcg.Next(12000)) * FIXED_ONE;
    LY := (LLcg.Next(12000)) * FIXED_ONE;
    LHash.AddInteger(ATarget.GroundType(LX, LY));
  end;
  ALines.Add(Format('ground other size hash=%.8x', [LHash.Value]));

  LHash.Start;
  for LProbe := 0 to 799 do
  begin
    LX := Integer(Cardinal(LLcg.Next(MaxInt)) * 2654435761) div (1 + LProbe mod 3);
    LHash.AddInteger(ATarget.SlipCalculation(LX, Byte(LLcg.Next(256))));
  end;
  ALines.Add(Format('ground slipcalculation hash=%.8x', [LHash.Value]));
end;

procedure RunScores(const ATarget: IRacingScenarioTarget; ALines: TStrings);
const
  NAMES: array[0..5] of string = ('ANN', 'BOB', 'CHRISTOPHER', 'ZZ', 'A VERY LONG PILOT NAME', '');
var
  LSetup: TRacingScenarioSetup;
  LScore: TRacingScore;
  LHash, LBytesHash: TRacingFingerprint;
  LLcg: TLcg;
  LStep, LLap: Integer;
  LBytes: TBytes;
begin
  FillChar(LSetup, SizeOf(LSetup), 0);
  LSetup.Seed := 9;
  ATarget.Reset(LSetup);
  ATarget.ScoreClear;
  LLcg.Start(2024);
  LHash.Start;
  for LStep := 0 to 399 do
  begin
    FillChar(LScore, SizeOf(LScore), 0);
    LScore.Episode := LLcg.Next(6);
    LScore.Map := LLcg.Next(11);
    LScore.NumLaps := LLcg.Next(12);
    LScore.CarInfo := LLcg.Next(RACING_CAR_COUNT);
    LScore.RacePosition := 1 + LLcg.Next(8);
    for LLap := 0 to RACING_MAX_LAPS - 1 do
      if LLcg.Next(9) <> 0 then
      begin
        LScore.LapTimes[LLap] := 1000 + LLcg.Next(8000);
        Inc(LScore.TotalTime, LScore.LapTimes[LLap]);
      end;
    ATarget.ScoreUpdate(LScore, NAMES[LLcg.Next(6)], TRacingSkill(LLcg.Next(5)));
    LHash.AddInteger(Ord(ATarget.ScoreCheck(1 + LLcg.Next(4), 1 + LLcg.Next(9), TRacingCarType(LLcg.Next(2)),
      900 + LLcg.Next(8000))));
  end;
  LBytes := ATarget.ScoreBytes;
  LBytesHash.Start;
  LBytesHash.AddBytes(LBytes[0], Length(LBytes));
  ALines.Add(Format('scores size=%d recordsize=%d bytes=%.8x checks=%.8x',
    [Length(LBytes), SizeOf(TRacingScoreItem), LBytesHash.Value, LHash.Value]));
end;

procedure RunGrids(const ATarget: IRacingScenarioTarget; ALines: TStrings);
const
  STARTS: array[0..6] of Integer = (0, 1, 5, 12, 19, 20, 21);
var
  LSetup: TRacingScenarioSetup;
  LCarType, LStart, LPlayers, LIndex, LStartCar: Integer;
  LResult, LPlayerCars: TArray<Integer>;
  LHash: TRacingFingerprint;
  LText: string;
begin
  LHash.Start;
  for LCarType := 0 to 2 do
    for LPlayers := 0 to 3 do
    begin
      FillChar(LSetup, SizeOf(LSetup), 0);
      LSetup.Seed := 30 + LCarType * 4 + LPlayers;
      ATarget.Reset(LSetup);
      case LPlayers of
        0: LPlayerCars := [];
        1: LPlayerCars := [0];
        2: LPlayerCars := [20, 3];
      else
        LPlayerCars := [5, 6, 7, 8];
      end;
      for LIndex := 0 to High(STARTS) do
      begin
        LStart := STARTS[LIndex];
        LText := '';
        try
          LResult := ATarget.Grid(LStart, TRacingCarType(LCarType), LPlayerCars);
          for LStartCar := 0 to High(LResult) do
            LText := LText + ' ' + IntToStr(LResult[LStartCar]);
        except
          on E: ERacingException do
            LText := ' error';
        end;
        LHash.AddString(Format('%d,%d,%d:%s', [LCarType, LPlayers, LStart, LText]));
        if LStart = 19 then
          ALines.Add(Format('grid cartype=%d players=%d start=%d:%s', [LCarType, LPlayers, LStart, LText]));
      end;
    end;
  ALines.Add(Format('grid all hash=%.8x', [LHash.Value]));
end;

class procedure TRacingScenarios.Run(const ATarget: IRacingScenarioTarget; ALines: TStrings);
begin
  ALines.Add(Format('sizes scoreitem=%d recordtable=%d', [ATarget.ScoreItemSize, Length(ATarget.ScoreBytes)]));
  RunGround(ATarget, ALines);
  RunScores(ATarget, ALines);
  RunGrids(ATarget, ALines);
  RunTracks(ATarget, ALines);
  RunPhysics(ATarget, ALines);
  RunRaces(ATarget, ALines);
end;

end.

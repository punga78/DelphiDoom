{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the race in a saved game                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.SaveGameCodec;

// Times and positions are 32 bit integers that wrap as in the old code
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Racing.RaceController;

type
  /// <summary>
  ///   The state of a race as bytes, in a layout of its own that is the same at 32 and at 64 bit (every
  ///   field is written one by one: the records of the cars have padding that depends on the compiler).
  ///   The saved game of the engine keeps the objects, the cars' positions among them; this keeps what the
  ///   objects do not have: the engine of the cars, the laps, the times at every point of the path, the
  ///   state of the race
  /// </summary>
  TRacingSaveGameCodec = class
  public
    /// <summary>The state of the race of the controller as bytes</summary>
    class function Encode(const AController: TRacingRaceController): TBytes; static;
    /// <summary>
    ///   Puts a state back into a controller that has the same cars and the same track as the one that
    ///   was saved. Nothing is changed when the bytes are not a state of this race
    /// </summary>
    /// <returns>False when the bytes are too short, of another version, of another number of cars or of points</returns>
    class function Decode(const AController: TRacingRaceController; const ABytes: TBytes): Boolean; static;
  end;

implementation

uses
  System.Classes, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

const
  MAGIC: array[0..7] of AnsiChar = ('R', 'A', 'C', 'I', 'N', 'G', 'S', 'V');
  VERSION = 1;

type
  TWriter = class
  strict private
    FStream: TBytesStream;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Int(AValue: Integer);
    procedure Bool(AValue: Boolean);
    procedure Dbl(AValue: Double);
    function Bytes: TBytes;
  end;

  TReader = class
  strict private
    FBytes: TBytes;
    FPosition: Integer;
    FFailed: Boolean;
  public
    constructor Create(const ABytes: TBytes);
    function Int: Integer;
    function Bool: Boolean;
    function Dbl: Double;
    property Failed: Boolean read FFailed;
    function Remaining: Integer;
  end;

{ TWriter }

constructor TWriter.Create;
begin
  inherited Create;
  FStream := TBytesStream.Create;
end;

destructor TWriter.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;

procedure TWriter.Int(AValue: Integer);
begin
  FStream.WriteBuffer(AValue, 4);
end;

procedure TWriter.Bool(AValue: Boolean);
var
  LByte: Byte;
begin
  LByte := Ord(AValue);
  FStream.WriteBuffer(LByte, 1);
end;

procedure TWriter.Dbl(AValue: Double);
begin
  FStream.WriteBuffer(AValue, 8);
end;

function TWriter.Bytes: TBytes;
begin
  Result := Copy(FStream.Bytes, 0, FStream.Size);
end;

{ TReader }

constructor TReader.Create(const ABytes: TBytes);
begin
  inherited Create;
  FBytes := ABytes;
end;

function TReader.Remaining: Integer;
begin
  Result := Length(FBytes) - FPosition;
end;

function TReader.Int: Integer;
begin
  Result := 0;
  if FFailed or (Remaining < 4) then
  begin
    FFailed := True;
    Exit;
  end;
  Move(FBytes[FPosition], Result, 4);
  Inc(FPosition, 4);
end;

function TReader.Bool: Boolean;
begin
  Result := False;
  if FFailed or (Remaining < 1) then
  begin
    FFailed := True;
    Exit;
  end;
  Result := FBytes[FPosition] <> 0;
  Inc(FPosition);
end;

function TReader.Dbl: Double;
begin
  Result := 0;
  if FFailed or (Remaining < 8) then
  begin
    FFailed := True;
    Exit;
  end;
  Move(FBytes[FPosition], Result, 8);
  Inc(FPosition, 8);
end;

procedure WriteScore(AWriter: TWriter; const AScore: TRacingScore);
var
  LIndex: Integer;
begin
  AWriter.Int(AScore.Episode);
  AWriter.Int(AScore.Map);
  AWriter.Int(AScore.NumLaps);
  AWriter.Int(AScore.CarInfo);
  AWriter.Int(AScore.RacePosition);
  for LIndex := 0 to RACING_MAX_LAPS - 1 do
    AWriter.Int(AScore.LapTimes[LIndex]);
  AWriter.Int(AScore.TotalTime);
end;

procedure ReadScore(AReader: TReader; var AScore: TRacingScore);
var
  LIndex: Integer;
begin
  AScore.Episode := AReader.Int;
  AScore.Map := AReader.Int;
  AScore.NumLaps := AReader.Int;
  AScore.CarInfo := AReader.Int;
  AScore.RacePosition := AReader.Int;
  for LIndex := 0 to RACING_MAX_LAPS - 1 do
    AScore.LapTimes[LIndex] := AReader.Int;
  AScore.TotalTime := AReader.Int;
end;

procedure WriteCar(AWriter: TWriter; const ACar: TRacingCarState);
var
  LIndex: Integer;
begin
  AWriter.Int(ACar.X);
  AWriter.Int(ACar.Y);
  AWriter.Int(ACar.Z);
  AWriter.Int(ACar.OldX);
  AWriter.Int(ACar.OldY);
  AWriter.Int(Integer(ACar.Angle));
  AWriter.Int(ACar.MomentumX);
  AWriter.Int(ACar.MomentumY);
  AWriter.Int(ACar.EngineSpeed);
  AWriter.Int(ACar.CarInfo);
  AWriter.Int(ACar.CarId);
  AWriter.Int(Integer(ACar.DestinationAngle));
  AWriter.Int(ACar.DestinationSpeed);
  AWriter.Int(ACar.CurrentPath);
  AWriter.Int(ACar.PreviousPath);
  AWriter.Int(ACar.LapsCompleted);
  AWriter.Int(ACar.RacePosition);
  AWriter.Int(ACar.NextParticle);
  for LIndex := 0 to 3 do
    AWriter.Dbl(ACar.TireDistance[LIndex]);
  AWriter.Int(ACar.TireAngle);
  AWriter.Int(ACar.SoundCountdown);
  AWriter.Int(ACar.CarTurn);
  AWriter.Int(ACar.CarAccelerate);
  AWriter.Int(ACar.CarDecelerate);
  AWriter.Int(ACar.CarBrake);
  AWriter.Int(ACar.BrakeSoundCountdown);
  AWriter.Int(ACar.BrakeSoundX);
  AWriter.Int(ACar.BrakeSoundY);
  AWriter.Int(ACar.BrakeSoundZ);
  AWriter.Int(ACar.Rpm);
  AWriter.Int(ACar.Gear);
  AWriter.Int(ACar.DestinationGear);
  AWriter.Int(ACar.GearTics);
  AWriter.Int(ACar.NextGearTics);
  AWriter.Int(ACar.DriftAngle);
  AWriter.Int(Integer(ACar.Key));
  AWriter.Bool(ACar.IsPlayer);
end;

procedure ReadCar(AReader: TReader; var ACar: TRacingCarState);
var
  LIndex: Integer;
begin
  ACar.X := AReader.Int;
  ACar.Y := AReader.Int;
  ACar.Z := AReader.Int;
  ACar.OldX := AReader.Int;
  ACar.OldY := AReader.Int;
  ACar.Angle := Cardinal(AReader.Int);
  ACar.MomentumX := AReader.Int;
  ACar.MomentumY := AReader.Int;
  ACar.EngineSpeed := AReader.Int;
  ACar.CarInfo := AReader.Int;
  ACar.CarId := AReader.Int;
  ACar.DestinationAngle := Cardinal(AReader.Int);
  ACar.DestinationSpeed := AReader.Int;
  ACar.CurrentPath := AReader.Int;
  ACar.PreviousPath := AReader.Int;
  ACar.LapsCompleted := AReader.Int;
  ACar.RacePosition := AReader.Int;
  ACar.NextParticle := AReader.Int;
  for LIndex := 0 to 3 do
    ACar.TireDistance[LIndex] := AReader.Dbl;
  ACar.TireAngle := AReader.Int;
  ACar.SoundCountdown := AReader.Int;
  ACar.CarTurn := AReader.Int;
  ACar.CarAccelerate := AReader.Int;
  ACar.CarDecelerate := AReader.Int;
  ACar.CarBrake := AReader.Int;
  ACar.BrakeSoundCountdown := AReader.Int;
  ACar.BrakeSoundX := AReader.Int;
  ACar.BrakeSoundY := AReader.Int;
  ACar.BrakeSoundZ := AReader.Int;
  ACar.Rpm := AReader.Int;
  ACar.Gear := AReader.Int;
  ACar.DestinationGear := AReader.Int;
  ACar.GearTics := AReader.Int;
  ACar.NextGearTics := AReader.Int;
  ACar.DriftAngle := AReader.Int;
  ACar.Key := Cardinal(AReader.Int);
  ACar.IsPlayer := AReader.Bool;
end;

{ TRacingSaveGameCodec }

class function TRacingSaveGameCodec.Encode(const AController: TRacingRaceController): TBytes;
var
  LWriter: TWriter;
  LIndex, LCar, LVisit: Integer;
  LRace: IRacingRaceSettings;
  LState: TRacingControllerState;
  LPath: PRacingPath;
begin
  LWriter := TWriter.Create;
  try
    for LIndex := 0 to High(MAGIC) do
      LWriter.Int(Ord(MAGIC[LIndex]));
    LWriter.Int(VERSION);
    LRace := AController.Race;
    LWriter.Int(Ord(LRace.Status));
    LWriter.Int(Ord(LRace.CarType));
    LWriter.Int(Ord(LRace.GameType));
    LWriter.Int(LRace.TransmissionType);
    LWriter.Int(LRace.NumLaps);
    LWriter.Int(LRace.RaceTime);
    LWriter.Int(LRace.LevelTime);
    LWriter.Int(Ord(LRace.Skill));
    LWriter.Int(LRace.Episode);
    LWriter.Int(LRace.Map);

    LState := AController.State;
    LWriter.Int(LState.FinishTic);
    LWriter.Bool(LState.ResultGiven);
    LWriter.Bool(LState.Left);
    LWriter.Bool(LState.HasFinalScore);
    WriteScore(LWriter, LState.FinalScore);
    for LIndex := 0 to RACING_MAX_LAPS - 1 do
      LWriter.Bool(LState.PlayerState.LapRecordChecked[LIndex]);

    LWriter.Int(AController.Count);
    LWriter.Int(AController.PlayerIndex);
    for LCar := 0 to AController.Count - 1 do
      WriteCar(LWriter, AController.Cars[LCar]^);

    LWriter.Int(AController.Track.PathCount);
    for LIndex := 0 to AController.Track.PathCount - 1 do
    begin
      LPath := AController.Track.GetPath(LIndex);
      for LCar := 0 to RACING_CAR_COUNT - 1 do
        for LVisit := 0 to RACING_MAX_LAPS do
        begin
          LWriter.Int(LPath.Visits[LCar][LVisit].EnterTime);
          LWriter.Int(LPath.Visits[LCar][LVisit].ExitTime);
          LWriter.Int(LPath.Visits[LCar][LVisit].VisitLap);
        end;
    end;
    Result := LWriter.Bytes;
  finally
    LWriter.Free;
  end;
end;

class function TRacingSaveGameCodec.Decode(const AController: TRacingRaceController;
  const ABytes: TBytes): Boolean;
var
  LReader: TReader;
  LIndex, LCar, LVisit, LCount: Integer;
  LStatus, LCarType, LGameType, LTransmission, LLaps, LRaceTime, LLevelTime, LSkill, LEpisode, LMap: Integer;
  LState: TRacingControllerState;
  LCars: TArray<TRacingCarState>;
  LVisits: TArray<TRacingPathVisit>;
  LPath: PRacingPath;
  LRace: IRacingRaceSettings;
begin
  Result := False;
  LReader := TReader.Create(ABytes);
  try
    for LIndex := 0 to High(MAGIC) do
      if LReader.Int <> Ord(MAGIC[LIndex]) then
        Exit;
    if LReader.Int <> VERSION then
      Exit;
    LStatus := LReader.Int;
    LCarType := LReader.Int;
    LGameType := LReader.Int;
    LTransmission := LReader.Int;
    LLaps := LReader.Int;
    LRaceTime := LReader.Int;
    LLevelTime := LReader.Int;
    LSkill := LReader.Int;
    LEpisode := LReader.Int;
    LMap := LReader.Int;
    LState := Default(TRacingControllerState);
    LState.FinishTic := LReader.Int;
    LState.ResultGiven := LReader.Bool;
    LState.Left := LReader.Bool;
    LState.HasFinalScore := LReader.Bool;
    ReadScore(LReader, LState.FinalScore);
    for LIndex := 0 to RACING_MAX_LAPS - 1 do
      LState.PlayerState.LapRecordChecked[LIndex] := LReader.Bool;
    LCount := LReader.Int;
    LReader.Int;
    if LReader.Failed or (LCount <> AController.Count) or
       (LStatus < Ord(Low(TRacingStatus))) or (LStatus > Ord(High(TRacingStatus))) or
       (LCarType < Ord(Low(TRacingCarType))) or (LCarType > Ord(High(TRacingCarType))) or
       (LGameType < Ord(Low(TRacingGameType))) or (LGameType > Ord(High(TRacingGameType))) or
       (LSkill < Ord(Low(TRacingSkill))) or (LSkill > Ord(High(TRacingSkill))) then
      Exit;
    SetLength(LCars, LCount);
    for LCar := 0 to LCount - 1 do
      ReadCar(LReader, LCars[LCar]);
    if LReader.Failed or (LReader.Int <> AController.Track.PathCount) then
      Exit;
    SetLength(LVisits, AController.Track.PathCount * RACING_CAR_COUNT * (RACING_MAX_LAPS + 1));
    for LIndex := 0 to High(LVisits) do
    begin
      LVisits[LIndex].EnterTime := LReader.Int;
      LVisits[LIndex].ExitTime := LReader.Int;
      LVisits[LIndex].VisitLap := LReader.Int;
    end;
    if LReader.Failed then
      Exit;

    // everything was read: now the controller changes
    LRace := AController.Race;
    LRace.SetStatus(TRacingStatus(LStatus));
    LRace.SetCarType(TRacingCarType(LCarType));
    LRace.SetGameType(TRacingGameType(LGameType));
    LRace.SetTransmissionType(LTransmission);
    LRace.SetNumLaps(LLaps);
    LRace.SetRaceTime(LRaceTime);
    LRace.SetLevelTime(LLevelTime);
    LRace.SetSkill(TRacingSkill(LSkill));
    LRace.SetEpisode(LEpisode);
    LRace.SetMap(LMap);
    AController.State := LState;
    for LCar := 0 to LCount - 1 do
      AController.Cars[LCar]^ := LCars[LCar];
    LIndex := 0;
    for LCount := 0 to AController.Track.PathCount - 1 do
    begin
      LPath := AController.Track.GetPath(LCount);
      for LCar := 0 to RACING_CAR_COUNT - 1 do
        for LVisit := 0 to RACING_MAX_LAPS do
        begin
          LPath.Visits[LCar][LVisit] := LVisits[LIndex];
          Inc(LIndex);
        end;
    end;
    Result := True;
  finally
    LReader.Free;
  end;
end;

end.

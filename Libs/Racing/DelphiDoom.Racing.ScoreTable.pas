{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the tables of the best times                   }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of speed_score.pas (the file of the records is the same)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.ScoreTable;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   The ten best times of every track, for the formula cars and for the stock cars: of the
  ///   laps and of the whole race for each number of laps. The file of the records is the bytes
  ///   of the table as they are, so the files of the old game are read
  /// </summary>
  TRacingScoreTableStore = class(TInterfacedObject, IRacingScoreTable)
  strict private
    FRecords: TRacingRecordTable;
    function ItemsOf(ALaps, AEpisode, AMap: Integer; ACarType: TRacingCarType): PRacingScoreItems;
    procedure Sort(ALaps, AEpisode, AMap: Integer; ACarType: TRacingCarType);
  public
    constructor Create;
    function GetRecords: PRacingRecordTable;
    procedure Clear;
    procedure Update(const AScore: TRacingScore; const ADriverName: string; ASkill: TRacingSkill);
    function CheckLapRecord(AEpisode, AMap: Integer; ACarType: TRacingCarType; ATime: Integer): Boolean;
    function LoadFromBytes(const ABytes: TBytes): Boolean;
    function SaveToBytes: TBytes;
  end;

implementation

uses
  DelphiDoom.Racing.CarData, DelphiDoom.Racing.Math;

{ TRacingScoreTableStore }

constructor TRacingScoreTableStore.Create;
begin
  inherited Create;
  Clear;
end;

function TRacingScoreTableStore.GetRecords: PRacingRecordTable;
begin
  Result := @FRecords;
end;

procedure TRacingScoreTableStore.Clear;
begin
  FillChar(FRecords, SizeOf(FRecords), 0);
end;

function TRacingScoreTableStore.ItemsOf(ALaps, AEpisode, AMap: Integer;
  ACarType: TRacingCarType): PRacingScoreItems;
begin
  if ALaps = 0 then
    Result := @FRecords.LapRecords[AEpisode, AMap, ACarType]
  else if TRacingMath.IsInRange(ALaps, RACING_MIN_LAPS, RACING_MAX_LAPS) then
    Result := @FRecords.CourseRecords[ALaps][AEpisode, AMap, ACarType]
  else
    Result := nil;
end;

procedure TRacingScoreTableStore.Sort(ALaps, AEpisode, AMap: Integer; ACarType: TRacingCarType);
var
  LItems: TRacingScoreItems;
  LTable: PRacingScoreItems;
  LCount, LIndex: Integer;

  procedure QuickSort(ALeft, ARight: Integer);
  var
    LI, LJ, LPivot: Integer;
    LTemp: TRacingScoreItem;
  begin
    repeat
      LI := ALeft;
      LJ := ARight;
      // The pivot is the slot, not a copy: the swaps can change what is in it, as in the old sort
      LPivot := (ALeft + ARight) shr 1;
      repeat
        while LItems[LI].Time < LItems[LPivot].Time do
          Inc(LI);
        while LItems[LJ].Time > LItems[LPivot].Time do
          Dec(LJ);
        if LI <= LJ then
        begin
          LTemp := LItems[LI];
          LItems[LI] := LItems[LJ];
          LItems[LJ] := LTemp;
          Inc(LI);
          Dec(LJ);
        end;
      until LI > LJ;
      if ALeft < LJ then
        QuickSort(ALeft, LJ);
      ALeft := LI;
    until LI >= ARight;
  end;

begin
  LTable := ItemsOf(ALaps, AEpisode, AMap, ACarType);
  if LTable = nil then
    Exit;

  FillChar(LItems, SizeOf(LItems), 0);

  LCount := 0;
  for LIndex := 0 to RACING_SCORES_PER_TABLE - 1 do
    if LTable[LIndex].Time <> 0 then
    begin
      LItems[LCount] := LTable[LIndex];
      Inc(LCount);
    end;

  if LCount > 1 then
    QuickSort(0, LCount - 1);

  for LIndex := 0 to RACING_SCORES_PER_TABLE - 1 do
    LTable[LIndex] := LItems[LIndex];
end;

procedure TRacingScoreTableStore.Update(const AScore: TRacingScore; const ADriverName: string;
  ASkill: TRacingSkill);
var
  LCarType: TRacingCarType;
  LLap: Integer;
  LLast: ^TRacingScoreItem;
begin
  if not TRacingMath.IsInRange(AScore.Episode, 1, RACING_MAX_EPISODES) or
     not TRacingMath.IsInRange(AScore.Map, 1, RACING_MAX_MAPS) then
    Exit;

  if not TRacingMath.IsInRange(AScore.NumLaps, RACING_MIN_LAPS, RACING_MAX_LAPS) then
    Exit;

  LCarType := RACING_CAR_DATA[AScore.CarInfo].CarType;
  if not (LCarType in [TRacingCarType.Formula, TRacingCarType.Stock]) then
    Exit;

  // Lap records
  Sort(0, AScore.Episode, AScore.Map, LCarType);
  LLast := @FRecords.LapRecords[AScore.Episode, AScore.Map, LCarType][RACING_SCORES_PER_TABLE - 1];
  for LLap := 0 to AScore.NumLaps - 1 do
    if (LLast.Time = 0) or (LLast.Time > AScore.LapTimes[LLap]) then
    begin
      LLast.DriverName := ShortString(ADriverName);
      LLast.Time := AScore.LapTimes[LLap];
      LLast.CarId := AScore.CarInfo;
      LLast.Skill := Ord(ASkill);
      Sort(0, AScore.Episode, AScore.Map, LCarType);
    end;

  // Course records
  Sort(AScore.NumLaps, AScore.Episode, AScore.Map, LCarType);
  LLast := @FRecords.CourseRecords[AScore.NumLaps][AScore.Episode, AScore.Map, LCarType][RACING_SCORES_PER_TABLE - 1];
  if (LLast.Time = 0) or (LLast.Time > AScore.TotalTime) then
  begin
    LLast.DriverName := ShortString(ADriverName);
    LLast.Time := AScore.TotalTime;
    LLast.CarId := AScore.CarInfo;
    LLast.Skill := Ord(ASkill);
    Sort(AScore.NumLaps, AScore.Episode, AScore.Map, LCarType);
  end;
end;

function TRacingScoreTableStore.CheckLapRecord(AEpisode, AMap: Integer; ACarType: TRacingCarType;
  ATime: Integer): Boolean;
begin
  // The old code did not look at the numbers and read other memory for a track or a family that does not exist
  if not TRacingMath.IsInRange(AEpisode, 1, RACING_MAX_EPISODES) or
     not TRacingMath.IsInRange(AMap, 1, RACING_MAX_MAPS) or
     not (ACarType in [TRacingCarType.Formula, TRacingCarType.Stock]) then
  begin
    Result := False;
    Exit;
  end;

  Sort(0, AEpisode, AMap, ACarType);
  Result := (FRecords.LapRecords[AEpisode, AMap, ACarType][RACING_SCORES_PER_TABLE - 1].Time = 0) or
    (FRecords.LapRecords[AEpisode, AMap, ACarType][RACING_SCORES_PER_TABLE - 1].Time > ATime);
end;

function TRacingScoreTableStore.LoadFromBytes(const ABytes: TBytes): Boolean;
begin
  Clear;
  Result := Length(ABytes) = SizeOf(FRecords);
  if Result then
    Move(ABytes[0], FRecords, SizeOf(FRecords));
end;

function TRacingScoreTableStore.SaveToBytes: TBytes;
begin
  SetLength(Result, SizeOf(FRecords));
  Move(FRecords, Result[0], SizeOf(FRecords));
end;

end.

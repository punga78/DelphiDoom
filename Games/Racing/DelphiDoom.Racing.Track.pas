{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the path of the track, the laps and the order  }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the logic of speed_path.pas: SH_GroupPathSequence, SH_GetNextPath,  }
{  SH_NotifyPath, SH_GetTimeLaps and SH_CalculatePositions                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Track;

// Positions and distances are 16.16 fixed point and the angles unsigned: they wrap as in the old code
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   The points that the cars of the computer follow, one after the other, around the track.
  ///   It tells a car which point to go to, counts the laps and the time of each lap and puts the
  ///   cars in order
  /// </summary>
  /// <remarks>
  ///   The points are ordered by following the nearest point ahead, starting from the first one.
  ///   The old code reordered the records but left the numbers of the points (the id and the
  ///   links) as they were in the map, so a map that does not list the points in the order of
  ///   the lap has cars that use the wrong point: the defect is kept (a test shows it), and the
  ///   maps of the game list the points in order
  /// </remarks>
  TRacingTrack = class(TInterfacedObject, IRacingTrack)
  strict private
    FRace: IRacingRaceState;
    FGeometry: IRacingGeometry;
    FPaths: TArray<TRacingPath>;
    // The table of the order is kept between the calls, as the old global was: the laps of a car
    // that has finished are not written again, so they are the ones of the last call
    FItems: array[0..RACING_CAR_COUNT - 1] of TRacingPositionItem;
    procedure GroupSequence;
    function CheckedIndex(AIndex: Integer): Integer;
  public
    constructor Create(const ARace: IRacingRaceState; const AGeometry: IRacingGeometry);
    function Load(const APoints: array of TRacingPathPoint): Boolean;
    function PathCount: Integer;
    function GetPath(AIndex: Integer): PRacingPath;
    function GetNextPath(AX, AY: TFixed): Integer;
    procedure Notify(var ACar: TRacingCarState);
    procedure GetLapTimes(const ACar: TRacingCarState; out ATimes: TRacingLapTimes);
    function CalculatePositions(const ACars: array of TRacingPositionInput): TArray<TRacingPositionItem>;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Racing.Math;

const
  SPathIndex = 'The point %d of the path does not exist (the path has %d points)';
  STooManyCars = 'The order of the race has %d cars: the most is %d';
  SNoPath = 'The track has no path';

{ TRacingTrack }

constructor TRacingTrack.Create(const ARace: IRacingRaceState; const AGeometry: IRacingGeometry);
begin
  inherited Create;
  if not Assigned(ARace) then
    raise EArgumentNilException.Create('ARace');
  if not Assigned(AGeometry) then
    raise EArgumentNilException.Create('AGeometry');
  FRace := ARace;
  FGeometry := AGeometry;
end;

function TRacingTrack.CheckedIndex(AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= Length(FPaths)) then
    raise ERacingException.CreateFmt(SPathIndex, [AIndex, Length(FPaths)]);
  Result := AIndex;
end;

function TRacingTrack.Load(const APoints: array of TRacingPathPoint): Boolean;
var
  LIndex: Integer;
begin
  Result := Length(APoints) > 0;
  SetLength(FPaths, Length(APoints));
  FillChar(FItems, SizeOf(FItems), 0);
  if not Result then
    Exit;

  for LIndex := 0 to High(APoints) do
  begin
    FillChar(FPaths[LIndex], SizeOf(TRacingPath), 0);
    FPaths[LIndex].X := APoints[LIndex].X;
    FPaths[LIndex].Y := APoints[LIndex].Y;
    FPaths[LIndex].Angle := APoints[LIndex].Angle;
    FPaths[LIndex].Speed := APoints[LIndex].Speed;
  end;
  GroupSequence;
end;

procedure TRacingTrack.GroupSequence;
var
  LCount, LFrom, LTo, LBest: Integer;
  LAngle: TAngle;
  LDistance, LMinimum: TFixed;
  LSaved: TArray<TRacingPath>;
begin
  LCount := Length(FPaths);

  for LFrom := 0 to LCount - 1 do
  begin
    LBest := 0;
    LMinimum := MaxInt;
    for LTo := 0 to LCount - 1 do
      if LFrom <> LTo then
      begin
        LAngle := FGeometry.PointToAngle(FPaths[LFrom].X, FPaths[LFrom].Y, FPaths[LTo].X, FPaths[LTo].Y) -
          FPaths[LTo].Angle;
        // A point is ahead if its direction is within a quarter turn of the line to it
        if (LAngle <= ANG90) or (LAngle >= ANG270) then
        begin
          LDistance := TRacingMath.Distance(FPaths[LFrom].X - FPaths[LTo].X, FPaths[LFrom].Y - FPaths[LTo].Y);
          if LDistance < LMinimum then
          begin
            LMinimum := LDistance;
            LBest := LTo;
          end;
        end;
      end;
    FPaths[LFrom].Id := LFrom;
    FPaths[LFrom].Next := LBest;
    FPaths[LFrom].DistanceToNext := LMinimum;
    FPaths[LBest].Previous := LFrom;
  end;

  SetLength(LSaved, LCount);
  LSaved[0] := FPaths[0];
  for LFrom := 1 to LCount - 1 do
    LSaved[LFrom] := FPaths[LSaved[LFrom - 1].Next];
  FPaths := LSaved;

  FPaths[0].DistanceToHere := FPaths[LCount - 1].DistanceToNext;
  for LFrom := 1 to LCount - 1 do
    FPaths[LFrom].DistanceToHere := FPaths[LFrom - 1].DistanceToHere + FPaths[LFrom - 1].DistanceToNext;
end;

function TRacingTrack.PathCount: Integer;
begin
  Result := Length(FPaths);
end;

function TRacingTrack.GetPath(AIndex: Integer): PRacingPath;
begin
  Result := @FPaths[CheckedIndex(AIndex)];
end;

function TRacingTrack.GetNextPath(AX, AY: TFixed): Integer;
var
  LIndex, LBest: Integer;
  LAngle: TAngle;
  LDistance, LMinimum: TFixed;
begin
  if Length(FPaths) = 0 then
    raise ERacingException.Create(SNoPath);

  LBest := 0;
  LMinimum := MaxInt;
  for LIndex := 0 to High(FPaths) do
  begin
    // A car exactly on a point goes to the next one
    if (AX = FPaths[LIndex].X) and (AY = FPaths[LIndex].Y) then
    begin
      Result := FPaths[LIndex].Next;
      Exit;
    end;

    LAngle := FGeometry.PointToAngle(AX, AY, FPaths[LIndex].X, FPaths[LIndex].Y) - FPaths[LIndex].Angle;
    if (LAngle <= ANG90) or (LAngle >= ANG270) then
    begin
      LDistance := TRacingMath.Distance(AX - FPaths[LIndex].X, AY - FPaths[LIndex].Y);
      if LDistance < LMinimum then
      begin
        LMinimum := LDistance;
        LBest := LIndex;
      end;
    end;
  end;
  Result := LBest;
end;

procedure TRacingTrack.Notify(var ACar: TRacingCarState);
var
  LVisits: ^TRacingPathVisits;
  LPath: PRacingPath;
begin
  CheckedIndex(0);

  // Crossed the finish line
  if ACar.CurrentPath = 0 then
    if ACar.PreviousPath = FPaths[0].Previous then
    begin
      Inc(ACar.LapsCompleted);
      ACar.PreviousPath := ACar.CurrentPath;
    end;

  // Crossed the finish line the wrong way
  if ACar.CurrentPath = FPaths[0].Previous then
    if ACar.PreviousPath = 0 then
    begin
      Dec(ACar.LapsCompleted);
      ACar.PreviousPath := ACar.CurrentPath;
    end;

  if TRacingMath.IsInRange(ACar.LapsCompleted, 0, FRace.NumLaps) then
  begin
    LPath := @FPaths[CheckedIndex(ACar.CurrentPath)];
    LVisits := @LPath.Visits[ACar.CarInfo];

    if LVisits[ACar.LapsCompleted].VisitLap <= ACar.LapsCompleted then
    begin
      LVisits[ACar.LapsCompleted].VisitLap := ACar.LapsCompleted + 1;
      LVisits[ACar.LapsCompleted].EnterTime := TRacingMath.Clamp(FRace.RaceTime, 1, MaxInt);
    end;
    LVisits[ACar.LapsCompleted].ExitTime := FRace.RaceTime;
  end;
end;

procedure TRacingTrack.GetLapTimes(const ACar: TRacingCarState; out ATimes: TRacingLapTimes);
var
  LIndex, LStart, LEnd: Integer;
  LVisits: ^TRacingPathVisits;
begin
  CheckedIndex(0);

  for LIndex := 0 to RACING_MAX_LAPS - 1 do
    ATimes[LIndex] := 0;

  LVisits := @FPaths[0].Visits[ACar.CarInfo];
  for LIndex := 0 to FRace.NumLaps - 1 do
  begin
    if LIndex = 0 then
      LStart := 0
    else
      LStart := LVisits[LIndex].ExitTime;
    LEnd := LVisits[LIndex + 1].ExitTime;
    if LEnd > LStart then
      ATimes[LIndex] := LEnd - LStart
    else
      Break;
  end;
end;

function TRacingTrack.CalculatePositions(const ACars: array of TRacingPositionInput): TArray<TRacingPositionItem>;
var
  LCount, LIndex: Integer;
  LLapSize, LRaceLength: Int64;
  LCurrent, LPrevious: PRacingPath;

  function Compare(const AItem1, AItem2: TRacingPositionItem): Int64;
  begin
    Result := AItem2.LapsCompleted - AItem1.LapsCompleted;
    if Result = 0 then
    begin
      Result := AItem2.TotalDistance - AItem1.TotalDistance;
      if Result = 0 then
      begin
        if AItem1.FinishTime = AItem2.FinishTime then
          Result := AItem1.Key - AItem2.Key // The sort is not stable: the key makes the order sure
        else if AItem1.FinishTime = 0 then
          Result := 1
        else if AItem2.FinishTime = 0 then
          Result := -1
        else
          Result := AItem1.FinishTime - AItem2.FinishTime;
      end;
    end;
  end;

  procedure QuickSort(ALeft, ARight: Integer);
  var
    LI, LJ, LPivot: Integer;
    LTemp: TRacingPositionItem;
  begin
    repeat
      LI := ALeft;
      LJ := ARight;
      // The pivot is the slot, not a copy: the swaps can change what is in it, as in the old sort
      LPivot := (ALeft + ARight) shr 1;
      repeat
        while Compare(FItems[LI], FItems[LPivot]) < 0 do
          Inc(LI);
        while Compare(FItems[LJ], FItems[LPivot]) > 0 do
          Dec(LJ);
        if LI <= LJ then
        begin
          LTemp := FItems[LI];
          FItems[LI] := FItems[LJ];
          FItems[LJ] := LTemp;
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
  LCount := Length(ACars);
  if LCount > RACING_CAR_COUNT then
    raise ERacingException.CreateFmt(STooManyCars, [LCount, RACING_CAR_COUNT]);
  if Length(FPaths) = 0 then
    raise ERacingException.Create(SNoPath);

  // lapsize in meters: DistanceToHere / 550620
  LLapSize := FPaths[High(FPaths)].DistanceToHere;
  LRaceLength := LLapSize * Int64(FRace.NumLaps);

  for LIndex := 0 to LCount - 1 do
  begin
    FItems[LIndex].Index := LIndex;
    FItems[LIndex].Key := ACars[LIndex].Key;
    if ACars[LIndex].LapsCompleted >= FRace.NumLaps then
    begin
      FItems[LIndex].FinishTime := FPaths[0].Visits[ACars[LIndex].CarInfo][FRace.NumLaps].EnterTime;
      FItems[LIndex].TotalDistance := LRaceLength;
    end
    else
    begin
      FItems[LIndex].FinishTime := 0;
      LCurrent := @FPaths[CheckedIndex(ACars[LIndex].CurrentPath)];
      LPrevious := @FPaths[CheckedIndex(LCurrent.Previous)];
      FItems[LIndex].LapsCompleted := ACars[LIndex].LapsCompleted;
      FItems[LIndex].TotalDistance :=
        Int64(ACars[LIndex].LapsCompleted) * LLapSize + // Completed laps
        LPrevious.DistanceToHere + // Previous point
        TRacingMath.Distance(ACars[LIndex].X - LPrevious.X, ACars[LIndex].Y - LPrevious.Y); // Distance in the current path

      // Crossed the finish line at least once: exactly at the finish line the previous
      // distance is taken away, because the lap has changed
      if ACars[LIndex].LapsCompleted >= 0 then
        if ACars[LIndex].CurrentPath = 0 then
          FItems[LIndex].TotalDistance := FItems[LIndex].TotalDistance - LPrevious.DistanceToHere;

      // The distance is not more than the length of the race
      if FItems[LIndex].TotalDistance > LRaceLength then
        FItems[LIndex].TotalDistance := LRaceLength;
    end;
  end;

  if LCount > 0 then
    QuickSort(0, LCount - 1);

  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
    Result[LIndex] := FItems[LIndex];
end;

end.

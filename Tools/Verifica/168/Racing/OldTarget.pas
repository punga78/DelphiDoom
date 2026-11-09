// Issue #168 (S4, Libs\Racing): the scenarios of the parity on the OLD code (OldRacing.pas)
unit OldTarget;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Intf, DelphiDoom.Racing.Types,
  DelphiDoom.Tests.Racing.Scenarios;

type
  TOldRacingTarget = class(TInterfacedObject, IRacingScenarioTarget)
  strict private
    FEffects: TStringList;
    procedure FlushEffects;
    procedure ClearWorld;
  public
    constructor Create;
    destructor Destroy; override;
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
  DelphiDoom.MathCore.Factory, OldRacing;

var
  GRandom: IGameRandom;
  GPlayerScore: playerscore_t;

function GlobalSystemRandom: Integer;
begin
  Result := GRandom.NextSystem;
end;

procedure ToMobj(const ACar: TRacingCarState; var AMobj: mobj_t);
var
  LIndex: Integer;
begin
  FillChar(AMobj, SizeOf(AMobj), 0);
  AMobj.thinker.prev := nil;
  AMobj.thinker._function.acp1 := P_MobjThinker;
  AMobj.x := ACar.X;
  AMobj.y := ACar.Y;
  AMobj.z := ACar.Z;
  AMobj.oldx := ACar.OldX;
  AMobj.oldy := ACar.OldY;
  AMobj.angle := ACar.Angle;
  AMobj.momx := ACar.MomentumX;
  AMobj.momy := ACar.MomentumY;
  AMobj.key := ACar.Key;
  AMobj.carid := ACar.CarId;
  AMobj.enginespeed := ACar.EngineSpeed;
  AMobj.destAngle := ACar.DestinationAngle;
  AMobj.destSpeed := ACar.DestinationSpeed;
  AMobj.currPath := ACar.CurrentPath;
  AMobj.prevPath := ACar.PreviousPath;
  AMobj.lapscompleted := ACar.LapsCompleted;
  AMobj.raceposition := ACar.RacePosition;
  AMobj.carinfo := ACar.CarInfo;
  AMobj.nextparticle := ACar.NextParticle;
  for LIndex := 0 to 3 do
    AMobj.tiredistance[LIndex] := ACar.TireDistance[LIndex];
  AMobj.tireangle := ACar.TireAngle;
  AMobj.soundcountdown := ACar.SoundCountdown;
  AMobj.carturn := ACar.CarTurn;
  AMobj.caraccelerate := ACar.CarAccelerate;
  AMobj.cardeccelerate := ACar.CarDecelerate;
  AMobj.carbrake := ACar.CarBrake;
  AMobj.brakesoundcountdown := ACar.BrakeSoundCountdown;
  AMobj.brakesoundorg.x := ACar.BrakeSoundX;
  AMobj.brakesoundorg.y := ACar.BrakeSoundY;
  AMobj.brakesoundorg.z := ACar.BrakeSoundZ;
  AMobj.rpm := ACar.Rpm;
  AMobj.gear := ACar.Gear;
  AMobj.destgear := ACar.DestinationGear;
  AMobj.geartics := ACar.GearTics;
  AMobj.nextgeartics := ACar.NextGearTics;
  AMobj.driftangle := ACar.DriftAngle;
end;

procedure FromMobj(const AMobj: mobj_t; var ACar: TRacingCarState);
var
  LIndex: Integer;
begin
  ACar.X := AMobj.x;
  ACar.Y := AMobj.y;
  ACar.Z := AMobj.z;
  ACar.OldX := AMobj.oldx;
  ACar.OldY := AMobj.oldy;
  ACar.Angle := AMobj.angle;
  ACar.MomentumX := AMobj.momx;
  ACar.MomentumY := AMobj.momy;
  ACar.CarId := AMobj.carid;
  ACar.EngineSpeed := AMobj.enginespeed;
  ACar.DestinationAngle := AMobj.destAngle;
  ACar.DestinationSpeed := AMobj.destSpeed;
  ACar.CurrentPath := AMobj.currPath;
  ACar.PreviousPath := AMobj.prevPath;
  ACar.LapsCompleted := AMobj.lapscompleted;
  ACar.RacePosition := AMobj.raceposition;
  ACar.CarInfo := AMobj.carinfo;
  ACar.NextParticle := AMobj.nextparticle;
  for LIndex := 0 to 3 do
    ACar.TireDistance[LIndex] := AMobj.tiredistance[LIndex];
  ACar.TireAngle := AMobj.tireangle;
  ACar.SoundCountdown := AMobj.soundcountdown;
  ACar.CarTurn := AMobj.carturn;
  ACar.CarAccelerate := AMobj.caraccelerate;
  ACar.CarDecelerate := AMobj.cardeccelerate;
  ACar.CarBrake := AMobj.carbrake;
  ACar.BrakeSoundCountdown := AMobj.brakesoundcountdown;
  ACar.BrakeSoundX := AMobj.brakesoundorg.x;
  ACar.BrakeSoundY := AMobj.brakesoundorg.y;
  ACar.BrakeSoundZ := AMobj.brakesoundorg.z;
  ACar.Rpm := AMobj.rpm;
  ACar.Gear := AMobj.gear;
  ACar.DestinationGear := AMobj.destgear;
  ACar.GearTics := AMobj.geartics;
  ACar.NextGearTics := AMobj.nextgeartics;
  ACar.DriftAngle := AMobj.driftangle;
end;

function ParticleName(AType: Integer): string;
begin
  case AType of
    1001, 1002: Result := 'spark';
    1003, 1004: Result := 'smoke';
    1005, 1006: Result := 'grass';
    1007, 1008: Result := 'dirt';
  else
    Result := 'sand';
  end;
end;

{ TOldRacingTarget }

constructor TOldRacingTarget.Create;
begin
  inherited Create;
  FEffects := TStringList.Create;
  HarnessSysRandom := GlobalSystemRandom;
  Reset(Default(TRacingScenarioSetup));
end;

destructor TOldRacingTarget.Destroy;
begin
  FEffects.Free;
  inherited Destroy;
end;

procedure TOldRacingTarget.ClearWorld;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(HarnessSpawned) do
    Dispose(HarnessSpawned[LIndex]);
  SetLength(HarnessSpawned, 0);
  HarnessSounds.Clear;
  FillChar(racepositions, SizeOf(racepositions), 0);
  numpaths := 0;
  rtlpaths := nil;
  thinkercap.next := @thinkercap;
  thinkercap.prev := @thinkercap;
  FillChar(players, SizeOf(players), 0);
  FillChar(playeringame, SizeOf(playeringame), 0);
end;

procedure TOldRacingTarget.Reset(const ASetup: TRacingScenarioSetup);
begin
  ClearWorld;
  FEffects.Clear;
  GRandom := TMathCoreFactory.CreateGameRandom;
  GRandom.SystemSeed := ASetup.Seed mod 256;
  GRandom.SystemIndex := (ASetup.Seed * 37) mod 10007;

  FillChar(race, SizeOf(race), 0);
  race.cartype := cartype_t(Ord(ASetup.CarType));
  race.racestatus := racestatus_t(Ord(ASetup.Status));
  race.numlaps := ASetup.Laps;
  race.transmissiontype := ASetup.Transmission;
  race.gametype := gt_championship;
  gameskill := skill_t(Ord(ASetup.Skill));
  gameepisode := ASetup.Episode;
  gamemap := ASetup.Map;
  racetime := 0;
  leveltime := 0;
  viewx := 0;
  viewy := 0;
  HarnessGroundPtr := nil;
  HarnessGroundSize := 0;
  FillChar(recordtable, SizeOf(recordtable), 0);
  FillChar(GPlayerScore, SizeOf(GPlayerScore), 0);
end;

procedure TOldRacingTarget.SetGround(AMap: PByte; ASize: Integer);
begin
  HarnessGroundPtr := AMap;
  HarnessGroundSize := ASize;
end;

procedure TOldRacingTarget.SetClocks(ARaceTime, ALevelTime: Integer);
begin
  racetime := ARaceTime;
  leveltime := ALevelTime;
end;

procedure TOldRacingTarget.SetStatus(AStatus: TRacingStatus);
begin
  race.racestatus := racestatus_t(Ord(AStatus));
end;

procedure TOldRacingTarget.SetView(AX, AY: Integer);
begin
  viewx := AX;
  viewy := AY;
end;

function TOldRacingTarget.LoadTrack(const APoints: array of TRacingPathPoint): Boolean;
var
  LIndex: Integer;
  LMobj: Pmobj_t;
begin
  Result := Length(APoints) > 0;
  if not Result then
    Exit;
  numpaths := Length(APoints);
  GetMem(rtlpaths, numpaths * SizeOf(rtlpath_t));
  FillChar(rtlpaths^, numpaths * SizeOf(rtlpath_t), 0);
  for LIndex := 0 to High(APoints) do
  begin
    New(LMobj);
    FillChar(LMobj^, SizeOf(mobj_t), 0);
    LMobj.x := APoints[LIndex].X;
    LMobj.y := APoints[LIndex].Y;
    LMobj.angle := APoints[LIndex].Angle;
    rtlpaths[LIndex].mo := LMobj;
    rtlpaths[LIndex].speed := APoints[LIndex].Speed;
  end;
  SH_GroupPathSequence;
end;

procedure TOldRacingTarget.DescribeTrack(ALines: TStrings);
var
  LIndex, LCar, LLap: Integer;
  LVisits: Int64;
begin
  for LIndex := 0 to numpaths - 1 do
  begin
    LVisits := 0;
    for LCar := 0 to NUMCARINFO - 1 do
      for LLap := 0 to MAXLAPS do
        LVisits := LVisits + rtlpaths[LIndex].cardata[LCar][LLap].entertime +
          rtlpaths[LIndex].cardata[LCar][LLap].exittime + rtlpaths[LIndex].cardata[LCar][LLap].visitlap;
    ALines.Add(Format('%d id=%d x=%d y=%d a=%d s=%d p=%d n=%d dn=%d dh=%d v=%d',
      [LIndex, rtlpaths[LIndex].id, rtlpaths[LIndex].mo.x, rtlpaths[LIndex].mo.y,
       Integer(rtlpaths[LIndex].mo.angle), rtlpaths[LIndex].speed, rtlpaths[LIndex].prev,
       rtlpaths[LIndex].next, rtlpaths[LIndex].dist_to_next, rtlpaths[LIndex].dist_to_here, LVisits]));
  end;
end;

function TOldRacingTarget.NextPath(AX, AY: Integer): Integer;
var
  LMobj: mobj_t;
begin
  FillChar(LMobj, SizeOf(LMobj), 0);
  LMobj.x := AX;
  LMobj.y := AY;
  Result := (NativeInt(SH_GetNextPath(@LMobj)) - NativeInt(@rtlpaths[0])) div SizeOf(rtlpath_t);
end;

procedure TOldRacingTarget.FlushEffects;
var
  LIndex, LSpawned: Integer;
  LLine: string;
  LMobj: Pmobj_t;
begin
  for LIndex := 0 to HarnessSounds.Count - 1 do
  begin
    LLine := HarnessSounds[LIndex];
    if Copy(LLine, 1, 2) = 'P#' then
    begin
      LSpawned := StrToInt(Copy(LLine, 3, MaxInt));
      LMobj := HarnessSpawned[LSpawned];
      LLine := TRacingScenarios.FormatParticle(ParticleName(LMobj.index), LMobj.x, LMobj.y, LMobj.z,
        LMobj.momx, LMobj.momy);
    end;
    FEffects.Add(LLine);
  end;
  HarnessSounds.Clear;
  for LIndex := 0 to High(HarnessSpawned) do
    Dispose(HarnessSpawned[LIndex]);
  SetLength(HarnessSpawned, 0);
end;

procedure TOldRacingTarget.MoveCar(var ACar: TRacingCarState; var APlayer: TRacingPlayerState;
  const AInput: TRacingPlayerInput; AKind: TRacingDriverKind);
var
  LMobj: mobj_t;
  LPlayer: player_t;
begin
  ToMobj(ACar, LMobj);
  if AKind = TRacingDriverKind.Person then
  begin
    FillChar(LPlayer, SizeOf(LPlayer), 0);
    LPlayer.mo := @LMobj;
    LPlayer.cmd.angleturn := AInput.AngleTurn;
    LPlayer.cmd.forwardmove := AInput.ForwardMove * 25;
    LPlayer.cmd.buttons2 := AInput.Buttons;
    Move(APlayer.LapRecordChecked, LPlayer.laprecordchecked, SizeOf(LPlayer.laprecordchecked));
    LPlayer.currentscore := GPlayerScore;
    LMobj.player := @LPlayer;
    SH_MoveCarPlayer(@LMobj);
    GPlayerScore := LPlayer.currentscore;
    Move(LPlayer.laprecordchecked, APlayer.LapRecordChecked, SizeOf(LPlayer.laprecordchecked));
  end
  else
    SH_MoveCarAI(@LMobj);
  FromMobj(LMobj, ACar);
  FlushEffects;
end;

function TOldRacingTarget.Positions(const ACars: array of TRacingPositionInput): TArray<TRacingPositionItem>;
var
  LMobjs: array of Pmobj_t;
  LIndex, LPlace: Integer;
begin
  SetLength(LMobjs, Length(ACars));
  thinkercap.next := @thinkercap;
  thinkercap.prev := @thinkercap;
  for LIndex := 0 to High(ACars) do
  begin
    New(LMobjs[LIndex]);
    FillChar(LMobjs[LIndex]^, SizeOf(mobj_t), 0);
    LMobjs[LIndex].thinker._function.acp1 := P_MobjThinker;
    LMobjs[LIndex].key := ACars[LIndex].Key;
    LMobjs[LIndex].carinfo := ACars[LIndex].CarInfo;
    LMobjs[LIndex].lapscompleted := ACars[LIndex].LapsCompleted;
    LMobjs[LIndex].currPath := ACars[LIndex].CurrentPath;
    LMobjs[LIndex].x := ACars[LIndex].X;
    LMobjs[LIndex].y := ACars[LIndex].Y;
    LMobjs[LIndex].index := LIndex;
    // At the end of the list
    LMobjs[LIndex].thinker.prev := thinkercap.prev;
    LMobjs[LIndex].thinker.next := @thinkercap;
    thinkercap.prev.next := @LMobjs[LIndex].thinker;
    thinkercap.prev := @LMobjs[LIndex].thinker;
  end;
  SH_CalculatePositions;
  SetLength(Result, racepositions.numracepositions);
  for LPlace := 0 to racepositions.numracepositions - 1 do
  begin
    Result[LPlace].Index := racepositions.items[LPlace].mo.index;
    Result[LPlace].Key := racepositions.items[LPlace].mo.key;
    Result[LPlace].TotalDistance := racepositions.items[LPlace].totaldistance;
    Result[LPlace].LapsCompleted := racepositions.items[LPlace].lapscompleted;
    Result[LPlace].FinishTime := racepositions.items[LPlace].finishtime;
  end;
  for LIndex := 0 to High(LMobjs) do
    Dispose(LMobjs[LIndex]);
  thinkercap.next := @thinkercap;
  thinkercap.prev := @thinkercap;
end;

procedure TOldRacingTarget.LapTimes(const ACar: TRacingCarState; out ATimes: TRacingLapTimes);
var
  LMobj: mobj_t;
  LTimes: timelaps_t;
  LIndex: Integer;
begin
  FillChar(LMobj, SizeOf(LMobj), 0);
  LMobj.carinfo := ACar.CarInfo;
  SH_GetTimeLaps(@LMobj, @LTimes);
  for LIndex := 0 to RACING_MAX_LAPS - 1 do
    ATimes[LIndex] := LTimes[LIndex];
end;

function TOldRacingTarget.PlayerScore: TRacingScore;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Episode := GPlayerScore.episode;
  Result.Map := GPlayerScore.map;
  Result.NumLaps := GPlayerScore.numlaps;
  Result.CarInfo := GPlayerScore.carinfo;
  Result.RacePosition := GPlayerScore.raceposition;
  for LIndex := 0 to RACING_MAX_LAPS - 1 do
    Result.LapTimes[LIndex] := GPlayerScore.laptimes[LIndex];
  Result.TotalTime := GPlayerScore.totaltime;
end;

function TOldRacingTarget.EffectLog: TStrings;
begin
  Result := FEffects;
end;

function TOldRacingTarget.GroundType(AX, AY: Integer): Integer;
begin
  Result := Ord(SH_GroundTypeAtXY(AX, AY));
end;

function TOldRacingTarget.Slip(AX, AY: Integer): Integer;
begin
  Result := SH_SlipperFactorAtXY(AX, AY);
end;

function TOldRacingTarget.SlipCalculation(AForce: Integer; ASlip: Byte): Integer;
begin
  Result := SH_SlipCalculation(AForce, ASlip);
end;

procedure TOldRacingTarget.ScoreClear;
begin
  FillChar(recordtable, SizeOf(recordtable), 0);
end;

procedure TOldRacingTarget.ScoreUpdate(const AScore: TRacingScore; const AName: string;
  ASkill: TRacingSkill);
var
  LPlayer: player_t;
  LIndex: Integer;
begin
  FillChar(LPlayer, SizeOf(LPlayer), 0);
  LPlayer.currentscore.episode := AScore.Episode;
  LPlayer.currentscore.map := AScore.Map;
  LPlayer.currentscore.numlaps := AScore.NumLaps;
  LPlayer.currentscore.carinfo := AScore.CarInfo;
  LPlayer.currentscore.raceposition := AScore.RacePosition;
  for LIndex := 0 to RACING_MAX_LAPS - 1 do
    LPlayer.currentscore.laptimes[LIndex] := AScore.LapTimes[LIndex];
  LPlayer.currentscore.totaltime := AScore.TotalTime;
  LPlayer.playername := AName;
  SH_UpdateScoreTable(@LPlayer, AScore.Episode, AScore.Map, skill_t(Ord(ASkill)));
end;

function TOldRacingTarget.ScoreCheck(AEpisode, AMap: Integer; ACarType: TRacingCarType;
  ATime: Integer): Boolean;
begin
  Result := SH_CheckLapRecord(AEpisode, AMap, cartype_t(Ord(ACarType)), ATime);
end;

function TOldRacingTarget.ScoreBytes: TBytes;
begin
  SetLength(Result, SizeOf(recordtable));
  Move(recordtable, Result[0], SizeOf(recordtable));
end;

function TOldRacingTarget.ScoreItemSize: Integer;
begin
  Result := SizeOf(speedtimetableitem_t);
end;

function TOldRacingTarget.Grid(AStartCount: Integer; ACarType: TRacingCarType;
  const APlayerCars: array of Integer): TArray<Integer>;
var
  LStars: array of Pmobj_t;
  LOther: array of Pmobj_t;
  LPlayerMobjs: array of Pmobj_t;
  LIndex: Integer;
  LCount: Integer;
  procedure Link(AMobj: Pmobj_t);
  begin
    AMobj.thinker._function.acp1 := P_MobjThinker;
    AMobj.thinker.prev := thinkercap.prev;
    AMobj.thinker.next := @thinkercap;
    thinkercap.prev.next := @AMobj.thinker;
    thinkercap.prev := @AMobj.thinker;
  end;
begin
  ClearWorld;
  race.cartype := cartype_t(Ord(ACarType));
  // The old code needs the path to find where each car is
  LoadTrack(TRacingScenarios.Circuit(8, 1000, False));

  SetLength(LStars, AStartCount);
  SetLength(LOther, AStartCount);
  for LIndex := 0 to AStartCount - 1 do
  begin
    New(LOther[LIndex]);
    FillChar(LOther[LIndex]^, SizeOf(mobj_t), 0);
    New(LOther[LIndex].info);
    LOther[LIndex].info.doomednum := 5;
    Link(LOther[LIndex]);

    New(LStars[LIndex]);
    FillChar(LStars[LIndex]^, SizeOf(mobj_t), 0);
    New(LStars[LIndex].info);
    LStars[LIndex].info.doomednum := _SHTH_STARPOSITION;
    LStars[LIndex].x := (4000 + LIndex * 3) * FRACUNIT;
    LStars[LIndex].y := 4000 * FRACUNIT;
    Link(LStars[LIndex]);
  end;

  SetLength(LPlayerMobjs, Length(APlayerCars));
  for LIndex := 0 to High(APlayerCars) do
  begin
    New(LPlayerMobjs[LIndex]);
    FillChar(LPlayerMobjs[LIndex]^, SizeOf(mobj_t), 0);
    LPlayerMobjs[LIndex].carinfo := APlayerCars[LIndex];
    LPlayerMobjs[LIndex].x := 4000 * FRACUNIT;
    players[LIndex].mo := LPlayerMobjs[LIndex];
    playeringame[LIndex] := True;
  end;

  try
    SH_InitLevelCars;
    SetLength(Result, AStartCount);
    for LIndex := 0 to AStartCount - 1 do
      Result[LIndex] := LStars[LIndex].carinfo;
  finally
    LCount := AStartCount;
    thinkercap.next := @thinkercap;
    thinkercap.prev := @thinkercap;
    for LIndex := 0 to LCount - 1 do
    begin
      Dispose(LOther[LIndex].info);
      Dispose(LOther[LIndex]);
      Dispose(LStars[LIndex].info);
      Dispose(LStars[LIndex]);
    end;
    for LIndex := 0 to High(LPlayerMobjs) do
      Dispose(LPlayerMobjs[LIndex]);
    FillChar(players, SizeOf(players), 0);
    FillChar(playeringame, SizeOf(playeringame), 0);
  end;
end;

end.

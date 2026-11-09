// Issue #168 (S4, Libs\Racing): the OLD code of Speed Haste (GLSpeed, Reference\Speed\Speed) in a harness.
//
// The functions of speed_cars, speed_race, speed_path, speed_score and speed_particles are NOT copied
// by hand: Extract-Old.ps1 cuts them from the original files and this unit includes them as they are.
// What is written here is only the world that they need (the objects, the thinkers, the lumps, the
// sounds), reduced to the fields that the old code reads, plus the functions of the original units
// that the cars call (FixedMul and P_Distance copied from m_fixed and p_maputl).
unit OldRacing;

{$B-,C+,D+,E-,F-,G+,H+,I+,J+,K-,L+,M-,N+,O+,P+,Q-,R-,S-,T-,U-,V+,W-,X+,Y+,Z1}
{$ALIGN 8}

interface

uses
  Windows, SysUtils, Classes;

type
  fixed_t = integer;
  fixed64_t = int64;
  angle_t = LongWord;
  fixed_tArray = array[0..$7FFF] of fixed_t;
  Pfixed_tArray = ^fixed_tArray;

  skill_t = (sk_baby, sk_easy, sk_medium, sk_hard, sk_nightmare);
  gametype_t = (gt_championship, gt_singlerace, gt_practice);
  statenum_t = integer;

const
  FRACBITS = 16;
  FRACUNIT = 1 shl FRACBITS;
  TICRATE = 35;
  MAXPLAYERS = 4;
  TT_AUTOMATIC = 0;
  TT_MANUAL = 1;
  BT2_GEARUP = 1;
  BT2_GEARDOWN = 2;
  PILOTNAMESIZE = 16;
  ANGLETOFINESHIFT = 19;
  ANG45 = $20000000;
  ANG90 = $40000000;
  ANG180 = $80000000;
  ANG270 = $C0000000;
  ANG1 = ANG90 div 90;
  SPEED_LEVEL_SCALE = 2;
  _SHTH_STARPOSITION = 241;
  PU_LEVEL = 50;
  // The numbers of the sounds in the fake world (the same ones as DelphiDoom.Tests.Racing.Scenarios)
  sfx_speedhaste_MOTOR0_0 = 300;
  sfx_speedhaste_MOTOR1_0 = 320;
  sfx_speedhaste_DERRAPE = 340;

{$I cars_types.inc}
{$I race_types.inc}

type
  Pplayerscore_t = ^playerscore_t;
  playerscore_t = record
    episode: integer;
    map: integer;
    numlaps: integer;
    carinfo: integer;
    raceposition: integer;
    laptimes: array[0..MAXLAPS - 1] of integer;
    totaltime: integer;
  end;

  Pmobj_t = ^mobj_t;
  Pplayer_t = ^player_t;
  Pthinker_t = ^thinker_t;
  actionp1 = procedure(mo: pointer);
  actionf_t = record
    case integer of
      0: (acp1: actionp1);
      1: (acv: pointer);
  end;
  thinker_t = record
    prev, next: Pthinker_t;
    _function: actionf_t;
  end;
  degenmobj_t = record
    x, y, z: fixed_t;
  end;
  Pdegenmobj_t = ^degenmobj_t;
  mobjinfo_t = record
    doomednum: integer;
    spawnstate: integer;
  end;
  Pmobjinfo_t = ^mobjinfo_t;
  mobj_t = record
    thinker: thinker_t;
    x, y, z: fixed_t;
    oldx, oldy: fixed_t;
    angle: angle_t;
    momx, momy: fixed_t;
    key: LongWord;
    info: Pmobjinfo_t;
    player: Pplayer_t;
    target: Pmobj_t;
    carid: integer;
    enginespeed: fixed_t;
    destAngle: angle_t;
    destSpeed: fixed_t;
    currPath: integer;
    prevPath: integer;
    lapscompleted: integer;
    raceposition: integer;
    carinfo: integer;
    nextparticle: integer;
    tiredistance: array[0..3] of double;
    tireangle: integer;
    soundcountdown: integer;
    carturn: fixed_t;
    caraccelerate: fixed_t;
    cardeccelerate: fixed_t;
    carbrake: fixed_t;
    brakesoundcountdown: integer;
    brakesoundorg: degenmobj_t;
    rpm: integer;
    gear: integer;
    destgear: integer;
    geartics: integer;
    nextgeartics: integer;
    driftangle: integer;
    index: integer; // of the harness
  end;
  ticcmd_t = record
    angleturn: smallint;
    forwardmove: shortint;
    buttons2: byte;
  end;
  player_t = record
    mo: Pmobj_t;
    cmd: ticcmd_t;
    laprecordchecked: array[0..MAXLAPS - 1] of boolean;
    currentscore: playerscore_t;
    playername: string;
  end;

{$I path_types.inc}
{$I score_types.inc}

var
  gameskill: skill_t;
  gameepisode: integer;
  gamemap: integer;
  racetime: integer;
  leveltime: integer;
  viewx, viewy: fixed_t;
  thinkercap: thinker_t;
  players: array[0..MAXPLAYERS - 1] of player_t;
  playeringame: array[0..MAXPLAYERS - 1] of boolean;
  finesine: Pfixed_tArray;
  finecosine: Pfixed_tArray;
  // The world of the harness
  HarnessSounds: TStringList;
  HarnessSpawned: array of Pmobj_t;
  HarnessGroundPtr: pointer;
  HarnessGroundSize: integer;
  HarnessSysRandom: function: integer;

procedure SH_InitLevelCars;
procedure SH_EngineSound(const caller: Pmobj_t; const soundtarg: Pmobj_t);
procedure SH_BrakeSound(const caller: Pmobj_t);
procedure SH_MoveCarPlayer(const mo: Pmobj_t);
procedure SH_MoveCarAI(const mo: Pmobj_t);
function SH_GroundTypeAtXY(const x, y: fixed_t): groundtype_t;
function SH_SlipperFactorAtXY(const x, y: fixed_t): byte;
function SH_SlipCalculation(const x: fixed_t; const slip: byte): fixed_t;
procedure SH_GroupPathSequence;
function SH_GetNextPath(const mo: Pmobj_t): Prtlpath_t;
procedure SH_GetTimeLaps(const mo: Pmobj_t; const tl: Ptimelaps_t);
procedure SH_CalculatePositions;
procedure SH_UpdateScoreTable(const p: Pplayer_t; const epi, map: integer; skill: skill_t);
function SH_CheckLapRecord(const epi, map: integer; const ctyp: cartype_t; const t: integer): boolean;
procedure P_MobjThinker(mo: pointer);

implementation

uses
  DelphiDoom.Racing.Types,
  DelphiDoom.Tests.Racing.Scenarios,
  DelphiDoom.MathCore.TableFineSine;

//------------------------------------------------------------------------------
// The functions of the original units that the cars call, as they are
//------------------------------------------------------------------------------

// m_fixed.pas
function FixedMul(const a, b: fixed_t): fixed_t; assembler;
asm
  imul b
  shrd eax, edx, 16
end;

// m_fixed.pas
function FixedSqrt(const a: fixed_t): fixed_t;
begin
  Result := Round(Sqrt(a / FRACUNIT) * FRACUNIT);
end;

// p_maputl.pas
function P_Distance(dx: fixed_t; dy: fixed_t): fixed_t;
var
  ddx, ddy: double;
begin
  ddx := dx / FRACUNIT;
  ddy := dy / FRACUNIT;
  Result := Round(Sqrt(ddx * ddx + ddy * ddy) * FRACUNIT);
end;

// d_delphi.pas
function IsIntegerInRange(const test, f1, f2: integer): boolean;
begin
  if f1 < f2 then
    result := (test >= f1) and (test <= f2)
  else
    result := (test >= f2) and (test <= f1)
end;

// d_delphi.pas
function GetIntegerInRange(const val, f1, f2: integer): integer;
begin
  if val < f1 then
    result := f1
  else if val > f2 then
    result := f2
  else
    result := val;
end;

// d_delphi.pas
function MinI(const a, b: integer): integer;
begin
  if a > b then
    result := b
  else
    result := a;
end;

// d_delphi.pas
function iSign(const x: integer): integer;
begin
  if x > 0 then
    Result := 1
  else if x < 0 then
    Result := -1
  else
    Result := 0;
end;

//------------------------------------------------------------------------------
// The lists of d_delphi that the cars use (TDNumberList.Delete keeps the order)
//------------------------------------------------------------------------------
type
  TDNumberList = class
  private
    fList: array of integer;
    fNumItems: integer;
    function GetNumber(const Index: integer): integer;
  public
    procedure FastClear;
    function Add(const value: integer): integer;
    function Delete(const Index: integer): boolean;
    function IndexOf(const value: integer): integer;
    property Count: integer read fNumItems;
    property Numbers[const Index: integer]: integer read GetNumber;
  end;

  TDPointerList = class
  private
    fList: array of pointer;
    fNumItems: integer;
    function GetPointer(const Index: integer): pointer;
  public
    function Add(const value: pointer): integer;
    property Count: integer read fNumItems;
    property Pointers[const Index: integer]: pointer read GetPointer;
  end;

function TDNumberList.GetNumber(const Index: integer): integer;
begin
  Result := fList[Index];
end;

procedure TDNumberList.FastClear;
begin
  fNumItems := 0;
end;

function TDNumberList.Add(const value: integer): integer;
begin
  if fNumItems >= Length(fList) then
    SetLength(fList, fNumItems + 16);
  fList[fNumItems] := value;
  Result := fNumItems;
  inc(fNumItems);
end;

function TDNumberList.Delete(const Index: integer): boolean;
var
  i: integer;
begin
  if (Index < 0) or (Index >= fNumItems) then
  begin
    result := false;
    exit;
  end;
  for i := Index + 1 to fNumItems - 1 do
    fList[i - 1] := fList[i];
  dec(fNumItems);
  result := true;
end;

function TDNumberList.IndexOf(const value: integer): integer;
var
  i: integer;
begin
  for i := 0 to fNumItems - 1 do
    if fList[i] = value then
    begin
      result := i;
      exit;
    end;
  result := -1;
end;

function TDPointerList.GetPointer(const Index: integer): pointer;
begin
  Result := fList[Index];
end;

function TDPointerList.Add(const value: pointer): integer;
begin
  if fNumItems >= Length(fList) then
    SetLength(fList, fNumItems + 16);
  fList[fNumItems] := value;
  Result := fNumItems;
  inc(fNumItems);
end;

//------------------------------------------------------------------------------
// The world: sounds, objects, random numbers, geometry
//------------------------------------------------------------------------------
procedure P_MobjThinker(mo: pointer);
begin
end;

function Sys_Random: integer;
begin
  Result := HarnessSysRandom;
end;

function P_Random: integer;
begin
  Result := 0;
end;

procedure I_Error(const fmt: string; const args: array of const);
begin
  raise ERacingException.CreateFmt(fmt, args);
end;

procedure printf(const fmt: string; const args: array of const);
begin
end;

function R_PointToAngle2(const x1: fixed_t; const y1: fixed_t; const x2: fixed_t; const y2: fixed_t): angle_t;
begin
  Result := TRacingScenarios.PointToAngle(x1, y1, x2, y2);
end;

function P_AproxDistance(dx: fixed_t; dy: fixed_t): fixed_t;
begin
  Result := TRacingScenarios.ApproximateDistance(dx, dy);
end;

function Info_GetMobjNumForName(const name: string): integer;
begin
  if name = 'MT_SPARK1A' then Result := 1001
  else if name = 'MT_SPARK1B' then Result := 1002
  else if name = 'MT_SMOKE1A' then Result := 1003
  else if name = 'MT_SMOKE1B' then Result := 1004
  else if name = 'MT_DIRT3A' then Result := 1005
  else if name = 'MT_DIRT3B' then Result := 1006
  else if name = 'MT_DIRT1A' then Result := 1007
  else if name = 'MT_DIRT1B' then Result := 1008
  else if name = 'MT_DIRT2A' then Result := 1009
  else if name = 'MT_DIRT2B' then Result := 1010
  else if name = 'MT_CHECKLAPRECORD' then Result := 2000
  else
    Result := -1;
end;

function P_SpawnMobj(x, y, z: fixed_t; _type: integer): Pmobj_t;
begin
  New(Result);
  FillChar(Result^, SizeOf(mobj_t), 0);
  Result.x := x;
  Result.y := y;
  Result.z := z;
  Result.index := _type;
  SetLength(HarnessSpawned, Length(HarnessSpawned) + 1);
  HarnessSpawned[High(HarnessSpawned)] := Result;
  // A particle leaves a mark in the log: the line is written when the call ends (the momentum is set after)
  if (_type >= 1001) and (_type <= 1010) then
    HarnessSounds.Add('P#' + IntToStr(High(HarnessSpawned)));
end;

procedure P_SetMobjState(mo: Pmobj_t; state: statenum_t);
begin
end;

procedure S_StartSound(origin: pointer; const name: string);
begin
  // The engine sounds come from the object (no coordinates), the brakes from the point under the car
  if StrToInt(name) = sfx_speedhaste_DERRAPE then
    HarnessSounds.Add(TRacingScenarios.FormatBrakeSound(StrToInt(name), Pdegenmobj_t(origin).x,
      Pdegenmobj_t(origin).y, Pdegenmobj_t(origin).z))
  else
    HarnessSounds.Add(TRacingScenarios.FormatEngineSound(StrToInt(name)));
end;

type
  speedsound_t = record
    name: string;
  end;

var
  speedsounds: array[0..511] of speedsound_t;

function S_SpeedSoundDuration(const sndid: integer): integer;
begin
  Result := TRacingScenarios.SoundDuration(sndid);
end;

function W_LumpLength(const lump: integer): integer;
begin
  Result := HarnessGroundSize;
end;

function W_CacheLumpNum(const lump: integer; const tag: integer): pointer;
begin
  Result := HarnessGroundPtr;
end;

function malloc(const size: integer): pointer;
begin
  GetMem(Result, size);
end;

procedure memcpy(const dest, src: pointer; const size: integer);
begin
  Move(src^, dest^, size);
end;

procedure memfree(var p: pointer; const size: integer);
begin
  FreeMem(p);
  p := nil;
end;

procedure SH_SaveScoreTable;
begin
end;

//------------------------------------------------------------------------------
// The old code, as it is
//------------------------------------------------------------------------------
{$I cars_gears.inc}
{$I particles_vars.inc}
{$I race_funcs.inc}
{$I particles_funcs.inc}
{$I path_funcs.inc}
{$I score_funcs.inc}
{$I cars_funcs.inc}

var
  LSound: integer;

initialization
  for LSound := 0 to High(speedsounds) do
    speedsounds[LSound].name := IntToStr(LSound);
  finesine := @FINE_SINE_TABLE[0];
  finecosine := @FINE_SINE_TABLE[2048];
  HarnessSounds := TStringList.Create;

end.

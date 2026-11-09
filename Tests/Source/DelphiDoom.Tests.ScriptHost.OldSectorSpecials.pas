{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the script host - the old psi_map.pas (oracle)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The bodies of the 77 PS_* functions of psi_map.pas as they were before the  }
{  specials of the sectors became classes (commit 919a19ef), with the PS_ of   }
{  the names changed to Old_ and the EVH_* of the engine replaced by recorders:}
{  every call writes "name|kind|the 8 bytes". Generated from the old file by   }
{  replacing the engine constants (CLEV_*, FLEV_*, ...) with their names.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.OldSectorSpecials;

interface

uses
  System.SysUtils;

var
  /// <summary>Where the recorders write</summary>
  OldSpecialsLog: TProc<string>;
  /// <summary>What the recorders give back</summary>
  OldSpecialsResult: Boolean;
function Old_Ceiling_CrushAndRaise(const tag: integer; const speed: integer; const crush: integer): boolean;
function Old_Ceiling_CrushRaiseAndStay(const tag: integer; const speed: integer; const crush: integer): boolean;
function Old_Ceiling_CrushStop(const tag: integer): boolean;
function Old_Ceiling_LowerAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;
function Old_Ceiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Ceiling_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Ceiling_LowerToFloor(const tag: integer; const speed: integer): boolean;
function Old_Ceiling_LowerToHighestFloor(const tag: integer; const speed: integer): boolean;
function Old_Ceiling_LowerToLowest(const tag: integer; const speed: integer): boolean;
function Old_Ceiling_MoveToValueAndCrush(const tag: integer; const speed: integer; const height: integer; const crush: integer): boolean;
function Old_Ceiling_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
function Old_Ceiling_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
function Old_Ceiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Ceiling_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Ceiling_RaiseToHighestFloor(const tag: integer; const speed: integer): boolean;
function Old_Door_Close(const tag: integer; const speed: integer): boolean;
function Old_Door_CloseWaitOpen(const tag: integer; const speed: integer; const delay: integer): boolean;
function Old_Door_Open(const tag: integer; const speed: integer): boolean;
function Old_Door_Raise(const tag: integer; const speed: integer; delay: integer): boolean;
function Old_FloorAndCeiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_FloorAndCeiling_LowerRaise(const tag: integer; const fspeed, cspeed: integer): boolean;
function Old_FloorAndCeiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Floor_CrushStop(const tag: integer): boolean;
function Old_Floor_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Floor_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Floor_LowerToHighest(const tag: integer; const speed: integer; const adjust: integer): boolean;
function Old_Floor_LowerToLowestCeiling(const tag: integer; const speed: integer): boolean;
function Old_Floor_LowerToLowest(const tag: integer; const speed: integer): boolean;
function Old_Floor_LowerToNearest(const tag: integer; const speed: integer): boolean;
function Old_Floor_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
function Old_Floor_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
function Old_Floor_RaiseAndCrushDoom(const tag: integer; const speed: integer; const crush: integer): boolean;
function Old_Floor_RaiseAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;
function Old_Floor_RaiseByTexture(const tag: integer; const speed: integer): boolean;
function Old_Floor_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Floor_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Floor_RaiseInstant(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Floor_LowerInstant(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Floor_RaiseToCeilingNoChange(const tag: integer; const speed: integer; const crush: integer; const gap: integer): boolean;
function Old_Floor_RaiseToHighest(const tag: integer; const speed: integer): boolean;
function Old_Floor_RaiseToLowestCeiling(const tag: integer; const speed: integer): boolean;
function Old_Floor_RaiseToNearest(const tag: integer; const speed: integer): boolean;
function Old_Floor_ToCeilingInstantNoChange(const tag: integer; const crush: integer; const gap: integer): boolean;
function Old_Floor_Waggle(const tag: integer; const amp: integer; const freq: integer; const offset: integer; const time: integer): boolean;
function Old_Light_ChangeToValue(const tag: integer; const value: integer): boolean;
function Old_Light_Fade(const tag: integer; const value: integer; const tics: integer): boolean;
function Old_Light_Flicker(const tag: integer; const upper: integer; const lower: integer): boolean;
function Old_Light_ForceLightning: boolean;
function Old_Light_ForceLightningTics(const tics: integer): boolean;
function Old_Light_Glow(const tag: integer; const upper: integer; const lower: integer; const tics: integer): boolean;
function Old_Light_LowerByValue(const tag: integer; const value: integer): boolean;
function Old_Light_MaxNeighbor(const tag: integer): boolean;
function Old_Light_MinNeighbor(const tag: integer): boolean;
function Old_Light_RaiseByValue(const tag: integer; const value: integer): boolean;
function Old_Light_Strobe(const tag: integer; const upper: integer; const lower: integer; const utics: integer; const ltics: integer): boolean;
function Old_Light_StrobeDoom(const tag: integer; const utics: integer; const ltics: integer): boolean;
function Old_Pillar_BuildAndCrush(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Pillar_Build(const tag: integer; const speed: integer; const height: integer): boolean;
function Old_Pillar_Open(const tag: integer; const speed: integer; const fdist: integer; const cdist: integer): boolean;
function Old_Plat_DownByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;
function Old_Plat_DownWaitUpStay(const tag: integer; const speed: integer; const delay: integer): boolean;
function Old_Plat_DownWaitUpStayLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;
function Old_Plat_PerpetualRaise(const tag: integer; const speed: integer; const delay: integer): boolean;
function Old_Plat_PerpetualRaiseLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;
function Old_Plat_UpByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;
function Old_Plat_UpNearestWaitDownStay (const tag: integer; const speed: integer; const delay: integer): boolean;
function Old_Plat_UpWaitDownStay(const tag: integer; const speed: integer; const delay: integer): boolean;
function Old_Polyobj_DoorSlide(const po: integer; const speed: integer; const angle: integer; const dist: integer; const delay: integer): boolean;
function Old_Polyobj_DoorSwing(const po: integer; const speed: integer; const angle: integer; const delay: integer): boolean;
function Old_Polyobj_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
function Old_Polyobj_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
function Old_Polyobj_OR_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
function Old_Polyobj_OR_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
function Old_Polyobj_OR_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;
function Old_Polyobj_OR_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;
function Old_Polyobj_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;
function Old_Polyobj_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;

implementation

type
  argsbuffer_t = array[0..7] of byte;
  Pargsbuffer_t = ^argsbuffer_t;

function Bytes(const AArguments: Pointer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to 7 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(PByteArray(AArguments)^[LIndex]);
  end;
end;

procedure Rec(const AText: string);
begin
  OldSpecialsLog(AText);
end;

procedure ClearArgs(const args: Pargsbuffer_t);
begin
  FillChar(args^, SizeOf(argsbuffer_t), 0);
end;

function EVH_DoCeiling(line: Pointer; args: Pointer; kind: string): Boolean;
begin
  Rec('DoCeiling|' + kind + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_CeilingCrushStop(line: Pointer; args: Pointer): Boolean;
begin
  Rec('CeilingCrushStop||' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_DoDoor(line: Pointer; args: Pointer; kind: string): Boolean;
begin
  Rec('DoDoor|' + kind + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_DoFloor(line: Pointer; args: Pointer; kind: string): Boolean;
begin
  Rec('DoFloor|' + kind + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_DoFloorAndCeiling(line: Pointer; args: Pointer; doraise: Boolean): Boolean;
begin
  Rec('DoFloorAndCeiling|' + BoolToStr(doraise, True) + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_FloorCrushStop(line: Pointer; args: Pointer): Boolean;
begin
  Rec('FloorCrushStop||' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_StartFloorWaggle(tag, height, speed, offset, timer: Integer): Boolean;
begin
  Rec(Format('StartFloorWaggle||%d,%d,%d,%d,%d', [tag, height, speed, offset, timer]));
  Result := OldSpecialsResult;
end;

function EVH_SpawnLight(line: Pointer; args: Pointer; kind: string): Boolean;
begin
  Rec('SpawnLight|' + kind + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

procedure P_ForceLightning(const tics: Integer);
begin
  Rec('ForceLightning||' + IntToStr(tics));
end;

function EVH_BuildPillar(line: Pointer; args: Pointer; crush: Boolean): Boolean;
begin
  Rec('BuildPillar|' + BoolToStr(crush, True) + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_OpenPillar(line: Pointer; args: Pointer): Boolean;
begin
  Rec('OpenPillar||' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_DoPlat(line: Pointer; args: Pointer; kind: string; amount: Integer): Boolean;
begin
  Rec('DoPlat|' + kind + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_OpenPolyDoor(line: Pointer; args: Pointer; kind: string): Boolean;
begin
  Rec('OpenPolyDoor|' + kind + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_MovePoly(line: Pointer; args: Pointer; timesEight, overr: Boolean): Boolean;
begin
  Rec('MovePoly|' + BoolToStr(timesEight, True) + ',' + BoolToStr(overr, True) + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;

function EVH_RotatePoly(line: Pointer; args: Pointer; direction: Integer; overr: Boolean): Boolean;
begin
  Rec('RotatePoly|' + IntToStr(direction) + ',' + BoolToStr(overr, True) + '|' + Bytes(args));
  Result := OldSpecialsResult;
end;
//==============================================================================
function Old_Ceiling_CrushAndRaise(const tag: integer; const speed: integer; const crush: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := crush;
  result := EVH_DoCeiling(nil, @args, 'CLEV_CRUSHANDRAISE');
end;

//==============================================================================
// Old_Ceiling_CrushRaiseAndStay
//
// Action 45
//
//==============================================================================
function Old_Ceiling_CrushRaiseAndStay(const tag: integer; const speed: integer; const crush: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := crush;
  result := EVH_DoCeiling(nil, @args, 'CLEV_CRUSHRAISEANDSTAY');
end;

//==============================================================================
// Old_Ceiling_CrushStop
//
// Action 44
//
//==============================================================================
function Old_Ceiling_CrushStop(const tag: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  result := EVH_CeilingCrushStop(nil, @args);
end;

//==============================================================================
// Old_Ceiling_LowerAndCrush
//
// Action 43
//
//==============================================================================
function Old_Ceiling_LowerAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := crush;
  result := EVH_DoCeiling(nil, @args, 'CLEV_LOWERANDCRUSH');
end;

//==============================================================================
// Old_Ceiling_LowerByValue
//
// Action 40
//
//==============================================================================
function Old_Ceiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoCeiling(nil, @args, 'CLEV_LOWERBYVALUE');
end;

//==============================================================================
// Old_Ceiling_LowerByValueTimes8
//
// Action 199 (ZDoom)
//
//==============================================================================
function Old_Ceiling_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoCeiling(nil, @args, 'CLEV_LOWERBYVALUETIMES8');
end;

//==============================================================================
// Old_Ceiling_LowerToFloor
//
// Action 254 (ZDoom)
//
//==============================================================================
function Old_Ceiling_LowerToFloor(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoCeiling(nil, @args, 'CLEV_LOWERTOFLOOR');
end;

//==============================================================================
// Old_Ceiling_LowerToHighestFloor
//
// Action 192 (ZDoom)
//
//==============================================================================
function Old_Ceiling_LowerToHighestFloor(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoCeiling(nil, @args, 'CLEV_LOWERTOMAXFLOOR');
end;

//==============================================================================
// Old_Ceiling_LowerToLowest
//
// Action 253 (ZDoom)
//
//==============================================================================
function Old_Ceiling_LowerToLowest(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoCeiling(nil, @args, 'CLEV_LOWERTOLOWEST');
end;

//==============================================================================
// Old_Ceiling_MoveToValueAndCrush
//
// Action 280 (ZDoom)
//
//==============================================================================
function Old_Ceiling_MoveToValueAndCrush(const tag: integer; const speed: integer; const height: integer; const crush: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  PSmallInt(@args[2])^ := height;
  args[4] := crush;
  result := EVH_DoCeiling(nil, @args, 'CLEV_MOVETOVALUEANDCRUSH');
end;

//==============================================================================
// Old_Ceiling_MoveToValue
//
// Action 47 (ZDoom)
//
//==============================================================================
function Old_Ceiling_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  PSmallInt(@args[2])^ := height;
  args[4] := neg;
  result := EVH_DoCeiling(nil, @args, 'CLEV_MOVETOVALUE');
end;

//==============================================================================
// Old_Ceiling_MoveToValueTimes8
//
// Action 69
//
//==============================================================================
function Old_Ceiling_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  args[3] := neg;
  result := EVH_DoCeiling(nil, @args, 'CLEV_MOVETOVALUETIMES8');
end;

//==============================================================================
// Old_Ceiling_RaiseByValue
//
// Action 41
//
//==============================================================================
function Old_Ceiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoCeiling(nil, @args, 'CLEV_RAISEBYVALUE');
end;

//==============================================================================
// Old_Ceiling_RaiseByValueTimes8
//
// Action 198 (ZDoom)
//
//==============================================================================
function Old_Ceiling_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoCeiling(nil, @args, 'CLEV_RAISEBYVALUETIMES8');
end;

//==============================================================================
// Old_Ceiling_RaiseToHighestFloor
//
// Action 266 (ZDoom)
//
//==============================================================================
function Old_Ceiling_RaiseToHighestFloor(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoCeiling(nil, @args, 'CLEV_RAISETOHIGHESTFLOOR');
end;

//==============================================================================
// Old_Door_Close
//
// Action 10
//
//==============================================================================
function Old_Door_Close(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoDoor(nil, @args, 'DREV_CLOSE');
end;

//==============================================================================
// Old_Door_CloseWaitOpen
//
// Action 249 (ZDoom)
//
//==============================================================================
function Old_Door_CloseWaitOpen(const tag: integer; const speed: integer; const delay: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  result := EVH_DoDoor(nil, @args, 'DREV_CLOSEWAITTHENOPEN');
end;

//==============================================================================
// Old_Door_Open
//
// Action 11
//
//==============================================================================
function Old_Door_Open(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoDoor(nil, @args, 'DREV_OPEN');
end;

//==============================================================================
// Old_Door_Raise
//
// Action 12
//
//==============================================================================
function Old_Door_Raise(const tag: integer; const speed: integer; delay: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  result := EVH_DoDoor(nil, @args, 'DREV_NORMAL');
end;

//==============================================================================
// Old_FloorAndCeiling_LowerByValue
//
// Action 95
//
//==============================================================================
function Old_FloorAndCeiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoFloorAndCeiling(nil, @args, false);
end;

//==============================================================================
// Old_FloorAndCeiling_LowerRaise
//
// Action 251 (ZDoom)
//
//==============================================================================
function Old_FloorAndCeiling_LowerRaise(const tag: integer; const fspeed, cspeed: integer): boolean;
var
  args: argsbuffer_t;
  ret1, ret2: boolean;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := fspeed;
  ret1 := EVH_DoFloor(nil, @args, 'FLEV_LOWERFLOORTOLOWEST');
  args[1] := cspeed;
  ret2 := EVH_DoCeiling(nil, @args, 'CLEV_RAISETOHIGHEST');
  result := ret1 or ret2;
end;

//==============================================================================
// Old_FloorAndCeiling_RaiseByValue
//
// Action 96
//
//==============================================================================
function Old_FloorAndCeiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoFloorAndCeiling(nil, @args, true);
end;

//==============================================================================
// Old_Floor_CrushStop
//
// Action 46
//
//==============================================================================
function Old_Floor_CrushStop(const tag: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  result := EVH_FloorCrushStop(nil, @args);
end;

//==============================================================================
// Old_Floor_LowerByValue
//
// Action 20
//
//==============================================================================
function Old_Floor_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoFloor(nil, @args, 'FLEV_LOWERFLOORBYVALUE');
end;

//==============================================================================
// Old_Floor_LowerByValueTimes8
//
// Action 36
//
//==============================================================================
function Old_Floor_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoFloor(nil, @args, 'FLEV_LOWERBYVALUETIMES8');
end;

//==============================================================================
// Old_Floor_LowerToHighest
//
// Action 242 (ZDoom)
//
//==============================================================================
function Old_Floor_LowerToHighest(const tag: integer; const speed: integer; const adjust: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := adjust;
  result := EVH_DoFloor(nil, @args, 'FLEV_LOWERFLOORTOHIGHEST');
end;

//==============================================================================
// Old_Floor_LowerToLowestCeiling
//
// Action 258 (ZDoom)
//
//==============================================================================
function Old_Floor_LowerToLowestCeiling(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoFloor(nil, @args, 'FLEV_LOWERFLOORTOLOWESTCEILING');
end;

//==============================================================================
// Old_Floor_LowerToLowest
//
// Action 21
//
//==============================================================================
function Old_Floor_LowerToLowest(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoFloor(nil, @args, 'FLEV_LOWERFLOORTOLOWEST');
end;

//==============================================================================
// Old_Floor_LowerToNearest
//
// Action 22
//
//==============================================================================
function Old_Floor_LowerToNearest(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoFloor(nil, @args, 'FLEV_LOWERFLOOR');
end;

//==============================================================================
// Old_Floor_MoveToValue
//
// Action 37 (ZDoom)
//
//==============================================================================
function Old_Floor_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  PSmallInt(@args[2])^ := height;
  args[4] := neg;
  result := EVH_DoFloor(nil, @args, 'FLEV_MOVETOVALUE');
end;

//==============================================================================
// Old_Floor_MoveToValueTimes8
//
// Action 68
//
//==============================================================================
function Old_Floor_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  args[3] := neg;
  result := EVH_DoFloor(nil, @args, 'FLEV_MOVETOVALUETIMES8');
end;

//==============================================================================
// Old_Floor_RaiseAndCrushDoom
//
// Action 99 (ZDoom)
//
//==============================================================================
function Old_Floor_RaiseAndCrushDoom(const tag: integer; const speed: integer; const crush: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := crush;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISEFLOORCRUSHDOOM');
end;

//==============================================================================
// Old_Floor_RaiseAndCrush
//
// Action 28
//
//==============================================================================
function Old_Floor_RaiseAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := crush;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISEFLOORCRUSH');
end;

//==============================================================================
// Old_Floor_RaiseByTexture
//
// Action 240 (ZDoom)
//
//==============================================================================
function Old_Floor_RaiseByTexture(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISETOTEXTURE');
end;

//==============================================================================
// Old_Floor_RaiseByValue
//
// Action 23
//
//==============================================================================
function Old_Floor_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISEFLOORBYVALUE');
end;

//==============================================================================
// Old_Floor_RaiseByValueTimes8
//
// Action 35
//
//==============================================================================
function Old_Floor_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISEFLOORBYVALUETIMES8');
end;

//==============================================================================
// Old_Floor_RaiseInstant
//
// Action 67
//
//==============================================================================
function Old_Floor_RaiseInstant(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISETIMES8INSTANT');
end;

//==============================================================================
// Old_Floor_LowerInstant
//
// Action 66
//
//==============================================================================
function Old_Floor_LowerInstant(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_DoFloor(nil, @args, 'FLEV_LOWERTIMES8INSTANT');
end;

//==============================================================================
// Old_Floor_RaiseToCeilingNoChange
//
// Action 259 (ZDoom) without the change
//
//==============================================================================
function Old_Floor_RaiseToCeilingNoChange(const tag: integer; const speed: integer; const crush: integer; const gap: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := crush;
  args[3] := gap;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISETOCEILING');
end;

//==============================================================================
// Old_Floor_RaiseToHighest
//
// Action 24
//
//==============================================================================
function Old_Floor_RaiseToHighest(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISEFLOOR');
end;

//==============================================================================
// Old_Floor_RaiseToLowestCeiling
//
// Action 238 (ZDoom)
//
//==============================================================================
function Old_Floor_RaiseToLowestCeiling(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISETOLOWESTCEILING');
end;

//==============================================================================
// Old_Floor_RaiseToNearest
//
// Action 25
//
//==============================================================================
function Old_Floor_RaiseToNearest(const tag: integer; const speed: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  result := EVH_DoFloor(nil, @args, 'FLEV_RAISEFLOORTONEAREST');
end;

//==============================================================================
// Old_Floor_ToCeilingInstantNoChange
//
// Action 260 (ZDoom) without the change
//
//==============================================================================
function Old_Floor_ToCeilingInstantNoChange(const tag: integer; const crush: integer; const gap: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := 0;
  args[2] := crush;
  args[3] := gap;
  result := EVH_DoFloor(nil, @args, 'FLEV_FLOORTOCEILINGINSTANT');
end;

//==============================================================================
// Old_Floor_Waggle
//
// Action 138
//
//==============================================================================
function Old_Floor_Waggle(const tag: integer; const amp: integer; const freq: integer; const offset: integer; const time: integer): boolean;
begin
  result := EVH_StartFloorWaggle(tag, amp, freq, offset, time);
end;

//==============================================================================
// Old_Light_ChangeToValue
//
// Action 112
//
//==============================================================================
function Old_Light_ChangeToValue(const tag: integer; const value: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := value;
  result := EVH_SpawnLight(nil, @args, 'LITE_CHANGETOVALUE');
end;

//==============================================================================
// Old_Light_Fade
//
// Action 113
//
//==============================================================================
function Old_Light_Fade(const tag: integer; const value: integer; const tics: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := value;
  args[2] := tics;
  result := EVH_SpawnLight(nil, @args, 'LITE_FADE');
end;

//==============================================================================
// Old_Light_Flicker
//
// Action 115
//
//==============================================================================
function Old_Light_Flicker(const tag: integer; const upper: integer; const lower: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := upper;
  args[2] := lower;
  result := EVH_SpawnLight(nil, @args, 'LITE_FLICKER');
end;

//==============================================================================
// Old_Light_ForceLightning
//
// Action 109
//
//==============================================================================
function Old_Light_ForceLightning: boolean;
begin
  P_ForceLightning(0);
  result := true;
end;

//==============================================================================
// Old_Light_ForceLightningTics
//
// Action 109
//
//==============================================================================
function Old_Light_ForceLightningTics(const tics: integer): boolean;
begin
  P_ForceLightning(tics);
  result := true;
end;

//==============================================================================
// Old_Light_Glow
//
// Action 114
//
//==============================================================================
function Old_Light_Glow(const tag: integer; const upper: integer; const lower: integer; const tics: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := upper;
  args[2] := lower;
  args[3] := tics;
  result := EVH_SpawnLight(nil, @args, 'LITE_GLOW');
end;

//==============================================================================
// Old_Light_LowerByValue
//
// Action 111
//
//==============================================================================
function Old_Light_LowerByValue(const tag: integer; const value: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := value;
  result := EVH_SpawnLight(nil, @args, 'LITE_LOWERBYVALUE');
end;

//==============================================================================
// Old_Light_MaxNeighbor
//
// Action 234 (ZDoom)
//
//==============================================================================
function Old_Light_MaxNeighbor(const tag: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  result := EVH_SpawnLight(nil, @args, 'LITE_MAXNEIGHTBOR');
end;

//==============================================================================
// Old_Light_MinNeighbor
//
// Action 233 (ZDoom)
//
//==============================================================================
function Old_Light_MinNeighbor(const tag: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  result := EVH_SpawnLight(nil, @args, 'LITE_MINNEIGHTBOR');
end;

//==============================================================================
// Old_Light_RaiseByValue
//
// Action 110
//
//==============================================================================
function Old_Light_RaiseByValue(const tag: integer; const value: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  result := EVH_SpawnLight(nil, @args, 'LITE_RAISEBYVALUE');
end;

//==============================================================================
// Old_Light_Strobe
//
// Action 116
//
//==============================================================================
function Old_Light_Strobe(const tag: integer; const upper: integer; const lower: integer; const utics: integer; const ltics: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := upper;
  args[2] := lower;
  args[3] := utics;
  args[4] := ltics;
  result := EVH_SpawnLight(nil, @args, 'LITE_STROBE');
end;

//==============================================================================
// Old_Light_StrobeDoom
//
// Action 232 (ZDoom)
//
//==============================================================================
function Old_Light_StrobeDoom(const tag: integer; const utics: integer; const ltics: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := utics;
  args[2] := ltics;
  result := EVH_SpawnLight(nil, @args, 'LITE_STROBEDOOM');
end;

//==============================================================================
// Old_Pillar_BuildAndCrush
//
// Action 94
//
//==============================================================================
function Old_Pillar_BuildAndCrush(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_BuildPillar(nil, @args, true);
end;

//==============================================================================
// Old_Pillar_Build
//
// Action 29
//
//==============================================================================
function Old_Pillar_Build(const tag: integer; const speed: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := height;
  result := EVH_BuildPillar(nil, @args, false);
end;

//==============================================================================
// Old_Pillar_Open
//
// Action 30
//
//==============================================================================
function Old_Pillar_Open(const tag: integer; const speed: integer; const fdist: integer; const cdist: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := fdist;
  args[3] := cdist;
  result := EVH_OpenPillar(nil, @args);
end;

//==============================================================================
// Old_Plat_DownByValue
//
// Action 63
//
//==============================================================================
function Old_Plat_DownByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  args[3] := height;
  result := EVH_DoPlat(nil, @args, 'PLAT_DOWNBYVALUEWAITUPSTAY', 0);
end;

//==============================================================================
// Old_Plat_DownWaitUpStay
//
// Action 62
//
//==============================================================================
function Old_Plat_DownWaitUpStay(const tag: integer; const speed: integer; const delay: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  result := EVH_DoPlat(nil, @args, 'PLAT_DOWNWAITUPSTAY', 0);
end;

//==============================================================================
// Old_Plat_DownWaitUpStayLip
//
// Action 206 (ZDoom)
//
//==============================================================================
function Old_Plat_DownWaitUpStayLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  args[3] := lip;
  result := EVH_DoPlat(nil, @args, 'PLAT_DOWNWAITUPSTAYLIP', 0);
end;

//==============================================================================
// Old_Plat_PerpetualRaise
//
// Action 60
//
//==============================================================================
function Old_Plat_PerpetualRaise(const tag: integer; const speed: integer; const delay: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  result := EVH_DoPlat(nil, @args, 'PLAT_PERPETUALRAISE', 0);
end;

//==============================================================================
// Old_Plat_PerpetualRaiseLip
//
// Action 207 (ZDoom)
//
//==============================================================================
function Old_Plat_PerpetualRaiseLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  args[3] := lip;
  result := EVH_DoPlat(nil, @args, 'PLAT_PERPETUALRAISELIP', 0);
end;

//==============================================================================
// Old_Plat_UpByValue
//
// Action 65
//
//==============================================================================
function Old_Plat_UpByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  args[3] := height;
  result := EVH_DoPlat(nil, @args, 'PLAT_UPBYVALUEWAITDOWNSTAY', 0);
end;

//==============================================================================
// Old_Plat_UpNearestWaitDownStay 
//
// Action 172 (ZDoom)
//
//==============================================================================
function Old_Plat_UpNearestWaitDownStay (const tag: integer; const speed: integer; const delay: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  result := EVH_DoPlat(nil, @args, 'PLAT_UPNEARESTWAITDOWNSTAY', 0);
end;

//==============================================================================
// Old_Plat_UpWaitDownStay
//
// Action 64
//
//==============================================================================
function Old_Plat_UpWaitDownStay(const tag: integer; const speed: integer; const delay: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := tag;
  args[1] := speed;
  args[2] := delay;
  result := EVH_DoPlat(nil, @args, 'PLAT_UPWAITDOWNSTAY', 0);
end;

//==============================================================================
// Old_Polyobj_DoorSlide
//
// Action 8
//
//==============================================================================
function Old_Polyobj_DoorSlide(const po: integer; const speed: integer; const angle: integer; const dist: integer; const delay: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  args[3] := dist;
  args[4] := delay;
  result := EVH_OpenPolyDoor(nil, @args, 'PODOOR_SLIDE');
end;

//==============================================================================
// Old_Polyobj_DoorSwing
//
// Action 7
//
//==============================================================================
function Old_Polyobj_DoorSwing(const po: integer; const speed: integer; const angle: integer; const delay: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := Abs(speed);
  args[2] := angle;
  args[3] := delay;
  if speed < 0 then
    args[4] := 1;
  result := EVH_OpenPolyDoor(nil, @args, 'PODOOR_SWING');
end;

//==============================================================================
// Old_Polyobj_Move
//
// Action 4
//
//==============================================================================
function Old_Polyobj_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  args[3] := dist;
  result := EVH_MovePoly(nil, @args, false, false);
end;

//==============================================================================
// Old_Polyobj_MoveTimes8
//
// Action 6
//
//==============================================================================
function Old_Polyobj_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  args[3] := dist;
  result := EVH_MovePoly(nil, @args, true, false);
end;

//==============================================================================
// Old_Polyobj_OR_Move
//
// Action 92
//
//==============================================================================
function Old_Polyobj_OR_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  args[3] := dist;
  result := EVH_MovePoly(nil, @args, false, true);
end;

//==============================================================================
// Old_Polyobj_OR_MoveTimes8
//
// Action 93
//
//==============================================================================
function Old_Polyobj_OR_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  args[3] := dist;
  result := EVH_MovePoly(nil, @args, true, true);
end;

//==============================================================================
// Old_Polyobj_OR_RotateLeft
//
// Action 90
//
//==============================================================================
function Old_Polyobj_OR_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  result := EVH_RotatePoly(nil, @args, 1, true);
end;

//==============================================================================
// Old_Polyobj_OR_RotateRight
//
// Action 91
//
//==============================================================================
function Old_Polyobj_OR_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  result := EVH_RotatePoly(nil, @args, -1, true);
end;

//==============================================================================
// Old_Polyobj_RotateLeft
//
// Action 2
//
//==============================================================================
function Old_Polyobj_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  result := EVH_RotatePoly(nil, @args, 1, false);
end;

//==============================================================================
// Old_Polyobj_RotateRight
//
// Action 3
//
//==============================================================================
function Old_Polyobj_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;
var
  args: argsbuffer_t;
begin
  ClearArgs(@args);
  args[0] := po;
  args[1] := speed;
  args[2] := angle;
  result := EVH_RotatePoly(nil, @args, -1, false);
end;

end.

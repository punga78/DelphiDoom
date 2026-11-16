//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Pascal Script RTL - Map interaction
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit psi_map;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf;

//==============================================================================
//
// PS_ConfigureSectorSpecials
//
//==============================================================================
procedure PS_ConfigureSectorSpecials(const AFunctions: IScriptSectorSpecialFunctions);

//==============================================================================
// PS_Ceiling_CrushAndRaise
//
// Action 42
//
//==============================================================================
function PS_Ceiling_CrushAndRaise(const tag: integer; const speed: integer; const crush: integer): boolean;

//==============================================================================
// PS_Ceiling_CrushRaiseAndStay
//
// Action 45
//
//==============================================================================
function PS_Ceiling_CrushRaiseAndStay(const tag: integer; const speed: integer; const crush: integer): boolean;

//==============================================================================
// PS_Ceiling_CrushStop
//
// Action 44
//
//==============================================================================
function PS_Ceiling_CrushStop(const tag: integer): boolean;

//==============================================================================
// PS_Ceiling_LowerAndCrush
//
// Action 43
//
//==============================================================================
function PS_Ceiling_LowerAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;

//==============================================================================
// PS_Ceiling_LowerByValue
//
// Action 40
//
//==============================================================================
function PS_Ceiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Ceiling_LowerByValueTimes8
//
// Action 199 (ZDoom)
//
//==============================================================================
function PS_Ceiling_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Ceiling_LowerToFloor
//
// Action 254 (ZDoom)
//
//==============================================================================
function PS_Ceiling_LowerToFloor(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Ceiling_LowerToHighestFloor
//
// Action 192 (ZDoom)
//
//==============================================================================
function PS_Ceiling_LowerToHighestFloor(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Ceiling_LowerToLowest
//
// Action 253 (ZDoom)
//
//==============================================================================
function PS_Ceiling_LowerToLowest(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Ceiling_MoveToValueAndCrush
//
// Action 280 (ZDoom)
//
//==============================================================================
function PS_Ceiling_MoveToValueAndCrush(const tag: integer; const speed: integer; const height: integer; const crush: integer): boolean;

//==============================================================================
// PS_Ceiling_MoveToValue
//
// Action 47 (ZDoom)
//
//==============================================================================
function PS_Ceiling_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;

//==============================================================================
// PS_Ceiling_MoveToValueTimes8
//
// Action 69
//
//==============================================================================
function PS_Ceiling_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;

//==============================================================================
// PS_Ceiling_RaiseByValue
//
// Action 41
//
//==============================================================================
function PS_Ceiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Ceiling_RaiseByValueTimes8
//
// Action 198 (ZDoom)
//
//==============================================================================
function PS_Ceiling_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Ceiling_RaiseToHighestFloor
//
// Action 266 (ZDoom)
//
//==============================================================================
function PS_Ceiling_RaiseToHighestFloor(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Door_Close
//
// Action 10
//
//==============================================================================
function PS_Door_Close(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Door_CloseWaitOpen
//
// Action 249 (ZDoom)
//
//==============================================================================
function PS_Door_CloseWaitOpen(const tag: integer; const speed: integer; const delay: integer): boolean;

//==============================================================================
// PS_Door_Open
//
// Action 11
//
//==============================================================================
function PS_Door_Open(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Door_Raise
//
// Action 12
//
//==============================================================================
function PS_Door_Raise(const tag: integer; const speed: integer; delay: integer): boolean;

//==============================================================================
// PS_FloorAndCeiling_LowerByValue
//
// Action 95
//
//==============================================================================
function PS_FloorAndCeiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_FloorAndCeiling_LowerRaise
//
// Action 251 (ZDoom)
//
//==============================================================================
function PS_FloorAndCeiling_LowerRaise(const tag: integer; const fspeed, cspeed: integer): boolean;

//==============================================================================
// PS_FloorAndCeiling_RaiseByValue
//
// Action 96
//
//==============================================================================
function PS_FloorAndCeiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Floor_CrushStop
//
// Action 46
//
//==============================================================================
function PS_Floor_CrushStop(const tag: integer): boolean;

//==============================================================================
// PS_Floor_LowerByValue
//
// Action 20
//
//==============================================================================
function PS_Floor_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Floor_LowerByValueTimes8
//
// Action 36
//
//==============================================================================
function PS_Floor_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Floor_LowerToHighest
//
// Action 242 (ZDoom)
//
//==============================================================================
function PS_Floor_LowerToHighest(const tag: integer; const speed: integer; const adjust: integer): boolean;

//==============================================================================
// PS_Floor_LowerToLowestCeiling
//
// Action 258 (ZDoom)
//
//==============================================================================
function PS_Floor_LowerToLowestCeiling(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Floor_LowerToLowest
//
// Action 21
//
//==============================================================================
function PS_Floor_LowerToLowest(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Floor_LowerToNearest
//
// Action 22
//
//==============================================================================
function PS_Floor_LowerToNearest(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Floor_MoveToValue
//
// Action 37 (ZDoom)
//
//==============================================================================
function PS_Floor_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;

//==============================================================================
// PS_Floor_MoveToValueTimes8
//
// Action 68
//
//==============================================================================
function PS_Floor_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;

//==============================================================================
// PS_Floor_RaiseAndCrushDoom
//
// Action 99 (ZDoom)
//
//==============================================================================
function PS_Floor_RaiseAndCrushDoom(const tag: integer; const speed: integer; const crush: integer): boolean;

//==============================================================================
// PS_Floor_RaiseAndCrush
//
// Action 28
//
//==============================================================================
function PS_Floor_RaiseAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;

//==============================================================================
// PS_Floor_RaiseByTexture
//
// Action 240 (ZDoom)
//
//==============================================================================
function PS_Floor_RaiseByTexture(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Floor_RaiseByValue
//
// Action 23
//
//==============================================================================
function PS_Floor_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Floor_RaiseByValueTimes8
//
// Action 35
//
//==============================================================================
function PS_Floor_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Floor_RaiseInstant
//
// Action 67
//
//==============================================================================
function PS_Floor_RaiseInstant(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Floor_LowerInstant
//
// Action 66
//
//==============================================================================
function PS_Floor_LowerInstant(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Floor_RaiseToCeilingNoChange
//
// Action 259 (ZDoom) without the change
//
//==============================================================================
function PS_Floor_RaiseToCeilingNoChange(const tag: integer; const speed: integer; const crush: integer; const gap: integer): boolean;

//==============================================================================
// PS_Floor_RaiseToHighest
//
// Action 24
//
//==============================================================================
function PS_Floor_RaiseToHighest(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Floor_RaiseToLowestCeiling
//
// Action 238 (ZDoom)
//
//==============================================================================
function PS_Floor_RaiseToLowestCeiling(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Floor_RaiseToNearest
//
// Action 25
//
//==============================================================================
function PS_Floor_RaiseToNearest(const tag: integer; const speed: integer): boolean;

//==============================================================================
// PS_Floor_ToCeilingInstantNoChange
//
// Action 260 (ZDoom) without the change
//
//==============================================================================
function PS_Floor_ToCeilingInstantNoChange(const tag: integer; const crush: integer; const gap: integer): boolean;

//==============================================================================
// PS_Floor_Waggle
//
// Action 138
//
//==============================================================================
function PS_Floor_Waggle(const tag: integer; const amp: integer; const freq: integer; const offset: integer; const time: integer): boolean;

//==============================================================================
// PS_Light_ChangeToValue
//
// Action 112
//
//==============================================================================
function PS_Light_ChangeToValue(const tag: integer; const value: integer): boolean;

//==============================================================================
// PS_Light_Fade
//
// Action 113
//
//==============================================================================
function PS_Light_Fade(const tag: integer; const value: integer; const tics: integer): boolean;

//==============================================================================
// PS_Light_Flicker
//
// Action 115
//
//==============================================================================
function PS_Light_Flicker(const tag: integer; const upper: integer; const lower: integer): boolean;

//==============================================================================
// PS_Light_ForceLightning
//
// Action 109
//
//==============================================================================
function PS_Light_ForceLightning: boolean;

//==============================================================================
// PS_Light_ForceLightningTics
//
// Action 109
//
//==============================================================================
function PS_Light_ForceLightningTics(const tics: integer): boolean;

//==============================================================================
// PS_Light_Glow
//
// Action 114
//
//==============================================================================
function PS_Light_Glow(const tag: integer; const upper: integer; const lower: integer; const tics: integer): boolean;

//==============================================================================
// PS_Light_LowerByValue
//
// Action 111
//
//==============================================================================
function PS_Light_LowerByValue(const tag: integer; const value: integer): boolean;

//==============================================================================
// PS_Light_MaxNeighbor
//
// Action 234 (ZDoom)
//
//==============================================================================
function PS_Light_MaxNeighbor(const tag: integer): boolean;

//==============================================================================
// PS_Light_MinNeighbor
//
// Action 233 (ZDoom)
//
//==============================================================================
function PS_Light_MinNeighbor(const tag: integer): boolean;

//==============================================================================
// PS_Light_RaiseByValue
//
// Action 110
//
//==============================================================================
function PS_Light_RaiseByValue(const tag: integer; const value: integer): boolean;

//==============================================================================
// PS_Light_Strobe
//
// Action 116
//
//==============================================================================
function PS_Light_Strobe(const tag: integer; const upper: integer; const lower: integer; const utics: integer; const ltics: integer): boolean;

//==============================================================================
// PS_Light_StrobeDoom
//
// Action 232 (ZDoom)
//
//==============================================================================
function PS_Light_StrobeDoom(const tag: integer; const utics: integer; const ltics: integer): boolean;

//==============================================================================
// PS_Pillar_BuildAndCrush
//
// Action 94
//
//==============================================================================
function PS_Pillar_BuildAndCrush(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Pillar_Build
//
// Action 29
//
//==============================================================================
function PS_Pillar_Build(const tag: integer; const speed: integer; const height: integer): boolean;

//==============================================================================
// PS_Pillar_Open
//
// Action 30
//
//==============================================================================
function PS_Pillar_Open(const tag: integer; const speed: integer; const fdist: integer; const cdist: integer): boolean;

//==============================================================================
// PS_Plat_DownByValue
//
// Action 63
//
//==============================================================================
function PS_Plat_DownByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;

//==============================================================================
// PS_Plat_DownWaitUpStay
//
// Action 62
//
//==============================================================================
function PS_Plat_DownWaitUpStay(const tag: integer; const speed: integer; const delay: integer): boolean;

//==============================================================================
// PS_Plat_DownWaitUpStayLip
//
// Action 206 (ZDoom)
//
//==============================================================================
function PS_Plat_DownWaitUpStayLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;

//==============================================================================
// PS_Plat_PerpetualRaise
//
// Action 60
//
//==============================================================================
function PS_Plat_PerpetualRaise(const tag: integer; const speed: integer; const delay: integer): boolean;

//==============================================================================
// PS_Plat_PerpetualRaiseLip
//
// Action 207 (ZDoom)
//
//==============================================================================
function PS_Plat_PerpetualRaiseLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;

//==============================================================================
// PS_Plat_UpByValue
//
// Action 65
//
//==============================================================================
function PS_Plat_UpByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;

//==============================================================================
// PS_Plat_UpNearestWaitDownStay 
//
// Action 172 (ZDoom)
//
//==============================================================================
function PS_Plat_UpNearestWaitDownStay (const tag: integer; const speed: integer; const delay: integer): boolean;

//==============================================================================
// PS_Plat_UpWaitDownStay
//
// Action 64
//
//==============================================================================
function PS_Plat_UpWaitDownStay(const tag: integer; const speed: integer; const delay: integer): boolean;

//==============================================================================
// PS_Polyobj_DoorSlide
//
// Action 8
//
//==============================================================================
function PS_Polyobj_DoorSlide(const po: integer; const speed: integer; const angle: integer; const dist: integer; const delay: integer): boolean;

//==============================================================================
// PS_Polyobj_DoorSwing
//
// Action 7
//
//==============================================================================
function PS_Polyobj_DoorSwing(const po: integer; const speed: integer; const angle: integer; const delay: integer): boolean;

//==============================================================================
// PS_Polyobj_Move
//
// Action 4
//
//==============================================================================
function PS_Polyobj_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;

//==============================================================================
// PS_Polyobj_MoveTimes8
//
// Action 6
//
//==============================================================================
function PS_Polyobj_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;

//==============================================================================
// PS_Polyobj_OR_Move
//
// Action 92
//
//==============================================================================
function PS_Polyobj_OR_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;

//==============================================================================
// PS_Polyobj_OR_MoveTimes8
//
// Action 93
//
//==============================================================================
function PS_Polyobj_OR_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;

//==============================================================================
// PS_Polyobj_OR_RotateLeft
//
// Action 90
//
//==============================================================================
function PS_Polyobj_OR_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;

//==============================================================================
// PS_Polyobj_OR_RotateRight
//
// Action 91
//
//==============================================================================
function PS_Polyobj_OR_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;

//==============================================================================
// PS_Polyobj_RotateLeft
//
// Action 2
//
//==============================================================================
function PS_Polyobj_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;

//==============================================================================
// PS_Polyobj_RotateRight
//
// Action 3
//
//==============================================================================
function PS_Polyobj_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;

implementation

uses
  i_system;

var
  // given by the composition root
  ps_sectorspecials_ref: IScriptSectorSpecialFunctions = nil;

//==============================================================================
//
// PS_ConfigureSectorSpecials
//
//==============================================================================
procedure PS_ConfigureSectorSpecials(const AFunctions: IScriptSectorSpecialFunctions);
begin
  ps_sectorspecials_ref := AFunctions;
end;

//==============================================================================
//
// PS_SectorSpecials
//
//==============================================================================
function PS_SectorSpecials: IScriptSectorSpecialFunctions;
begin
  if ps_sectorspecials_ref = nil then
    I_Error('PS_ConfigureSectorSpecials() was not called: the specials of the sectors are missing');
  result := ps_sectorspecials_ref;
end;

//==============================================================================
//
// PS_Ceiling_CrushAndRaise
//
//==============================================================================
function PS_Ceiling_CrushAndRaise(const tag: integer; const speed: integer; const crush: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.CrushAndRaise(tag, speed, crush);
end;

//==============================================================================
//
// PS_Ceiling_CrushRaiseAndStay
//
//==============================================================================
function PS_Ceiling_CrushRaiseAndStay(const tag: integer; const speed: integer; const crush: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.CrushRaiseAndStay(tag, speed, crush);
end;

//==============================================================================
//
// PS_Ceiling_CrushStop
//
//==============================================================================
function PS_Ceiling_CrushStop(const tag: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.CrushStop(tag);
end;

//==============================================================================
//
// PS_Ceiling_LowerAndCrush
//
//==============================================================================
function PS_Ceiling_LowerAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.LowerAndCrush(tag, speed, crush);
end;

//==============================================================================
//
// PS_Ceiling_LowerByValue
//
//==============================================================================
function PS_Ceiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.LowerByValue(tag, speed, height);
end;

//==============================================================================
//
// PS_Ceiling_LowerByValueTimes8
//
//==============================================================================
function PS_Ceiling_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.LowerByValueTimes8(tag, speed, height);
end;

//==============================================================================
//
// PS_Ceiling_LowerToFloor
//
//==============================================================================
function PS_Ceiling_LowerToFloor(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.LowerToFloor(tag, speed);
end;

//==============================================================================
//
// PS_Ceiling_LowerToHighestFloor
//
//==============================================================================
function PS_Ceiling_LowerToHighestFloor(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.LowerToHighestFloor(tag, speed);
end;

//==============================================================================
//
// PS_Ceiling_LowerToLowest
//
//==============================================================================
function PS_Ceiling_LowerToLowest(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.LowerToLowest(tag, speed);
end;

//==============================================================================
//
// PS_Ceiling_MoveToValueAndCrush
//
//==============================================================================
function PS_Ceiling_MoveToValueAndCrush(const tag: integer; const speed: integer; const height: integer; const crush: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.MoveToValueAndCrush(tag, speed, height, crush);
end;

//==============================================================================
//
// PS_Ceiling_MoveToValue
//
//==============================================================================
function PS_Ceiling_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.MoveToValue(tag, speed, height, neg);
end;

//==============================================================================
//
// PS_Ceiling_MoveToValueTimes8
//
//==============================================================================
function PS_Ceiling_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.MoveToValueTimes8(tag, speed, height, neg);
end;

//==============================================================================
//
// PS_Ceiling_RaiseByValue
//
//==============================================================================
function PS_Ceiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.RaiseByValue(tag, speed, height);
end;

//==============================================================================
//
// PS_Ceiling_RaiseByValueTimes8
//
//==============================================================================
function PS_Ceiling_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.RaiseByValueTimes8(tag, speed, height);
end;

//==============================================================================
//
// PS_Ceiling_RaiseToHighestFloor
//
//==============================================================================
function PS_Ceiling_RaiseToHighestFloor(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Ceilings.RaiseToHighestFloor(tag, speed);
end;

//==============================================================================
//
// PS_Door_Close
//
//==============================================================================
function PS_Door_Close(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Doors.Close(tag, speed);
end;

//==============================================================================
//
// PS_Door_CloseWaitOpen
//
//==============================================================================
function PS_Door_CloseWaitOpen(const tag: integer; const speed: integer; const delay: integer): boolean;
begin
  result := PS_SectorSpecials.Doors.CloseWaitOpen(tag, speed, delay);
end;

//==============================================================================
//
// PS_Door_Open
//
//==============================================================================
function PS_Door_Open(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Doors.Open(tag, speed);
end;

//==============================================================================
//
// PS_Door_Raise
//
//==============================================================================
function PS_Door_Raise(const tag: integer; const speed: integer; delay: integer): boolean;
begin
  result := PS_SectorSpecials.Doors.RaiseDoor(tag, speed, delay);
end;

//==============================================================================
//
// PS_FloorAndCeiling_LowerByValue
//
//==============================================================================
function PS_FloorAndCeiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.FloorAndCeilingLowerByValue(tag, speed, height);
end;

//==============================================================================
//
// PS_FloorAndCeiling_LowerRaise
//
//==============================================================================
function PS_FloorAndCeiling_LowerRaise(const tag: integer; const fspeed, cspeed: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.FloorAndCeilingLowerRaise(tag, fspeed, cspeed);
end;

//==============================================================================
//
// PS_FloorAndCeiling_RaiseByValue
//
//==============================================================================
function PS_FloorAndCeiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.FloorAndCeilingRaiseByValue(tag, speed, height);
end;

//==============================================================================
//
// PS_Floor_CrushStop
//
//==============================================================================
function PS_Floor_CrushStop(const tag: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.CrushStop(tag);
end;

//==============================================================================
//
// PS_Floor_LowerByValue
//
//==============================================================================
function PS_Floor_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.LowerByValue(tag, speed, height);
end;

//==============================================================================
//
// PS_Floor_LowerByValueTimes8
//
//==============================================================================
function PS_Floor_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.LowerByValueTimes8(tag, speed, height);
end;

//==============================================================================
//
// PS_Floor_LowerToHighest
//
//==============================================================================
function PS_Floor_LowerToHighest(const tag: integer; const speed: integer; const adjust: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.LowerToHighest(tag, speed, adjust);
end;

//==============================================================================
//
// PS_Floor_LowerToLowestCeiling
//
//==============================================================================
function PS_Floor_LowerToLowestCeiling(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.LowerToLowestCeiling(tag, speed);
end;

//==============================================================================
//
// PS_Floor_LowerToLowest
//
//==============================================================================
function PS_Floor_LowerToLowest(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.LowerToLowest(tag, speed);
end;

//==============================================================================
//
// PS_Floor_LowerToNearest
//
//==============================================================================
function PS_Floor_LowerToNearest(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.LowerToNearest(tag, speed);
end;

//==============================================================================
//
// PS_Floor_MoveToValue
//
//==============================================================================
function PS_Floor_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.MoveToValue(tag, speed, height, neg);
end;

//==============================================================================
//
// PS_Floor_MoveToValueTimes8
//
//==============================================================================
function PS_Floor_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.MoveToValueTimes8(tag, speed, height, neg);
end;

//==============================================================================
//
// PS_Floor_RaiseAndCrushDoom
//
//==============================================================================
function PS_Floor_RaiseAndCrushDoom(const tag: integer; const speed: integer; const crush: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseAndCrushDoom(tag, speed, crush);
end;

//==============================================================================
//
// PS_Floor_RaiseAndCrush
//
//==============================================================================
function PS_Floor_RaiseAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseAndCrush(tag, speed, crush);
end;

//==============================================================================
//
// PS_Floor_RaiseByTexture
//
//==============================================================================
function PS_Floor_RaiseByTexture(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseByTexture(tag, speed);
end;

//==============================================================================
//
// PS_Floor_RaiseByValue
//
//==============================================================================
function PS_Floor_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseByValue(tag, speed, height);
end;

//==============================================================================
//
// PS_Floor_RaiseByValueTimes8
//
//==============================================================================
function PS_Floor_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseByValueTimes8(tag, speed, height);
end;

//==============================================================================
//
// PS_Floor_RaiseInstant
//
//==============================================================================
function PS_Floor_RaiseInstant(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseInstant(tag, speed, height);
end;

//==============================================================================
//
// PS_Floor_LowerInstant
//
//==============================================================================
function PS_Floor_LowerInstant(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.LowerInstant(tag, speed, height);
end;

//==============================================================================
//
// PS_Floor_RaiseToCeilingNoChange
//
//==============================================================================
function PS_Floor_RaiseToCeilingNoChange(const tag: integer; const speed: integer; const crush: integer; const gap: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseToCeilingNoChange(tag, speed, crush, gap);
end;

//==============================================================================
//
// PS_Floor_RaiseToHighest
//
//==============================================================================
function PS_Floor_RaiseToHighest(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseToHighest(tag, speed);
end;

//==============================================================================
//
// PS_Floor_RaiseToLowestCeiling
//
//==============================================================================
function PS_Floor_RaiseToLowestCeiling(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseToLowestCeiling(tag, speed);
end;

//==============================================================================
//
// PS_Floor_RaiseToNearest
//
//==============================================================================
function PS_Floor_RaiseToNearest(const tag: integer; const speed: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.RaiseToNearest(tag, speed);
end;

//==============================================================================
//
// PS_Floor_ToCeilingInstantNoChange
//
//==============================================================================
function PS_Floor_ToCeilingInstantNoChange(const tag: integer; const crush: integer; const gap: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.ToCeilingInstantNoChange(tag, crush, gap);
end;

//==============================================================================
//
// PS_Floor_Waggle
//
//==============================================================================
function PS_Floor_Waggle(const tag: integer; const amp: integer; const freq: integer; const offset: integer; const time: integer): boolean;
begin
  result := PS_SectorSpecials.Floors.Waggle(tag, amp, freq, offset, time);
end;

//==============================================================================
//
// PS_Light_ChangeToValue
//
//==============================================================================
function PS_Light_ChangeToValue(const tag: integer; const value: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.ChangeToValue(tag, value);
end;

//==============================================================================
//
// PS_Light_Fade
//
//==============================================================================
function PS_Light_Fade(const tag: integer; const value: integer; const tics: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.Fade(tag, value, tics);
end;

//==============================================================================
//
// PS_Light_Flicker
//
//==============================================================================
function PS_Light_Flicker(const tag: integer; const upper: integer; const lower: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.Flicker(tag, upper, lower);
end;

//==============================================================================
//
// PS_Light_ForceLightning
//
//==============================================================================
function PS_Light_ForceLightning: boolean;
begin
  result := PS_SectorSpecials.Lights.ForceLightning;
end;

//==============================================================================
//
// PS_Light_ForceLightningTics
//
//==============================================================================
function PS_Light_ForceLightningTics(const tics: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.ForceLightningTics(tics);
end;

//==============================================================================
//
// PS_Light_Glow
//
//==============================================================================
function PS_Light_Glow(const tag: integer; const upper: integer; const lower: integer; const tics: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.Glow(tag, upper, lower, tics);
end;

//==============================================================================
//
// PS_Light_LowerByValue
//
//==============================================================================
function PS_Light_LowerByValue(const tag: integer; const value: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.LowerByValue(tag, value);
end;

//==============================================================================
//
// PS_Light_MaxNeighbor
//
//==============================================================================
function PS_Light_MaxNeighbor(const tag: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.MaxNeighbor(tag);
end;

//==============================================================================
//
// PS_Light_MinNeighbor
//
//==============================================================================
function PS_Light_MinNeighbor(const tag: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.MinNeighbor(tag);
end;

//==============================================================================
//
// PS_Light_RaiseByValue
//
//==============================================================================
function PS_Light_RaiseByValue(const tag: integer; const value: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.RaiseByValue(tag, value);
end;

//==============================================================================
//
// PS_Light_Strobe
//
//==============================================================================
function PS_Light_Strobe(const tag: integer; const upper: integer; const lower: integer; const utics: integer; const ltics: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.Strobe(tag, upper, lower, utics, ltics);
end;

//==============================================================================
//
// PS_Light_StrobeDoom
//
//==============================================================================
function PS_Light_StrobeDoom(const tag: integer; const utics: integer; const ltics: integer): boolean;
begin
  result := PS_SectorSpecials.Lights.StrobeDoom(tag, utics, ltics);
end;

//==============================================================================
//
// PS_Pillar_BuildAndCrush
//
//==============================================================================
function PS_Pillar_BuildAndCrush(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Pillars.BuildAndCrush(tag, speed, height);
end;

//==============================================================================
//
// PS_Pillar_Build
//
//==============================================================================
function PS_Pillar_Build(const tag: integer; const speed: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Pillars.Build(tag, speed, height);
end;

//==============================================================================
//
// PS_Pillar_Open
//
//==============================================================================
function PS_Pillar_Open(const tag: integer; const speed: integer; const fdist: integer; const cdist: integer): boolean;
begin
  result := PS_SectorSpecials.Pillars.Open(tag, speed, fdist, cdist);
end;

//==============================================================================
//
// PS_Plat_DownByValue
//
//==============================================================================
function PS_Plat_DownByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Plats.DownByValue(tag, speed, delay, height);
end;

//==============================================================================
//
// PS_Plat_DownWaitUpStay
//
//==============================================================================
function PS_Plat_DownWaitUpStay(const tag: integer; const speed: integer; const delay: integer): boolean;
begin
  result := PS_SectorSpecials.Plats.DownWaitUpStay(tag, speed, delay);
end;

//==============================================================================
//
// PS_Plat_DownWaitUpStayLip
//
//==============================================================================
function PS_Plat_DownWaitUpStayLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;
begin
  result := PS_SectorSpecials.Plats.DownWaitUpStayLip(tag, speed, delay, lip);
end;

//==============================================================================
//
// PS_Plat_PerpetualRaise
//
//==============================================================================
function PS_Plat_PerpetualRaise(const tag: integer; const speed: integer; const delay: integer): boolean;
begin
  result := PS_SectorSpecials.Plats.PerpetualRaise(tag, speed, delay);
end;

//==============================================================================
//
// PS_Plat_PerpetualRaiseLip
//
//==============================================================================
function PS_Plat_PerpetualRaiseLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;
begin
  result := PS_SectorSpecials.Plats.PerpetualRaiseLip(tag, speed, delay, lip);
end;

//==============================================================================
//
// PS_Plat_UpByValue
//
//==============================================================================
function PS_Plat_UpByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;
begin
  result := PS_SectorSpecials.Plats.UpByValue(tag, speed, delay, height);
end;

//==============================================================================
//
// PS_Plat_UpNearestWaitDownStay
//
//==============================================================================
function PS_Plat_UpNearestWaitDownStay (const tag: integer; const speed: integer; const delay: integer): boolean;
begin
  result := PS_SectorSpecials.Plats.UpNearestWaitDownStay(tag, speed, delay);
end;

//==============================================================================
//
// PS_Plat_UpWaitDownStay
//
//==============================================================================
function PS_Plat_UpWaitDownStay(const tag: integer; const speed: integer; const delay: integer): boolean;
begin
  result := PS_SectorSpecials.Plats.UpWaitDownStay(tag, speed, delay);
end;

//==============================================================================
//
// PS_Polyobj_DoorSlide
//
//==============================================================================
function PS_Polyobj_DoorSlide(const po: integer; const speed: integer; const angle: integer; const dist: integer; const delay: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.DoorSlide(po, speed, angle, dist, delay);
end;

//==============================================================================
//
// PS_Polyobj_DoorSwing
//
//==============================================================================
function PS_Polyobj_DoorSwing(const po: integer; const speed: integer; const angle: integer; const delay: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.DoorSwing(po, speed, angle, delay);
end;

//==============================================================================
//
// PS_Polyobj_Move
//
//==============================================================================
function PS_Polyobj_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.MoveBy(po, speed, angle, dist);
end;

//==============================================================================
//
// PS_Polyobj_MoveTimes8
//
//==============================================================================
function PS_Polyobj_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.MoveTimes8(po, speed, angle, dist);
end;

//==============================================================================
//
// PS_Polyobj_OR_Move
//
//==============================================================================
function PS_Polyobj_OR_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.MoveOverride(po, speed, angle, dist);
end;

//==============================================================================
//
// PS_Polyobj_OR_MoveTimes8
//
//==============================================================================
function PS_Polyobj_OR_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.MoveTimes8Override(po, speed, angle, dist);
end;

//==============================================================================
//
// PS_Polyobj_OR_RotateLeft
//
//==============================================================================
function PS_Polyobj_OR_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.RotateLeftOverride(po, speed, angle);
end;

//==============================================================================
//
// PS_Polyobj_OR_RotateRight
//
//==============================================================================
function PS_Polyobj_OR_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.RotateRightOverride(po, speed, angle);
end;

//==============================================================================
//
// PS_Polyobj_RotateLeft
//
//==============================================================================
function PS_Polyobj_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.RotateLeft(po, speed, angle);
end;

//==============================================================================
//
// PS_Polyobj_RotateRight
//
//==============================================================================
function PS_Polyobj_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;
begin
  result := PS_SectorSpecials.Polyobjects.RotateRight(po, speed, angle);
end;

end.

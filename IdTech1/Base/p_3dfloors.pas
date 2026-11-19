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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_3dfloors;

interface

uses
  d_delphi,
  doomdata,
  m_fixed,
  p_mobj_h,
  r_defs;

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #247,
  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  T3dFloorRoutines = class sealed
  public
    //==============================================================================
    //
    // P_3dFloorNumber
    //
    //==============================================================================
    class function P_3dFloorNumber(const m: Pmobj_t): integer; overload; static;
    //==============================================================================
    //
    // P_3dFloorNumber
    //
    //==============================================================================
    class function P_3dFloorNumber(const s: Psector_t; const z: fixed_t): integer; overload; static;
    //==============================================================================
    //
    // P_3dFloorFindMapthingFloorZ
    //
    //==============================================================================
    class function P_3dFloorFindMapthingFloorZ(const m: Pmapthing_t): fixed_t; static;
    //==============================================================================
    //
    // P_3dFloorFindMapthingCeilingZ
    //
    //==============================================================================
    class function P_3dFloorFindMapthingCeilingZ(const m: Pmapthing_t): fixed_t; static;
    //==============================================================================
    //
    // P_3dFloorHeight
    //
    //==============================================================================
    class function P_3dFloorHeight(const x, y, z: fixed_t): fixed_t; overload; static;
    //==============================================================================
    //
    // P_3dCeilingHeight
    //
    //==============================================================================
    class function P_3dCeilingHeight(const x, y, z: fixed_t): fixed_t; overload; static;
    //==============================================================================
    //
    // P_3dFloorHeight
    //
    //==============================================================================
    class function P_3dFloorHeight(const m: Pmobj_t): fixed_t; overload; static;
    //==============================================================================
    //
    // P_3dCeilingHeight
    //
    //==============================================================================
    class function P_3dCeilingHeight(const m: Pmobj_t): fixed_t; overload; static;
    //==============================================================================
    //
    // P_3dFloorHeight
    //
    //==============================================================================
    class function P_3dFloorHeight(const s: Psector_t; const x, y, z: fixed_t): fixed_t; overload; static;
    //==============================================================================
    //
    // P_3dCeilingHeight
    //
    //==============================================================================
    class function P_3dCeilingHeight(const s: Psector_t; const x, y, z: fixed_t): fixed_t; overload; static;
    //==============================================================================
    //
    // P_PtInSolidFloor2
    //
    //==============================================================================
    class function P_PtInSolidFloor2(const x, y, z: fixed_t; const radious: fixed_t): boolean; static;
    //==============================================================================
    //
    // P_3dFloorSetupSegs
    //
    //==============================================================================
    class procedure P_3dFloorSetupSegs; static;
  end;


implementation

uses
  doomdef,
  p_setup,
  p_slopes,
  p_spec,
  r_main;

//==============================================================================
// P_3dFloorNumber
//
// Which floor?
//
//==============================================================================
class function T3dFloorRoutines.P_3dFloorNumber(const m: Pmobj_t): integer;
var
  ss: Psubsector_t;
  msec: Psector_t;
begin
  ss := TRendererMain.R_PointInSubsector(m.x, m.y);
  if ss.sector.midsec >= 0 then
  begin
    msec := @sectors[ss.sector.midsec];
    if m.z <= msec.floorheight then
      result := 0
    else
      result := 1;
  end
  else
    result := 0;
end;

//==============================================================================
//
// P_3dFloorNumber
//
//==============================================================================
class function T3dFloorRoutines.P_3dFloorNumber(const s: Psector_t; const z: fixed_t): integer;
var
  msec: Psector_t;
begin
  if s.midsec >= 0 then
  begin
    msec := @sectors[s.midsec];
    if z <= msec.floorheight then
      result := 0
    else
      result := 1;
  end
  else
    result := 0;
end;

//==============================================================================
//
// P_3dFloorFindMapthingFloorZ
//
//==============================================================================
class function T3dFloorRoutines.P_3dFloorFindMapthingFloorZ(const m: Pmapthing_t): fixed_t;
var
  ss: Psubsector_t;
  msec: Psector_t;
  x, y: fixed_t;
begin
  x := m.x * FRACUNIT;
  y := m.y * FRACUNIT;
  ss := TRendererMain.R_PointInSubsector(x, y);
  if m.options and MTF_ONMIDSECTOR = 0 then
  begin
    result := TSlopeRoutines.P_FloorHeight(ss.sector, x, y);
    exit;
  end;

  if ss.sector.midsec >= 0 then
  begin
    msec := @sectors[ss.sector.midsec];
    result := msec.ceilingheight;
  end
  else
    result := TSlopeRoutines.P_FloorHeight(ss.sector, x, y);
end;

//==============================================================================
//
// P_3dFloorFindMapthingCeilingZ
//
//==============================================================================
class function T3dFloorRoutines.P_3dFloorFindMapthingCeilingZ(const m: Pmapthing_t): fixed_t;
var
  ss: Psubsector_t;
  msec: Psector_t;
  x, y: fixed_t;
begin
  x := m.x * FRACUNIT;
  y := m.y * FRACUNIT;
  ss := TRendererMain.R_PointInSubsector(x, y);
  if m.options and MTF_ONMIDSECTOR <> 0 then
  begin
    result := TSlopeRoutines.P_CeilingHeight(ss.sector, x, y);
    exit;
  end;

  if ss.sector.midsec >= 0 then
  begin
    msec := @sectors[ss.sector.midsec];
    result := msec.floorheight;
  end
  else
    result := TSlopeRoutines.P_CeilingHeight(ss.sector, x, y);
end;

//==============================================================================
//
// P_3dFloorHeight
//
//==============================================================================
class function T3dFloorRoutines.P_3dFloorHeight(const x, y, z: fixed_t): fixed_t;
var
  ss: Psubsector_t;
  msec: Psector_t;
begin
  ss := TRendererMain.R_PointInSubsector(x, y);
  if ss.sector.midsec >= 0 then
  begin
    msec := @sectors[ss.sector.midsec];
    if z <= msec.floorheight then
      result := TSlopeRoutines.P_FloorHeight(ss.sector, x, y)
    else
      result := msec.ceilingheight;
  end
  else
    result := TSlopeRoutines.P_FloorHeight(ss.sector, x, y);
end;

//==============================================================================
//
// P_3dCeilingHeight
//
//==============================================================================
class function T3dFloorRoutines.P_3dCeilingHeight(const x, y, z: fixed_t): fixed_t;
var
  ss: Psubsector_t;
  msec: Psector_t;
begin
  ss := TRendererMain.R_PointInSubsector(x, y);
  if ss.sector.midsec >= 0 then
  begin
    msec := @sectors[ss.sector.midsec];
    if z > msec.floorheight then
      result := TSlopeRoutines.P_CeilingHeight(ss.sector, x, y)
    else
      result := msec.floorheight;
  end
  else
    result := TSlopeRoutines.P_CeilingHeight(ss.sector, x, y);
end;

//==============================================================================
//
// P_3dFloorHeight
//
//==============================================================================
class function T3dFloorRoutines.P_3dFloorHeight(const m: Pmobj_t): fixed_t;
begin
  result := P_3dFloorHeight(m.x, m.y, m.z);
end;

//==============================================================================
//
// P_3dCeilingHeight
//
//==============================================================================
class function T3dFloorRoutines.P_3dCeilingHeight(const m: Pmobj_t): fixed_t;
begin
  result := P_3dCeilingHeight(m.x, m.y, m.z);
end;

//==============================================================================
//
// P_3dFloorHeight
//
//==============================================================================
class function T3dFloorRoutines.P_3dFloorHeight(const s: Psector_t; const x, y, z: fixed_t): fixed_t;
var
  msec: Psector_t;
begin
  if s.midsec >= 0 then
  begin
    msec := @sectors[s.midsec];
    if z <= msec.floorheight then
      result := TSlopeRoutines.P_FloorHeight(s, x, y)
    else
      result := msec.ceilingheight;
  end
  else
    result := TSlopeRoutines.P_FloorHeight(s, x, y);
end;

//==============================================================================
//
// P_3dCeilingHeight
//
//==============================================================================
class function T3dFloorRoutines.P_3dCeilingHeight(const s: Psector_t; const x, y, z: fixed_t): fixed_t;
var
  msec: Psector_t;
begin
  if s.midsec >= 0 then
  begin
    msec := @sectors[s.midsec];
    if z > msec.floorheight then
      result := TSlopeRoutines.P_CeilingHeight(s, x, y)
    else
      result := msec.floorheight;
  end
  else
    result := TSlopeRoutines.P_CeilingHeight(s, x, y);
end;

//==============================================================================
//
// P_PtInSolidFloor2
//
//==============================================================================
class function T3dFloorRoutines.P_PtInSolidFloor2(const x, y, z: fixed_t; const radious: fixed_t): boolean;
var
  s: Psubsector_t;
  sec: Psector_t;
begin
  s := TRendererMain.R_PointInSubsector(x, y);
  if s.sector.midsec >= 0 then
  begin
    sec := @sectors[s.sector.midsec];
    result := (z >= sec.floorheight - radious) and (z <= sec.ceilingheight + radious);
  end
  else
    result := false;
end;

//==============================================================================
//
// P_3dFloorSetupSegs
//
//==============================================================================
class procedure T3dFloorRoutines.P_3dFloorSetupSegs;
var
  i: integer;
  s, sec: integer;
begin
  for i := 0 to numlines - 1 do
  begin
    case lines[i].special of
      // JVAL: Middle sector (3d floor)
      {$IFDEF HEXEN}
      253:
      {$ELSE}
      281:
      {$ENDIF}
        begin
          sec := pDiff(sides[lines[i].sidenum[0]].sector, sectors, SizeOf(sector_t));
          s := -1;
          while P_FindSectorFromLineTag2(@lines[i], s) >= 0 do
          begin
            sectors[s].midsec := sec;
            sectors[s].midline := i;
          end;
        end;
    end;
  end;

end;

end.


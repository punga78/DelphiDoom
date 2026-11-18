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

unit udmf_mobj;

interface

uses
  p_mobj_h;

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TUdmfMobjRoutines = class sealed
  public
    //==============================================================================
    //
    // P_FindMobjFromTID
    //
    //==============================================================================
    class function P_FindMobjFromTID(tid: integer; var searchPosition: pointer): Pmobj_t; overload; static;

    //==============================================================================
    //
    // P_FindMobjFromTID
    //
    //==============================================================================
    class function P_FindMobjFromTID(tid: integer; var searchPosition: pointer; var ret: Pmobj_t): Pmobj_t; overload; static;
  end;

implementation

uses
  d_think,
  p_tick,
  p_mobj,
  DelphiDoom.Engine.World.MobjRules;

//==============================================================================
//
// P_FindMobjFromTID
//
//==============================================================================
class function TUdmfMobjRoutines.P_FindMobjFromTID(tid: integer; var searchPosition: pointer): Pmobj_t;
var
  th: Pthinker_t;
  mo: Pmobj_t;
begin
  th := searchPosition;
  th := th.next;
  while th <> @TTickState.ThinkerCap do
  begin
    if @th._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(th);
      if mo.tid = tid then
      begin
        searchPosition := mo;
        result := mo;
        exit;
      end;
    end;
    th := th.next;
  end;
  searchPosition := nil;
  result := nil;
end;

//==============================================================================
//
// P_FindMobjFromTID
//
//==============================================================================
class function TUdmfMobjRoutines.P_FindMobjFromTID(tid: integer; var searchPosition: pointer; var ret: Pmobj_t): Pmobj_t;
begin
  result := P_FindMobjFromTID(tid, searchPosition);
  ret := result;
end;

end.

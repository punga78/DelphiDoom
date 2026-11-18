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

unit udmf_plats;

interface

uses
  d_delphi,
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  r_defs;

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 12): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TUdmfPlatRoutines = class sealed
  public
    //==============================================================================
    //
    // TH_PlatRaise
    //
    //==============================================================================
    class procedure TH_PlatRaise(plat: Pplat_t); static;

    //==============================================================================
    //
    // EVH_DoPlat
    //
    //==============================================================================
    class function EVH_DoPlat(line: Pline_t; args: PByteArray; _type: plattype_e; amount: integer): boolean; static;

    //==============================================================================
    //
    // EVH_StopPlat
    //
    //==============================================================================
    class procedure EVH_StopPlat(line: Pline_t; args: PByteArray); static;

    //==============================================================================
    //
    // PH_AddActivePlat
    //
    //==============================================================================
    class procedure PH_AddActivePlat(plat: Pplat_t); static;

    //==============================================================================
    //
    // PH_RemoveActivePlat
    //
    //==============================================================================
    class procedure PH_RemoveActivePlat(plat: Pplat_t); static;
  end;

implementation

uses
  i_system,
  p_setup,
  p_tick,
  p_acs,
{$IFNDEF HEXEN}
  udmf_spec,
{$ENDIF}
  z_zone,
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Engine.Plat.Services,
  DelphiDoom.Engine.Plat.Thinker;

//==============================================================================
// TH_PlatRaise
//
//      Move a plat up and down
//      The calculation is TUdmfPlatMachine (IdTech1\Thinkers), the thinker stays
//      the record that the savegames know
//
//==============================================================================
class procedure TUdmfPlatRoutines.TH_PlatRaise(plat: Pplat_t);
var
  state: TPlatState;
begin
  UdmfPlatLoadState(plat, state);
  UdmfPlatMachine.Tick(plat, plat.sector, UdmfPlatKindOf(plat._type), state);
  UdmfPlatStoreState(plat, state);
end;

//==============================================================================
// EVH_DoPlat
//
//      Do Platforms
//      "amount" is only used for SOME platforms.
//
//==============================================================================
class function TUdmfPlatRoutines.EVH_DoPlat(line: Pline_t; args: PByteArray; _type: plattype_e; amount: integer): boolean;
var
  plat: Pplat_t;
  secnum: integer;
  sec: Psector_t;
  state: TPlatState;
begin
  result := false;
  secnum := -1;

  while {$IFNDEF HEXEN}TUdmfSpecRoutines.{$ENDIF}P_FindSectorFromTag2(args[0], secnum) >= 0 do
  begin
    sec := @sectors[secnum];
    if sec.specialdata <> nil then
      continue;

    //
    // Find lowest & highest floors around sector
    //
    result := true;
    plat := Z_Malloc(SizeOf(plat_t), PU_LEVSPEC, nil);
    TTickRoutines.P_AddThinker(@plat.thinker);

    plat._type := _type;
    plat.sector := sec;
    plat.sector.specialdata := plat;
    plat.thinker._function.acp1 := @TH_PlatRaise;

    UdmfPlatLoadState(plat, state);
    UdmfPlatMachine.Configure(sec, UdmfPlatKindOf(_type), args[0], args[1], args[2], args[3], state);
    UdmfPlatStoreState(plat, state);

    PH_AddActivePlat(plat);
    UdmfPlatMachine.AnnounceStart(sec);
  end;
end;

//==============================================================================
//
// EVH_StopPlat
//
//==============================================================================
class procedure TUdmfPlatRoutines.EVH_StopPlat(line: Pline_t; args: PByteArray);
var
  i: integer;
begin
  for i := 0 to TTickRoutines.P_World.UdmfPlats.Capacity - 1 do
  begin
    Pplat_t(TTickRoutines.P_World.UdmfPlats[i]).tag := args[0]; // JVAL SOS
    if args[0] <> 0 then
    begin
      Pplat_t(TTickRoutines.P_World.UdmfPlats[i]).sector.specialdata := nil;
      P_TagFinished(Pplat_t(TTickRoutines.P_World.UdmfPlats[i]).sector.tag);
      TTickRoutines.P_RemoveThinker(@Pplat_t(TTickRoutines.P_World.UdmfPlats[i]).thinker);
      TTickRoutines.P_World.UdmfPlats.Release(i);

      exit;
    end;
  end;

end;

//==============================================================================
//
// PH_AddActivePlat
//
//==============================================================================
class procedure TUdmfPlatRoutines.PH_AddActivePlat(plat: Pplat_t);
var
  i: integer;
begin
  for i := 0 to TTickRoutines.P_World.UdmfPlats.Capacity - 1 do
    if Pplat_t(TTickRoutines.P_World.UdmfPlats[i]) = nil then
    begin
      TTickRoutines.P_World.UdmfPlats.Add(plat);
      exit;
    end;
  I_Error('PH_AddActivePlat(): no more plats!');
end;

//==============================================================================
//
// PH_RemoveActivePlat
//
//==============================================================================
class procedure TUdmfPlatRoutines.PH_RemoveActivePlat(plat: Pplat_t);
var
  i: integer;
begin
  for i := 0 to TTickRoutines.P_World.UdmfPlats.Capacity - 1 do
    if plat = Pplat_t(TTickRoutines.P_World.UdmfPlats[i]) then
    begin
      Pplat_t(TTickRoutines.P_World.UdmfPlats[i]).sector.specialdata := nil;
      P_TagFinished(plat.sector.tag);
      TTickRoutines.P_RemoveThinker(@Pplat_t(TTickRoutines.P_World.UdmfPlats[i]).thinker);
      TTickRoutines.P_World.UdmfPlats.Release(i);
      exit;
    end;
  I_Error('PH_RemoveActivePlat(): can''t find plat!');
end;

end.

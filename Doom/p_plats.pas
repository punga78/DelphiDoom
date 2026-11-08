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
//  Plats (i.e. elevator platforms) code, raising/lowering.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_plats;

interface

uses
  p_spec,
  r_defs;

var
  activeplats: array[0..MAXPLATS - 1] of Pplat_t;

//==============================================================================
//
// T_PlatRaise
//
//==============================================================================
procedure T_PlatRaise(plat: Pplat_t);

//==============================================================================
//
// EV_DoPlat
//
//==============================================================================
function EV_DoPlat(line: Pline_t; _type: plattype_e; amount: integer): integer;

//==============================================================================
//
// P_ActivateInStasis
//
//==============================================================================
procedure P_ActivateInStasis(tag: integer);

//==============================================================================
//
// EV_StopPlat
//
//==============================================================================
function EV_StopPlat(line: Pline_t): integer;

//==============================================================================
//
// P_AddActivePlat
//
//==============================================================================
procedure P_AddActivePlat(plat: Pplat_t);

//==============================================================================
//
// P_RemoveActivePlat
//
//==============================================================================
procedure P_RemoveActivePlat(plat: Pplat_t);

implementation

uses
  i_system,
  p_tick,
  p_setup,
  z_zone,
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Engine.Plat.Services,
  DelphiDoom.Engine.Plat.Thinker;

//==============================================================================
//
// T_PlatRaise
//
// The tic of a platform: the calculation is TPlatMachine (Libs\Thinkers), the
// thinker stays the record that the savegames know
//
//==============================================================================
procedure T_PlatRaise(plat: Pplat_t);
var
  state: TPlatState;
begin
  PlatLoadState(plat, state);
  PlatMachine.Tick(plat, plat.sector, PlatKindOf(plat._type), state);
  PlatStoreState(plat, state);
end;

//==============================================================================
// EV_DoPlat
//
// Do Platforms
//  "amount" is only used for SOME platforms.
//
//==============================================================================
function EV_DoPlat(line: Pline_t; _type: plattype_e; amount: integer): integer;
var
  plat: Pplat_t;
  secnum: integer;
  sec: Psector_t;
  kind: TPlatKind;
  picture: integer;
  state: TPlatState;
begin
  // Activate all <type> plats that are in_stasis
  if _type = toggleUpDn then
  begin
    P_ActivateInStasis(line.tag);
    result := 1;
  end
  else
  begin
    if _type = perpetualRaise then
      P_ActivateInStasis(line.tag);
    result := 0;
  end;

  kind := PlatKindOf(_type);

  secnum := -1;
  while P_FindSectorFromLineTag2(line, secnum) >= 0 do
  begin
    sec := @sectors[secnum];

    // don't start a second floor function if already moving
    if P_SectorActive(floor_special, sec) then
      continue;

    // Find lowest & highest floors around sector
    result := 1;
    plat := Z_Malloc(SizeOf(plat_t), PU_LEVSPEC, nil);
    P_AddThinker(@plat.thinker);

    plat._type := _type;
    plat.sector := sec;
    plat.sector.floordata := plat;
    plat.thinker._function.acp1 := @T_PlatRaise;
    plat.crush := false;
    plat.tag := line.tag;

    // only the two kinds that change the floor look at the side of the line
    if (kind = TPlatKind.RaiseToNearestAndChange) or (kind = TPlatKind.RaiseAndChange) then
      picture := sides[line.sidenum[0]].sector.floorpic
    else
      picture := 0;

    PlatLoadState(plat, state);
    PlatMachine.Configure(sec, kind, picture, amount, state);
    PlatStoreState(plat, state);
    P_AddActivePlat(plat);
  end;
end;

//==============================================================================
//
// P_ActivateInStasis
//
//==============================================================================
procedure P_ActivateInStasis(tag: integer);
var
  i: integer;
  plt: Pplat_t;
begin
  for i := 0 to MAXPLATS - 1 do
  begin
    plt := activeplats[i];
    if (plt <> nil) and
      (plt.tag = tag) and
      (plt.status = in_stasis) then
    begin
      // the toggle goes the other way, the others do what they were doing
      plt.status := PlatEngineStatusOf(
        PlatMachine.WakeUpStatus(PlatKindOf(plt._type), PlatStatusOf(plt.oldstatus)));
      plt.thinker._function.acp1 := @T_PlatRaise;
    end;
  end;
end;

//==============================================================================
//
// EV_StopPlat
//
//==============================================================================
function EV_StopPlat(line: Pline_t): integer;
var
  i: integer;
  plt: Pplat_t;
  state: TPlatState;
begin
  result := 0;
  for i := 0 to MAXPLATS - 1 do
  begin
    plt := activeplats[i];
    if (plt <> nil) and
      (plt.status <> in_stasis) and
      (plt.tag = line.tag) then
    begin
      result := 1;
      PlatLoadState(plt, state);
      PlatMachine.Pause(state);
      plt.oldstatus := PlatEngineStatusOf(state.OldStatus);
      plt.status := PlatEngineStatusOf(state.Status);
      plt.thinker._function.acv := nil;
    end;
  end;
end;

//==============================================================================
//
// P_AddActivePlat
//
//==============================================================================
procedure P_AddActivePlat(plat: Pplat_t);
var
  i: integer;
begin
  for i := 0 to MAXPLATS - 1 do
    if activeplats[i] = nil then
    begin
      activeplats[i] := plat;
      exit;
    end;

  I_Error('P_AddActivePlat(): no more plats!');
end;

//==============================================================================
//
// P_RemoveActivePlat
//
//==============================================================================
procedure P_RemoveActivePlat(plat: Pplat_t);
var
  i: integer;
begin
  for i := 0 to MAXPLATS - 1 do
    if plat = activeplats[i] then
    begin
      activeplats[i].sector.floordata := nil;
      P_RemoveThinker(@activeplats[i].thinker);
      activeplats[i] := nil;
      exit;
    end;

  I_Error('P_RemoveActivePlat(): can''t find plat!');
end;

end.

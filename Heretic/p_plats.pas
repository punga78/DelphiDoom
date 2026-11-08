//------------------------------------------------------------------------------
//
//  DelphiHeretic is a source port of the game Heretic and it is
//  based on original Linux Doom as published by "id Software", on
//  Heretic source as published by "Raven" software and DelphiDoom
//  as published by Jim Valavanis.
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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
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
procedure EV_StopPlat(line: Pline_t);

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
  result := 0;

  // Activate all <type> plats that are in_stasis
  if _type = perpetualRaise then
    P_ActivateInStasis(line.tag);

  kind := PlatKindOf(_type);

  secnum := P_FindSectorFromLineTag(line, -1);
  while secnum >= 0 do
  begin
    sec := @sectors[secnum];
    secnum := P_FindSectorFromLineTag(line, secnum);

    if sec.specialdata <> nil then
      continue;

    // Find lowest & highest floors around sector
    result := 1;
    plat := Z_Malloc(SizeOf(plat_t), PU_LEVSPEC, nil);
    P_AddThinker(@plat.thinker);

    plat._type := _type;
    plat.sector := sec;
    plat.sector.specialdata := plat;
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
begin
  for i := 0 to MAXPLATS - 1 do
    if (activeplats[i] <> nil) and
      (activeplats[i].tag = tag) and
      (activeplats[i].status = in_stasis) then
    begin
      activeplats[i].status := PlatEngineStatusOf(
        PlatMachine.WakeUpStatus(PlatKindOf(activeplats[i]._type),
          PlatStatusOf(activeplats[i].oldstatus)));
      activeplats[i].thinker._function.acp1 := @T_PlatRaise;
    end;
end;

//==============================================================================
//
// EV_StopPlat
//
//==============================================================================
procedure EV_StopPlat(line: Pline_t);
var
  i: integer;
  state: TPlatState;
begin
  for i := 0 to MAXPLATS - 1 do
    if (activeplats[i] <> nil) and
      (activeplats[i].status <> in_stasis) and
      (activeplats[i].tag = line.tag) then
    begin
      PlatLoadState(activeplats[i], state);
      PlatMachine.Pause(state);
      activeplats[i].oldstatus := PlatEngineStatusOf(state.OldStatus);
      activeplats[i].status := PlatEngineStatusOf(state.Status);
      activeplats[i].thinker._function.acv := nil;
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
      activeplats[i].sector.specialdata := nil;
      P_RemoveThinker(@activeplats[i].thinker);
      activeplats[i] := nil;
      exit;
    end;

  I_Error('P_RemoveActivePlat(): can''t find plat!');
end;

end.

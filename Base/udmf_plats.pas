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
  p_spec,
  r_defs;

var
  hactiveplats: array[0..MAXPLATS - 1] of Pplat_t;

//==============================================================================
//
// TH_PlatRaise
//
//==============================================================================
procedure TH_PlatRaise(plat: Pplat_t);

//==============================================================================
//
// EVH_DoPlat
//
//==============================================================================
function EVH_DoPlat(line: Pline_t; args: PByteArray; _type: plattype_e; amount: integer): boolean;

//==============================================================================
//
// EVH_StopPlat
//
//==============================================================================
procedure EVH_StopPlat(line: Pline_t; args: PByteArray);

//==============================================================================
//
// PH_AddActivePlat
//
//==============================================================================
procedure PH_AddActivePlat(plat: Pplat_t);

//==============================================================================
//
// PH_RemoveActivePlat
//
//==============================================================================
procedure PH_RemoveActivePlat(plat: Pplat_t);

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
//      The calculation is TUdmfPlatMachine (Libs\Thinkers), the thinker stays
//      the record that the savegames know
//
//==============================================================================
procedure TH_PlatRaise(plat: Pplat_t);
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
function EVH_DoPlat(line: Pline_t; args: PByteArray; _type: plattype_e; amount: integer): boolean;
var
  plat: Pplat_t;
  secnum: integer;
  sec: Psector_t;
  state: TPlatState;
begin
  result := false;
  secnum := -1;

  while P_FindSectorFromTag2(args[0], secnum) >= 0 do
  begin
    sec := @sectors[secnum];
    if sec.specialdata <> nil then
      continue;

    //
    // Find lowest & highest floors around sector
    //
    result := true;
    plat := Z_Malloc(SizeOf(plat_t), PU_LEVSPEC, nil);
    P_AddThinker(@plat.thinker);

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
procedure EVH_StopPlat(line: Pline_t; args: PByteArray);
var
  i: integer;
begin
  for i := 0 to MAXPLATS - 1 do
  begin
    hactiveplats[i].tag := args[0]; // JVAL SOS
    if args[0] <> 0 then
    begin
      hactiveplats[i].sector.specialdata := nil;
      P_TagFinished(hactiveplats[i].sector.tag);
      P_RemoveThinker(@hactiveplats[i].thinker);
      hactiveplats[i] := nil;

      exit;
    end;
  end;

end;

//==============================================================================
//
// PH_AddActivePlat
//
//==============================================================================
procedure PH_AddActivePlat(plat: Pplat_t);
var
  i: integer;
begin
  for i := 0 to MAXPLATS - 1 do
    if hactiveplats[i] = nil then
    begin
      hactiveplats[i] := plat;
      exit;
    end;
  I_Error('PH_AddActivePlat(): no more plats!');
end;

//==============================================================================
//
// PH_RemoveActivePlat
//
//==============================================================================
procedure PH_RemoveActivePlat(plat: Pplat_t);
var
  i: integer;
begin
  for i := 0 to MAXPLATS - 1 do
    if plat = hactiveplats[i] then
    begin
      hactiveplats[i].sector.specialdata := nil;
      P_TagFinished(plat.sector.tag);
      P_RemoveThinker(@hactiveplats[i].thinker);
      hactiveplats[i] := nil;
      exit;
    end;
  I_Error('PH_RemoveActivePlat(): can''t find plat!');
end;

end.

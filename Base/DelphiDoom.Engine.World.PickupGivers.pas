{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what a pickup gives (Doom, Heretic, Strife)            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PickupGivers;

// The armor and the dropped things of Doom, Heretic and Strife (issue #185, step
// 2f-2c). They were in p_inter, the same in Doom and Heretic, with the Strife
// negative armor and the compatibility test of each game as rules of
// TInterGameRules. Hexen does not use this unit: its player has an armor per
// type (armorpoints is an array) and its things have no MF_DROPPED, so its
// P_GiveArmor and P_SpawnDroppedMobj stay in its rules

interface

uses
  m_fixed,
  d_player,
  p_mobj_h;

//==============================================================================
//
// P_GiveArmor
// Returns false if the armor is worse
// than the current armor.
//
//==============================================================================
function P_GiveArmor(player: Pplayer_t; armortype: integer): boolean;

//==============================================================================
// P_SpawnDroppedMobj
//
// KillMobj
//
//==============================================================================
function P_SpawnDroppedMobj(x, y, z: fixed_t; _type: integer): Pmobj_t;

implementation

uses
  g_game,
  m_rnd,
  p_mobj,
  DelphiDoom.Engine.World.InterRules;

//==============================================================================
//
// P_GiveArmor
// Returns false if the armor is worse
// than the current armor.
//
//==============================================================================
function P_GiveArmor(player: Pplayer_t; armortype: integer): boolean;
var
  hits: integer;
begin
  // villsa [STRIFE]
  if TInterGameRules.AllowsNegativeArmor and (armortype < 0) then
  begin
    if player.armorpoints <> 0 then
    begin
      result := false;
      exit;
    end;

    armortype := -armortype;
  end;

  hits := armortype * 100;
  if player.armorpoints >= hits then
  begin
    result := false;  // don't pick up
    exit;
  end;

  player.armortype := armortype;
  player.armorpoints := hits;

  result := true;
end;

//==============================================================================
// P_SpawnDroppedMobj
//
// KillMobj
//
//==============================================================================
function P_SpawnDroppedMobj(x, y, z: fixed_t; _type: integer): Pmobj_t;
begin
  result := P_SpawnMobj(x, y, z, _type);
  result.flags := result.flags or MF_DROPPED; // special versions of items
  // JVAL Dropped items fall down to floor.
  if not TInterGameRules.NeedsCompatibility then
  begin
    result.z := result.z + 32 * FRACUNIT;
    result.momz := 4 * FRACUNIT;
    if G_PlayingEngineVersion >= TInterGameRules.DroppedScatterVersion then
    begin
      result.momx := 64 * N_Random;
      result.momy := 64 * N_Random;
    end;
  end;
end;

end.

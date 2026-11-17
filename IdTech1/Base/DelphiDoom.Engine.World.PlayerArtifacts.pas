{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the artifacts of the player (Heretic, Hexen)           }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PlayerArtifacts;

// The inventory routines Heretic and Hexen have in common (issue #185, step 2f-1):
// the rest of the artifacts (P_UseArtifact, P_PlayerUseArtifact, P_ArtiTele) is of each
// game and is in its TUserGameRules unit

interface

uses
  d_player;

//==============================================================================
//
// P_PlayerNextArtifact
//
//==============================================================================
procedure P_PlayerNextArtifact(player: Pplayer_t);

//==============================================================================
//
// P_GetPlayerNum
//
//==============================================================================
function P_GetPlayerNum(player: Pplayer_t): integer;

//==============================================================================
//
// P_PlayerRemoveArtifact
//
//==============================================================================
procedure P_PlayerRemoveArtifact(player: Pplayer_t; slot: integer);

//==============================================================================
//
// P_AutoUseHealth
//
//==============================================================================
procedure P_AutoUseHealth(player: Pplayer_t; saveHealth: integer);

implementation

uses
  doomdef,
  p_mobj_h,
  g_game,
  sb_bar,
  DelphiDoom.Engine.World.UserRules;

procedure P_PlayerNextArtifact(player: Pplayer_t);
begin
  if player = @TGameSession.Players[TGameSession.ConsolePlayer] then
  begin
    dec(inv_ptr);
    if inv_ptr < 6 then
    begin
      dec(curpos);
      if curpos < 0 then
        curpos := 0;
    end;
    if inv_ptr < 0 then
    begin
      inv_ptr := player.inventorySlotNum - 1;
      if inv_ptr < 6 then
        curpos := inv_ptr
      else
        curpos := 6;
    end;

    player.readyArtifact := artitype_t(player.inventory[inv_ptr]._type);
  end;
end;

function P_GetPlayerNum(player: Pplayer_t): integer;
var
  i: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if player = @TGameSession.Players[i] then
    begin
      result := i;
      exit;
    end;

  result := 0;
end;

//==============================================================================
//----------------------------------------------------------------------------
//
// PROC P_PlayerRemoveArtifact
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_PlayerRemoveArtifact(player: Pplayer_t; slot: integer);
var
  i: integer;
begin
  if TUserGameRules.SlotIsEmpty(player, slot) then
    exit;

  dec(player.artifactCount);
  dec(player.inventory[slot].count);
  if player.inventory[slot].count = 0 then
  begin // Used last of a type - compact the artifact list
    player.readyArtifact := arti_none;
    player.inventory[slot]._type := Ord(arti_none);
    for i := slot + 1 to player.inventorySlotNum - 1 do
      player.inventory[i - 1] := player.inventory[i];

    TUserGameRules.ClearFreedSlot(player);
    dec(player.inventorySlotNum);
    if player = @TGameSession.Players[TGameSession.ConsolePlayer] then
    begin // Set position markers and get next readyArtifact
      dec(inv_ptr);
      if inv_ptr < 6 then
      begin
        dec(curpos);
        if curpos < 0 then
          curpos := 0;
      end;
      if inv_ptr >= player.inventorySlotNum then
        inv_ptr := player.inventorySlotNum - 1;
      if inv_ptr < 0 then
        inv_ptr := 0;
      player.readyArtifact := artitype_t(player.inventory[inv_ptr]._type);
    end;
  end;
end;

//==============================================================================
//
// P_AutoUseHealth
//
//==============================================================================
procedure P_AutoUseHealth(player: Pplayer_t; saveHealth: integer);
var
  i: integer;
  count: integer;
  normalCount: integer;
  normalSlot: integer;
  superCount: integer;
  superSlot: integer;
begin
  normalCount := 0;
  superCount := 0;
  normalSlot := 0;
  superSlot := 0;

  for i := 0 to player.inventorySlotNum - 1 do
  begin
    if player.inventory[i]._type = Ord(arti_health) then
    begin
      normalSlot := i;
      normalCount := player.inventory[i].count;
    end
    else if player.inventory[i]._type = Ord(arti_superhealth) then
    begin
      superSlot := i;
      superCount := player.inventory[i].count;
    end;
  end;

  if (TGameSession.GameSkill = sk_baby) and (normalCount * 25 >= saveHealth) then
  begin // Use quartz flasks
    count := (saveHealth + 24) div 25;
    for i := 0 to count - 1 do
    begin
      player.health := player.health + 25;
      P_PlayerRemoveArtifact(player, normalSlot);
    end;
  end
  else if superCount * 100 >= saveHealth then
  begin // Use mystic urns
    count := (saveHealth + 99) div 100;
    for i := 0 to count - 1 do
    begin
      player.health := player.health + 100;
      P_PlayerRemoveArtifact(player, superSlot);
    end;
  end
  else if (TGameSession.GameSkill = sk_baby) and (superCount * 100 + normalCount * 25 >= saveHealth) then
  begin // Use mystic urns and quartz flasks
    count := (saveHealth + 24) div 25;
    saveHealth := saveHealth - count * 25;
    for i := 0 to count - 1 do
    begin
      player.health := player.health + 25;
      P_PlayerRemoveArtifact(player, normalSlot);
    end;
    count := (saveHealth + 99) div 100;
    for i := 0 to count - 1 do
    begin
      player.health := player.health + 100;
      P_PlayerRemoveArtifact(player, normalSlot);
    end;
  end;

  player.mo.health := player.health;
end;
end.

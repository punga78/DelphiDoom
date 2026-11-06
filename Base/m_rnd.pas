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
//  Random number LUT.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit m_rnd;

interface

uses
  m_fixed,
  DelphiDoom.MathCore.Intf;

//==============================================================================
//
// M_ConfigureRandom
// The generator of Libs\MathCore, given by the composition root
//
//==============================================================================
procedure M_ConfigureRandom(const ARandom: IGameRandom);

//==============================================================================
// M_Random
//
// Returns a number from 0 to 255,
// from a lookup table.
//
//==============================================================================
function M_Random: integer;

//==============================================================================
//
// P_Random
//
//==============================================================================
function P_Random: integer;

//==============================================================================
//
// N_Random
//
//==============================================================================
function N_Random: integer;

//==============================================================================
//
// I_Random
//
//==============================================================================
function I_Random: integer;

//==============================================================================
//
// Sys_Random
//
//==============================================================================
function Sys_Random: integer;

//==============================================================================
//
// C_Random
//
//==============================================================================
function C_Random(var idx: integer): integer;

//==============================================================================
//
// M_ClearRandom
// Call all RNGs to reset
//
//==============================================================================
procedure M_ClearRandom;

//==============================================================================
//
// P_SaveRandom
//
//==============================================================================
procedure P_SaveRandom;

//==============================================================================
//
// P_RestoreRandom
//
//==============================================================================
procedure P_RestoreRandom;

//==============================================================================
//
// P_RandomFromSeed
//
//==============================================================================
function P_RandomFromSeed(const seed: integer): integer;

//==============================================================================
//
// P_RandomHitscanAngle
//
//==============================================================================
function P_RandomHitscanAngle(spread: fixed_t): integer;

//==============================================================================
//
// P_RandomHitscanSlope
//
//==============================================================================
function P_RandomHitscanSlope(spread: fixed_t): integer;

//==============================================================================
//
// M_GetMenuRandomIndex
// The index of the generator of the menu: the network checks that it is the same everywhere
//
//==============================================================================
function M_GetMenuRandomIndex: integer;

//==============================================================================
//
// M_GetSystemRandomSeed
// The seed of the random monsters: demos keep it
//
//==============================================================================
function M_GetSystemRandomSeed: integer;

//==============================================================================
//
// M_SetSystemRandomSeed
//
//==============================================================================
procedure M_SetSystemRandomSeed(const seed: integer);

implementation

uses
  i_system;

var
  game_random: IGameRandom;

//==============================================================================
//
// M_ConfigureRandom
//
//==============================================================================
procedure M_ConfigureRandom(const ARandom: IGameRandom);
begin
  game_random := ARandom;
end;


function M_Random: integer;
begin
  result := game_random.NextMenu;
end;

function P_Random: integer;
begin
  result := game_random.NextPlay;
end;

function N_Random: integer;
begin
  result := game_random.NextNonCompatible;
end;

function I_Random: integer;
begin
  result := game_random.NextUnpredictable;
end;

function Sys_Random: integer;
begin
  result := game_random.NextSystem;
end;

function C_Random(var idx: integer): integer;
begin
  result := game_random.NextWithIndex(idx);
end;

function P_RandomFromSeed(const seed: integer): integer;
begin
  result := game_random.FromSeed(seed);
end;

procedure M_ClearRandom;
begin
  game_random.Clear;
end;

procedure P_SaveRandom;
begin
  game_random.SavePlayIndex;
end;

procedure P_RestoreRandom;
begin
  if not game_random.RestorePlayIndex then
    I_DevError('P_RestoreRandom(): Stack is empty!'#13#10);
end;

function P_RandomHitscanAngle(spread: fixed_t): integer;
begin
  result := game_random.HitscanAngle(spread);
end;

function P_RandomHitscanSlope(spread: fixed_t): integer;
begin
  result := game_random.HitscanSlope(spread);
end;

function M_GetMenuRandomIndex: integer;
begin
  result := game_random.MenuIndex;
end;

function M_GetSystemRandomSeed: integer;
begin
  result := game_random.SystemSeed;
end;

procedure M_SetSystemRandomSeed(const seed: integer);
begin
  game_random.SystemSeed := seed;
end;

end.

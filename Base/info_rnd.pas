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

// Facade (issue #185, slice 1b): the classes of monsters and the choice are
// Libs\Info\DelphiDoom.Info.RandomMonsters; what changes from game to game is
// Base\DelphiDoom.Engine.Info.RandomRules

// JVAL: Random items

unit info_rnd;

interface

uses
  DelphiDoom.Engine.Info.Intf;

//==============================================================================
//
// Info_ConfigureRandom
//
// What chooses the monsters placed at random: ComposeEngine gives it
//
//==============================================================================
procedure Info_ConfigureRandom(const ARandom: IEngineInfoRandom);

//==============================================================================
//
// Info_SelectRandomMonster
//
//==============================================================================
function Info_SelectRandomMonster(_type: integer): integer;

//==============================================================================
//
// Info_InitRandom
//
//==============================================================================
procedure Info_InitRandom;

//==============================================================================
//
// Info_ShutDownRandom
//
//==============================================================================
procedure Info_ShutDownRandom;

//==============================================================================
//
// Info_IsMonster
//
//==============================================================================
function Info_IsMonster(_type: integer): boolean;

implementation

uses
  i_system;

var
  random_service: IEngineInfoRandom = nil;

//==============================================================================
//
// Info_ConfigureRandom
//
//==============================================================================
procedure Info_ConfigureRandom(const ARandom: IEngineInfoRandom);
begin
  random_service := ARandom;
end;

//==============================================================================
//
// Info_Random
//
//==============================================================================
function Info_Random: IEngineInfoRandom;
begin
  if random_service = nil then
    I_Error('Info_Random(): the random monsters are not configured (ComposeEngine was not called)');
  result := random_service;
end;

//==============================================================================
//
// Info_SelectRandomMonster
//
//==============================================================================
function Info_SelectRandomMonster(_type: integer): integer;
begin
  result := Info_Random.SelectMonster(_type);
end;

//==============================================================================
//
// Info_InitRandom
//
//==============================================================================
procedure Info_InitRandom;
begin
  Info_Random.Initialize;
end;

//==============================================================================
//
// Info_ShutDownRandom
//
//==============================================================================
procedure Info_ShutDownRandom;
begin
  if random_service <> nil then
    random_service.ShutDown;
end;

//==============================================================================
//
// Info_IsMonster
//
//==============================================================================
function Info_IsMonster(_type: integer): boolean;
begin
  result := Info_Random.IsMonster(_type);
end;

end.

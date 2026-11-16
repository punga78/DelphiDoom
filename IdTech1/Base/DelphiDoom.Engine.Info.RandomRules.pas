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

unit DelphiDoom.Engine.Info.RandomRules;

interface

uses
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.Types;

type
  /// <summary>
  ///   What differs from game to game in the monsters placed at random: the classes of health
  ///   (Heretic has two sets, by the version being played; Hexen has one class only), what a
  ///   monster is (Hexen also leaves out the players' alternate numbers) and whether random
  ///   numbers are thrown away before the choice (not in Hexen). The old {$IFDEF}s of info_rnd
  /// </summary>
  TEngineInfoRandomRules = class(TInterfacedObject, IInfoRandomRules)
  public
    function Thresholds: TArray<Integer>;
    function IsMonster(const AMobj: TInfoMobj): Boolean;
    function IsValidThing(const ADoomedNum: Integer): Boolean;
    function DiscardCount: Integer;
  end;

implementation

uses
{$IFDEF HERETIC}
  g_game,
{$ENDIF}
  doomdef,
  m_rnd,
  p_mobj_h,
  p_setup;

{ TEngineInfoRandomRules }

function TEngineInfoRandomRules.Thresholds: TArray<Integer>;
begin
{$IF DEFINED(HERETIC)}
  if G_PlayingEngineVersion > VERSION110 then
    Result := [90, 120, 220, 1000]
  else
    Result := [80, 400, 1200, 2500];
{$ELSEIF DEFINED(HEXEN)}
  Result := [1000000, 1000000, 1000000, 1000000];
{$ELSE}
  Result := [80, 400, 1200, 2500];
{$ENDIF}
end;

function TEngineInfoRandomRules.IsMonster(const AMobj: TInfoMobj): Boolean;
begin
{$IFDEF HEXEN}
  Result := (AMobj.DoomedNum > MAXPLAYERS) and      // Not player
            (AMobj.DoomedNum <> 9100) and           // Not player
            (AMobj.DoomedNum <> 9101) and           // Not player
            (AMobj.DoomedNum <> 9102) and           // Not player
            (AMobj.DoomedNum <> 9103) and           // Not player
            (AMobj.Flags and MF_SHOOTABLE <> 0) and // Shootable
            (AMobj.Flags and MF_COUNTKILL <> 0);    // Count kill or can attack
{$ELSE}
  Result := (AMobj.DoomedNum > MAXPLAYERS) and // Not player
            (AMobj.Flags and MF_SHOOTABLE <> 0) and  // Shootable
            ((AMobj.Flags and MF_COUNTKILL <> 0) or (AMobj.MissileState <> 0) or (AMobj.MeleeState <> 0));  // Count kill or can attack
{$ENDIF}
end;

function TEngineInfoRandomRules.IsValidThing(const ADoomedNum: Integer): Boolean;
begin
  Result := P_GameValidThing(ADoomedNum);
end;

function TEngineInfoRandomRules.DiscardCount: Integer;
begin
{$IFDEF HEXEN}
  Result := 0;
{$ELSE}
  Result := M_GetSystemRandomSeed;
{$ENDIF}
end;

end.

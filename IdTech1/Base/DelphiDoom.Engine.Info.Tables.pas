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

unit DelphiDoom.Engine.Info.Tables;

interface

uses
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.Types;

type
  /// <summary>
  ///   The tables of the game (mobjinfo[], states[], sprnames[]) as the library reads them:
  ///   the tables stay data, this class only looks at them
  /// </summary>
  TEngineInfoTables = class(TInterfacedObject, IInfoMobjSource, IInfoStateSource, IInfoSpriteSource)
  public
    // IInfoMobjSource
    function Count: Integer;
    function BuiltInCount: Integer;
    function Get(const AIndex: Integer): TInfoMobj;
    function Name(const AIndex: Integer): string;
    function DoomedNum(const AIndex: Integer): Integer;
    function InheritsFrom(const AIndex: Integer): Integer;
  strict private
    // IInfoStateSource and IInfoSpriteSource share the names of Count and Get with the first one:
    // the methods are resolved to the ones below
    function StateCount: Integer;
    function StateGet(const AIndex: Integer): TInfoState;
    function SpriteCount: Integer;
    function SpriteCode(const AIndex: Integer): Integer;
    function IInfoStateSource.Count = StateCount;
    function IInfoStateSource.Get = StateGet;
    function IInfoSpriteSource.Count = SpriteCount;
    function IInfoSpriteSource.Code = SpriteCode;
  public
    function IsOwnedBy(const AState, AMobj: Integer): Boolean;
  end;

implementation

uses
  info_h,
  info,
  info_common,
  p_pspr;

{ TEngineInfoTables }

function TEngineInfoTables.Count: Integer;
begin
  Result := nummobjtypes;
end;

function TEngineInfoTables.BuiltInCount: Integer;
begin
  Result := Ord(DO_NUMMOBJTYPES);
end;

function TEngineInfoTables.Get(const AIndex: Integer): TInfoMobj;
var
  LInfo: Pmobjinfo_t;
begin
  LInfo := @mobjinfo[AIndex];
  Result.Name := Info_GetMobjName(LInfo);
  Result.DoomedNum := LInfo.doomednum;
  Result.InheritsFrom := LInfo.inheritsfrom;
  Result.SpawnHealth := LInfo.spawnhealth;
  Result.Flags := LInfo.flags;
  Result.SpawnState := LInfo.spawnstate;
  Result.SeeState := LInfo.seestate;
  Result.PainState := LInfo.painstate;
  Result.MeleeState := LInfo.meleestate;
  Result.MissileState := LInfo.missilestate;
  Result.DeathState := LInfo.deathstate;
  Result.XDeathState := LInfo.xdeathstate;
  Result.RaiseState := LInfo.raisestate;
  Result.HealState := LInfo.healstate;
  Result.CrashState := LInfo.crashstate;
  Result.CrushState := LInfo.crushstate;
  Result.InteractState := LInfo.interactstate;
end;

function TEngineInfoTables.Name(const AIndex: Integer): string;
begin
  Result := Info_GetMobjName(AIndex);
end;

function TEngineInfoTables.DoomedNum(const AIndex: Integer): Integer;
begin
  Result := mobjinfo[AIndex].doomednum;
end;

function TEngineInfoTables.InheritsFrom(const AIndex: Integer): Integer;
begin
  Result := mobjinfo[AIndex].inheritsfrom;
end;

function TEngineInfoTables.StateCount: Integer;
begin
  Result := numstates;
end;

function TEngineInfoTables.StateGet(const AIndex: Integer): TInfoState;
begin
  Result.Sprite := states[AIndex].sprite;
  Result.Frame := states[AIndex].frame and FF_FRAMEMASK;
  Result.NextState := Ord(states[AIndex].nextstate);
  Result.Tics := states[AIndex].tics;
end;

function TEngineInfoTables.IsOwnedBy(const AState, AMobj: Integer): Boolean;
begin
  Result := (states[AState].owners <> nil) and (states[AState].owners.IndexOf(AMobj) >= 0);
end;

function TEngineInfoTables.SpriteCount: Integer;
begin
  Result := numsprites;
end;

function TEngineInfoTables.SpriteCode(const AIndex: Integer): Integer;
begin
  Result := sprnames[AIndex];
end;

end.

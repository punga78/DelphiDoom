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

unit DelphiDoom.Engine.Info.StateNames;

interface

uses
  DelphiDoom.Engine.Info.Intf,
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.StateNames,
  DelphiDoom.Info.Types,
  p_mobj_h;

type
  /// <summary>
  ///   The states that the actions name in a script (P_GetStateFromName and
  ///   P_GetStateFromNameWithOffsetCheck), for the actor of the game
  /// </summary>
  TEngineStateNames = class(TInterfacedObject, IEngineStateNames)
  strict private
    FTables: IInfoMobjSource;
    FNames: TInfoStateNames;
    function InfoOf(const AActor: Pmobj_t): TInfoMobj;
  public
    constructor Create(const ATables: IInfoMobjSource; const ATokens: IInfoStateTokens;
      const AThings: IInfoThingNames; const AText: IInfoStateText);
    destructor Destroy; override;
    function StateFromName(const AActor: Pmobj_t; const AText: string): Integer;
    function StateFromNameWithOffset(const AActor: Pmobj_t; const AText: string): Integer;
  end;

implementation

uses
  info_h,
  info;

{ TEngineStateNames }

constructor TEngineStateNames.Create(const ATables: IInfoMobjSource; const ATokens: IInfoStateTokens;
  const AThings: IInfoThingNames; const AText: IInfoStateText);
begin
  inherited Create;
  FTables := ATables;
  FNames := TInfoStateNames.Create(ATokens, ATables, AThings, AText);
end;

destructor TEngineStateNames.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

function TEngineStateNames.InfoOf(const AActor: Pmobj_t): TInfoMobj;
begin
  Result := FTables.Get((NativeInt(AActor.info) - NativeInt(@mobjinfo[0])) div SizeOf(mobjinfo_t));
end;

function TEngineStateNames.StateFromName(const AActor: Pmobj_t; const AText: string): Integer;
begin
  Result := FNames.StateFromName(InfoOf(AActor), AText);
end;

function TEngineStateNames.StateFromNameWithOffset(const AActor: Pmobj_t; const AText: string): Integer;
begin
  Result := FNames.StateFromNameWithOffset(InfoOf(AActor),
    (NativeInt(AActor.state) - NativeInt(states)) div SizeOf(state_t), AText);
end;

end.

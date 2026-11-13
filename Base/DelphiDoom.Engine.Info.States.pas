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

unit DelphiDoom.Engine.Info.States;

interface

uses
  DelphiDoom.Engine.Info.Intf,
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.SpriteStates,
  DelphiDoom.Info.StateWalker;

type
  /// <summary>The chains of states and the states of a sprite, on the tables of the game</summary>
  TEngineInfoStates = class(TInterfacedObject, IEngineInfoStates)
  strict private
    FWalker: TInfoStateWalker;
    FSprites: TInfoSpriteStates;
  public
    constructor Create(const AMobjs: IInfoMobjSource; const AStates: IInfoStateSource;
      const ASprites: IInfoSpriteSource);
    destructor Destroy; override;
    function StatesOfThing(const AMobj: Integer): TArray<Integer>;
    function StatesWithEndlessChain: TArray<Integer>;
    function StatesFromSprite(const ASprite: string): TArray<Integer>;
  end;

implementation

{ TEngineInfoStates }

constructor TEngineInfoStates.Create(const AMobjs: IInfoMobjSource; const AStates: IInfoStateSource;
  const ASprites: IInfoSpriteSource);
begin
  inherited Create;
  FWalker := TInfoStateWalker.Create(AMobjs, AStates);
  FSprites := TInfoSpriteStates.Create(ASprites, AStates);
end;

destructor TEngineInfoStates.Destroy;
begin
  FSprites.Free;
  FWalker.Free;
  inherited Destroy;
end;

function TEngineInfoStates.StatesOfThing(const AMobj: Integer): TArray<Integer>;
begin
  Result := FWalker.StatesOf(AMobj);
end;

function TEngineInfoStates.StatesWithEndlessChain: TArray<Integer>;
begin
  Result := FWalker.StatesWithEndlessChain;
end;

function TEngineInfoStates.StatesFromSprite(const ASprite: string): TArray<Integer>;
begin
  Result := FSprites.Find(ASprite);
end;

end.

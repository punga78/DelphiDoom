//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the states and the sprites for VOXELDEF
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.Voxel.DefinitionLookup;

interface

uses
  DelphiDoom.Voxel.Intf;

type
  /// <summary>The state names (statenames) and the states that use a sprite (info_fnd), as the game has them</summary>
  TEngineVoxelDefinitionLookup = class(TInterfacedObject, IVoxelDefinitionLookup)
  public
    function FindState(const AName: string): Integer;
    function FindStatesOfSprite(const ASpriteName: string): TArray<Integer>;
  end;

implementation

uses
  d_delphi,
  info_fnd,
  sc_states;

{ TEngineVoxelDefinitionLookup }

function TEngineVoxelDefinitionLookup.FindState(const AName: string): Integer;
begin
  Result := statenames.IndexOfToken(AName);
end;

function TEngineVoxelDefinitionLookup.FindStatesOfSprite(const ASpriteName: string): TArray<Integer>;
var
  LList: TDNumberList;
  LIndex: Integer;
begin
  LList := Info_FindStatesFromSprite(ASpriteName);
  try
    SetLength(Result, LList.Count);
    for LIndex := 0 to LList.Count - 1 do
      Result[LIndex] := LList.Numbers[LIndex];
  finally
    LList.Free;
  end;
end;

end.
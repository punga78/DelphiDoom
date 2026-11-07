//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the voxel manager as the sink of VOXELDEF
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

unit DelphiDoom.Engine.Voxel.DefinitionSink;

interface

uses
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>
  ///   Gives what the VOXELDEF parser finds to the voxel manager of vx_base (voxels, states and
  ///   the names of the sprites that a voxel replaces). The renderers keep the offset and the
  ///   scale as they have always done: fixed point in the software one (the offset in map
  ///   units), floats in OpenGL.
  /// </summary>
  TEngineVoxelDefinitionSink = class(TInterfacedObject, IVoxelDefinitionSink)
  public
    function AddVoxel(const AItem: TVoxelDefinitionItem): Integer;
    procedure AddState(const AState: TVoxelDefinitionState);
    procedure CheckSprite(const ASpriteName, AVoxelName: string);
  end;

implementation

uses
  {$IFNDEF OPENGL}
  m_fixed,
  r_softgl,
  {$ENDIF}
  vx_base;

{ TEngineVoxelDefinitionSink }

function TEngineVoxelDefinitionSink.AddVoxel(const AItem: TVoxelDefinitionItem): Integer;
var
  LItem: voxelmanageritem_t;
begin
  LItem.name := ShortString(AItem.Name);
  {$IFDEF OPENGL}
  LItem.offset := AItem.Offset;
  LItem.scale := AItem.Scale;
  {$ELSE}
  LItem.offset := FloatToFixed(MAP_COEFF * AItem.Offset);
  LItem.scale := FloatToFixed(AItem.Scale);
  {$ENDIF}
  LItem.angleoffset := AItem.AngleOffset;
  LItem.droppedspin := AItem.DroppedSpin;
  LItem.placedspin := AItem.PlacedSpin;
  LItem.flags := AItem.Flags;
  LItem.voxel := nil;
  Result := VX_AddVoxel(LItem);
end;

procedure TEngineVoxelDefinitionSink.AddState(const AState: TVoxelDefinitionState);
var
  LState: voxelstate_t;
begin
  LState.voxelidx := AState.VoxelIndex;
  LState.frame := AState.Frame;
  LState.state := AState.State;
  VX_AddVoxelState(LState);
end;

procedure TEngineVoxelDefinitionSink.CheckSprite(const ASpriteName, AVoxelName: string);
begin
  VX_CheckVoxelSprite(ASpriteName, AVoxelName);
end;

end.
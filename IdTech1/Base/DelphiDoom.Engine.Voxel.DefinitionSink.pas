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
  ///   the names of the sprites that a voxel replaces). A voxel that is not there yet is read by
  ///   the loader and becomes the model of the renderer (columns in the software one, a display
  ///   list in OpenGL). The renderers keep the offset and the scale as they have always done:
  ///   fixed point in the software one (the offset in map units), floats in OpenGL.
  /// </summary>
  TEngineVoxelDefinitionSink = class(TInterfacedObject, IVoxelDefinitionSink)
  strict private
    FLoader: IVoxelLoader;
    FCubes: IVoxelCubeBuilder;
  public
    constructor Create(const ALoader: IVoxelLoader; const ACubes: IVoxelCubeBuilder);
    function AddVoxel(const AItem: TVoxelDefinitionItem): Integer;
    procedure AddState(const AState: TVoxelDefinitionState);
    procedure CheckSprite(const ASpriteName, AVoxelName: string);
  end;

implementation

uses
  System.SysUtils,
  {$IFDEF OPENGL}
  gl_voxels,
  {$ELSE}
  m_fixed,
  r_softgl,
  r_voxels,
  {$ENDIF}
  vx_base;

{ TEngineVoxelDefinitionSink }

constructor TEngineVoxelDefinitionSink.Create(const ALoader: IVoxelLoader;
  const ACubes: IVoxelCubeBuilder);
begin
  inherited Create;
  if not Assigned(ALoader) then
    raise EArgumentNilException.Create('ALoader');
  if not Assigned(ACubes) then
    raise EArgumentNilException.Create('ACubes');
  FLoader := ALoader;
  FCubes := ACubes;
end;

function TEngineVoxelDefinitionSink.AddVoxel(const AItem: TVoxelDefinitionItem): Integer;
var
  LItem: voxelmanageritem_t;
begin
  LItem.name := ShortString(AItem.Name);
  Result := VX_FindVoxel(string(LItem.name));
  if Result >= 0 then
    Exit;

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
  // the name of the model is the one the manager keeps (64 characters at most)
  {$IFDEF OPENGL}
  LItem.voxel := TVoxelModel.Create(string(LItem.name), LItem.offset, LItem.scale, FLoader, FCubes);
  {$ELSE}
  LItem.voxel := TVoxelModel.Create(string(LItem.name), LItem.offset, LItem.scale, LItem.flags,
    FLoader, FCubes);
  {$ENDIF}
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

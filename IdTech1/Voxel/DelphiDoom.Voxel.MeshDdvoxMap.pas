{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the axes of a DDVOX or VOX mesh                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.MeshDdvoxMap;

interface

uses
  DelphiDoom.Voxel.MeshTypes,
  DelphiDoom.Voxel.MeshRenderer.Intf;

type
  /// <summary>The vertexes of a cube are in cells: they are scaled by AStep and centered on the middle point</summary>
  TVoxelMeshDdvoxMap = class(TInterfacedObject, IVoxelMeshVertexMap)
  strict private
    FMidX: Single;
    FMidY: Single;
    FMidZ: Single;
    FStep: Single;
  public
    constructor Create(const AMidX, AMidY, AMidZ, AStep: Single);
    procedure Map(const AVertex: TVoxelMeshVertex; out AX, AY, AZ: Single);
  end;

implementation

constructor TVoxelMeshDdvoxMap.Create(const AMidX, AMidY, AMidZ, AStep: Single);
begin
  inherited Create;
  FMidX := AMidX;
  FMidY := AMidY;
  FMidZ := AMidZ;
  FStep := AStep;
end;

procedure TVoxelMeshDdvoxMap.Map(const AVertex: TVoxelMeshVertex; out AX, AY, AZ: Single);
begin
  AX := FMidX - AVertex.x * FStep;
  AY := AVertex.y * FStep - FMidY;
  AZ := AVertex.z * FStep - FMidZ;
end;

end.

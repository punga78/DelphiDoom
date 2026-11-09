{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the axes of a KVX mesh                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.MeshKvxMap;

interface

uses
  DelphiDoom.Voxel.MeshTypes,
  DelphiDoom.Voxel.MeshRenderer.Intf;

type
  /// <summary>The vertexes of a KVX model are already scaled: (x, z, -y)</summary>
  TVoxelMeshKvxMap = class(TInterfacedObject, IVoxelMeshVertexMap)
  public
    procedure Map(const AVertex: TVoxelMeshVertex; out AX, AY, AZ: Single);
  end;

implementation

procedure TVoxelMeshKvxMap.Map(const AVertex: TVoxelMeshVertex; out AX, AY, AZ: Single);
begin
  AX := AVertex.x;
  AY := AVertex.z;
  AZ := -AVertex.y;
end;

end.

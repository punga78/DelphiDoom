{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the DDMESH format (binary)                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Format.Ddmesh;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>
  ///   A DDMESH file has the faces of a reduced mesh (for OpenGL) and then the voxels: the magic
  ///   DDMS, the version (1), the side of the cube, the number of quads, the quads, the number
  ///   of voxels and the voxels (x, y, z and the color). The software renderer uses the voxels,
  ///   OpenGL the quads; the model keeps both.
  /// </summary>
  TVoxelDdmeshFormat = class(TInterfacedObject, IVoxelFormat)
  public
    function Handles(const AExtension: string): Boolean;
    function Locate(const ASource: IVoxelFileSource; const AName: string; out ABytes: TBytes): Boolean;
    function Decode(const ABytes: TBytes): IVoxelModel;
  end;

implementation

uses
  DelphiDoom.Voxel.ByteReader,
  DelphiDoom.Voxel.Colors,
  DelphiDoom.Voxel.Model;

{ TVoxelDdmeshFormat }

function TVoxelDdmeshFormat.Handles(const AExtension: string): Boolean;
begin
  Result := AExtension = '.DDMESH';
end;

function TVoxelDdmeshFormat.Locate(const ASource: IVoxelFileSource; const AName: string;
  out ABytes: TBytes): Boolean;
begin
  Result := ASource.TryReadFile(AName, ABytes);
end;

function TVoxelDdmeshFormat.Decode(const ABytes: TBytes): IVoxelModel;
var
  LReader: TVoxelByteReader;
  LVersion: Integer;
  LSide: Integer;
  LQuadCount: Integer;
  LVoxelCount: Integer;
  LQuads: TArray<TVoxelQuad>;
  LCells: TArray<Cardinal>;
  LQuadIndex, LCorner: Integer;
  LX, LY, LZ: Integer;
  LVoxelIndex: Integer;
begin
  LReader := TVoxelByteReader.Create(ABytes);
  try
    if LReader.ReadCardinal <> DDMESH_MAGIC then
      raise EVoxelException.Create(SVoxelDdmeshMagic);
    LVersion := LReader.ReadInteger;
    if LVersion <> DDMESH_VERSION then
      raise EVoxelException.CreateFmt(SVoxelDdmeshVersion, [LVersion]);
    LSide := LReader.ReadInteger;
    LQuadCount := LReader.ReadInteger;
    if (LSide < 1) or (LSide > VOXEL_MAX_SIZE) or (LQuadCount < 0) or
      (Int64(LQuadCount) * DDMESH_QUAD_SIZE + DDMESH_HEADER_SIZE + 4 > Length(ABytes)) then
      raise EVoxelException.CreateFmt(SVoxelDdmeshCounts, [LSide, LQuadCount, -1]);

    SetLength(LQuads, LQuadCount);
    for LQuadIndex := 0 to LQuadCount - 1 do
    begin
      LQuads[LQuadIndex].Color := TVoxelColors.SwapRgb(LReader.ReadCardinal);
      for LCorner := 0 to 3 do
      begin
        LQuads[LQuadIndex].Vertexes[LCorner].X := LReader.ReadInteger;
        LQuads[LQuadIndex].Vertexes[LCorner].Y := LReader.ReadInteger;
        LQuads[LQuadIndex].Vertexes[LCorner].Z := LReader.ReadInteger;
      end;
    end;

    LVoxelCount := LReader.ReadInteger;
    if (LVoxelCount < 0) or (Int64(LVoxelCount) * DDMESH_VOXEL_SIZE > LReader.Remaining) then
      raise EVoxelException.CreateFmt(SVoxelDdmeshCounts, [LSide, LQuadCount, LVoxelCount]);

    SetLength(LCells, LSide * LSide * LSide);
    for LVoxelIndex := 0 to LVoxelCount - 1 do
    begin
      LX := LReader.ReadByte;
      LY := LReader.ReadByte;
      LZ := LReader.ReadByte;
      // a voxel outside the cube is never seen
      if (LX < LSide) and (LY < LSide) and (LZ < LSide) then
        LCells[(LX * LSide + LY) * LSide + LZ] := TVoxelColors.SwapRgb(LReader.ReadCardinal)
      else
        LReader.ReadCardinal;
    end;
  finally
    LReader.Free;
  end;

  Result := TVoxelModel.Create(vfDdmesh, LSide, LSide, LSide, 0, 0, 0, LCells, LQuads);
end;

end.

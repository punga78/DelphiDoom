{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the import of a DDMESH file                       }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Format.Ddmesh;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   Reads the voxels of a DDMESH file back into a cube (DoLoadDDMESH): the quads are skipped, the voxels that are
  ///   listed after them are the cube. The voxels that were buried when the mesh was made are not there
  /// </summary>
  TVoxelEditorDdmeshFormat = class sealed
  public
    /// <summary>
    ///   Reads the file into the model. A wrong magic number or version, a voxel outside the cube and a list
    ///   that goes beyond the file are an EVoxelEditorException (the old loader wrote outside its buffer)
    /// </summary>
    class procedure Read(const ABytes: TBytes; const AModel: TVoxelEditorModel); static;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.ByteReader;

const
  /// <summary>A quad in the file: its color and four vertices of three integers</summary>
  QUAD_BYTES = 4 + 4 * 12;
  HEADER_BYTES = 16;

{ TVoxelEditorDdmeshFormat }

class procedure TVoxelEditorDdmeshFormat.Read(const ABytes: TBytes; const AModel: TVoxelEditorModel);
var
  LReader: TVoxelEditorByteReader;
  LSize, LQuads, LCount, LIndex, LX, LY, LZ: Integer;
  LVersion: Integer;
begin
  LReader := TVoxelEditorByteReader.Create(ABytes);
  try
    if LReader.ReadCardinal <> VOXEL_EDITOR_DDMESH_MAGIC then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [Format(SVoxelEditorNoDdmeshMagic, [''])]);
    LVersion := LReader.ReadInteger;
    if LVersion <> VOXEL_EDITOR_DDMESH_VERSION then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [Format(SVoxelEditorBadVersion, ['', LVersion])]);
    LSize := LReader.ReadInteger;
    AModel.Reset(LSize);
    LQuads := LReader.ReadInteger;
    if LQuads < 0 then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, ['quads']);
    LReader.Seek(HEADER_BYTES + LQuads * QUAD_BYTES);
    LCount := LReader.ReadInteger;
    for LIndex := 0 to LCount - 1 do
    begin
      LX := LReader.ReadByte;
      LY := LReader.ReadByte;
      LZ := LReader.ReadByte;
      if (LX >= LSize) or (LY >= LSize) or (LZ >= LSize) then
        raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, ['a voxel is outside the cube']);
      AModel.Put(LX, LY, LZ, LReader.ReadCardinal);
    end;
  finally
    LReader.Free;
  end;
end;

end.

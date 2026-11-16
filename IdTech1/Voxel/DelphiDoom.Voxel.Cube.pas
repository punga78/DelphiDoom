{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - a cube of voxels                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Cube;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>The cells of a cube: the index of a cell is (X * Size + Y) * Size + Z</summary>
  TVoxelCube = class(TInterfacedObject, IVoxelCube)
  strict private
    FSize: Integer;
    FCells: TArray<Cardinal>;
    function GetSize: Integer;
    function GetCells: TArray<Cardinal>;
  public
    /// <summary>ASize is the side; the cells are all empty and the caller fills them through Cells</summary>
    constructor Create(const ASize: Integer);
    function Cell(const AX, AY, AZ: Integer): Cardinal;
    property Size: Integer read GetSize;
    property Cells: TArray<Cardinal> read GetCells;
  end;

implementation

{ TVoxelCube }

constructor TVoxelCube.Create(const ASize: Integer);
begin
  inherited Create;
  FSize := ASize;
  SetLength(FCells, ASize * ASize * ASize);
end;

function TVoxelCube.Cell(const AX, AY, AZ: Integer): Cardinal;
begin
  if (AX < 0) or (AX >= FSize) or (AY < 0) or (AY >= FSize) or (AZ < 0) or (AZ >= FSize) then
    Exit(0);
  Result := FCells[(AX * FSize + AY) * FSize + AZ];
end;

function TVoxelCube.GetSize: Integer;
begin
  Result := FSize;
end;

function TVoxelCube.GetCells: TArray<Cardinal>;
begin
  Result := FCells;
end;

end.

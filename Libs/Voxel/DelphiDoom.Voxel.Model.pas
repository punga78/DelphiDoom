{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - a voxel model                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Model;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>The voxels and the pivot that a reader found in a file</summary>
  TVoxelModel = class(TInterfacedObject, IVoxelModel)
  strict private
    FFormat: TVoxelFormatKind;
    FSizeX: Integer;
    FSizeY: Integer;
    FSizeZ: Integer;
    FPivotX: Integer;
    FPivotY: Integer;
    FPivotZ: Integer;
    FCells: TArray<Cardinal>;
    FQuads: TArray<TVoxelQuad>;
    function GetFormat: TVoxelFormatKind;
    function GetSizeX: Integer;
    function GetSizeY: Integer;
    function GetSizeZ: Integer;
    function GetPivotX: Integer;
    function GetPivotY: Integer;
    function GetPivotZ: Integer;
    function GetCells: TArray<Cardinal>;
    function GetQuadCount: Integer;
  public
    /// <summary>ACells must have SizeX * SizeY * SizeZ items; EVoxelException if not</summary>
    constructor Create(const AFormat: TVoxelFormatKind; const ASizeX, ASizeY, ASizeZ: Integer;
      const APivotX, APivotY, APivotZ: Integer; const ACells: TArray<Cardinal>;
      const AQuads: TArray<TVoxelQuad>);
    function Cell(const AX, AY, AZ: Integer): Cardinal;
    function Quad(const AIndex: Integer): TVoxelQuad;
  end;

implementation

{ TVoxelModel }

constructor TVoxelModel.Create(const AFormat: TVoxelFormatKind; const ASizeX, ASizeY, ASizeZ: Integer;
  const APivotX, APivotY, APivotZ: Integer; const ACells: TArray<Cardinal>;
  const AQuads: TArray<TVoxelQuad>);
begin
  inherited Create;
  if Length(ACells) <> ASizeX * ASizeY * ASizeZ then
    raise EVoxelException.CreateFmt(SVoxelInvalidModel, [ASizeX * ASizeY * ASizeZ, Length(ACells)]);
  FFormat := AFormat;
  FSizeX := ASizeX;
  FSizeY := ASizeY;
  FSizeZ := ASizeZ;
  FPivotX := APivotX;
  FPivotY := APivotY;
  FPivotZ := APivotZ;
  FCells := ACells;
  FQuads := AQuads;
end;

function TVoxelModel.Cell(const AX, AY, AZ: Integer): Cardinal;
begin
  if (AX < 0) or (AX >= FSizeX) or (AY < 0) or (AY >= FSizeY) or (AZ < 0) or (AZ >= FSizeZ) then
    Exit(0);
  Result := FCells[(AX * FSizeY + AY) * FSizeZ + AZ];
end;

function TVoxelModel.Quad(const AIndex: Integer): TVoxelQuad;
begin
  Result := FQuads[AIndex];
end;

function TVoxelModel.GetFormat: TVoxelFormatKind;
begin
  Result := FFormat;
end;

function TVoxelModel.GetSizeX: Integer;
begin
  Result := FSizeX;
end;

function TVoxelModel.GetSizeY: Integer;
begin
  Result := FSizeY;
end;

function TVoxelModel.GetSizeZ: Integer;
begin
  Result := FSizeZ;
end;

function TVoxelModel.GetPivotX: Integer;
begin
  Result := FPivotX;
end;

function TVoxelModel.GetPivotY: Integer;
begin
  Result := FPivotY;
end;

function TVoxelModel.GetPivotZ: Integer;
begin
  Result := FPivotZ;
end;

function TVoxelModel.GetCells: TArray<Cardinal>;
begin
  Result := FCells;
end;

function TVoxelModel.GetQuadCount: Integer;
begin
  Result := Length(FQuads);
end;

end.

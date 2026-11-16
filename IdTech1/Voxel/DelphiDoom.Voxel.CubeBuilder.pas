{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - from a model to a cube                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.CubeBuilder;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf,
  DelphiDoom.Voxel.Cube;

type
  /// <summary>
  ///   The placement that the three old loaders did each in its own way. A DDVOX or DDMESH
  ///   model is already a cube. A KVX model goes in a cube a bit bigger than its biggest side,
  ///   with its pivot in the middle (x and y) and its foot on the floor (z); the sprites want an
  ///   even side and take the pivot as it is. A VOX model (Slab6) is centered. In a cube the
  ///   old axes are swapped as the renderers want them: the cell (x, y, z) of the file is
  ///   (x, z, side - y - 1) of the cube. A voxel that would be outside the cube is lost (the old
  ///   code wrote it somewhere else in memory).
  /// </summary>
  TVoxelCubeBuilder = class(TInterfacedObject, IVoxelCubeBuilder)
  strict private
    class function BiggestSide(const AModel: IVoxelModel): Integer; static;
    class procedure Place(const ACube: TVoxelCube; const AModel: IVoxelModel;
      const AFirstX, AFirstY, AFirstZ: Integer); static;
    class function BuildDirect(const AModel: IVoxelModel): IVoxelCube; static;
    class function BuildKvx(const AModel: IVoxelModel; const AFit: TVoxelCubeFit): IVoxelCube; static;
    class function BuildSlab6(const AModel: IVoxelModel): IVoxelCube; static;
  public
    function Build(const AModel: IVoxelModel; const AFit: TVoxelCubeFit): IVoxelCube;
  end;

implementation

{ TVoxelCubeBuilder }

class function TVoxelCubeBuilder.BiggestSide(const AModel: IVoxelModel): Integer;
begin
  Result := AModel.SizeX;
  if Result < AModel.SizeY then
    Result := AModel.SizeY;
  if Result < AModel.SizeZ then
    Result := AModel.SizeZ;
end;

class procedure TVoxelCubeBuilder.Place(const ACube: TVoxelCube; const AModel: IVoxelModel;
  const AFirstX, AFirstY, AFirstZ: Integer);
var
  LCells: TArray<Cardinal>;
  LSide: Integer;
  LX, LY, LZ: Integer;
  LCubeX, LCubeY, LCubeZ: Integer;
  LColor: Cardinal;
begin
  LCells := ACube.Cells;
  LSide := ACube.Size;
  for LX := 0 to AModel.SizeX - 1 do
    for LY := 0 to AModel.SizeY - 1 do
      for LZ := 0 to AModel.SizeZ - 1 do
      begin
        LColor := AModel.Cell(LX, LY, LZ);
        if LColor = 0 then
          Continue;
        LCubeX := AFirstX + LX;
        LCubeY := AFirstZ + LZ;
        LCubeZ := LSide - (AFirstY + LY) - 1;
        if (LCubeX < 0) or (LCubeX >= LSide) or (LCubeY < 0) or (LCubeY >= LSide) or
          (LCubeZ < 0) or (LCubeZ >= LSide) then
          Continue;
        LCells[(LCubeX * LSide + LCubeY) * LSide + LCubeZ] := LColor;
      end;
end;

class function TVoxelCubeBuilder.BuildDirect(const AModel: IVoxelModel): IVoxelCube;
var
  LCube: TVoxelCube;
  LCells: TArray<Cardinal>;
  LX, LY, LZ: Integer;
  LSide: Integer;
begin
  LSide := BiggestSide(AModel);
  LCube := TVoxelCube.Create(LSide);
  Result := LCube;
  LCells := LCube.Cells;
  for LX := 0 to AModel.SizeX - 1 do
    for LY := 0 to AModel.SizeY - 1 do
      for LZ := 0 to AModel.SizeZ - 1 do
        LCells[(LX * LSide + LY) * LSide + LZ] := AModel.Cell(LX, LY, LZ);
end;

class function TVoxelCubeBuilder.BuildKvx(const AModel: IVoxelModel;
  const AFit: TVoxelCubeFit): IVoxelCube;
var
  LCube: TVoxelCube;
  LSide: Integer;
  LFirstX, LFirstY, LFirstZ: Integer;
begin
  LSide := BiggestSide(AModel);
  if AFit = cfSprite then
  begin
    if LSide < VOXEL_MAX_SIZE then
    begin
      Inc(LSide, 2);
      LSide := LSide and not 1;
    end;
  end
  else if LSide < VOXEL_MAX_SIZE then
    Inc(LSide);

  LFirstX := LSide div 2 - AModel.PivotX div KVX_PIVOT_UNIT;
  LFirstY := LSide div 2 - AModel.PivotY div KVX_PIVOT_UNIT;
  LFirstZ := LSide - AModel.PivotZ div KVX_PIVOT_UNIT; // align down
  if AFit = cfRenderer then
  begin
    // the renderers keep the model inside the cube; the sprites never did
    if LFirstX < 0 then
      LFirstX := 0;
    if LFirstY < 0 then
      LFirstY := 0;
    if LFirstZ < 0 then
      LFirstZ := 0;
    while LFirstX + AModel.SizeX >= LSide do
      Dec(LFirstX);
    while LFirstY + AModel.SizeY >= LSide do
      Dec(LFirstY);
    while LFirstZ + AModel.SizeZ >= LSide do
      Dec(LFirstZ);
  end;

  LCube := TVoxelCube.Create(LSide);
  Result := LCube;
  Place(LCube, AModel, LFirstX, LFirstY, LFirstZ);
end;

class function TVoxelCubeBuilder.BuildSlab6(const AModel: IVoxelModel): IVoxelCube;
var
  LCube: TVoxelCube;
  LSide: Integer;
begin
  LSide := BiggestSide(AModel);
  LCube := TVoxelCube.Create(LSide);
  Result := LCube;
  Place(LCube, AModel, (LSide - AModel.SizeX) div 2, (LSide - AModel.SizeY) div 2,
    (LSide - AModel.SizeZ) div 2);
end;

function TVoxelCubeBuilder.Build(const AModel: IVoxelModel; const AFit: TVoxelCubeFit): IVoxelCube;
begin
  if not Assigned(AModel) then
    raise EArgumentNilException.Create('AModel');
  case AModel.Format of
    vfDdvox, vfDdmesh:
      Result := BuildDirect(AModel);
    vfKvx:
      Result := BuildKvx(AModel, AFit);
  else
    Result := BuildSlab6(AModel);
  end;
end;

end.

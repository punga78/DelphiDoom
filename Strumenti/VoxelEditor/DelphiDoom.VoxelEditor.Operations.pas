{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the operations on the whole cube                  }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Operations;

interface

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   What DD_VOXEL did to the whole cube: removing the voxels that cannot be seen, cropping and shrinking the
  ///   height (the y axis), the gray scale, the count of the colors, the reduction to a palette, a terrain texture
  ///   and the cube of a heightmap. No window, no thread: the old code split the first one in two threads and
  ///   gave the same result
  /// </summary>
  TVoxelEditorOperations = class sealed
  public
    /// <summary>A voxel that has a voxel on each of its six sides, inside the cube, is emptied (the outer cells never are)</summary>
    class procedure RemoveNonVisible(const AModel: TVoxelEditorModel); static;
    /// <summary>
    ///   Cuts the cube at the heights AMin and AMax (0..255, scaled to the size of the cube): what is above and
    ///   below is emptied, and the two cut planes take the first voxel of each column that was cut away. The
    ///   full range does nothing
    /// </summary>
    class procedure CropHeight(const AModel: TVoxelEditorModel; AMin, AMax: Integer); static;
    /// <summary>Squeezes the cube between the heights AMin and AMax (0..255); the full range does nothing</summary>
    class procedure ShrinkHeight(const AModel: TVoxelEditorModel; AMin, AMax: Integer); static;
    /// <summary>
    ///   Each color becomes the gray of its red channel (the old command took the red for the three channels, a
    ///   defect that is kept); a color that would be black becomes 1. True if any voxel changed
    /// </summary>
    class function ToGrayScale(const AModel: TVoxelEditorModel): Boolean; static;
    class function CountColors(const AModel: TVoxelEditorModel): Integer; static;
    /// <summary>Each color becomes the nearest of the palette (0 would be "no voxel", it becomes 1); true if anything changed</summary>
    class function ApplyPalette(const AModel: TVoxelEditorModel; const APalette: TVoxelEditorPalette): Boolean; static;
    /// <summary>
    ///   Each column of voxels gets the color of the picture at its place (x, z): AImage is the picture, size x
    ///   size, indexed [x * size + z]
    /// </summary>
    class procedure ApplyTerrainTexture(const AModel: TVoxelEditorModel; const AImage: TVoxelEditorImage); static;
    /// <summary>
    ///   The cube of a heightmap: the picture (indexed [x * size + z], gray by the mean of its channels) is the
    ///   height of each column, 0..255 scaled to the size of the cube; the color is the gray; the cube is emptied
    ///   first and the voxels that cannot be seen are removed after
    /// </summary>
    class procedure BuildHeightmap(const AModel: TVoxelEditorModel; const AImage: TVoxelEditorImage); static;
    /// <summary>The size of the cube for a picture of this size: the next power of two, 256 at most</summary>
    class function HeightmapSize(AWidth, AHeight: Integer): Integer; static;
    /// <summary>The gray of a color: the mean of its channels, rounded</summary>
    class function Gray256(AColor: Cardinal): Integer; static;
  end;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  DelphiDoom.VoxelEditor.Palettes;

function ClampByte(AValue: Integer): Integer; inline;
begin
  if AValue < 0 then
    Result := 0
  else if AValue > 255 then
    Result := 255
  else
    Result := AValue;
end;

{ TVoxelEditorOperations }

class procedure TVoxelEditorOperations.RemoveNonVisible(const AModel: TVoxelEditorModel);
var
  LSize, LX, LY, LZ, LIndex, LStrideX, LStrideY: Integer;
  LFlags: TArray<Boolean>;
  LCells: TArray<Cardinal>;
begin
  LSize := AModel.Size;
  LCells := AModel.Cells;
  SetLength(LFlags, Length(LCells));
  LStrideX := LSize * LSize;
  LStrideY := LSize;
  for LX := 1 to LSize - 2 do
    for LY := 1 to LSize - 2 do
      for LZ := 1 to LSize - 2 do
      begin
        LIndex := LX * LStrideX + LY * LStrideY + LZ;
        if (LCells[LIndex] <> 0) and (LCells[LIndex - LStrideX] <> 0) and (LCells[LIndex + LStrideX] <> 0) and
          (LCells[LIndex - LStrideY] <> 0) and (LCells[LIndex + LStrideY] <> 0) and
          (LCells[LIndex - 1] <> 0) and (LCells[LIndex + 1] <> 0) then
          LFlags[LIndex] := True;
      end;
  for LIndex := 0 to High(LCells) do
    if LFlags[LIndex] then
      LCells[LIndex] := 0;
end;

class procedure TVoxelEditorOperations.CropHeight(const AModel: TVoxelEditorModel; AMin, AMax: Integer);
var
  LSize, LMin, LMax, LTemp, LX, LY, LZ: Integer;
  LTop, LBottom: TArray<Cardinal>;
  LColor: Cardinal;
begin
  if (AMin = 0) and (AMax = 255) then
    Exit;
  if (AMax = 0) and (AMin = 255) then
    Exit;
  LSize := AModel.Size;
  SetLength(LTop, LSize * LSize);
  SetLength(LBottom, LSize * LSize);
  if LSize = VOXEL_EDITOR_MAX_SIZE then
  begin
    LMin := AMin;
    LMax := AMax;
  end
  else
  begin
    LMin := Round(AMin * LSize / VOXEL_EDITOR_MAX_SIZE);
    LMax := Round(AMax * LSize / VOXEL_EDITOR_MAX_SIZE);
  end;
  LMin := EnsureRange(LMin, 0, LSize - 1);
  LMax := EnsureRange(LMax, 0, LSize - 1);
  if LMin > LMax then
  begin
    LTemp := LMin;
    LMin := LMax;
    LMax := LTemp;
  end;
  for LX := 0 to LSize - 1 do
    for LZ := 0 to LSize - 1 do
    begin
      LColor := 0;
      for LY := 0 to LMin do
        if AModel.Get(LX, LY, LZ) <> 0 then
        begin
          LColor := AModel.Get(LX, LY, LZ);
          Break;
        end;
      LTop[LX * LSize + LZ] := LColor;
      LColor := 0;
      for LY := LSize - 1 downto LMax do
        if AModel.Get(LX, LY, LZ) <> 0 then
        begin
          LColor := AModel.Get(LX, LY, LZ);
          Break;
        end;
      LBottom[LX * LSize + LZ] := LColor;
    end;
  for LX := 0 to LSize - 1 do
    for LZ := 0 to LSize - 1 do
    begin
      for LY := 0 to LMin - 1 do
        AModel.Put(LX, LY, LZ, 0);
      for LY := LMax + 1 to LSize - 1 do
        AModel.Put(LX, LY, LZ, 0);
      AModel.Put(LX, LMin, LZ, LTop[LX * LSize + LZ]);
      AModel.Put(LX, LMax, LZ, LBottom[LX * LSize + LZ]);
    end;
end;

class procedure TVoxelEditorOperations.ShrinkHeight(const AModel: TVoxelEditorModel; AMin, AMax: Integer);
var
  LSize, LMin, LMax, LTemp, LX, LY, LZ, LTarget: Integer;
  LBackup: TArray<Cardinal>;
  LFactor, LOffset: Extended;
begin
  if (AMin = 0) and (AMax = 255) then
    Exit;
  if (AMax = 0) and (AMin = 255) then
    Exit;
  LSize := AModel.Size;
  LBackup := Copy(AModel.Cells);
  LMin := ClampByte(AMin);
  LMax := ClampByte(AMax);
  if LMin > LMax then
  begin
    LTemp := LMin;
    LMin := LMax;
    LMax := LTemp;
  end;
  AModel.Clear;
  LFactor := (LMax - LMin) / VOXEL_EDITOR_MAX_SIZE;
  if LSize = VOXEL_EDITOR_MAX_SIZE then
    LOffset := LMin
  else
    LOffset := LMin * LSize / VOXEL_EDITOR_MAX_SIZE;
  for LX := 0 to LSize - 1 do
    for LZ := 0 to LSize - 1 do
      for LY := 0 to LSize - 1 do
      begin
        // the old code let the target reach the size of the cube, one past the last cell: it stops at the last
        LTarget := EnsureRange(Round(LOffset + LY * LFactor), 0, LSize - 1);
        if AModel.Get(LX, LTarget, LZ) = 0 then
          AModel.Put(LX, LTarget, LZ, LBackup[(LX * LSize + LY) * LSize + LZ]);
      end;
end;

class function TVoxelEditorOperations.ToGrayScale(const AModel: TVoxelEditorModel): Boolean;
var
  LIndex, LGrey, LRed, LGreen, LBlue: Integer;
  LColor, LNew: Cardinal;
  LCells: TArray<Cardinal>;
begin
  Result := False;
  LCells := AModel.Cells;
  for LIndex := 0 to High(LCells) do
  begin
    LColor := LCells[LIndex];
    if LColor <> 0 then
    begin
      LRed := LColor and $FF;
      LGreen := LRed; // defect of the original: the red channel is used for the three
      LBlue := LRed;
      LGrey := EnsureRange(Round(0.3 * LRed + 0.59 * LGreen + 0.11 * LBlue), 0, 255);
      if LGrey = 0 then
        LGrey := 1;
      LNew := TVoxelEditorPalettes.Rgb(LGrey, LGrey, LGrey);
      if LNew <> LColor then
      begin
        LCells[LIndex] := LNew;
        Result := True;
      end;
    end;
  end;
end;

class function TVoxelEditorOperations.CountColors(const AModel: TVoxelEditorModel): Integer;
var
  LIndex: Integer;
  LSeen: TDictionary<Cardinal, Boolean>;
begin
  LSeen := TDictionary<Cardinal, Boolean>.Create;
  try
    for LIndex := 0 to High(AModel.Cells) do
      if AModel.Cells[LIndex] <> 0 then
        LSeen.AddOrSetValue(AModel.Cells[LIndex], True);
    Result := LSeen.Count;
  finally
    LSeen.Free;
  end;
end;

class function TVoxelEditorOperations.ApplyPalette(const AModel: TVoxelEditorModel;
  const APalette: TVoxelEditorPalette): Boolean;
var
  LIndex: Integer;
  LColor, LNew: Cardinal;
  LCells: TArray<Cardinal>;
begin
  Result := False;
  LCells := AModel.Cells;
  for LIndex := 0 to High(LCells) do
  begin
    LColor := LCells[LIndex];
    if LColor <> 0 then
    begin
      LNew := APalette[TVoxelEditorPalettes.FindApproximateIndex(APalette, LColor, 0, 255)];
      if LNew = 0 then
        LNew := VOXEL_EDITOR_NEAR_BLACK;
      if LNew <> LColor then
      begin
        LCells[LIndex] := LNew;
        Result := True;
      end;
    end;
  end;
end;

class procedure TVoxelEditorOperations.ApplyTerrainTexture(const AModel: TVoxelEditorModel;
  const AImage: TVoxelEditorImage);
var
  LSize, LX, LY, LZ: Integer;
  LColor: Cardinal;
begin
  LSize := AModel.Size;
  for LX := 0 to LSize - 1 do
    for LZ := 0 to LSize - 1 do
      for LY := 0 to LSize - 1 do
        if AModel.Get(LX, LY, LZ) <> 0 then
        begin
          LColor := AImage[LX * LSize + LZ] and $FFFFFF;
          if LColor = 0 then
            LColor := VOXEL_EDITOR_NEAR_BLACK;
          AModel.Put(LX, LY, LZ, LColor);
        end;
end;

class function TVoxelEditorOperations.Gray256(AColor: Cardinal): Integer;
begin
  Result := EnsureRange(Round(((AColor and $FF) + ((AColor shr 8) and $FF) + ((AColor shr 16) and $FF)) / 3), 0, 255);
end;

class procedure TVoxelEditorOperations.BuildHeightmap(const AModel: TVoxelEditorModel; const AImage: TVoxelEditorImage);
var
  LSize, LX, LZ, LK, LGray, LHeight: Integer;
  LScale: Extended;
  LColor: Cardinal;
begin
  LSize := AModel.Size;
  AModel.Clear;
  LScale := LSize / VOXEL_EDITOR_MAX_SIZE;
  for LX := 0 to LSize - 1 do
    for LZ := 0 to LSize - 1 do
    begin
      LGray := Gray256(AImage[LX * LSize + LZ]);
      if LSize = VOXEL_EDITOR_MAX_SIZE then
        LHeight := LGray
      else
        LHeight := EnsureRange(Round(LGray * LScale), 0, LSize - 1);
      LColor := TVoxelEditorPalettes.Rgb(LGray, LGray, LGray);
      if LColor = 0 then
        LColor := VOXEL_EDITOR_NEAR_BLACK;
      for LK := 0 to LHeight do
        AModel.Put(LX, LSize - LK - 1, LZ, LColor);
    end;
  RemoveNonVisible(AModel);
end;

class function TVoxelEditorOperations.HeightmapSize(AWidth, AHeight: Integer): Integer;
begin
  Result := 1;
  while AWidth > Result do
    Result := Result * 2;
  while AHeight > Result do
    Result := Result * 2;
  if Result > VOXEL_EDITOR_MAX_SIZE then
    Result := VOXEL_EDITOR_MAX_SIZE;
end;

end.

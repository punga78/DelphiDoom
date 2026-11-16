{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the Slab6 VOX file                                }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Format.Vox;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   The VOX file of Slab6: three integers (the sides), the colors as indexes of a palette (255 is "empty") and
  ///   the 768 bytes of the palette (DoLoadVOX and VXE_ExportVoxelToSlab6VOX of DD_VOXEL)
  /// </summary>
  TVoxelEditorVoxFormat = class sealed
  public
    /// <summary>
    ///   Reads the file into the model: the cube has the largest side and the voxel is put at its middle, the axes
    ///   turned as the editor wants them. Sides outside 1..256, or less data than the sides say, are an
    ///   EVoxelEditorException
    /// </summary>
    class procedure Read(const ABytes: TBytes; const AModel: TVoxelEditorModel); static;
    /// <summary>
    ///   The file of a cube: a cube of 256 loses its first row of cells on each axis (the format holds up to 255);
    ///   the colors are reduced to 255 by the octree if there are more, and the palette of Doom is used if that does
    ///   not work
    /// </summary>
    class function Write(const AModel: TVoxelEditorModel): TBytes; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.ByteReader,
  DelphiDoom.VoxelEditor.Format.SlabPalette,
  DelphiDoom.VoxelEditor.Palettes,
  DelphiDoom.VoxelEditor.Quantizer,
  DelphiDoom.Palette.GamePalettes;

const
  EMPTY_INDEX = 255;

{ TVoxelEditorVoxFormat }

class procedure TVoxelEditorVoxFormat.Read(const ABytes: TBytes; const AModel: TVoxelEditorModel);
var
  LReader: TVoxelEditorByteReader;
  LPalette: TVoxelEditorPalette;
  LXSize, LYSize, LZSize, LSize, LX, LY, LZ, LX1, LY1, LZ1, LIndex: Integer;
begin
  LPalette := TVoxelEditorSlabPalette.Read(ABytes);
  LReader := TVoxelEditorByteReader.Create(ABytes);
  try
    LXSize := LReader.ReadInteger;
    LYSize := LReader.ReadInteger;
    LZSize := LReader.ReadInteger;
    if (LXSize <= 0) or (LXSize > VOXEL_EDITOR_MAX_SIZE) or (LYSize <= 0) or (LYSize > VOXEL_EDITOR_MAX_SIZE) or
      (LZSize <= 0) or (LZSize > VOXEL_EDITOR_MAX_SIZE) then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadDimensions, ['', LXSize, LYSize, LZSize]);
    if 12 + LXSize * LYSize * LZSize > Length(ABytes) - 768 then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, ['the data is shorter than the sides']);
    LSize := Max(LXSize, Max(LYSize, LZSize));
    AModel.Reset(LSize);
    LX1 := (LSize - LXSize) div 2;
    LY1 := (LSize - LYSize) div 2;
    LZ1 := (LSize - LZSize) div 2;
    LIndex := 12;
    for LX := LX1 to LX1 + LXSize - 1 do
      for LY := LY1 to LY1 + LYSize - 1 do
        for LZ := LZ1 to LZ1 + LZSize - 1 do
        begin
          if ABytes[LIndex] <> EMPTY_INDEX then
            AModel.Put(LX, LZ, LSize - LY - 1, LPalette[ABytes[LIndex]]);
          Inc(LIndex);
        end;
  finally
    LReader.Free;
  end;
end;

class function TVoxelEditorVoxFormat.Write(const AModel: TVoxelEditorModel): TBytes;
var
  LSide, LFrom, LTo, LX, LY, LZ, LIndex, LPosition: Integer;
  LRaw: TBytes;
  LColors: TVoxelEditorPalette;
  LPalette: array[0..767] of Byte;
  LColor: Cardinal;
begin
  if AModel.Size >= VOXEL_EDITOR_MAX_SIZE then
  begin
    LFrom := 1;
    LTo := 255;
    LSide := 255;
  end
  else
  begin
    LFrom := 0;
    LTo := AModel.Size - 1;
    LSide := AModel.Size;
  end;
  FillChar(LColors, SizeOf(LColors), 0);
  if TVoxelEditorQuantizer.GetPalette(AModel, 255, LColors) then
    for LIndex := 0 to 255 do
    begin
      LPalette[3 * LIndex] := LColors[LIndex] and $FF;
      LPalette[3 * LIndex + 1] := (LColors[LIndex] shr 8) and $FF;
      LPalette[3 * LIndex + 2] := (LColors[LIndex] shr 16) and $FF;
    end
  else
  begin
    // the palette of Doom without its first color, and black as the last
    LRaw := TGamePalettes.Colors(gpDoom);
    for LIndex := 0 to 764 do
      LPalette[LIndex] := LRaw[LIndex + 3];
    for LIndex := 765 to 767 do
      LPalette[LIndex] := 0;
    for LIndex := 0 to 254 do
      LColors[LIndex] := TVoxelEditorPalettes.Rgb(LPalette[3 * LIndex], LPalette[3 * LIndex + 1], LPalette[3 * LIndex + 2]);
  end;
  SetLength(Result, 12 + LSide * LSide * LSide + 768);
  for LIndex := 0 to 2 do
    PInteger(@Result[LIndex * 4])^ := LSide;
  LPosition := 12;
  for LX := LFrom to LTo do
    for LY := LFrom to LTo do
      for LZ := LFrom to LTo do
      begin
        LColor := AModel.Get(LX, LZ, LSide - 1 - LY);
        if LColor = 0 then
          Result[LPosition] := EMPTY_INDEX
        else
          Result[LPosition] := TVoxelEditorPalettes.FindApproximateIndex(LColors, LColor, 0, 254);
        Inc(LPosition);
      end;
  Move(LPalette[0], Result[LPosition], 768);
end;

end.

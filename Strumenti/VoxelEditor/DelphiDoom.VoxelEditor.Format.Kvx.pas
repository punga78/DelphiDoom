{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - the import of a KVX file (Build engine)           }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.Format.Kvx;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Model;

type
  /// <summary>
  ///   The import of a KVX voxel of Ken Silverman's Build (DoLoadKVX of DD_VOXEL, and the same code of the batch
  ///   conversion to DDMESH). The cube has the next power of two of the largest side, doubled below 256, and the
  ///   voxel is put in it by its pivot; the axes are turned as the editor wants them (x, z, size - 1 - y)
  /// </summary>
  TVoxelEditorKvxFormat = class sealed
  public
    /// <summary>
    ///   Reads the file into the model. A KVX that goes beyond its bytes, with sides over 256, or with a slab
    ///   that does not fit, is an EVoxelEditorException (the old loader read outside its buffers)
    /// </summary>
    class procedure Read(const ABytes: TBytes; const AModel: TVoxelEditorModel); static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.ByteReader,
  DelphiDoom.VoxelEditor.Format.SlabPalette;

resourcestring
  SKvxBadSize = 'the sides are %d x %d x %d';
  SKvxBadOffsets = 'a column is outside the data';
  SKvxBadSlab = 'a slab does not fit in its column';

const
  NO_CELL = $FFFF;

{ TVoxelEditorKvxFormat }

class procedure TVoxelEditorKvxFormat.Read(const ABytes: TBytes; const AModel: TVoxelEditorModel);
var
  LReader: TVoxelEditorByteReader;
  LPalette: TVoxelEditorPalette;
  LNumBytes, LXSize, LYSize, LZSize, LXPivot, LYPivot, LZPivot, LSize, LData, LDataSize: Integer;
  LXOffset: TArray<Integer>;
  LXYOffset: TArray<Word>;
  LCells: TArray<Word>;
  LX, LY, LZ, LX1, LY1, LZ1, LPosition, LEnd, LTop, LLength, LBase: Integer;
begin
  LPalette := TVoxelEditorSlabPalette.Read(ABytes);
  LReader := TVoxelEditorByteReader.Create(ABytes);
  try
    LNumBytes := LReader.ReadInteger;
    LXSize := LReader.ReadInteger;
    LYSize := LReader.ReadInteger;
    LZSize := LReader.ReadInteger;
    if (LXSize < 1) or (LXSize > VOXEL_EDITOR_MAX_SIZE) or (LYSize < 1) or (LYSize > VOXEL_EDITOR_MAX_SIZE) or
      (LZSize < 1) or (LZSize > VOXEL_EDITOR_MAX_SIZE) then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [Format(SKvxBadSize, [LXSize, LYSize, LZSize])]);
    LSize := 1;
    while LXSize > LSize do
      LSize := LSize * 2;
    while LYSize > LSize do
      LSize := LSize * 2;
    while LZSize > LSize do
      LSize := LSize * 2;
    if LSize < 256 then
      LSize := LSize * 2;
    LXPivot := LReader.ReadInteger;
    LYPivot := LReader.ReadInteger;
    LZPivot := LReader.ReadInteger;
    SetLength(LXOffset, LXSize + 1);
    for LX := 0 to LXSize do
      LXOffset[LX] := LReader.ReadInteger;
    SetLength(LXYOffset, LXSize * (LYSize + 1));
    for LX := 0 to High(LXYOffset) do
      LXYOffset[LX] := LReader.ReadWord;
    LDataSize := LNumBytes - 24 - (LXSize + 1) * 4 - LXSize * (LYSize + 1) * 2;
    LData := LReader.Position;
    if (LDataSize < 0) or (LData + LDataSize > Length(ABytes) - 768) then
      raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SKvxBadOffsets]);

    SetLength(LCells, LXSize * LYSize * LZSize);
    for LX := 0 to High(LCells) do
      LCells[LX] := NO_CELL;
    for LX := 0 to LXSize - 1 do
      for LY := 0 to LYSize - 1 do
      begin
        LBase := LXOffset[LX] - LXOffset[0];
        LPosition := LBase + LXYOffset[LX * (LYSize + 1) + LY];
        LEnd := LBase + LXYOffset[LX * (LYSize + 1) + LY + 1];
        if (LPosition < 0) or (LEnd > LDataSize) then
          raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SKvxBadOffsets]);
        while LPosition < LEnd do
        begin
          if LPosition + 3 > LDataSize then
            raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SKvxBadSlab]);
          LTop := ABytes[LData + LPosition];
          LLength := ABytes[LData + LPosition + 1];
          if LPosition + 3 + LLength > LDataSize then
            raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SKvxBadSlab]);
          for LZ := LTop to LTop + LLength - 1 do
            if LZ < LZSize then
              LCells[(LX * LYSize + LY) * LZSize + LZ] := ABytes[LData + LPosition + 3 + LZ - LTop];
          Inc(LPosition, LLength + 3);
        end;
      end;

    LX1 := LSize div 2 - LXPivot div 256;
    LY1 := LSize div 2 - LYPivot div 256;
    LZ1 := LSize {div 2} - LZPivot div 256;
    LX1 := Max(LX1, 0);
    LY1 := Max(LY1, 0);
    LZ1 := Max(LZ1, 0);
    while LX1 + LXSize > LSize do
      Dec(LX1);
    while LY1 + LYSize > LSize do
      Dec(LY1);
    while LZ1 + LZSize > LSize do
      Dec(LZ1);
    AModel.Reset(LSize);
    for LX := LX1 to LX1 + LXSize - 1 do
      for LY := LY1 to LY1 + LYSize - 1 do
        for LZ := LZ1 to LZ1 + LZSize - 1 do
        begin
          LTop := LCells[((LX - LX1) * LYSize + (LY - LY1)) * LZSize + (LZ - LZ1)];
          if LTop <> NO_CELL then
            AModel.Put(LX, LZ, LSize - LY - 1, LPalette[LTop]);
        end;
  finally
    LReader.Free;
  end;
end;

end.

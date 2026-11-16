{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the KVX format (Ken Silverman, Build engine)    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Format.Kvx;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>
  ///   A KVX file: the number of bytes after the first number, the three sizes and the three
  ///   pivots (1/256 of a voxel), the offset of each x, the offset of each y of each x, the
  ///   slabs (top, length, faces, and one palette index for each voxel of the slab) and at the
  ///   end the palette. The name has the extension .KVX or none: then the format looks for
  ///   the file with and without the extension and last for a lump of the WADs.
  /// </summary>
  TVoxelKvxFormat = class(TInterfacedObject, IVoxelFormat)
  public
    function Handles(const AExtension: string): Boolean;
    function Locate(const ASource: IVoxelFileSource; const AName: string; out ABytes: TBytes): Boolean;
    function Decode(const ABytes: TBytes): IVoxelModel;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings,
  DelphiDoom.Voxel.ByteReader,
  DelphiDoom.Voxel.KvxPalette,
  DelphiDoom.Voxel.Model;

{ TVoxelKvxFormat }

function TVoxelKvxFormat.Handles(const AExtension: string): Boolean;
begin
  Result := (AExtension = '.KVX') or (AExtension = '');
end;

function TVoxelKvxFormat.Locate(const ASource: IVoxelFileSource; const AName: string;
  out ABytes: TBytes): Boolean;
var
  LWithExtension: string;
  LFileName, LLumpName, LRest: string;
begin
  if ASource.TryReadFile(AName, ABytes) then
    Exit(True);
  if ASource.TryReadDirectoryFile(AName, ABytes) then
    Exit(True);
  if Pos('.', AName) = 0 then
  begin
    LWithExtension := AName + '.KVX';
    if ASource.TryReadFile(LWithExtension, ABytes) then
      Exit(True);
    if ASource.TryReadDirectoryFile(LWithExtension, ABytes) then
      Exit(True);
  end;
  // the lump has the name of the file without the folders and the extension
  LFileName := ExtractFileName(AName);
  TScannerStrings.SplitAtFirst(LFileName, LLumpName, LRest, '.');
  Result := ASource.TryReadLump(LLumpName, ABytes);
end;

function TVoxelKvxFormat.Decode(const ABytes: TBytes): IVoxelModel;
var
  LPalette: TArray<Cardinal>;
  LReader: TVoxelByteReader;
  LByteCount: Integer;
  LSizeX, LSizeY, LSizeZ: Integer;
  LPivotX, LPivotY, LPivotZ: Integer;
  LColumnOffsets: TArray<Integer>;
  LRowOffsets: TArray<TArray<Word>>;
  LDataStart: Integer;
  LDataSize: Integer;
  LData: TBytes;
  LCells: TArray<Cardinal>;
  LFirstOffset: Integer;
  LX, LY, LZ: Integer;
  LSlab, LEnd: Integer;
  LTop, LLength: Integer;
begin
  if Length(ABytes) < KVX_HEADER_SIZE + VOXEL_PALETTE_BYTES then
    raise EVoxelException.CreateFmt(SVoxelTooShort, [Length(ABytes)]);
  LPalette := TVoxelKvxPalette.Read(ABytes);

  LReader := TVoxelByteReader.Create(ABytes);
  try
    LByteCount := LReader.ReadInteger;
    LSizeX := LReader.ReadInteger;
    LSizeY := LReader.ReadInteger;
    LSizeZ := LReader.ReadInteger;
    LPivotX := LReader.ReadInteger;
    LPivotY := LReader.ReadInteger;
    LPivotZ := LReader.ReadInteger;
    if (LSizeX < 1) or (LSizeX > VOXEL_MAX_SIZE) or (LSizeY < 1) or (LSizeY > VOXEL_MAX_SIZE) or
      (LSizeZ < 1) or (LSizeZ > VOXEL_MAX_SIZE) then
      raise EVoxelException.CreateFmt(SVoxelInvalidSize, [LSizeX, LSizeY, LSizeZ]);

    SetLength(LColumnOffsets, LSizeX + 1);
    for LX := 0 to LSizeX do
      LColumnOffsets[LX] := LReader.ReadInteger;
    SetLength(LRowOffsets, LSizeX);
    for LX := 0 to LSizeX - 1 do
    begin
      SetLength(LRowOffsets[LX], LSizeY + 1);
      for LY := 0 to LSizeY do
        LRowOffsets[LX][LY] := LReader.ReadWord;
    end;

    LFirstOffset := LColumnOffsets[0];
    LDataStart := LReader.Position;
    LDataSize := LByteCount - 24 - (LSizeX + 1) * 4 - LSizeX * (LSizeY + 1) * 2;
    if (LDataSize < 0) or (Int64(LDataStart) + LDataSize > Length(ABytes) - VOXEL_PALETTE_BYTES) then
      raise EVoxelException.CreateFmt(SVoxelKvxData, [LDataSize, LByteCount]);
    SetLength(LData, LDataSize);
    if LDataSize > 0 then
      Move(ABytes[LDataStart], LData[0], LDataSize);
  finally
    LReader.Free;
  end;

  SetLength(LCells, LSizeX * LSizeY * LSizeZ);
  for LX := 0 to LSizeX - 1 do
    for LY := 0 to LSizeY - 1 do
    begin
      LSlab := LColumnOffsets[LX] + LRowOffsets[LX][LY] - LFirstOffset;
      LEnd := LColumnOffsets[LX] + LRowOffsets[LX][LY + 1] - LFirstOffset;
      if LEnd > LDataSize then
        raise EVoxelException.CreateFmt(SVoxelKvxOffsets, [LX, LY]);
      while LSlab < LEnd do
      begin
        if (LSlab < 0) or (LSlab + 3 > LDataSize) then
          raise EVoxelException.CreateFmt(SVoxelKvxOffsets, [LX, LY]);
        LTop := LData[LSlab];
        LLength := LData[LSlab + 1];
        if (LSlab + 3 + LLength > LDataSize) then
          raise EVoxelException.CreateFmt(SVoxelKvxOffsets, [LX, LY]);
        if LTop + LLength > LSizeZ then
          raise EVoxelException.CreateFmt(SVoxelKvxSlab, [LX, LY, LTop, LLength]);
        for LZ := LTop to LTop + LLength - 1 do
          LCells[(LX * LSizeY + LY) * LSizeZ + LZ] := LPalette[LData[LSlab + 3 + LZ - LTop]];
        Inc(LSlab, LLength + 3);
      end;
    end;

  Result := TVoxelModel.Create(vfKvx, LSizeX, LSizeY, LSizeZ, LPivotX, LPivotY, LPivotZ, LCells, nil);
end;

end.

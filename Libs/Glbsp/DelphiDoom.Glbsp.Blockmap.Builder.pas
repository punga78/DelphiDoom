{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - builds the BLOCKMAP lump                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of blockmap.c of glBSP 2.24 (C) 2000-2007 Andrew Apted                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Blockmap.Builder;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Node.Builder,
  DelphiDoom.Glbsp.Options,
  DelphiDoom.Glbsp.Wad.Document,
  DelphiDoom.Glbsp.Wad.Lump;

type
  /// <summary>
  ///   Computes the area of the blockmap and writes the BLOCKMAP lump:
  ///   blocks of 128 by 128 units with the lines that touch them, where the
  ///   equal blocks are stored once
  /// </summary>
  TGlbspBlockmapBuilder = class
  private
    type
      // The lines of one block, with the checksum that speeds up the
      // comparison of two blocks
      TBlock = class
      public
        Checksum: Word;
        Lines: TList<Word>;
        constructor Create;
        destructor Destroy; override;
      end;
  private
    FData: TGlbspLevelData;
    FWad: TGlbspWad;
    FOptions: TGlbspOptions;
    FMessages: TStrings;
    FBlockX, FBlockY: Integer;
    FBlockW, FBlockH: Integer;
    FBlockCount: Integer;
    FBlockMidX, FBlockMidY: Integer;
    FBlocks: TObjectList<TBlock>;
    FBlockPtrs: TArray<Word>;
    FBlockDups: TArray<Integer>;
    FOverflowed: Boolean;
    FCompression: Integer;
    procedure MiniWarn(const AMessage: string);
    procedure FindBlockmapLimits(out ABBox: TGlbspBBox);
    procedure TruncateBlockmap;
    procedure BlockAdd(const ABlockNumber, ALineIndex: Integer);
    procedure BlockAddLine(const ALine: TGlbspLinedef);
    procedure CreateBlockmap;
    class function CompareBlocks(const ALeft, ARight: TBlock): Integer; static;
    procedure CompressBlockmap;
    procedure WriteBlockmap;
  public
    /// <param name="AData">Level whose linedefs are indexed</param>
    /// <param name="AWad">WAD whose current level receives the lump</param>
    /// <param name="AOptions">Options; the block limit caps the size</param>
    /// <param name="AMessages">Receives the warnings; may be nil</param>
    constructor Create(const AData: TGlbspLevelData; const AWad: TGlbspWad;
      const AOptions: TGlbspOptions; const AMessages: TStrings);
    destructor Destroy; override;

    /// <summary>
    ///   Computes the origin and the size of the blockmap from the loaded
    ///   linedefs
    /// </summary>
    procedure InitBlockmap;

    /// <summary>Builds the blockmap and writes it to the BLOCKMAP lump</summary>
    procedure PutBlockmap;

    /// <summary>Origin and size, as the node builder needs them</summary>
    function GetBounds: TGlbspBlockmapBounds;

    property BlockX: Integer read FBlockX;
    property BlockY: Integer read FBlockY;
    property BlockW: Integer read FBlockW;
    property BlockH: Integer read FBlockH;
    /// <summary>True when the lump had to be left empty: it was too big</summary>
    property Overflowed: Boolean read FOverflowed;
    /// <summary>How much the sharing of equal blocks saved, in percent</summary>
    property Compression: Integer read FCompression;
  end;

implementation

uses
  System.Generics.Defaults,
  System.Math,
  DelphiDoom.Glbsp.Geometry,
  DelphiDoom.Glbsp.Level.Raw,
  DelphiDoom.Glbsp.Wad.Types;

const
  SHRT_MAX = 32767;
  SHRT_MIN = -32768;
  // Words the lump uses before the lists: the header (4) ...
  BLOCKMAP_HEADER_WORDS = 4;
  // ... and the offset that all the empty blocks share
  DUMMY_DUP = -1;

{ TGlbspBlockmapBuilder.TBlock }

constructor TGlbspBlockmapBuilder.TBlock.Create;
begin
  inherited Create;
  Lines := TList<Word>.Create;
  Checksum := $1234;
end;

destructor TGlbspBlockmapBuilder.TBlock.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

{ TGlbspBlockmapBuilder }

constructor TGlbspBlockmapBuilder.Create(const AData: TGlbspLevelData; const AWad: TGlbspWad;
  const AOptions: TGlbspOptions; const AMessages: TStrings);
begin
  inherited Create;
  FData := AData;
  FWad := AWad;
  FOptions := AOptions;
  FMessages := AMessages;
  FBlocks := TObjectList<TBlock>.Create(True);
end;

destructor TGlbspBlockmapBuilder.Destroy;
begin
  FBlocks.Free;
  inherited Destroy;
end;

procedure TGlbspBlockmapBuilder.MiniWarn(const AMessage: string);
begin
  if FOptions.MiniWarnings and Assigned(FMessages) then
    FMessages.Add(AMessage);
end;

function TGlbspBlockmapBuilder.GetBounds: TGlbspBlockmapBounds;
begin
  Result.X := FBlockX;
  Result.Y := FBlockY;
  Result.Width := FBlockW;
  Result.Height := FBlockH;
end;

procedure TGlbspBlockmapBuilder.FindBlockmapLimits(out ABBox: TGlbspBBox);
var
  LLine: TGlbspLinedef;
  LX1, LY1, LX2, LY2: Double;
  LLx, LLy, LHx, LHy: Integer;
  LMidX, LMidY: Integer;
begin
  LMidX := 0;
  LMidY := 0;
  ABBox.MinX := SHRT_MAX;
  ABBox.MinY := SHRT_MAX;
  ABBox.MaxX := SHRT_MIN;
  ABBox.MaxY := SHRT_MIN;

  for LLine in FData.Linedefs do
  begin
    if LLine.ZeroLength then
      Continue;

    LX1 := LLine.Start.X;
    LY1 := LLine.Start.Y;
    LX2 := LLine.EndVertex.X;
    LY2 := LLine.EndVertex.Y;

    LLx := Floor(Min(LX1, LX2));
    LLy := Floor(Min(LY1, LY2));
    LHx := Ceil(Max(LX1, LX2));
    LHy := Ceil(Max(LY1, LY2));

    if LLx < ABBox.MinX then
      ABBox.MinX := LLx;
    if LLy < ABBox.MinY then
      ABBox.MinY := LLy;
    if LHx > ABBox.MaxX then
      ABBox.MaxX := LHx;
    if LHy > ABBox.MaxY then
      ABBox.MaxY := LHy;

    // The middle of the cluster, roughly so that it does not overflow
    Inc(LMidX, (LLx + LHx) div 32);
    Inc(LMidY, (LLy + LHy) div 32);
  end;

  if FData.Linedefs.Count > 0 then
  begin
    FBlockMidX := (LMidX div FData.Linedefs.Count) * 16;
    FBlockMidY := (LMidY div FData.Linedefs.Count) * 16;
  end;
end;

procedure TGlbspBlockmapBuilder.InitBlockmap;
var
  LBBox: TGlbspBBox;
begin
  // The limits of the linedefs are the limits of the map
  FindBlockmapLimits(LBBox);

  FBlockX := LBBox.MinX - (LBBox.MinX and $7);
  FBlockY := LBBox.MinY - (LBBox.MinY and $7);

  FBlockW := ((LBBox.MaxX - FBlockX) div 128) + 1;
  FBlockH := ((LBBox.MaxY - FBlockY) div 128) + 1;
  FBlockCount := FBlockW * FBlockH;
end;

procedure TGlbspBlockmapBuilder.TruncateBlockmap;
begin
  while FBlockW * FBlockH > FOptions.BlockLimit do
  begin
    Dec(FBlockW, FBlockW div 8);
    Dec(FBlockH, FBlockH div 8);
  end;

  FBlockCount := FBlockW * FBlockH;

  MiniWarn(Format('Blockmap TOO LARGE!  Truncated to %dx%d blocks', [FBlockW, FBlockH]));
  FWad.MarkSoftFailure(LIMIT_BMAP_TRUNC);

  // The truncated blockmap is centered
  FBlockX := FBlockMidX - FBlockW * 64;
  FBlockY := FBlockMidY - FBlockH * 64;
end;

procedure TGlbspBlockmapBuilder.BlockAdd(const ABlockNumber, ALineIndex: Integer);
var
  LBlock: TBlock;
begin
  if (ABlockNumber < 0) or (ABlockNumber >= FBlockCount) then
    raise EGlbspLevelException.CreateFmt('BlockAdd: bad block number %d', [ABlockNumber]);

  LBlock := FBlocks[ABlockNumber];
  if not Assigned(LBlock) then
  begin
    LBlock := TBlock.Create;
    FBlocks[ABlockNumber] := LBlock;
  end;

  // The new checksum
  LBlock.Checksum := Word(((LBlock.Checksum shl 4) or (LBlock.Checksum shr 12)) xor ALineIndex);
  LBlock.Lines.Add(Word(ALineIndex));
end;

procedure TGlbspBlockmapBuilder.BlockAddLine(const ALine: TGlbspLinedef);
var
  LX1, LY1, LX2, LY2: Integer;
  LBx1, LBy1, LBx2, LBy2: Integer;
  LBx, LBy: Integer;
  LMinX, LMinY, LMaxX, LMaxY: Integer;
begin
  LX1 := Trunc(ALine.Start.X);
  LY1 := Trunc(ALine.Start.Y);
  LX2 := Trunc(ALine.EndVertex.X);
  LY2 := Trunc(ALine.EndVertex.Y);

  LBx1 := (Min(LX1, LX2) - FBlockX) div 128;
  LBy1 := (Min(LY1, LY2) - FBlockY) div 128;
  LBx2 := (Max(LX1, LX2) - FBlockX) div 128;
  LBy2 := (Max(LY1, LY2) - FBlockY) div 128;

  // Truncated blockmaps
  if LBx1 < 0 then
    LBx1 := 0;
  if LBy1 < 0 then
    LBy1 := 0;
  if LBx2 >= FBlockW then
    LBx2 := FBlockW - 1;
  if LBy2 >= FBlockH then
    LBy2 := FBlockH - 1;

  if (LBx2 < LBx1) or (LBy2 < LBy1) then
    Exit;

  // Simple case: completely horizontal
  if LBy1 = LBy2 then
  begin
    for LBx := LBx1 to LBx2 do
      BlockAdd(LBy1 * FBlockW + LBx, ALine.Index);
    Exit;
  end;

  // Simple case: completely vertical
  if LBx1 = LBx2 then
  begin
    for LBy := LBy1 to LBy2 do
      BlockAdd(LBy * FBlockW + LBx1, ALine.Index);
    Exit;
  end;

  // The rest: diagonals
  for LBy := LBy1 to LBy2 do
  begin
    for LBx := LBx1 to LBx2 do
    begin
      LMinX := FBlockX + LBx * 128;
      LMinY := FBlockY + LBy * 128;
      LMaxX := LMinX + 127;
      LMaxY := LMinY + 127;

      if TGlbspGeometry.CheckLinedefInsideBox(LMinX, LMinY, LMaxX, LMaxY, LX1, LY1, LX2, LY2) then
        BlockAdd(LBy * FBlockW + LBx, ALine.Index);
    end;
  end;
end;

procedure TGlbspBlockmapBuilder.CreateBlockmap;
var
  LIndex: Integer;
  LLine: TGlbspLinedef;
begin
  FBlocks.Clear;
  for LIndex := 0 to FBlockCount - 1 do
    FBlocks.Add(nil);

  for LLine in FData.Linedefs do
  begin
    // Zero length lines are ignored
    if LLine.ZeroLength then
      Continue;
    BlockAddLine(LLine);
  end;
end;

class function TGlbspBlockmapBuilder.CompareBlocks(const ALeft, ARight: TBlock): Integer;
var
  LIndex: Integer;
  LA, LB: Word;
begin
  if ALeft = ARight then
    Exit(0);
  if not Assigned(ALeft) then
    Exit(-1);
  if not Assigned(ARight) then
    Exit(1);

  if ALeft.Lines.Count <> ARight.Lines.Count then
    Exit(ALeft.Lines.Count - ARight.Lines.Count);

  if ALeft.Checksum <> ARight.Checksum then
    Exit(ALeft.Checksum - ARight.Checksum);

  // memcmp on the little endian words: the low byte is compared first
  for LIndex := 0 to ALeft.Lines.Count - 1 do
  begin
    LA := ALeft.Lines[LIndex];
    LB := ARight.Lines[LIndex];
    if (LA and $FF) <> (LB and $FF) then
      Exit(Integer(LA and $FF) - Integer(LB and $FF));
    if (LA shr 8) <> (LB shr 8) then
      Exit(Integer(LA shr 8) - Integer(LB shr 8));
  end;
  Result := 0;
end;

procedure TGlbspBlockmapBuilder.CompressBlockmap;
var
  LIndex, LBlockNumber, LCount: Integer;
  LCurOffset, LOrigSize, LNewSize: Integer;
begin
  SetLength(FBlockPtrs, FBlockCount);
  SetLength(FBlockDups, FBlockCount);

  // The duplicate detecting array is sorted: the duplicates end up next to
  // each other, and its order is that of the block lists in the lump. The
  // number of the block breaks the ties, so the sort does not matter
  for LIndex := 0 to FBlockCount - 1 do
    FBlockDups[LIndex] := LIndex;

  TArray.Sort<Integer>(FBlockDups, TComparer<Integer>.Construct(
    function(const ALeft, ARight: Integer): Integer
    begin
      Result := CompareBlocks(FBlocks[ALeft], FBlocks[ARight]);
      if Result = 0 then
        Result := ALeft - ARight;
    end));

  // The offset array is built by scanning the duplicate array
  LCurOffset := BLOCKMAP_HEADER_WORDS + FBlockCount + 2;
  LOrigSize := BLOCKMAP_HEADER_WORDS + FBlockCount;
  LNewSize := LCurOffset;

  for LIndex := 0 to FBlockCount - 1 do
  begin
    LBlockNumber := FBlockDups[LIndex];

    // An empty block?
    if not Assigned(FBlocks[LBlockNumber]) then
    begin
      FBlockPtrs[LBlockNumber] := Word(BLOCKMAP_HEADER_WORDS + FBlockCount);
      FBlockDups[LIndex] := DUMMY_DUP;
      Inc(LOrigSize, 2);
      Continue;
    end;

    LCount := 2 + FBlocks[LBlockNumber].Lines.Count;

    // A duplicate? Only the very last of a sequence of duplicates updates
    // the current offset
    if (LIndex + 1 < FBlockCount) and
      (CompareBlocks(FBlocks[LBlockNumber], FBlocks[FBlockDups[LIndex + 1]]) = 0) then
    begin
      FBlockPtrs[LBlockNumber] := Word(LCurOffset);
      FBlockDups[LIndex] := DUMMY_DUP;

      // The memory of the duplicated block is released
      FBlocks[LBlockNumber] := nil;

      Inc(LOrigSize, LCount);
      Continue;
    end;

    // The last of a series of duplicates, or a singleton
    FBlockPtrs[LBlockNumber] := Word(LCurOffset);
    Inc(LCurOffset, LCount);
    Inc(LOrigSize, LCount);
    Inc(LNewSize, LCount);
  end;

  if LCurOffset > 65535 then
  begin
    FWad.MarkSoftFailure(LIMIT_BLOCKMAP);
    FOverflowed := True;
    Exit;
  end;

  FCompression := (LOrigSize - LNewSize) * 100 div LOrigSize;

  // There is a tiny chance of a new size greater than the original
  if FCompression < 0 then
    FCompression := 0;
end;

procedure TGlbspBlockmapBuilder.WriteBlockmap;
var
  LLump: TGlbspLump;
  LHeader: TRawBlockmapHeader;
  LIndex, LBlockNumber, LLine: Integer;
  LWord: Word;
  LBlock: TBlock;

  procedure AppendWord(const AValue: Word);
  begin
    LLump.Append(AValue, SizeOf(AValue));
  end;

begin
  LLump := FWad.CreateLevelLump('BLOCKMAP');

  // The lump stays empty if the blockmap overflowed
  if FOverflowed then
    Exit;

  // The header
  LHeader.XOrigin := SmallInt(FBlockX);
  LHeader.YOrigin := SmallInt(FBlockY);
  LHeader.XBlocks := SmallInt(FBlockW);
  LHeader.YBlocks := SmallInt(FBlockH);
  LLump.Append(LHeader, SizeOf(LHeader));

  // The pointers
  for LIndex := 0 to FBlockCount - 1 do
  begin
    LWord := FBlockPtrs[LIndex];
    if LWord = 0 then
      raise EGlbspLevelException.CreateFmt('WriteBlockmap: offset %d not set.', [LIndex]);
    AppendWord(LWord);
  end;

  // The null block that all the empty blocks use
  AppendWord($0000);
  AppendWord($FFFF);

  // The list of each block
  for LIndex := 0 to FBlockCount - 1 do
  begin
    LBlockNumber := FBlockDups[LIndex];

    // Duplicate and empty blocks are ignored
    if LBlockNumber = DUMMY_DUP then
      Continue;

    LBlock := FBlocks[LBlockNumber];
    if not Assigned(LBlock) then
      raise EGlbspLevelException.CreateFmt('WriteBlockmap: block %d is NULL !', [LIndex]);

    AppendWord($0000);
    for LLine := 0 to LBlock.Lines.Count - 1 do
      AppendWord(LBlock.Lines[LLine]);
    AppendWord($FFFF);
  end;
end;

procedure TGlbspBlockmapBuilder.PutBlockmap;
begin
  FOverflowed := False;
  FCompression := 0;

  // The blockmap is truncated if it is too large: the blocks are limited to
  // around 16000 (changeable), which leaves about 48K of words for the
  // lists of lines
  if FBlockCount > FOptions.BlockLimit then
    TruncateBlockmap;

  // First: the internal blockmap with the index of all the lines in each block
  CreateBlockmap;

  // Second: it is compressed. The blocks are sorted, a typical way to detect
  // the duplicates of a large list
  CompressBlockmap;

  // Finally it is written in the right format
  WriteBlockmap;
end;

end.


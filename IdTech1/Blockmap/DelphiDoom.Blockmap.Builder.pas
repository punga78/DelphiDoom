{******************************************************************************}
{                                                                              }
{  DelphiDoom: blockmap - builder                                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Algorithm of killough and jff (MBF, 10/98), order of nlines*(ncols+nrows)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Blockmap.Builder;

// The products of a line and a coordinate may wrap around: it is the behaviour
// of the original code and of its results, so the checks are off
{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Blockmap.Intf,
  DelphiDoom.Blockmap.Types;

type
  /// <summary>
  ///   Builds the blockmap of a level: finds where each line crosses the columns and
  ///   the rows of the blocks and adds the line to every block it touches. Every list
  ///   starts with line 0 and ends with -1, the lines in between come from the
  ///   highest number to the lowest. Not thread safe: it keeps the work of one call
  /// </summary>
  TBlockmapBuilder = class(TInterfacedObject, IBlockmapBuilder)
  strict private
    // area of the blockmap, in map units and blocks
    FOriginX: Integer;
    FOriginY: Integer;
    FColumns: Integer;
    FRows: Integer;
    FBlockCount: Integer;
    // the line being added, in map units
    FCurrentLine: Integer;
    FX1: Integer;
    FY1: Integer;
    FDeltaX: Integer;
    FDeltaY: Integer;
    FMinX: Integer;
    FMaxX: Integer;
    FMinY: Integer;
    FMaxY: Integer;
    FSlopeNegative: Boolean;
    FSlopePositive: Boolean;
    // blocks and lines of the pairs (block, line), in the order they were found
    FPairBlocks: TArray<Integer>;
    FPairLines: TArray<Integer>;
    FPairCount: Integer;
    // the last line that was added to each block: a line enters a block only once
    FLastLine: TArray<Integer>;
    class function ShiftRight(const AValue, ABits: Integer): Integer; static;
    procedure AddBlockLine(const ABlockNumber: Integer);
    procedure AddLine(const ALineIndex: Integer; const ALine: TBlockmapLine);
    procedure AddColumnCrossings;
    procedure AddRowCrossings;
    function Assemble: TBlockmapData;
  public
    function Build(const AVertexes: TArray<TBlockmapPoint>;
      const ALines: TArray<TBlockmapLine>): TBlockmapData;
  end;

implementation

resourcestring
  SBlockmapLineOutside = 'Blockmap: line %d is outside the area of the blockmap';

{ TBlockmapBuilder }

class function TBlockmapBuilder.ShiftRight(const AValue, ABits: Integer): Integer;
begin
  // arithmetic shift: a negative value keeps its sign
  if AValue >= 0 then
    Result := AValue shr ABits
  else
    Result := not ((not AValue) shr ABits);
end;

procedure TBlockmapBuilder.AddBlockLine(const ABlockNumber: Integer);
begin
  if (ABlockNumber < 0) or (ABlockNumber >= FBlockCount) then
    raise EBlockmapException.CreateFmt(SBlockmapLineOutside, [FCurrentLine]);
  if FLastLine[ABlockNumber] = FCurrentLine then
    Exit;
  FLastLine[ABlockNumber] := FCurrentLine;
  if FPairCount = Length(FPairBlocks) then
  begin
    SetLength(FPairBlocks, FPairCount * 2 + 1024);
    SetLength(FPairLines, Length(FPairBlocks));
  end;
  FPairBlocks[FPairCount] := ABlockNumber;
  FPairLines[FPairCount] := FCurrentLine;
  Inc(FPairCount);
end;

procedure TBlockmapBuilder.AddColumnCrossings;
var
  LColumn, LX, LY, LRowBlock, LRowPosition: Integer;
begin
  // intersection of the line with x = xorg + (j shl blkshift): (y - y1) * dx = dy * (x - x1)
  for LColumn := 0 to FColumns - 1 do
  begin
    LX := FOriginX + (LColumn shl BLOCKMAP_SHIFT);
    LY := (FDeltaY * (LX - FX1)) div FDeltaX + FY1;
    LRowBlock := ShiftRight(LY - FOriginY, BLOCKMAP_SHIFT);
    LRowPosition := (LY - FOriginY) and BLOCKMAP_MASK;

    if (LRowBlock < 0) or (LRowBlock > FRows - 1) then
      Continue;
    if (LX < FMinX) or (LX > FMaxX) then
      Continue;

    // the cell that holds the intersection is always added
    AddBlockLine(FColumns * LRowBlock + LColumn);

    // at a corner the slope tells which blocks are hit
    if LRowPosition = 0 then
    begin
      if FSlopeNegative then
      begin
        if (LRowBlock > 0) and (FMinY < LY) then
          AddBlockLine(FColumns * (LRowBlock - 1) + LColumn);
        if (LColumn > 0) and (FMinX < LX) then
          AddBlockLine(FColumns * LRowBlock + LColumn - 1);
      end
      else if FSlopePositive then
      begin
        if (LRowBlock > 0) and (LColumn > 0) and (FMinX < LX) then
          AddBlockLine(FColumns * (LRowBlock - 1) + LColumn - 1);
      end
      else if FDeltaY = 0 then
      begin
        if (LColumn > 0) and (FMinX < LX) then
          AddBlockLine(FColumns * LRowBlock + LColumn - 1);
      end;
    end
    else if (LColumn > 0) and (FMinX < LX) then
      AddBlockLine(FColumns * LRowBlock + LColumn - 1);
  end;
end;

procedure TBlockmapBuilder.AddRowCrossings;
var
  LRow, LX, LY, LColumnBlock, LColumnPosition: Integer;
begin
  // intersection of the line with y = yorg + (j shl blkshift): x = dx * (y - y1) / dy + x1
  for LRow := 0 to FRows - 1 do
  begin
    LY := FOriginY + (LRow shl BLOCKMAP_SHIFT);
    LX := (FDeltaX * (LY - FY1)) div FDeltaY + FX1;
    LColumnBlock := ShiftRight(LX - FOriginX, BLOCKMAP_SHIFT);
    LColumnPosition := (LX - FOriginX) and BLOCKMAP_MASK;

    if (LColumnBlock < 0) or (LColumnBlock > FColumns - 1) then
      Continue;
    if (LY < FMinY) or (LY > FMaxY) then
      Continue;

    AddBlockLine(FColumns * LRow + LColumnBlock);

    if LColumnPosition = 0 then
    begin
      if FSlopeNegative then
      begin
        if (LRow > 0) and (FMinY < LY) then
          AddBlockLine(FColumns * (LRow - 1) + LColumnBlock);
        if (LColumnBlock > 0) and (FMinX < LX) then
          AddBlockLine(FColumns * LRow + LColumnBlock - 1);
      end
      else if FDeltaX = 0 then
      begin
        if (LRow > 0) and (FMinY < LY) then
          AddBlockLine(FColumns * (LRow - 1) + LColumnBlock);
      end
      else if FSlopePositive then
      begin
        if (LColumnBlock > 0) and (LRow > 0) and (FMinY < LY) then
          AddBlockLine(FColumns * (LRow - 1) + LColumnBlock - 1);
      end;
    end
    else if (LRow > 0) and (FMinY < LY) then
      AddBlockLine(FColumns * (LRow - 1) + LColumnBlock);
  end;
end;

procedure TBlockmapBuilder.AddLine(const ALineIndex: Integer; const ALine: TBlockmapLine);
var
  LX2, LY2: Integer;
begin
  FCurrentLine := ALineIndex;
  FX1 := ShiftRight(ALine.X1, 16);
  FY1 := ShiftRight(ALine.Y1, 16);
  LX2 := ShiftRight(ALine.X2, 16);
  LY2 := ShiftRight(ALine.Y2, 16);
  FDeltaX := LX2 - FX1;
  FDeltaY := LY2 - FY1;
  FSlopePositive := (FDeltaX xor FDeltaY) > 0;
  FSlopeNegative := (FDeltaX xor FDeltaY) < 0;
  if FX1 > LX2 then
  begin
    FMinX := LX2;
    FMaxX := FX1;
  end
  else
  begin
    FMinX := FX1;
    FMaxX := LX2;
  end;
  if FY1 > LY2 then
  begin
    FMinY := LY2;
    FMaxY := FY1;
  end
  else
  begin
    FMinY := FY1;
    FMaxY := LY2;
  end;

  // the line always belongs to the blocks that hold its ends
  AddBlockLine(ShiftRight(FY1 - FOriginY, BLOCKMAP_SHIFT) * FColumns +
    ShiftRight(FX1 - FOriginX, BLOCKMAP_SHIFT));
  AddBlockLine(ShiftRight(LY2 - FOriginY, BLOCKMAP_SHIFT) * FColumns +
    ShiftRight(LX2 - FOriginX, BLOCKMAP_SHIFT));

  // a vertical line does not cross the columns, a horizontal one does not cross the rows
  if FDeltaX <> 0 then
    AddColumnCrossings;
  if FDeltaY <> 0 then
    AddRowCrossings;
end;

function TBlockmapBuilder.Assemble: TBlockmapData;
var
  LBlock, LPair, LIndex, LOffset: Integer;
  LCounts, LStarts, LSorted: TArray<Integer>;
begin
  // count the lines of each block, then sort the pairs by block keeping their order
  SetLength(LCounts, FBlockCount);
  for LPair := 0 to FPairCount - 1 do
    Inc(LCounts[FPairBlocks[LPair]]);
  SetLength(LStarts, FBlockCount);
  LIndex := 0;
  for LBlock := 0 to FBlockCount - 1 do
  begin
    LStarts[LBlock] := LIndex;
    Inc(LIndex, LCounts[LBlock]);
  end;
  SetLength(LSorted, FPairCount);
  for LPair := 0 to FPairCount - 1 do
  begin
    LSorted[LStarts[FPairBlocks[LPair]]] := FPairLines[LPair];
    Inc(LStarts[FPairBlocks[LPair]]);
  end;

  Result.OriginX := FOriginX;
  Result.OriginY := FOriginY;
  Result.Columns := FColumns;
  Result.Rows := FRows;
  Result.Built := True;
  SetLength(Result.Lump, BLOCKMAP_HEADER_SIZE + FBlockCount + FPairCount + 2 * FBlockCount);
  Result.Lump[0] := FOriginX;
  Result.Lump[1] := FOriginY;
  Result.Lump[2] := FColumns;
  Result.Lump[3] := FRows;

  // each list: line 0, the lines from the last to the first, then -1
  LOffset := BLOCKMAP_HEADER_SIZE + FBlockCount;
  LIndex := 0;
  for LBlock := 0 to FBlockCount - 1 do
  begin
    Result.Lump[BLOCKMAP_HEADER_SIZE + LBlock] := LOffset;
    Result.Lump[LOffset] := 0;
    Inc(LOffset);
    for LPair := LIndex + LCounts[LBlock] - 1 downto LIndex do
    begin
      Result.Lump[LOffset] := LSorted[LPair];
      Inc(LOffset);
    end;
    Inc(LIndex, LCounts[LBlock]);
    Result.Lump[LOffset] := -1;
    Inc(LOffset);
  end;

  // MAES: for a full 512 by 512 map both limits are -1, for 257 by 257 they are -255 ...
  if FColumns > 255 then
    Result.NegX := FColumns - 512
  else
    Result.NegX := BLOCKMAP_NEG_DISABLED;
  if FRows > 255 then
    Result.NegY := FRows - 512
  else
    Result.NegY := BLOCKMAP_NEG_DISABLED;
end;

function TBlockmapBuilder.Build(const AVertexes: TArray<TBlockmapPoint>;
  const ALines: TArray<TBlockmapLine>): TBlockmapData;
var
  LIndex: Integer;
  LMinX, LMinY, LMaxX, LMaxY: Integer;
  LBlocks: Int64;
begin
  if Length(AVertexes) = 0 then
    raise EBlockmapException.Create(SBlockmapNoVertexes);

  // the blockmap must enclose the whole map
  LMinX := High(Integer);
  LMinY := High(Integer);
  LMaxX := Low(Integer);
  LMaxY := Low(Integer);
  for LIndex := 0 to High(AVertexes) do
  begin
    if AVertexes[LIndex].X < LMinX then
      LMinX := AVertexes[LIndex].X;
    if AVertexes[LIndex].X > LMaxX then
      LMaxX := AVertexes[LIndex].X;
    if AVertexes[LIndex].Y < LMinY then
      LMinY := AVertexes[LIndex].Y;
    if AVertexes[LIndex].Y > LMaxY then
      LMaxY := AVertexes[LIndex].Y;
  end;
  // work in map units, not in fixed point
  LMinX := ShiftRight(LMinX, 16);
  LMaxX := ShiftRight(LMaxX, 16);
  LMinY := ShiftRight(LMinY, 16);
  LMaxY := ShiftRight(LMaxY, 16);

  // +1 so that a map one unit wide still has one cell
  FOriginX := LMinX;
  FOriginY := LMinY;
  FColumns := ShiftRight(LMaxX - FOriginX + 1 + BLOCKMAP_MASK, BLOCKMAP_SHIFT);
  FRows := ShiftRight(LMaxY - FOriginY + 1 + BLOCKMAP_MASK, BLOCKMAP_SHIFT);
  LBlocks := Int64(FColumns) * FRows;
  if (FColumns <= 0) or (FRows <= 0) or (LBlocks > 64 * 1024 * 1024) then
    raise EBlockmapException.CreateFmt(SBlockmapTooBig, [FColumns, FRows]);

  FBlockCount := Integer(LBlocks);
  SetLength(FLastLine, FBlockCount);
  for LIndex := 0 to FBlockCount - 1 do
    FLastLine[LIndex] := -1;
  FPairCount := 0;
  SetLength(FPairBlocks, 0);
  SetLength(FPairLines, 0);

  for LIndex := 0 to High(ALines) do
    AddLine(LIndex, ALines[LIndex]);

  Result := Assemble;

  // do not keep the work of the level
  SetLength(FPairBlocks, 0);
  SetLength(FPairLines, 0);
  SetLength(FLastLine, 0);
end;

end.

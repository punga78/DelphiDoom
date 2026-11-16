{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - sorting the sprites with the radix sort      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_SortVisSprites_RadixSort of r_things_sortvissprites.pas (JVAL     }
{  20180914)                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.RadixSorter;

interface

uses
  DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   A fast radix sort optimized for positive integer values (range [0..MAXINT]), such as the
  ///   scale of a sprite. Every value has 3 virtual digits: the 2 least significant are base 2048
  ///   (11 bits) and the most significant (the third) is base 1024 (10 bits). Special care has
  ///   been taken when the keys are in the range 1..2^22 (two passes). It is faster than the
  ///   quick sort with more than 500 to 1000 sprites: sorting 5000 to 10000 sprites takes a
  ///   quarter of the time. It is stable
  /// </summary>
  TRendererRadixSorter = class(TInterfacedObject, IRendererSpriteSorter)
  strict private
    FIndex: array[0..5 * 2048 div 2 - 1] of Integer;
    FFirstBuffer: TArray<TRendererSortItem>;
    FSecondBuffer: TArray<TRendererSortItem>;
    procedure Grow(var ABuffer: TArray<TRendererSortItem>; ACount: Integer);
  public
    function UsesDroppedAdjustment: Boolean;
    procedure Reserve(ACount: Integer);
    procedure Sort(AItems: PRendererSortItemArray; ACount: Integer);
    procedure Release;
  end;

implementation

// the keys are used as unsigned numbers and the counters wrap as they did
{$Q-}
{$R-}

const
  RADIX_BASE = 2048;
  RADIX_MASK = RADIX_BASE - 1;
  // the buffers grow by more than needed, so the next frames do not allocate
  EXTRA_ROOM = 128;

{ TRendererRadixSorter }

function TRendererRadixSorter.UsesDroppedAdjustment: Boolean;
begin
  Result := True;
end;

procedure TRendererRadixSorter.Grow(var ABuffer: TArray<TRendererSortItem>; ACount: Integer);
begin
  if ACount > Length(ABuffer) then
    SetLength(ABuffer, ACount + EXTRA_ROOM);
end;

procedure TRendererRadixSorter.Reserve(ACount: Integer);
begin
  Grow(FFirstBuffer, ACount);
  Grow(FSecondBuffer, ACount);
end;

procedure TRendererRadixSorter.Sort(AItems: PRendererSortItemArray; ACount: Integer);
var
  LIndex: Integer;
  LDigit: Integer;
  LCount1, LCount2, LCount3, LTotal: Integer;
  LIndex1, LIndex2, LIndex3: PIntegerArray;
  LCounter: PInteger;
  LKey: Cardinal;
begin
  Grow(FFirstBuffer, ACount);

  LIndex1 := @FIndex;
  LIndex2 := @LIndex1[RADIX_BASE];
  LIndex3 := @LIndex2[RADIX_BASE];

  FillChar(LIndex1^, 5 * RADIX_BASE * SizeOf(Integer) div 2, 0);
  for LIndex := 0 to ACount - 1 do
  begin
    LKey := Cardinal(AItems[LIndex].Key);
    Inc(LIndex1[LKey and RADIX_MASK]);
    Inc(LIndex2[(LKey shr 11) and RADIX_MASK]);
    Inc(LIndex3[LKey shr 22]);
  end;

  if LIndex3[0] = ACount then // 2 passes
  begin
    LCount1 := 0;
    LCount2 := 0;

    for LDigit := 0 to RADIX_BASE - 1 do
    begin
      LCounter := @LIndex1[LDigit];
      LTotal := LCounter^ + LCount1;
      LCounter^ := LCount1 - 1;
      LCount1 := LTotal;

      Inc(LCounter, RADIX_BASE);
      LTotal := LCounter^ + LCount2;
      LCounter^ := LCount2 - 1;
      LCount2 := LTotal;
    end;

    // first pass: from the items to the first buffer
    for LIndex := 0 to ACount - 1 do
    begin
      LCounter := @LIndex1[Cardinal(AItems[LIndex].Key) and RADIX_MASK];
      Inc(LCounter^);
      FFirstBuffer[LCounter^] := AItems[LIndex];
    end;

    // second pass: from the first buffer back to the items
    for LIndex := 0 to ACount - 1 do
    begin
      LCounter := @LIndex2[(Cardinal(FFirstBuffer[LIndex].Key) shr 11) and RADIX_MASK];
      Inc(LCounter^);
      AItems[LCounter^] := FFirstBuffer[LIndex];
    end;
  end
  else // 3 passes (it should rarely happen: only with sprites very close to the view)
  begin
    Grow(FSecondBuffer, ACount);

    LCount1 := 0;
    LCount2 := 0;
    LCount3 := 0;

    for LDigit := 0 to RADIX_BASE div 2 - 1 do
    begin
      LCounter := @LIndex1[LDigit];
      LTotal := LCounter^ + LCount1;
      LCounter^ := LCount1 - 1;
      LCount1 := LTotal;

      Inc(LCounter, RADIX_BASE);
      LTotal := LCounter^ + LCount2;
      LCounter^ := LCount2 - 1;
      LCount2 := LTotal;

      Inc(LCounter, RADIX_BASE);
      LTotal := LCounter^ + LCount3;
      LCounter^ := LCount3 - 1;
      LCount3 := LTotal;
    end;

    for LDigit := RADIX_BASE div 2 to RADIX_BASE - 1 do
    begin
      LCounter := @LIndex1[LDigit];
      LTotal := LCounter^ + LCount1;
      LCounter^ := LCount1 - 1;
      LCount1 := LTotal;

      Inc(LCounter, RADIX_BASE);
      LTotal := LCounter^ + LCount2;
      LCounter^ := LCount2 - 1;
      LCount2 := LTotal;
    end;

    // first pass: from the items to the first buffer
    for LIndex := 0 to ACount - 1 do
    begin
      LCounter := @LIndex1[Cardinal(AItems[LIndex].Key) and RADIX_MASK];
      Inc(LCounter^);
      FFirstBuffer[LCounter^] := AItems[LIndex];
    end;

    // second pass: from the first buffer to the second
    for LIndex := 0 to ACount - 1 do
    begin
      LCounter := @LIndex2[(Cardinal(FFirstBuffer[LIndex].Key) shr 11) and RADIX_MASK];
      Inc(LCounter^);
      FSecondBuffer[LCounter^] := FFirstBuffer[LIndex];
    end;

    // third pass: from the second buffer back to the items
    for LIndex := 0 to ACount - 1 do
    begin
      LCounter := @LIndex3[Cardinal(FSecondBuffer[LIndex].Key) shr 22];
      Inc(LCounter^);
      AItems[LCounter^] := FSecondBuffer[LIndex];
    end;
  end;
end;

procedure TRendererRadixSorter.Release;
begin
  FFirstBuffer := nil;
  FSecondBuffer := nil;
end;

end.

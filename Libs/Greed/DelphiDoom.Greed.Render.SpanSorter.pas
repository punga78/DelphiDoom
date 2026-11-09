{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the sort of the spans                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the sort of r_spans.pas     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.SpanSorter;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Greed.Render.Types;

type
  /// <summary>
  ///   Puts the spans from the farthest to the nearest. It is the quicksort with the cut at 16 elements and the
  ///   insertion sort of the original, not another sort: the comparison of the original says "equal" for two spans of
  ///   the same distance when the first has the smaller number (a mistake of the original, t2.span &lt; t2.span), so
  ///   the order of those depends on the algorithm and has to be the same for the pictures to be the same
  /// </summary>
  TGreedSpanSorter = class
  strict private
    type
      PTags = ^TTags;
      TTags = array[0..GREED_MAX_SPANS] of TGreedSpanTag;
    class function Compare(const ALeft, ARight: PGreedSpanTag): Integer; static; inline;
    class procedure MedianOfThree(AData: PTags; ACount: Integer); static;
    class function Partition(AData: PTags; ACount: Cardinal): Integer; static;
    class procedure QuickSort(AData: PTags; ACount: Cardinal); static;
    class procedure InsertionSort(AData: PTags; ACount: Cardinal); static;
  public
    class procedure Sort(var ATags: TArray<TGreedSpanTag>; ACount: Integer); static;
  end;

implementation

const
  QUICKSORT_CUTOFF = 16;

{ TGreedSpanSorter }

class function TGreedSpanSorter.Compare(const ALeft, ARight: PGreedSpanTag): Integer;
begin
  if ALeft^.Point > ARight^.Point then
    Result := -1
  else if ALeft^.Point < ARight^.Point then
    Result := 1
  else if ALeft^.Span > ARight^.Span then
    Result := -1
  else
    // the original compares t2.span with itself here, which is never true
    Result := 0;
end;

class procedure TGreedSpanSorter.MedianOfThree(AData: PTags; ACount: Integer);
var
  LTemp: TGreedSpanTag;
  LBegin, LMid, LStop: PGreedSpanTag;

  procedure Swap(const A, B: PGreedSpanTag);
  begin
    LTemp := A^;
    A^ := B^;
    B^ := LTemp;
  end;

begin
  if ACount >= 3 then
  begin
    LBegin := @AData^[0];
    LMid := @AData^[ACount div 2];
    LStop := @AData^[ACount - 1];
    if Compare(LBegin, LMid) = -1 then
    begin
      if Compare(LMid, LStop) = -1 then
        Swap(LBegin, LMid)
      else if Compare(LBegin, LStop) = -1 then
        Swap(LBegin, LStop);
    end
    else if Compare(LMid, LStop) = -1 then
    begin
      if Compare(LBegin, LStop) = -1 then
        Swap(LBegin, LStop);
    end
    else
      Swap(LBegin, LMid);
  end;
end;

class function TGreedSpanSorter.Partition(AData: PTags; ACount: Cardinal): Integer;
var
  LPart, LTemp: TGreedSpanTag;
  LI, LJ: Integer;
begin
  LPart := AData^[0];
  LI := -1;
  LJ := Integer(ACount);
  while LI < LJ do
  begin
    repeat
      Dec(LJ);
    until Compare(@LPart, @AData^[LJ]) <> -1;
    repeat
      Inc(LI);
    until Compare(@AData^[LI], @LPart) <> -1;
    if LI >= LJ then
      Break;
    LTemp := AData^[LI];
    AData^[LI] := AData^[LJ];
    AData^[LJ] := LTemp;
  end;
  Result := LJ + 1;
end;

class procedure TGreedSpanSorter.QuickSort(AData: PTags; ACount: Cardinal);
var
  LLeft, LPart: Integer;
  LData: PTags;
begin
  LLeft := 0;
  if ACount > QUICKSORT_CUTOFF then
  begin
    while ACount > 1 do
    begin
      LData := PTags(@AData^[LLeft]);
      MedianOfThree(LData, ACount);
      LPart := Partition(LData, ACount);
      QuickSort(LData, LPart);
      LLeft := LLeft + LPart;
      ACount := ACount - Cardinal(LPart);
    end;
  end;
end;

class procedure TGreedSpanSorter.InsertionSort(AData: PTags; ACount: Cardinal);
var
  LI, LJ: Integer;
  LTemp: TGreedSpanTag;
begin
  for LI := 1 to Integer(ACount) - 1 do
  begin
    if Compare(@AData^[LI], @AData^[LI - 1]) = -1 then
    begin
      LTemp := AData^[LI];
      LJ := LI;
      while (LJ <> 0) and (Compare(@LTemp, @AData^[LJ - 1]) = -1) do
      begin
        AData^[LJ] := AData^[LJ - 1];
        Dec(LJ);
      end;
      AData^[LJ] := LTemp;
    end;
  end;
end;

class procedure TGreedSpanSorter.Sort(var ATags: TArray<TGreedSpanTag>; ACount: Integer);
begin
  if ACount > 1 then
  begin
    QuickSort(PTags(@ATags[0]), ACount);
    InsertionSort(PTags(@ATags[0]), ACount);
  end;
end;

end.

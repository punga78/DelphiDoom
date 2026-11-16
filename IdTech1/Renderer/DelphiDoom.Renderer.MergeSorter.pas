{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - sorting the sprites with the merge sort      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_SortVisSprites_MergeSort of r_things_sortvissprites.pas, from     }
{  http://alexandrecmachado.blogspot.com.br/2015/02/merge-sort-for-delphi.html }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.MergeSorter;

interface

uses
  DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Merge sort with insertion sort for the short pieces. It is stable. The old code compared
  ///   the plain scale of the sprites (a dropped object did not count one more): the sorter
  ///   says so, and the caller gives it the plain scale as the key
  /// </summary>
  TRendererMergeSorter = class(TInterfacedObject, IRendererSpriteSorter)
  strict private
    FTemp: TArray<TRendererSortItem>;
    procedure InsertionSort(AItems: PRendererSortItemArray; AFirst, ALast: Integer);
    procedure MergeSort(AItems: PRendererSortItemArray; AFirst, ALast: Integer);
  public
    function UsesDroppedAdjustment: Boolean;
    procedure Reserve(ACount: Integer);
    procedure Sort(AItems: PRendererSortItemArray; ACount: Integer);
    procedure Release;
  end;

implementation

const
  // When the list is smaller than this the insertion sort is used instead of calling the merge
  // sort again: 8 and 64 seem to be the lower and upper limits where the performance degrades
  MIN_LIST_SIZE = 16;
  // the space grows by more than needed, so the sorting of the next frames does not allocate
  EXTRA_ROOM = 128;

{ TRendererMergeSorter }

function TRendererMergeSorter.UsesDroppedAdjustment: Boolean;
begin
  Result := False;
end;

procedure TRendererMergeSorter.Reserve(ACount: Integer);
var
  LNeeded: Integer;
begin
  // half of the list and one more is the room that the merge uses
  LNeeded := ACount div 2 + 1;
  if LNeeded > Length(FTemp) then
    SetLength(FTemp, LNeeded + EXTRA_ROOM);
end;

procedure TRendererMergeSorter.InsertionSort(AItems: PRendererSortItemArray; AFirst,
  ALast: Integer);
var
  LIndex: Integer;
  LPosition: Integer;
  LTemp: TRendererSortItem;
begin
  for LIndex := AFirst + 1 to ALast do
  begin
    LTemp := AItems[LIndex];
    LPosition := LIndex;
    while (LPosition > AFirst) and (LTemp.Key < AItems[LPosition - 1].Key) do
    begin
      AItems[LPosition] := AItems[LPosition - 1];
      Dec(LPosition);
    end;
    AItems[LPosition] := LTemp;
  end;
end;

procedure TRendererMergeSorter.MergeSort(AItems: PRendererSortItemArray; AFirst, ALast: Integer);
var
  LMid: Integer;
  LLeft: Integer;
  LRight: Integer;
  LTarget: Integer;
  LFirstCount: Integer;
begin
  LMid := (AFirst + ALast) div 2;
  // sort the first half: with the merge sort, or, if there are few items, with the insertion sort
  if AFirst < LMid then
  begin
    if LMid - AFirst <= MIN_LIST_SIZE then
      InsertionSort(AItems, AFirst, LMid)
    else
      MergeSort(AItems, AFirst, LMid);
  end;
  // the second half likewise
  if (LMid + 1) < ALast then
  begin
    if (ALast - LMid - 1) <= MIN_LIST_SIZE then
      InsertionSort(AItems, Succ(LMid), ALast)
    else
      MergeSort(AItems, Succ(LMid), ALast);
  end;
  // copy the first half of the list to the temporary list
  LFirstCount := LMid - AFirst + 1;
  Move(AItems[AFirst], FTemp[0], LFirstCount * SizeOf(TRendererSortItem));
  // LLeft is the index of the temporary list (the first half), LRight the one of the second
  // half, LTarget where the merged items go
  LLeft := 0;
  LRight := LMid + 1;
  LTarget := AFirst;
  // merge the two lists until one of them is empty
  while (LLeft < LFirstCount) and (LRight <= ALast) do
  begin
    if FTemp[LLeft].Key <= AItems[LRight].Key then
    begin
      AItems[LTarget] := FTemp[LLeft];
      Inc(LLeft);
    end
    else
    begin
      AItems[LTarget] := AItems[LRight];
      Inc(LRight);
    end;
    Inc(LTarget);
  end;
  // the rest of the first list goes back; the rest of the second is already in place
  if LLeft < LFirstCount then
    Move(FTemp[LLeft], AItems[LTarget], (LFirstCount - LLeft) * SizeOf(TRendererSortItem));
end;

procedure TRendererMergeSorter.Sort(AItems: PRendererSortItemArray; ACount: Integer);
begin
  if ACount < 2 then
    Exit;
  Reserve(ACount);
  MergeSort(AItems, 0, ACount - 1);
end;

procedure TRendererMergeSorter.Release;
begin
  FTemp := nil;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the sorting of the sprites      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.SpriteSorters;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererSpriteSorters = class(TObject)
  private
    FSelection: IRendererSpriteSorter;
    FQuick: IRendererSpriteSorter;
    FMerge: IRendererSpriteSorter;
    FRadix: IRendererSpriteSorter;
    FPolicy: IRendererSpriteSortPolicy;
    function RandomItems(ACount, AMaxKey: Integer): TArray<TRendererSortItem>;
    procedure CheckSame(const AOld, ANew: TArray<TRendererSortItem>);
    procedure CheckOrdered(const AItems: TArray<TRendererSortItem>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeOrdinareConLaSelezione;
    [Test]
    procedure DovrebbeOrdinareConIlQuickSort;
    [Test]
    procedure DovrebbeOrdinareConIlMergeSort;
    [Test]
    procedure DovrebbeOrdinareConIlRadixSort;
    [Test]
    procedure DovrebbeUsareLaScalaCorrettaPerOgniOrdinatore;
    [Test]
    procedure DovrebbeScegliereLOrdinatorePerIlNumeroDiSprite;
    [Test]
    procedure DovrebbeFallireSeMancaUnOrdinatore;
    [Test]
    procedure DovrebbeFareComeIlVecchioSelectionSort;
    [Test]
    procedure DovrebbeFareComeIlVecchioQuickSort;
    [Test]
    procedure DovrebbeFareComeIlVecchioMergeSort;
    /// <summary>
    ///   Parity: the old radix sort, copied here as it was, in the case of two passes (keys
    ///   below 2^22) and of three, with many equal keys (the order of equal ones matters)
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioRadixSort;
  end;

implementation

uses
  DelphiDoom.Renderer.Factory, DelphiDoom.Renderer.SpriteSortPolicy;

// the old radix sort counted with wrapping numbers
{$Q-}
{$R-}

{ TTestRendererSpriteSorters }

procedure TTestRendererSpriteSorters.Setup;
begin
  FSelection := TRendererFactory.CreateSelectionSorter;
  FQuick := TRendererFactory.CreateQuickSorter;
  FMerge := TRendererFactory.CreateMergeSorter;
  FRadix := TRendererFactory.CreateRadixSorter;
  FPolicy := TRendererFactory.CreateSpriteSortPolicy;
end;

procedure TTestRendererSpriteSorters.TearDown;
begin
  FPolicy := nil;
  FRadix := nil;
  FMerge := nil;
  FQuick := nil;
  FSelection := nil;
end;

function TTestRendererSpriteSorters.RandomItems(ACount, AMaxKey: Integer): TArray<TRendererSortItem>;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
  begin
    Result[LIndex].Key := Random(AMaxKey);
    // the number of the sprite: it tells which of the equal ones came first
    Result[LIndex].Item := Pointer(LIndex + 1);
  end;
end;

procedure TTestRendererSpriteSorters.CheckSame(const AOld, ANew: TArray<TRendererSortItem>);
var
  LIndex: Integer;
begin
  Assert.AreEqual<Integer>(Length(AOld), Length(ANew));
  for LIndex := 0 to High(AOld) do
  begin
    Assert.AreEqual(AOld[LIndex].Key, ANew[LIndex].Key);
    Assert.AreEqual<NativeInt>(NativeInt(AOld[LIndex].Item), NativeInt(ANew[LIndex].Item));
  end;
end;

procedure TTestRendererSpriteSorters.CheckOrdered(const AItems: TArray<TRendererSortItem>);
var
  LIndex: Integer;
begin
  for LIndex := 1 to High(AItems) do
    Assert.IsTrue(AItems[LIndex - 1].Key <= AItems[LIndex].Key);
end;

procedure TTestRendererSpriteSorters.DovrebbeOrdinareConLaSelezione;
var
  LItems: TArray<TRendererSortItem>;
begin
  RandSeed := 1;
  LItems := RandomItems(30, 100);
  FSelection.Sort(@LItems[0], Length(LItems));
  CheckOrdered(LItems);
end;

procedure TTestRendererSpriteSorters.DovrebbeOrdinareConIlQuickSort;
var
  LItems: TArray<TRendererSortItem>;
begin
  RandSeed := 2;
  LItems := RandomItems(400, 1000);
  FQuick.Sort(@LItems[0], Length(LItems));
  CheckOrdered(LItems);
end;

procedure TTestRendererSpriteSorters.DovrebbeOrdinareConIlMergeSort;
var
  LItems: TArray<TRendererSortItem>;
begin
  RandSeed := 3;
  LItems := RandomItems(900, 1000);
  FMerge.Sort(@LItems[0], Length(LItems));
  CheckOrdered(LItems);
end;

procedure TTestRendererSpriteSorters.DovrebbeOrdinareConIlRadixSort;
var
  LItems: TArray<TRendererSortItem>;
begin
  RandSeed := 4;
  LItems := RandomItems(3000, MaxInt);
  FRadix.Sort(@LItems[0], Length(LItems));
  CheckOrdered(LItems);
end;

procedure TTestRendererSpriteSorters.DovrebbeUsareLaScalaCorrettaPerOgniOrdinatore;
begin
  // the merge sort of the old code ignored the "dropped" adjustment
  Assert.IsTrue(FSelection.UsesDroppedAdjustment);
  Assert.IsTrue(FQuick.UsesDroppedAdjustment);
  Assert.IsFalse(FMerge.UsesDroppedAdjustment);
  Assert.IsTrue(FRadix.UsesDroppedAdjustment);
end;

procedure TTestRendererSpriteSorters.DovrebbeScegliereLOrdinatorePerIlNumeroDiSprite;
begin
  Assert.IsTrue(FPolicy.Select(0) = FPolicy.Select(32));
  Assert.IsFalse(FPolicy.Select(32) = FPolicy.Select(33));
  Assert.IsTrue(FPolicy.Select(33) = FPolicy.Select(512));
  Assert.IsFalse(FPolicy.Select(512) = FPolicy.Select(513));
  Assert.IsTrue(FPolicy.Select(513) = FPolicy.Select(1024));
  Assert.IsFalse(FPolicy.Select(1024) = FPolicy.Select(1025));
  // the four are different sorters
  Assert.IsFalse(FPolicy.Select(10) = FPolicy.Select(100));
  Assert.IsFalse(FPolicy.Select(100) = FPolicy.Select(600));
  Assert.IsFalse(FPolicy.Select(600) = FPolicy.Select(2000));
  Assert.IsFalse(FPolicy.Select(10).UsesDroppedAdjustment = FPolicy.Select(600).UsesDroppedAdjustment);
end;

procedure TTestRendererSpriteSorters.DovrebbeFallireSeMancaUnOrdinatore;
begin
  Assert.WillRaise(
    procedure
    begin
      TRendererSpriteSortPolicy.Create(FSelection, FQuick, nil, FRadix);
    end, EArgumentNilException);
end;

procedure TTestRendererSpriteSorters.DovrebbeFareComeIlVecchioSelectionSort;
var
  LRound: Integer;
  LNew, LOld: TArray<TRendererSortItem>;
  I, J: Integer;
  T: TRendererSortItem;
begin
  RandSeed := 10;
  for LRound := 1 to 200 do
  begin
    LNew := RandomItems(2 + Random(40), 1 + Random(30));
    LOld := Copy(LNew);
    // the old procedure
    for I := 0 to Length(LOld) - 2 do
      for J := Length(LOld) - 1 downto I + 1 do
        if LOld[I].Key > LOld[J].Key then
        begin
          T := LOld[I];
          LOld[I] := LOld[J];
          LOld[J] := T;
        end;
    FSelection.Sort(@LNew[0], Length(LNew));
    CheckSame(LOld, LNew);
  end;
end;

procedure TTestRendererSpriteSorters.DovrebbeFareComeIlVecchioQuickSort;
var
  LRound: Integer;
  LNew, LOld: TArray<TRendererSortItem>;

  procedure QSortOld(L, R: Integer);
  var
    I, J: Integer;
    T: TRendererSortItem;
    Scale: Integer;
  begin
    repeat
      I := L;
      J := R;
      Scale := LOld[(L + R) shr 1].Key;
      repeat
        while LOld[I].Key < Scale do
          Inc(I);
        while LOld[J].Key > Scale do
          Dec(J);
        if I <= J then
        begin
          T := LOld[I];
          LOld[I] := LOld[J];
          LOld[J] := T;
          Inc(I);
          Dec(J);
        end;
      until I > J;
      if L < J then
        QSortOld(L, J);
      L := I;
    until I >= R;
  end;

begin
  RandSeed := 11;
  for LRound := 1 to 200 do
  begin
    LNew := RandomItems(2 + Random(700), 1 + Random(200));
    LOld := Copy(LNew);
    QSortOld(0, Length(LOld) - 1);
    FQuick.Sort(@LNew[0], Length(LNew));
    CheckSame(LOld, LNew);
  end;
end;

procedure TTestRendererSpriteSorters.DovrebbeFareComeIlVecchioMergeSort;
var
  LRound: Integer;
  LNew, LOld: TArray<TRendererSortItem>;
  LTemp: TArray<TRendererSortItem>;

  procedure InsertionOld(First, Last: Integer);
  var
    I, J: Integer;
    T: TRendererSortItem;
  begin
    for I := First + 1 to Last do
    begin
      T := LOld[I];
      J := I;
      while (J > First) and (T.Key < LOld[J - 1].Key) do
      begin
        LOld[J] := LOld[J - 1];
        Dec(J);
      end;
      LOld[J] := T;
    end;
  end;

  procedure MergeOld(First, Last: Integer);
  const
    MIN_LIST_SIZE = 16;
  var
    Mid, I, J, ToInx, FirstCount: Integer;
  begin
    Mid := (First + Last) div 2;
    if First < Mid then
    begin
      if Mid - First <= MIN_LIST_SIZE then
        InsertionOld(First, Mid)
      else
        MergeOld(First, Mid);
    end;
    if (Mid + 1) < Last then
    begin
      if (Last - Mid - 1) <= MIN_LIST_SIZE then
        InsertionOld(Succ(Mid), Last)
      else
        MergeOld(Succ(Mid), Last);
    end;
    FirstCount := Mid - First + 1;
    Move(LOld[First], LTemp[0], FirstCount * SizeOf(TRendererSortItem));
    I := 0;
    J := Mid + 1;
    ToInx := First;
    while (I < FirstCount) and (J <= Last) do
    begin
      if LTemp[I].Key <= LOld[J].Key then
      begin
        LOld[ToInx] := LTemp[I];
        Inc(I);
      end
      else
      begin
        LOld[ToInx] := LOld[J];
        Inc(J);
      end;
      Inc(ToInx);
    end;
    if I < FirstCount then
      Move(LTemp[I], LOld[ToInx], (FirstCount - I) * SizeOf(TRendererSortItem));
  end;

begin
  RandSeed := 12;
  for LRound := 1 to 100 do
  begin
    LNew := RandomItems(2 + Random(1500), 1 + Random(300));
    LOld := Copy(LNew);
    SetLength(LTemp, Length(LOld) div 2 + 1);
    MergeOld(0, Length(LOld) - 1);
    FMerge.Sort(@LNew[0], Length(LNew));
    CheckSame(LOld, LNew);
  end;
end;

procedure TTestRendererSpriteSorters.DovrebbeFareComeIlVecchioRadixSort;
const
  RADIX_BASE = 2048;
  RADIX_MASK = RADIX_BASE - 1;
var
  LRound: Integer;
  LNew, LOld, LBuf1, LBuf2: TArray<TRendererSortItem>;
  LIndexBuf: array[0..5 * RADIX_BASE div 2 - 1] of Integer;
  I, J, N1, N2, N3, Tot, Count: Integer;
  Idx1, Idx2, Idx3: PIntegerArray;
  Pi: PInteger;
  Scale: Cardinal;
  MaxKey: Integer;
begin
  RandSeed := 13;
  for LRound := 1 to 60 do
  begin
    // alternate the keys that need two passes and the ones that need three
    if LRound mod 2 = 0 then
      MaxKey := 1 + Random(1 shl 22)
    else
      MaxKey := MaxInt;
    if LRound mod 3 = 0 then
      MaxKey := 1 + Random(50);
    LNew := RandomItems(2 + Random(3000), MaxKey);
    LOld := Copy(LNew);
    Count := Length(LOld);
    SetLength(LBuf1, Count);
    SetLength(LBuf2, Count);

    // the old procedure
    Idx1 := @LIndexBuf;
    Idx2 := @Idx1[RADIX_BASE];
    Idx3 := @Idx2[RADIX_BASE];
    FillChar(Idx1^, 5 * RADIX_BASE * SizeOf(Integer) div 2, 0);
    for I := 0 to Count - 1 do
    begin
      Scale := Cardinal(LOld[I].Key);
      Inc(Idx1[Scale and RADIX_MASK]);
      Inc(Idx2[(Scale shr 11) and RADIX_MASK]);
      Inc(Idx3[Scale shr 22]);
    end;
    if Idx3[0] = Count then
    begin
      N1 := 0;
      N2 := 0;
      for J := 0 to RADIX_BASE - 1 do
      begin
        Pi := @Idx1[J];
        Tot := Pi^ + N1;
        Pi^ := N1 - 1;
        N1 := Tot;
        Inc(Pi, RADIX_BASE);
        Tot := Pi^ + N2;
        Pi^ := N2 - 1;
        N2 := Tot;
      end;
      for I := 0 to Count - 1 do
      begin
        Pi := @Idx1[Cardinal(LOld[I].Key) and RADIX_MASK];
        Inc(Pi^);
        LBuf1[Pi^] := LOld[I];
      end;
      for I := 0 to Count - 1 do
      begin
        Pi := @Idx2[(Cardinal(LBuf1[I].Key) shr 11) and RADIX_MASK];
        Inc(Pi^);
        LOld[Pi^] := LBuf1[I];
      end;
    end
    else
    begin
      N1 := 0;
      N2 := 0;
      N3 := 0;
      for J := 0 to RADIX_BASE div 2 - 1 do
      begin
        Pi := @Idx1[J];
        Tot := Pi^ + N1;
        Pi^ := N1 - 1;
        N1 := Tot;
        Inc(Pi, RADIX_BASE);
        Tot := Pi^ + N2;
        Pi^ := N2 - 1;
        N2 := Tot;
        Inc(Pi, RADIX_BASE);
        Tot := Pi^ + N3;
        Pi^ := N3 - 1;
        N3 := Tot;
      end;
      for J := RADIX_BASE div 2 to RADIX_BASE - 1 do
      begin
        Pi := @Idx1[J];
        Tot := Pi^ + N1;
        Pi^ := N1 - 1;
        N1 := Tot;
        Inc(Pi, RADIX_BASE);
        Tot := Pi^ + N2;
        Pi^ := N2 - 1;
        N2 := Tot;
      end;
      for I := 0 to Count - 1 do
      begin
        Pi := @Idx1[Cardinal(LOld[I].Key) and RADIX_MASK];
        Inc(Pi^);
        LBuf1[Pi^] := LOld[I];
      end;
      for I := 0 to Count - 1 do
      begin
        Pi := @Idx2[(Cardinal(LBuf1[I].Key) shr 11) and RADIX_MASK];
        Inc(Pi^);
        LBuf2[Pi^] := LBuf1[I];
      end;
      for I := 0 to Count - 1 do
      begin
        Pi := @Idx3[Cardinal(LBuf2[I].Key) shr 22];
        Inc(Pi^);
        LOld[Pi^] := LBuf2[I];
      end;
    end;

    FRadix.Sort(@LNew[0], Length(LNew));
    CheckSame(LOld, LNew);
  end;
end;

end.

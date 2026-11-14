{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the heap and the table of the path   }
{  finding                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.PathHeap;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Path.Types, DelphiDoom.War.Path.NodeHeap,
  DelphiDoom.War.Path.ScatterTable;

type
  /// <summary>The open set: the heap of shl/binary_heap.h with the sift up and sift down of the original</summary>
  [TestFixture]
  [Category('war')]
  TTestWarNodeHeap = class(TObject)
  private
    FHeap: TWarNodeHeap;
    function Node(ATile, AScore: Integer): TWarPathNode;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeDareIPuntiInOrdineDiPunteggioCrescente;
    [Test]
    procedure DovrebbeDareInOrdineDiInserimentoDueNodiADuePariPunteggioNelPrimoCaso;
    [Test]
    procedure DovrebbeTrovareLaCasellaDopoChePiuNodiSiSonoScambiati;
    [Test]
    procedure DovrebbeNonTrovareUnaCasellaGiaUscita;
    [Test]
    procedure DovrebbeRimettereInOrdineUnNodoCheHaPerso;
    [Test]
    procedure DovrebbeRimettereInOrdineUnNodoChePeggiora;
    [Test]
    procedure DovrebbeIgnorareLAggiornamentoDiUnaPosizioneFuoriDalloHeap;
    [Test]
    procedure DovrebbeDimenticareLeCaselleQuandoSiSvuota;
    [Test]
    procedure DovrebbeDareGliStessiOrdiniDiUnaCopiaDelloHeapDiShl;
  end;

  /// <summary>The hash table of shl/map.h that gives the order in which the A star walks the closed set</summary>
  [TestFixture]
  [Category('war')]
  TTestWarScatterTable = class(TObject)
  public
    [Test]
    procedure DovrebbeCominciareConOttoBucketVuoti;
    [Test]
    procedure DovrebbeRaddoppiareQuandoLeChiaviArrivanoAlFattoreDiCarico;
    [Test]
    procedure DovrebbeContareUnaChiaveDueVolteUnaVolta;
    [Test]
    procedure DovrebbeTenereTutteLeChiaviCheSiSonoAggiunte;
    [Test]
    procedure DovrebbeDareLoStessoOrdineDeiBucketDellaMappaDelC;
  end;

implementation

uses
  DelphiDoom.Tests.War.RealData;

type
  /// <summary>shl/binary_heap.h written once more, with the linear search, as the reference of the heap</summary>
  TReferenceHeap = class
  strict private
    FItems: TArray<TWarPathNode>;
    FCount: Integer;
    procedure Up(AIndex: Integer);
    procedure Down(AIndex: Integer);
  public
    procedure Push(const ANode: TWarPathNode);
    function Pop: TWarPathNode;
    function IndexOf(ATile: Integer): Integer;
    procedure Update(AIndex: Integer; const ANode: TWarPathNode);
    property Count: Integer read FCount;
  end;

procedure TReferenceHeap.Up(AIndex: Integer);
var
  LParent: Integer;
  LTemp: TWarPathNode;
begin
  LParent := (AIndex - 1) shr 1;
  while (AIndex > 0) and (FItems[AIndex].FScore - FItems[LParent].FScore < 0) do
  begin
    LTemp := FItems[AIndex];
    FItems[AIndex] := FItems[LParent];
    FItems[LParent] := LTemp;
    AIndex := LParent;
    LParent := (AIndex - 1) shr 1;
  end;
end;

procedure TReferenceHeap.Down(AIndex: Integer);
var
  LLeft: Integer;
  LRight: Integer;
  LMin: Integer;
  LTemp: TWarPathNode;
begin
  while AIndex < FCount do
  begin
    LLeft := 2 * AIndex + 1;
    if LLeft >= FCount then
      Break;
    LMin := LLeft;
    LRight := 2 * AIndex + 2;
    if (LRight < FCount) and (FItems[LRight].FScore - FItems[LMin].FScore < 0) then
      LMin := LRight;
    if FItems[LMin].FScore - FItems[AIndex].FScore >= 0 then
      Break;
    LTemp := FItems[AIndex];
    FItems[AIndex] := FItems[LMin];
    FItems[LMin] := LTemp;
    AIndex := LMin;
  end;
end;

procedure TReferenceHeap.Push(const ANode: TWarPathNode);
begin
  if Length(FItems) <= FCount then
    SetLength(FItems, Length(FItems) * 2 + 8);
  FItems[FCount] := ANode;
  Up(FCount);
  Inc(FCount);
end;

function TReferenceHeap.Pop: TWarPathNode;
begin
  Result := FItems[0];
  FItems[0] := FItems[FCount - 1];
  Dec(FCount);
  Down(0);
end;

function TReferenceHeap.IndexOf(ATile: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FCount - 1 do
    if FItems[LIndex].Id = ATile then
      Exit(LIndex);
  Result := -1;
end;

procedure TReferenceHeap.Update(AIndex: Integer; const ANode: TWarPathNode);
var
  LOld: TWarPathNode;
  LCompare: Integer;
begin
  LOld := FItems[AIndex];
  FItems[AIndex] := ANode;
  LCompare := ANode.FScore - LOld.FScore;
  if LCompare < 0 then
    Up(AIndex)
  else if LCompare > 0 then
    Down(AIndex);
end;

{ TTestWarNodeHeap }

function TTestWarNodeHeap.Node(ATile, AScore: Integer): TWarPathNode;
begin
  Result := Default(TWarPathNode);
  Result.Id := ATile;
  Result.X := ATile mod 64;
  Result.Y := ATile div 64;
  Result.FScore := AScore;
  Result.GScore := AScore;
  Result.Parent := -1;
end;

procedure TTestWarNodeHeap.Setup;
begin
  FHeap := TWarNodeHeap.Create;
end;

procedure TTestWarNodeHeap.TearDown;
begin
  FHeap.Free;
end;

procedure TTestWarNodeHeap.DovrebbeEssereVuotoAllInizio;
begin
  Assert.AreEqual(0, FHeap.Count);
  Assert.AreEqual(-1, FHeap.IndexOf(5));
end;

procedure TTestWarNodeHeap.DovrebbeDareIPuntiInOrdineDiPunteggioCrescente;
var
  LScores: array[0..7] of Integer;
  LIndex: Integer;
  LLast: Integer;
  LNode: TWarPathNode;
begin
  LScores[0] := 50;
  LScores[1] := 10;
  LScores[2] := 80;
  LScores[3] := 30;
  LScores[4] := 20;
  LScores[5] := 70;
  LScores[6] := 60;
  LScores[7] := 40;
  for LIndex := 0 to 7 do
    FHeap.Push(Node(100 + LIndex, LScores[LIndex]));
  Assert.AreEqual(8, FHeap.Count);
  LLast := -1;
  while FHeap.Count > 0 do
  begin
    LNode := FHeap.Pop;
    Assert.IsTrue(LNode.FScore >= LLast, 'in ordine');
    LLast := LNode.FScore;
  end;
  Assert.AreEqual(80, LLast);
end;

procedure TTestWarNodeHeap.DovrebbeDareInOrdineDiInserimentoDueNodiADuePariPunteggioNelPrimoCaso;
begin
  // the sift up stops at an equal score: the node that came first stays above
  FHeap.Push(Node(1, 5));
  FHeap.Push(Node(2, 5));
  Assert.AreEqual(1, FHeap.Pop.Id);
  Assert.AreEqual(2, FHeap.Pop.Id);
end;

procedure TTestWarNodeHeap.DovrebbeTrovareLaCasellaDopoChePiuNodiSiSonoScambiati;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 19 do
    FHeap.Push(Node(10 + LIndex, 100 - LIndex * 3));
  for LIndex := 0 to 19 do
    Assert.IsTrue(FHeap.IndexOf(10 + LIndex) >= 0, 'la casella ' + IntToStr(10 + LIndex));
  // the node found is the one of the tile, wherever the sifts put it
  for LIndex := 0 to 19 do
    Assert.AreEqual(10 + LIndex, FHeap[FHeap.IndexOf(10 + LIndex)].Id);
end;

procedure TTestWarNodeHeap.DovrebbeNonTrovareUnaCasellaGiaUscita;
begin
  FHeap.Push(Node(3, 9));
  FHeap.Push(Node(4, 1));
  Assert.AreEqual(4, FHeap.Pop.Id);
  Assert.AreEqual(-1, FHeap.IndexOf(4));
  Assert.IsTrue(FHeap.IndexOf(3) >= 0);
end;

procedure TTestWarNodeHeap.DovrebbeRimettereInOrdineUnNodoCheHaPerso;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 9 do
    FHeap.Push(Node(10 + LIndex, 50 + LIndex));
  // the node of the worst score gets the best one
  FHeap.Update(FHeap.IndexOf(19), Node(19, 1));
  Assert.AreEqual(19, FHeap.Pop.Id);
end;

procedure TTestWarNodeHeap.DovrebbeRimettereInOrdineUnNodoChePeggiora;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 9 do
    FHeap.Push(Node(10 + LIndex, 50 + LIndex));
  // the node of the best score gets the worst one
  FHeap.Update(FHeap.IndexOf(10), Node(10, 500));
  Assert.AreEqual(11, FHeap.Pop.Id);
end;

procedure TTestWarNodeHeap.DovrebbeIgnorareLAggiornamentoDiUnaPosizioneFuoriDalloHeap;
begin
  FHeap.Push(Node(3, 9));
  FHeap.Update(-1, Node(3, 1));
  FHeap.Update(1, Node(3, 1));
  Assert.AreEqual(9, FHeap.Pop.FScore);
end;

procedure TTestWarNodeHeap.DovrebbeDimenticareLeCaselleQuandoSiSvuota;
begin
  FHeap.Push(Node(3, 9));
  FHeap.Push(Node(4, 2));
  FHeap.Clear;
  Assert.AreEqual(0, FHeap.Count);
  Assert.AreEqual(-1, FHeap.IndexOf(3));
  Assert.AreEqual(-1, FHeap.IndexOf(4));
  // and the tiles can be pushed again
  FHeap.Push(Node(3, 7));
  Assert.AreEqual(0, FHeap.IndexOf(3));
end;

procedure TTestWarNodeHeap.DovrebbeDareGliStessiOrdiniDiUnaCopiaDelloHeapDiShl;
var
  LReference: TReferenceHeap;
  LState: Cardinal;
  LStep: Integer;
  LTile: Integer;
  LScore: Integer;
  LIndex: Integer;
  LNode: TWarPathNode;
  LOurs: TWarPathNode;
  LTheirs: TWarPathNode;
begin
  LReference := TReferenceHeap.Create;
  try
    LState := 12345;
    for LStep := 0 to 3000 do
    begin
      LState := LState * 1664525 + 1013904223;
      LTile := Integer((LState shr 8) mod 300);
      LState := LState * 1664525 + 1013904223;
      LScore := Integer((LState shr 8) mod 40);
      LState := LState * 1664525 + 1013904223;
      if (LState shr 8) mod 3 = 0 then
      begin
        if FHeap.Count > 0 then
        begin
          LOurs := FHeap.Pop;
          LTheirs := LReference.Pop;
          Assert.AreEqual(LTheirs.Id, LOurs.Id, 'il nodo che esce al passo ' + IntToStr(LStep));
        end;
      end
      else
      begin
        LNode := Node(LTile, LScore);
        LIndex := LReference.IndexOf(LTile);
        Assert.AreEqual(LIndex, FHeap.IndexOf(LTile), 'la posizione al passo ' + IntToStr(LStep));
        if LIndex >= 0 then
        begin
          LReference.Update(LIndex, LNode);
          FHeap.Update(LIndex, LNode);
        end
        else
        begin
          LReference.Push(LNode);
          FHeap.Push(LNode);
        end;
      end;
      Assert.AreEqual(LReference.Count, FHeap.Count);
    end;
  finally
    LReference.Free;
  end;
end;

{ TTestWarScatterTable }

procedure TTestWarScatterTable.DovrebbeCominciareConOttoBucketVuoti;
var
  LTable: TWarScatterTable;
  LBucket: Integer;
begin
  LTable := TWarScatterTable.Create;
  try
    Assert.AreEqual(8, LTable.Capacity);
    Assert.AreEqual(0, LTable.Count);
    for LBucket := 0 to 7 do
      Assert.IsFalse(LTable.Active[LBucket]);
  finally
    LTable.Free;
  end;
end;

procedure TTestWarScatterTable.DovrebbeRaddoppiareQuandoLeChiaviArrivanoAlFattoreDiCarico;
var
  LTable: TWarScatterTable;
  LKey: Integer;
begin
  LTable := TWarScatterTable.Create;
  try
    // the first load factor is 6: the seventh key makes 16 buckets (and the factor becomes the old capacity, 8)
    for LKey := 1 to 6 do
      LTable.Add(LKey * 7);
    Assert.AreEqual(8, LTable.Capacity);
    LTable.Add(100);
    Assert.AreEqual(16, LTable.Capacity);
    Assert.AreEqual(7, LTable.Count);
    LTable.Add(101);
    Assert.AreEqual(16, LTable.Capacity);
    LTable.Add(102);
    Assert.AreEqual(32, LTable.Capacity);
  finally
    LTable.Free;
  end;
end;

procedure TTestWarScatterTable.DovrebbeContareUnaChiaveDueVolteUnaVolta;
var
  LTable: TWarScatterTable;
begin
  LTable := TWarScatterTable.Create;
  try
    LTable.Add(42);
    LTable.Add(42);
    LTable.Add(42);
    Assert.AreEqual(1, LTable.Count);
  finally
    LTable.Free;
  end;
end;

procedure TTestWarScatterTable.DovrebbeTenereTutteLeChiaviCheSiSonoAggiunte;
var
  LTable: TWarScatterTable;
  LSeen: array[0..199] of Boolean;
  LKey: Integer;
  LBucket: Integer;
  LActive: Integer;
begin
  LTable := TWarScatterTable.Create;
  try
    for LKey := 0 to 199 do
      LTable.Add(LKey * 5 + 1);
    FillChar(LSeen, SizeOf(LSeen), 0);
    LActive := 0;
    for LBucket := 0 to LTable.Capacity - 1 do
      if LTable.Active[LBucket] then
      begin
        Inc(LActive);
        Assert.AreEqual(1, LTable.Keys[LBucket] mod 5);
        LSeen[(LTable.Keys[LBucket] - 1) div 5] := True;
      end;
    Assert.AreEqual(200, LActive);
    for LKey := 0 to 199 do
      Assert.IsTrue(LSeen[LKey], 'la chiave ' + IntToStr(LKey * 5 + 1));
  finally
    LTable.Free;
  end;
end;

procedure TTestWarScatterTable.DovrebbeDareLoStessoOrdineDeiBucketDellaMappaDelC;
var
  LGolden: TStringList;
  LAll: TStringList;
  LLine: string;
  LSeed: Cardinal;
  LState: Cardinal;
  LDraws: Cardinal;
  LIndex: Cardinal;
  LKey: Integer;
  LTable: TWarScatterTable;
  LHash: Cardinal;
  LBucket: Integer;
  LActual: string;
  LCount: Integer;
begin
  LAll := TStringList.Create;
  LGolden := TStringList.Create;
  try
    LAll.LoadFromFile(TWarRealData.GoldenPath('path.units.golden.txt'));
    for LLine in LAll do
      if (LLine <> '') and (LLine[1] = 'S') then
        LGolden.Add(LLine);
    Assert.AreEqual(20, LGolden.Count, 'scenari del golden');
    LCount := 0;
    for LSeed := 1 to 20 do
    begin
      LState := LSeed * 2654435761 + 31;
      LState := LState * 1664525 + 1013904223;
      LDraws := 1 + (LState shr 8) mod 400;
      LTable := TWarScatterTable.Create;
      try
        for LIndex := 1 to LDraws do
        begin
          LState := LState * 1664525 + 1013904223;
          LKey := Integer((LState shr 8) mod 4096);
          LTable.Add(LKey);
        end;
        LHash := 2166136261;
        for LBucket := 0 to LTable.Capacity - 1 do
          if LTable.Active[LBucket] then
          begin
            LHash := (LHash xor Cardinal(LTable.Keys[LBucket])) * 16777619;
            LHash := (LHash xor Cardinal(LBucket)) * 16777619;
          end;
        LActual := Format('S %u draws=%u count=%d cap=%d h=%s', [LSeed, LDraws, LTable.Count, LTable.Capacity,
          LowerCase(IntToHex(LHash, 8))]);
        Assert.AreEqual(LGolden[LCount], LActual);
        Inc(LCount);
      finally
        LTable.Free;
      end;
    end;
  finally
    LGolden.Free;
    LAll.Free;
  end;
end;

end.

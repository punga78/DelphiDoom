{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib containers                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Containers.Fixture;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of the containers with the C++ idLib (containers.golden.txt: random series of
  ///   operations whose results and internal state were printed by the real idHashIndex,
  ///   idLinkList, idHierarchy, idBTree, idBinSearch and idStrPool) and hand checks
  /// </summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibContainers = class(TObject)
  public
    [Test]
    procedure TIdHashIndexDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdLinkListDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdHierarchyDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdBTreeDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdBinSearchDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdStrPoolDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdHashIndexDovrebbeRifiutareUnaDimensioneNonPotenzaDiDue;
    [Test]
    procedure TIdStrPoolDovrebbeLiberareLaStringaAllUltimoUtente;
    [Test]
    procedure TIdHashIndexDovrebbeCrescereAPassiDellaGranularita;
    [Test]
    procedure TIdHashIndexDovrebbeRispondereMenoUnoPrimaDiAllocare;
    [Test]
    procedure TIdHashIndexDovrebbeCopiareUnaTabellaNonAllocata;
    [Test]
    procedure TIdHashIndexDovrebbeAllargareLIndiceQuandoInserisceOltreLaFine;
    [Test]
    procedure TIdHashIndexDovrebbeRifiutareUnaGranularitaNulla;
    [Test]
    procedure TIdStrPoolDovrebbeCopiareUnaStringaDellaStessaPoolODiUnAltra;
    [Test]
    procedure TIdStrPoolDovrebbeRifiutareLaStringaDiUnAltraPool;
    [Test]
    procedure TIdStrPoolDovrebbeSvuotarsiEContareLaMemoria;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Containers.HashIndex,
  DelphiDoom.IdLib.Containers.StrPool,
  DelphiDoom.Tests.IdLib.Golden, DelphiDoom.Tests.IdLib.Containers.Cases;

type
  TCaseProc = procedure(const ALines: TStrings);

procedure CheckSection(const ASection: string; const AProc: TCaseProc);
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('containers.golden.txt');
  LActual := TStringList.Create;
  try
    LGolden.SelectSection(ASection);
    try
      AProc(LActual);
    finally
      LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.' + ASection + '.actual.txt'));
    end;
    LGolden.Compare(LActual);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestIdLibContainers.TIdHashIndexDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('hashindex', TIdLibContainersCases.HashIndex);
end;

procedure TTestIdLibContainers.TIdLinkListDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('linklist', TIdLibContainersCases.LinkList);
end;

procedure TTestIdLibContainers.TIdHierarchyDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('hierarchy', TIdLibContainersCases.Hierarchy);
end;

procedure TTestIdLibContainers.TIdBTreeDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('btree', TIdLibContainersCases.BTree);
end;

procedure TTestIdLibContainers.TIdBinSearchDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('binsearch', TIdLibContainersCases.BinSearch);
end;

procedure TTestIdLibContainers.TIdStrPoolDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('strpool', TIdLibContainersCases.StrPool);
end;

procedure TTestIdLibContainers.TIdHashIndexDovrebbeRifiutareUnaDimensioneNonPotenzaDiDue;
var
  LRaised: Boolean;
  LHash: TIdHashIndex;
begin
  LRaised := False;
  try
    LHash := TIdHashIndex.Create(100, 10);
    LHash.Free;
  except
    on EArgumentException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestIdLibContainers.TIdStrPoolDovrebbeLiberareLaStringaAllUltimoUtente;
var
  LPool: TIdStrPool;
  LFirst, LSecond: TIdPoolStr;
begin
  LPool := TIdStrPool.Create;
  try
    LFirst := LPool.AllocString('abc');
    LSecond := LPool.AllocString('abc');
    Assert.IsTrue(LFirst = LSecond);
    Assert.AreEqual(2, LFirst.NumUsers);
    LPool.FreeString(LFirst);
    Assert.AreEqual(1, LPool.Num);
    LPool.FreeString(LSecond);
    Assert.AreEqual(0, LPool.Num);
  finally
    LPool.Free;
  end;
end;

// The expected values of the tests below are read in the C++ source (HashIndex.h, HashIndex.cpp,
// StrPool.h): Add allocates with index + 1 entries when the index does not fit, ResizeIndex rounds
// up to a multiple of the granularity and only records the size while nothing is allocated

procedure TTestIdLibContainers.TIdHashIndexDovrebbeCrescereAPassiDellaGranularita;
var
  LHash: TIdHashIndex;
begin
  LHash := TIdHashIndex.Create(16, 4);
  try
    LHash.SetGranularity(8);
    // the first Add allocates: Allocate( hashSize, index + 1 ), without rounding
    LHash.Add(1, 10);
    Assert.AreEqual(11, LHash.GetIndexSize);
    Assert.AreEqual(10, LHash.First(1));
    Assert.AreEqual(-1, LHash.Next(10));
    // then the index grows to the next multiple of the granularity
    LHash.Add(2, 20);
    Assert.AreEqual(24, LHash.GetIndexSize);
    LHash.ResizeIndex(32);
    Assert.AreEqual(32, LHash.GetIndexSize, 'already a multiple');
    LHash.ResizeIndex(16);
    Assert.AreEqual(32, LHash.GetIndexSize, 'a smaller size changes nothing');
    Assert.AreEqual(20, LHash.First(2), 'the chains survive the growth');
    Assert.AreEqual(10, LHash.First(1));
  finally
    LHash.Free;
  end;
end;

procedure TTestIdLibContainers.TIdHashIndexDovrebbeRispondereMenoUnoPrimaDiAllocare;
var
  LHash: TIdHashIndex;
begin
  LHash := TIdHashIndex.Create(16, 4);
  try
    LHash.SetGranularity(8);
    LHash.ResizeIndex(5);
    // nothing allocated: only the size is recorded
    Assert.AreEqual(8, LHash.GetIndexSize);
    Assert.AreEqual(-1, LHash.First(3));
    Assert.AreEqual(-1, LHash.Next(0));
    LHash.Add(3, 2);
    Assert.AreEqual(8, LHash.GetIndexSize, 'the index fits: Allocate( hashSize, indexSize )');
    Assert.AreEqual(2, LHash.First(3));
  finally
    LHash.Free;
  end;
end;

procedure TTestIdLibContainers.TIdHashIndexDovrebbeCopiareUnaTabellaNonAllocata;
var
  LEmpty, LHash: TIdHashIndex;
begin
  LEmpty := TIdHashIndex.Create(32, 8);
  LHash := TIdHashIndex.Create(16, 4);
  try
    LHash.Add(5, 1);
    Assert.AreEqual(1, LHash.First(5));
    LHash.Assign(LEmpty);
    Assert.AreEqual(32, LHash.GetHashSize);
    Assert.AreEqual(8, LHash.GetIndexSize);
    Assert.AreEqual(-1, LHash.First(5), 'the memory of the copy is freed');
  finally
    LHash.Free;
    LEmpty.Free;
  end;
end;

procedure TTestIdLibContainers.TIdHashIndexDovrebbeAllargareLIndiceQuandoInserisceOltreLaFine;
var
  LHash: TIdHashIndex;
  LIndex: Integer;
begin
  LHash := TIdHashIndex.Create(16, 4);
  try
    LHash.SetGranularity(4);
    for LIndex := 0 to 3 do
      LHash.Add(LIndex, LIndex);
    Assert.AreEqual(4, LHash.GetIndexSize);
    // every index moves up by one: the last one (4) needs a larger index
    LHash.InsertIndex(9, 0);
    Assert.AreEqual(8, LHash.GetIndexSize);
    Assert.AreEqual(0, LHash.First(9));
    for LIndex := 0 to 3 do
      Assert.AreEqual(LIndex + 1, LHash.First(LIndex));
  finally
    LHash.Free;
  end;
end;

procedure TTestIdLibContainers.TIdHashIndexDovrebbeRifiutareUnaGranularitaNulla;
var
  LHash: TIdHashIndex;
begin
  LHash := TIdHashIndex.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LHash.SetGranularity(0);
      end, EArgumentException);
    // Clear( newHashSize, newIndexSize ) does not check the size: the next Add allocates it
    LHash.Clear(3, 4);
    Assert.WillRaise(
      procedure
      begin
        LHash.Add(1, 1);
      end, EArgumentException);
  finally
    LHash.Free;
  end;
end;

procedure TTestIdLibContainers.TIdStrPoolDovrebbeCopiareUnaStringaDellaStessaPoolODiUnAltra;
var
  LPool, LOther: TIdStrPool;
  LString, LCopy, LForeign: TIdPoolStr;
begin
  LPool := TIdStrPool.Create;
  LOther := TIdStrPool.Create;
  try
    LString := LPool.AllocString('abc');
    // from this pool: just one more user
    LCopy := LPool.CopyString(LString);
    Assert.IsTrue(LCopy = LString);
    Assert.AreEqual(2, LString.NumUsers);
    Assert.AreEqual(1, LPool.Num);
    // from another pool: allocated again here
    LForeign := LOther.CopyString(LString);
    Assert.IsTrue(LForeign <> LString);
    Assert.IsTrue(LForeign.Pool = LOther);
    Assert.AreEqual('abc', string(LForeign.Text));
    Assert.AreEqual(1, LForeign.NumUsers);
    Assert.AreEqual(2, LString.NumUsers, 'the original is not touched');
  finally
    LOther.Free;
    LPool.Free;
  end;
end;

procedure TTestIdLibContainers.TIdStrPoolDovrebbeRifiutareLaStringaDiUnAltraPool;
var
  LPool, LOther: TIdStrPool;
  LString: TIdPoolStr;
begin
  LPool := TIdStrPool.Create;
  LOther := TIdStrPool.Create;
  try
    LString := LPool.AllocString('abc');
    Assert.WillRaise(
      procedure
      begin
        LOther.FreeString(LString);
      end, EIdLibException);
    Assert.AreEqual(1, LString.NumUsers);
  finally
    LOther.Free;
    LPool.Free;
  end;
end;

procedure TTestIdLibContainers.TIdStrPoolDovrebbeSvuotarsiEContareLaMemoria;
var
  LPool: TIdStrPool;
  LEmpty, LOne: NativeInt;
begin
  LPool := TIdStrPool.Create;
  try
    LEmpty := LPool.Allocated;
    LPool.AllocString('abcdefgh');
    LOne := LPool.Allocated;
    Assert.IsTrue(LOne >= LEmpty + 8, 'the characters of the string are counted');
    LPool.AllocString('xyz');
    Assert.AreEqual(2, LPool.Num);
    LPool.Clear;
    Assert.AreEqual(0, LPool.Num);
    // after Clear the pool is usable again
    Assert.AreEqual(1, LPool.AllocString('abc').NumUsers);
  finally
    LPool.Free;
  end;
end;

end.

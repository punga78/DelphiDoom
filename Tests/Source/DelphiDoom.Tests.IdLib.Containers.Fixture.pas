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
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Containers.HashIndex, DelphiDoom.IdLib.Containers.StrPool,
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

end.

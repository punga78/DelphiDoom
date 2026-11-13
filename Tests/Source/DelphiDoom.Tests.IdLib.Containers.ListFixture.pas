{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TIdList, TIdStaticList and TIdHashTable                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Containers.ListFixture;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity of the list containers with the C++ idLib (lists.golden.txt: random series of operations
  ///   whose results and state were printed by the real idList, idStaticList and idHashTable) and
  ///   checks by hand of the cases the series do not reach
  /// </summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibLists = class(TObject)
  public
    [Test]
    procedure TIdListDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdStaticListDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdHashTableDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure TIdListDovrebbeCrescereAPassiDellaGranularita;
    [Test]
    procedure TIdListDovrebbeAllocareSoloAlPrimoElemento;
    [Test]
    procedure TIdListDovrebbeRifiutareGranularitaENumeriNegativi;
    [Test]
    procedure TIdListDovrebbeRifiutareUnIndiceFuoriDallaLista;
    [Test]
    procedure TIdListDovrebbeConfrontareConIlConfrontatoreIniettato;
    [Test]
    procedure TIdListDovrebbeOrdinareConUnConfronto;
    [Test]
    procedure TIdListDovrebbeCondensareEScambiare;
    [Test]
    procedure TIdListDovrebbeCopiareSoloGliElementiUsati;
    [Test]
    procedure TIdListDovrebbeAccodareUnaListaAncheDiPiuGranularita;
    [Test]
    procedure TIdStaticListDovrebbeRispondereMenoUnoQuandoEPiena;
    [Test]
    procedure TIdStaticListDovrebbeRifiutareCapacitaEIndiciSbagliati;
    [Test]
    procedure TIdStaticListDovrebbeRifiutareListeDiCapacitaDiversa;
    [Test]
    procedure TIdHashTableDovrebbeRifiutareUnaDimensioneNonPotenzaDiDue;
    [Test]
    procedure TIdHashTableDovrebbeDistinguereLeMaiuscole;
    [Test]
    procedure TIdHashTableDovrebbeCopiarsiEIgnorareLaCopiaSuSeStessa;
    [Test]
    procedure TIdHashTableDovrebbeDareFalsoFuoriDalleVoci;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Defaults, DelphiDoom.IdLib.Core.Exceptions,
  DelphiDoom.IdLib.Containers.List, DelphiDoom.IdLib.Containers.StaticList,
  DelphiDoom.IdLib.Containers.HashTable, DelphiDoom.Tests.IdLib.Golden,
  DelphiDoom.Tests.IdLib.Containers.ListCases;

type
  TCaseProc = procedure(const ALines: TStrings);

procedure CheckSection(const ASection: string; const AProc: TCaseProc);
var
  LGolden: TIdLibGolden;
  LActual: TStringList;
begin
  LGolden := TIdLibGolden.Create('lists.golden.txt');
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

procedure TTestIdLibLists.TIdListDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('list', TIdLibListCases.List);
end;

procedure TTestIdLibLists.TIdStaticListDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('staticlist', TIdLibListCases.StaticList);
end;

procedure TTestIdLibLists.TIdHashTableDovrebbeDareLeStesseRispostePerIlCpp;
begin
  CheckSection('hashtable', TIdLibListCases.HashTable);
end;

procedure TTestIdLibLists.TIdListDovrebbeCrescereAPassiDellaGranularita;
var
  LList: TIdList<Integer>;
  LIndex: Integer;
begin
  LList := TIdList<Integer>.Create(4);
  try
    for LIndex := 1 to 5 do
      LList.Append(LIndex);
    Assert.AreEqual(5, LList.Num);
    Assert.AreEqual(8, LList.NumAllocated);
    Assert.AreEqual(4, LList.GetGranularity);
    LList.SetGranularity(3);
    Assert.AreEqual(6, LList.NumAllocated);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibLists.TIdListDovrebbeAllocareSoloAlPrimoElemento;
var
  LList: TIdList<Integer>;
begin
  LList := TIdList<Integer>.Create(8);
  try
    Assert.AreEqual(0, LList.NumAllocated);
    LList.Insert(7);
    Assert.AreEqual(8, LList.NumAllocated);
    LList.Clear;
    Assert.AreEqual(0, LList.NumAllocated);
    Assert.AreEqual(0, LList.Num);
    LList.AssureSize(3);
    Assert.AreEqual(3, LList.Num);
    Assert.AreEqual(8, LList.NumAllocated);
    LList.AssureSize(20, 5);
    Assert.AreEqual(20, LList.Num);
    Assert.AreEqual(24, LList.NumAllocated);
    Assert.AreEqual(5, LList[19]);
    Assert.AreEqual(20, LList.Alloc);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibLists.TIdListDovrebbeRifiutareGranularitaENumeriNegativi;
var
  LList: TIdList<Integer>;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdList<Integer>.Create(0).Free;
    end, EIdLibException);
  LList := TIdList<Integer>.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LList.Resize(-1);
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        LList.Resize(-1, 4);
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        LList.Resize(4, 0);
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        LList.SetNum(-2);
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        LList.SetGranularity(0);
      end, EIdLibException);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibLists.TIdListDovrebbeRifiutareUnIndiceFuoriDallaLista;
var
  LList: TIdList<Integer>;
begin
  LList := TIdList<Integer>.Create;
  try
    LList.Append(1);
    LList[0] := 9;
    Assert.AreEqual(9, LList[0]);
    Assert.WillRaise(
      procedure
      begin
        LList[1] := 3;
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        if LList[-1] = 0 then;
      end, EIdLibException);
    Assert.IsFalse(LList.RemoveIndex(1));
    Assert.IsFalse(LList.Remove(55));
  finally
    LList.Free;
  end;
end;

type
  TModuloTenEqual = class(TInterfacedObject, IEqualityComparer<Integer>)
    function Equals(const ALeft, ARight: Integer): Boolean; reintroduce;
    function GetHashCode(const AValue: Integer): Integer; reintroduce;
  end;

function TModuloTenEqual.Equals(const ALeft, ARight: Integer): Boolean;
begin
  Result := (ALeft mod 10) = (ARight mod 10);
end;

function TModuloTenEqual.GetHashCode(const AValue: Integer): Integer;
begin
  Result := AValue mod 10;
end;

procedure TTestIdLibLists.TIdListDovrebbeConfrontareConIlConfrontatoreIniettato;
var
  LList: TIdList<Integer>;
  LStatic: TIdStaticList<Integer>;
begin
  LList := TIdList<Integer>.Create(4, TModuloTenEqual.Create);
  LStatic := TIdStaticList<Integer>.Create(4, TModuloTenEqual.Create);
  try
    LList.Append(13);
    Assert.AreEqual(0, LList.AddUnique(23));
    Assert.AreEqual(1, LList.Num);
    LStatic.Append(13);
    Assert.AreEqual(0, LStatic.FindIndex(3));
  finally
    LStatic.Free;
    LList.Free;
  end;
end;

procedure TTestIdLibLists.TIdListDovrebbeOrdinareConUnConfronto;
var
  LList: TIdList<Integer>;
begin
  LList := TIdList<Integer>.Create(4);
  try
    LList.Sort;
    LList.SortSubSection(0, 3);
    LList.Append(3);
    LList.Append(1);
    LList.Append(2);
    LList.Append(0);
    LList.Sort(TComparer<Integer>.Construct(
      function(const ALeft, ARight: Integer): Integer
      begin
        Result := ARight - ALeft;
      end));
    Assert.AreEqual(3, LList[0]);
    Assert.AreEqual(0, LList[3]);
    LList.SortSubSection(1, 9,
      TComparer<Integer>.Construct(
        function(const ALeft, ARight: Integer): Integer
        begin
          Result := ALeft - ARight;
        end));
    Assert.AreEqual(0, LList[1]);
    Assert.AreEqual(2, LList[3]);
    LList.SortSubSection(-4, 2);
    Assert.AreEqual(0, LList[0]);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibLists.TIdListDovrebbeCondensareEScambiare;
var
  LFirst, LSecond: TIdList<Integer>;
begin
  LFirst := TIdList<Integer>.Create(8);
  LSecond := TIdList<Integer>.Create(2);
  try
    LFirst.Condense;
    LFirst.Append(5);
    LFirst.Condense;
    Assert.AreEqual(1, LFirst.NumAllocated);
    LFirst.Swap(LSecond);
    Assert.AreEqual(0, LFirst.Num);
    Assert.AreEqual(2, LFirst.GetGranularity);
    Assert.AreEqual(1, LSecond.Num);
    Assert.AreEqual(8, LSecond.GetGranularity);
    LSecond.RemoveIndex(0);
    LSecond.Condense;
    Assert.AreEqual(0, LSecond.NumAllocated);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestIdLibLists.TIdListDovrebbeCopiareSoloGliElementiUsati;
var
  LFirst, LSecond: TIdList<Integer>;
begin
  LFirst := TIdList<Integer>.Create(4);
  LSecond := TIdList<Integer>.Create(16);
  try
    LFirst.Append(1);
    LFirst.Append(2);
    LFirst.Append(3);
    LFirst.RemoveIndex(2);
    LSecond.Assign(LFirst);
    Assert.AreEqual(2, LSecond.Num);
    Assert.AreEqual(4, LSecond.NumAllocated);
    Assert.AreEqual(4, LSecond.GetGranularity);
    // the third element was left behind the end by RemoveIndex: it does not travel with the copy
    LSecond.SetNum(3, False);
    Assert.AreEqual(0, LSecond[2]);
    LFirst.SetNum(3, False);
    Assert.AreEqual(3, LFirst[2]);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestIdLibLists.TIdListDovrebbeAccodareUnaListaAncheDiPiuGranularita;
var
  LFirst, LSecond: TIdList<Integer>;
begin
  LFirst := TIdList<Integer>.Create(2);
  LSecond := TIdList<Integer>.Create(16);
  try
    LSecond.Append(1);
    LSecond.Append(2);
    LSecond.Append(3);
    Assert.AreEqual(3, LFirst.Append(LSecond));
    Assert.AreEqual(4, LFirst.NumAllocated);
    Assert.AreEqual(3, LFirst[2]);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestIdLibLists.TIdStaticListDovrebbeRispondereMenoUnoQuandoEPiena;
var
  LList: TIdStaticList<Integer>;
  LOther: TIdStaticList<Integer>;
begin
  LList := TIdStaticList<Integer>.Create(2);
  LOther := TIdStaticList<Integer>.Create(2);
  try
    Assert.AreEqual(0, LList.Append(1));
    Assert.AreEqual(1, LList.Alloc);
    Assert.AreEqual(-1, LList.Alloc);
    Assert.AreEqual(-1, LList.Append(3));
    Assert.AreEqual(-1, LList.Insert(3, 0));
    Assert.AreEqual(-1, LList.AddUnique(77));
    Assert.AreEqual(2, LList.Num);
    Assert.AreEqual(2, LList.Max);
    LOther.Append(8);
    LOther.Append(9);
    Assert.AreEqual(2, LOther.Append(LList));
    Assert.IsFalse(LList.Remove(1000));
    LList.Clear;
    Assert.AreEqual(2, LList.Append(LOther));
  finally
    LOther.Free;
    LList.Free;
  end;
end;

procedure TTestIdLibLists.TIdStaticListDovrebbeRifiutareCapacitaEIndiciSbagliati;
var
  LList: TIdStaticList<Integer>;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdStaticList<Integer>.Create(-1).Free;
    end, EIdLibException);
  LList := TIdStaticList<Integer>.Create(3);
  try
    LList.Append(4);
    LList[0] := 5;
    Assert.AreEqual(5, LList[0]);
    Assert.WillRaise(
      procedure
      begin
        LList[1] := 1;
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        if LList[-1] = 0 then;
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        LList.SetNum(4);
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        LList.SetNum(-1);
      end, EIdLibException);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibLists.TIdStaticListDovrebbeRifiutareListeDiCapacitaDiversa;
var
  LFirst, LSecond: TIdStaticList<Integer>;
begin
  LFirst := TIdStaticList<Integer>.Create(2);
  LSecond := TIdStaticList<Integer>.Create(3);
  try
    Assert.WillRaise(
      procedure
      begin
        LFirst.Swap(LSecond);
      end, EIdLibException);
    Assert.WillRaise(
      procedure
      begin
        LFirst.Assign(LSecond);
      end, EIdLibException);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestIdLibLists.TIdHashTableDovrebbeRifiutareUnaDimensioneNonPotenzaDiDue;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdHashTable<Integer>.Create(6).Free;
    end, EIdLibException);
  Assert.WillRaise(
    procedure
    begin
      TIdHashTable<Integer>.Create(0).Free;
    end, EIdLibException);
end;

procedure TTestIdLibLists.TIdHashTableDovrebbeDistinguereLeMaiuscole;
var
  LTable: TIdHashTable<Integer>;
  LValue: Integer;
begin
  LTable := TIdHashTable<Integer>.Create(1);
  try
    LTable.Put('Foo', 1);
    LTable.Put('foo', 2);
    LTable.Put('Foo', 3);
    Assert.AreEqual(2, LTable.Num);
    Assert.IsTrue(LTable.Get('Foo', LValue));
    Assert.AreEqual(3, LValue);
    Assert.IsTrue(LTable.Get('foo'));
    Assert.IsFalse(LTable.Get('FOO', LValue));
    Assert.AreEqual(0, LValue);
    Assert.IsFalse(LTable.Remove('FOO'));
    Assert.IsTrue(LTable.Remove('Foo'));
    Assert.IsFalse(LTable.Remove('Foo'));
    Assert.AreEqual(1, LTable.Num);
    Assert.AreEqual(1, LTable.GetTableSize);
  finally
    LTable.Free;
  end;
end;

procedure TTestIdLibLists.TIdHashTableDovrebbeCopiarsiEIgnorareLaCopiaSuSeStessa;
var
  LTable, LCopy: TIdHashTable<Integer>;
  LValue: Integer;
begin
  LTable := TIdHashTable<Integer>.Create(4);
  LCopy := TIdHashTable<Integer>.Create(256);
  try
    LTable.Put('a', 1);
    LTable.Put('b', 2);
    LCopy.Put('zzz', 9);
    LCopy.Assign(LTable);
    LCopy.Assign(LCopy);
    Assert.AreEqual(2, LCopy.Num);
    Assert.AreEqual(4, LCopy.GetTableSize);
    Assert.IsTrue(LCopy.Get('b', LValue));
    Assert.AreEqual(2, LValue);
    LCopy.Put('b', 5);
    Assert.IsTrue(LTable.Get('b', LValue));
    Assert.AreEqual(2, LValue);
  finally
    LCopy.Free;
    LTable.Free;
  end;
end;

procedure TTestIdLibLists.TIdHashTableDovrebbeDareFalsoFuoriDalleVoci;
var
  LTable: TIdHashTable<Integer>;
  LValue: Integer;
begin
  LTable := TIdHashTable<Integer>.Create(8);
  try
    LTable.Put('a', 4);
    Assert.IsFalse(LTable.GetIndex(-1, LValue));
    Assert.IsFalse(LTable.GetIndex(1, LValue));
    Assert.IsTrue(LTable.GetIndex(0, LValue));
    Assert.AreEqual(4, LValue);
  finally
    LTable.Free;
  end;
end;


end.

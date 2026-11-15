{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the functions of TIdList for lists of pointers         }
{  (FindNull, DeleteContents, AssureSizeAlloc, Ptr)                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Containers.ListPointers;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   The functions of idList that exist for lists of pointers. The C++ is trivial and is not a
  ///   golden: the expected numbers follow from the definitions in List.h (the allocation goes up
  ///   to the allocated size, a nil pointer is skipped by delete).
  /// </summary>
  [TestFixture]
  [Category('idlib')]
  TTestIdLibListPointers = class(TObject)
  public
    [Test]
    procedure FindNullDovrebbeDareIlPrimoElementoNil;
    [Test]
    procedure FindNullDovrebbeDareMenoUnoSeNonCeNeSono;
    [Test]
    procedure FindNullDovrebbeVederePureLozeroDiUnaListaDiNumeri;
    [Test]
    procedure DeleteContentsDovrebbeLiberareGliOggettiESvuotare;
    [Test]
    procedure DeleteContentsSenzaSvuotareDovrebbeLasciareGliElementiANil;
    [Test]
    procedure DeleteContentsDovrebbeRifiutareUnaListaDiNumeri;
    [Test]
    procedure AssureSizeAllocDovrebbeCrearePiuElementiDiQuelliRichiesti;
    [Test]
    procedure AssureSizeAllocNonDovrebbeRiallocareSeBastaLaDimensione;
    [Test]
    procedure AssureSizeAllocDovrebbeRifiutareUnAllocatoreNullo;
    [Test]
    procedure PtrDovrebbeDareNilSenzaAllocazioneEIlPrimoElementoDopo;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Containers.List, DelphiDoom.IdLib.Core.Exceptions;

var
  GDestroyed: Integer;

type
  TCounted = class
  public
    destructor Destroy; override;
  end;

destructor TCounted.Destroy;
begin
  Inc(GDestroyed);
  inherited Destroy;
end;

procedure TTestIdLibListPointers.FindNullDovrebbeDareIlPrimoElementoNil;
var
  LList: TIdList<TObject>;
  LItem: TObject;
begin
  LItem := TObject.Create;
  LList := TIdList<TObject>.Create(4);
  try
    LList.Append(LItem);
    LList.Append(TObject(nil));
    LList.Append(LItem);
    LList.Append(TObject(nil));
    Assert.AreEqual(1, LList.FindNull);
  finally
    LList.Free;
    LItem.Free;
  end;
end;

procedure TTestIdLibListPointers.FindNullDovrebbeDareMenoUnoSeNonCeNeSono;
var
  LList: TIdList<TObject>;
  LItem: TObject;
begin
  LItem := TObject.Create;
  LList := TIdList<TObject>.Create(4);
  try
    Assert.AreEqual(-1, LList.FindNull, 'lista vuota');
    LList.Append(LItem);
    Assert.AreEqual(-1, LList.FindNull);
  finally
    LList.Free;
    LItem.Free;
  end;
end;

procedure TTestIdLibListPointers.FindNullDovrebbeVederePureLozeroDiUnaListaDiNumeri;
var
  LList: TIdList<Integer>;
begin
  LList := TIdList<Integer>.Create;
  try
    LList.Append(5);
    LList.Append(0);
    Assert.AreEqual(1, LList.FindNull);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibListPointers.DeleteContentsDovrebbeLiberareGliOggettiESvuotare;
var
  LList: TIdList<TCounted>;
begin
  GDestroyed := 0;
  LList := TIdList<TCounted>.Create(4);
  try
    LList.Append(TCounted.Create);
    LList.Append(TCounted(nil));
    LList.Append(TCounted.Create);
    LList.DeleteContents(True);
    Assert.AreEqual(2, GDestroyed, 'un oggetto nil e'' saltato');
    Assert.AreEqual(0, LList.Num);
    Assert.AreEqual(0, LList.NumAllocated);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibListPointers.DeleteContentsSenzaSvuotareDovrebbeLasciareGliElementiANil;
var
  LList: TIdList<TCounted>;
begin
  GDestroyed := 0;
  LList := TIdList<TCounted>.Create(4);
  try
    LList.Append(TCounted.Create);
    LList.Append(TCounted.Create);
    LList.DeleteContents(False);
    Assert.AreEqual(2, GDestroyed);
    Assert.AreEqual(2, LList.Num);
    Assert.IsNull(LList[0]);
    Assert.IsNull(LList[1]);
    Assert.AreEqual(0, LList.FindNull);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibListPointers.DeleteContentsDovrebbeRifiutareUnaListaDiNumeri;
var
  LList: TIdList<Integer>;
begin
  LList := TIdList<Integer>.Create;
  try
    LList.Append(1);
    Assert.WillRaise(
      procedure
      begin
        LList.DeleteContents(True);
      end, EIdLibException);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibListPointers.AssureSizeAllocDovrebbeCrearePiuElementiDiQuelliRichiesti;
var
  LList: TIdList<TCounted>;
  LCalls: Integer;
  LIndex: Integer;
begin
  LCalls := 0;
  GDestroyed := 0;
  LList := TIdList<TCounted>.Create(8);
  try
    // 3 elements asked, 8 allocated: the allocator runs for each of the 8 slots, as in the C++
    LList.AssureSizeAlloc(3,
      function: TCounted
      begin
        Inc(LCalls);
        Result := TCounted.Create;
      end);
    Assert.AreEqual(3, LList.Num);
    Assert.AreEqual(8, LList.NumAllocated);
    Assert.AreEqual(8, LCalls);
    Assert.IsNotNull(LList[2]);
    // the slots beyond Num are the caller's to free
    LList.AssureSize(8);
    for LIndex := 0 to 7 do
    begin
      LList[LIndex].Free;
    end;
  finally
    LList.Free;
  end;
  Assert.AreEqual(8, GDestroyed);
end;

procedure TTestIdLibListPointers.AssureSizeAllocNonDovrebbeRiallocareSeBastaLaDimensione;
var
  LList: TIdList<TCounted>;
  LCalls: Integer;
begin
  LCalls := 0;
  LList := TIdList<TCounted>.Create(8);
  try
    LList.Append(TCounted(nil));
    LList.Append(TCounted(nil));
    LList.AssureSizeAlloc(5,
      function: TCounted
      begin
        Inc(LCalls);
        Result := nil;
      end);
    Assert.AreEqual(0, LCalls, 'la dimensione allocata basta: nessun elemento nuovo');
    Assert.AreEqual(5, LList.Num);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibListPointers.AssureSizeAllocDovrebbeRifiutareUnAllocatoreNullo;
var
  LList: TIdList<TObject>;
begin
  LList := TIdList<TObject>.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LList.AssureSizeAlloc(3, nil);
      end, EIdLibException);
  finally
    LList.Free;
  end;
end;

procedure TTestIdLibListPointers.PtrDovrebbeDareNilSenzaAllocazioneEIlPrimoElementoDopo;
var
  LList: TIdList<Integer>;
begin
  LList := TIdList<Integer>.Create;
  try
    Assert.IsNull(LList.Ptr);
    LList.Append(7);
    LList.Append(9);
    Assert.AreEqual(7, PInteger(LList.Ptr)^);
    Assert.AreEqual(9, PIntegerArray(LList.Ptr)^[1]);
  finally
    LList.Free;
  end;
end;

end.

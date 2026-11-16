{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the slots of the active ceilings and platforms         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.ActiveSlots;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.ActiveSlots;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersActiveSlots = class
  strict private
    FSlots: TActiveSlots;
    FItems: array[0..9] of Byte;
    function Item(const AIndex: Integer): Pointer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereVuotoAllaCreazione;
    [Test]
    procedure DovrebbeUsareIlPrimoPostoLibero;
    [Test]
    procedure DovrebbeRiusareIlPostoLiberatoPerPrimo;
    [Test]
    procedure DovrebbeDareFalsoQuandoPieno;
    [Test]
    procedure DovrebbeTrovareSoloCioCheContiene;
    [Test]
    procedure DovrebbeNonTrovareNil;
    [Test]
    procedure DovrebbeRimuovereEDireSeC;
    [Test]
    procedure DovrebbeLiberareUnPostoConRelease;
    [Test]
    procedure DovrebbeSvuotarsiConClear;
    [Test]
    procedure DovrebbeRifiutareUnaCapacitaNonPositiva;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriDaiLimiti;
  end;

implementation

{ TTestThinkersActiveSlots }

procedure TTestThinkersActiveSlots.Setup;
begin
  FSlots := TActiveSlots.Create(3);
end;

procedure TTestThinkersActiveSlots.TearDown;
begin
  FSlots.Free;
end;

function TTestThinkersActiveSlots.Item(const AIndex: Integer): Pointer;
begin
  Result := @FItems[AIndex];
end;

procedure TTestThinkersActiveSlots.DovrebbeEssereVuotoAllaCreazione;
var
  LIndex: Integer;
begin
  Assert.AreEqual(3, FSlots.Capacity);
  for LIndex := 0 to FSlots.Capacity - 1 do
    Assert.IsNull(FSlots[LIndex]);
end;

procedure TTestThinkersActiveSlots.DovrebbeUsareIlPrimoPostoLibero;
begin
  Assert.IsTrue(FSlots.Add(Item(0)));
  Assert.IsTrue(FSlots.Add(Item(1)));
  Assert.AreEqual(0, FSlots.IndexOf(Item(0)));
  Assert.AreEqual(1, FSlots.IndexOf(Item(1)));
end;

procedure TTestThinkersActiveSlots.DovrebbeRiusareIlPostoLiberatoPerPrimo;
begin
  FSlots.Add(Item(0));
  FSlots.Add(Item(1));
  FSlots.Add(Item(2));
  FSlots.Release(1);
  FSlots.Add(Item(3));
  Assert.AreEqual(1, FSlots.IndexOf(Item(3)));
end;

procedure TTestThinkersActiveSlots.DovrebbeDareFalsoQuandoPieno;
begin
  FSlots.Add(Item(0));
  FSlots.Add(Item(1));
  FSlots.Add(Item(2));
  Assert.IsFalse(FSlots.Add(Item(3)));
  Assert.IsFalse(FSlots.Contains(Item(3)));
end;

procedure TTestThinkersActiveSlots.DovrebbeTrovareSoloCioCheContiene;
begin
  FSlots.Add(Item(0));
  Assert.IsTrue(FSlots.Contains(Item(0)));
  Assert.IsFalse(FSlots.Contains(Item(1)));
  Assert.AreEqual(-1, FSlots.IndexOf(Item(1)));
end;

procedure TTestThinkersActiveSlots.DovrebbeNonTrovareNil;
begin
  // a free slot is nil, but it is not a thinker: the saved games ask for real ones
  Assert.IsFalse(FSlots.Contains(nil));
  Assert.AreEqual(-1, FSlots.IndexOf(nil));
end;

procedure TTestThinkersActiveSlots.DovrebbeRimuovereEDireSeC;
begin
  FSlots.Add(Item(0));
  Assert.IsTrue(FSlots.Remove(Item(0)));
  Assert.IsFalse(FSlots.Contains(Item(0)));
  Assert.IsFalse(FSlots.Remove(Item(0)));
end;

procedure TTestThinkersActiveSlots.DovrebbeLiberareUnPostoConRelease;
begin
  FSlots.Add(Item(0));
  FSlots.Release(0);
  Assert.IsNull(FSlots[0]);
end;

procedure TTestThinkersActiveSlots.DovrebbeSvuotarsiConClear;
begin
  FSlots.Add(Item(0));
  FSlots.Add(Item(1));
  FSlots.Clear;
  Assert.IsFalse(FSlots.Contains(Item(0)));
  Assert.IsFalse(FSlots.Contains(Item(1)));
end;

procedure TTestThinkersActiveSlots.DovrebbeRifiutareUnaCapacitaNonPositiva;
begin
  Assert.WillRaise(
    procedure
    begin
      TActiveSlots.Create(0).Free;
    end,
    EArgumentOutOfRangeException);
end;

procedure TTestThinkersActiveSlots.DovrebbeRifiutareUnIndiceFuoriDaiLimiti;
begin
  Assert.WillRaise(
    procedure
    begin
      FSlots.Release(3);
    end,
    EArgumentOutOfRangeException);
end;

end.

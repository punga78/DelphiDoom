{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixLevelVersions and of the choice of the fixes     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LevelVersions;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Level.Versions, DelphiDoom.Radix.Level.Intf, DelphiDoom.Radix.Level.FixSelector,
  DelphiDoom.Radix.Level.FixV2, DelphiDoom.Radix.Level.FixV11, DelphiDoom.Radix.Level.FixV10,
  DelphiDoom.Radix.Level.FixNone;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixLevelVersions = class(TObject)
  public
    [Test]
    procedure DovrebbeRiconoscereUnLivelloDellaVersione2;
    [Test]
    procedure DovrebbeRiconoscereUnLivelloDellaVersione10;
    [Test]
    procedure DovrebbeDareLaPrecedenzaAllaVersione11SeLaSommaEComune;
    [Test]
    procedure DovrebbeDareSconosciutoPerUnaSommaChePerQuelLivelloNonCe;
    [Test]
    procedure DovrebbeDareSconosciutoPerUnLivelloCheNonEUnLivello;
    [Test]
    procedure DovrebbeScegliereLeCorrezioniDellaVersione;
  end;

implementation

{ TTestRadixLevelVersions }

procedure TTestRadixLevelVersions.DovrebbeRiconoscereUnLivelloDellaVersione2;
begin
  Assert.AreEqual(Ord(rlvV2), Ord(TRadixLevelVersions.Identify('E1M1', $1E621ABE)));
  Assert.AreEqual(Ord(rlvV2), Ord(TRadixLevelVersions.Identify('E3M9', $6EDAD08A)));
end;

procedure TTestRadixLevelVersions.DovrebbeRiconoscereUnLivelloDellaVersione10;
begin
  Assert.AreEqual(Ord(rlvV10), Ord(TRadixLevelVersions.Identify('E1M1', $508E903B)));
end;

procedure TTestRadixLevelVersions.DovrebbeDareLaPrecedenzaAllaVersione11SeLaSommaEComune;
begin
  // E1M3 is the same in the 1.0 and in the 1.1
  Assert.AreEqual(Ord(rlvV11), Ord(TRadixLevelVersions.Identify('E1M3', $4FCE4AC0)));
  // E1M1 of the 1.1
  Assert.AreEqual(Ord(rlvV11), Ord(TRadixLevelVersions.Identify('E1M1', $9332AD1B)));
end;

procedure TTestRadixLevelVersions.DovrebbeDareSconosciutoPerUnaSommaChePerQuelLivelloNonCe;
begin
  Assert.AreEqual(Ord(rlvUnknown), Ord(TRadixLevelVersions.Identify('E1M1', $4FCE4AC0)));
  Assert.AreEqual(Ord(rlvUnknown), Ord(TRadixLevelVersions.Identify('E1M1', 0)));
end;

procedure TTestRadixLevelVersions.DovrebbeDareSconosciutoPerUnLivelloCheNonEUnLivello;
begin
  Assert.AreEqual(Ord(rlvUnknown), Ord(TRadixLevelVersions.Identify('E4M1', $1E621ABE)));
  Assert.AreEqual(Ord(rlvUnknown), Ord(TRadixLevelVersions.Identify('', 0)));
end;

procedure TTestRadixLevelVersions.DovrebbeScegliereLeCorrezioniDellaVersione;
var
  LSelector: IRadixLevelFixSelector;
begin
  LSelector := TRadixLevelFixSelector.Create;
  Assert.IsTrue(LSelector.Select('E1M1', $1E621ABE) is TRadixLevelFixV2);
  Assert.IsTrue(LSelector.Select('E1M1', $9332AD1B) is TRadixLevelFixV11);
  Assert.IsTrue(LSelector.Select('E1M1', $508E903B) is TRadixLevelFixV10);
  Assert.IsTrue(LSelector.Select('E1M1', 12345) is TRadixLevelFixNone);
end;

end.

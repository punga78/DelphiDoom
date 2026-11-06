{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the id Tech library - generations and versions         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdTech.Types;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdTech.Types;

type
  [TestFixture]
  [Category('idtech')]
  TTestIdTechTypes = class(TObject)
  public
    [TestCase('doom 1.99', '99,0,99,0.99')]
    [TestCase('doom 1.10', '110,1,10,1.10')]
    [TestCase('delphidoom 2.07', '207,2,7,2.07')]
    [TestCase('2.00', '200,2,0,2.00')]
    [TestCase('zero', '0,0,0,0.00')]
    procedure TestFromNumber(ANumber, AMajor, AMinor: Integer; const AText: string);
    [Test]
    procedure TestFromNumberRefusesNegatives;
    [Test]
    procedure TestCreateChecksTheParts;
    [Test]
    procedure TestNumberIsTheInverseOfFromNumber;
    [Test]
    procedure TestComparisons;
    [Test]
    procedure TestGenerationNumbersAndNames;
  end;

implementation

{ TTestIdTechTypes }

procedure TTestIdTechTypes.TestFromNumber(ANumber, AMajor, AMinor: Integer; const AText: string);
var
  LVersion: TIdTechVersion;
begin
  LVersion := TIdTechVersion.FromNumber(ANumber);
  Assert.AreEqual(AMajor, LVersion.Major);
  Assert.AreEqual(AMinor, LVersion.Minor);
  Assert.AreEqual(AText, LVersion.ToString);
  Assert.AreEqual(ANumber, LVersion.Number);
end;

procedure TTestIdTechTypes.TestFromNumberRefusesNegatives;
begin
  Assert.WillRaise(procedure begin TIdTechVersion.FromNumber(-1); end, EIdTechException);
end;

procedure TTestIdTechTypes.TestCreateChecksTheParts;
begin
  Assert.AreEqual('2.07', TIdTechVersion.Create(2, 7).ToString);
  Assert.AreEqual(1, TIdTechVersion.Create(0, 1).Number);
  Assert.WillRaise(procedure begin TIdTechVersion.Create(-1, 0); end, EIdTechException);
  Assert.WillRaise(procedure begin TIdTechVersion.Create(1, 100); end, EIdTechException);
  Assert.WillRaise(procedure begin TIdTechVersion.Create(1, -1); end, EIdTechException);
end;

procedure TTestIdTechTypes.TestNumberIsTheInverseOfFromNumber;
var
  LNumber: Integer;
begin
  for LNumber := 0 to 999 do
    Assert.AreEqual(LNumber, TIdTechVersion.FromNumber(LNumber).Number);
end;

procedure TTestIdTechTypes.TestComparisons;
var
  LOld, LNew, LSame: TIdTechVersion;
begin
  LOld := TIdTechVersion.FromNumber(122);
  LNew := TIdTechVersion.FromNumber(203);
  LSame := TIdTechVersion.Create(1, 22);
  Assert.IsTrue(LOld < LNew);
  Assert.IsTrue(LOld <= LNew);
  Assert.IsTrue(LNew > LOld);
  Assert.IsTrue(LNew >= LOld);
  Assert.IsTrue(LOld = LSame);
  Assert.IsTrue(LOld <= LSame);
  Assert.IsTrue(LOld >= LSame);
  Assert.IsTrue(LOld <> LNew);
  Assert.IsFalse(LOld > LSame);
  Assert.AreEqual(-1, TIdTechVersion.Compare(LOld, LNew));
  Assert.AreEqual(1, TIdTechVersion.Compare(LNew, LOld));
  Assert.AreEqual(0, TIdTechVersion.Compare(LOld, LSame));
end;

procedure TTestIdTechTypes.TestGenerationNumbersAndNames;
begin
  Assert.AreEqual(1, TIdTechGeneration.IdTech1.Number);
  Assert.AreEqual(7, TIdTechGeneration.IdTech7.Number);
  Assert.AreEqual('id Tech 1', TIdTechGeneration.IdTech1.Name);
  Assert.AreEqual('id Tech 4', TIdTechGeneration.IdTech4.Name);
end;

end.

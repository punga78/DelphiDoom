{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixForceFieldRules                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.PhysicsForceField;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Physics.ForceField;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixPhysicsForceField = class(TObject)
  public
    [Test]
    procedure DovrebbeRiconoscereIlBitDelCampoDiForza;
    [Test]
    [TestCase('solo davanti', '1024,0,True')]
    [TestCase('solo dietro', '0,1024,True')]
    [TestCase('tutti e due', '1024,1056,False')]
    [TestCase('nessuno', '9,32,False')]
    procedure UnaLineaDovrebbeFermareLaNavettaSoloSulBordoDelCampo(AFront, ABack: Integer; AExpected: Boolean);
    [Test]
    procedure LaDirezioneDovrebbePartireDalPrimoVerticeSeIlCampoEDietro;
    [Test]
    // the fine tables have 8192 steps a turn
    [TestCase('linea verso est: spinta a sud', '0,6144')]
    [TestCase('linea verso nord: spinta a est', '1073741824,0')]
    [TestCase('linea verso ovest: spinta a nord', '2147483648,2048')]
    [TestCase('linea verso sud: spinta a ovest', '3221225472,4096')]
    procedure LaSpintaDovrebbeEssereAUnQuartoDiGiroADestraDellaLinea(ALineAngle: Cardinal; AExpected: Integer);
    [Test]
    procedure IlMomentoDovrebbeEssereDiTrentaUnitaATic;
  end;

implementation

{ TTestRadixPhysicsForceField }

procedure TTestRadixPhysicsForceField.DovrebbeRiconoscereIlBitDelCampoDiForza;
begin
  Assert.IsTrue(TRadixForceFieldRules.HasField($400));
  Assert.IsTrue(TRadixForceFieldRules.HasField($409));
  Assert.IsFalse(TRadixForceFieldRules.HasField($3FF));
  Assert.IsFalse(TRadixForceFieldRules.HasField(0));
end;

procedure TTestRadixPhysicsForceField.UnaLineaDovrebbeFermareLaNavettaSoloSulBordoDelCampo(AFront, ABack: Integer;
  AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixForceFieldRules.BlocksCraft(AFront, ABack));
end;

procedure TTestRadixPhysicsForceField.LaDirezioneDovrebbePartireDalPrimoVerticeSeIlCampoEDietro;
begin
  Assert.IsTrue(TRadixForceFieldRules.FromFirstVertex($400));
  Assert.IsFalse(TRadixForceFieldRules.FromFirstVertex(0));
end;

procedure TTestRadixPhysicsForceField.LaSpintaDovrebbeEssereAUnQuartoDiGiroADestraDellaLinea(ALineAngle: Cardinal;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixForceFieldRules.ThrustFineAngle(ALineAngle));
end;

procedure TTestRadixPhysicsForceField.IlMomentoDovrebbeEssereDiTrentaUnitaATic;
begin
  Assert.AreEqual(30 * 65536, TRadixForceFieldRules.Momentum(65536));
  Assert.AreEqual(-30 * 65536, TRadixForceFieldRules.Momentum(-65536));
  Assert.AreEqual(0, TRadixForceFieldRules.Momentum(0));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixPhysicsForceField);

end.

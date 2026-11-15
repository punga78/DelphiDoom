{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixContactRules                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.PhysicsContact;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Physics.Contact;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixPhysicsContact = class(TObject)
  public
    [Test]
    // mover flag, other flag, mover type, other type, mover ancestor, other ancestor, strict, expected
    [TestCase('stesso tipo', 'True,True,7,7,1,1,False,True')]
    [TestCase('tipi diversi come Rad-X', 'True,True,7,8,1,2,False,True')]
    [TestCase('solo chi si muove', 'True,False,7,7,1,1,False,False')]
    [TestCase('solo l altro', 'False,True,7,7,1,1,False,False')]
    [TestCase('nessuno', 'False,False,7,7,1,1,False,False')]
    [TestCase('stretto stesso tipo', 'True,True,7,7,1,2,True,True')]
    [TestCase('stretto stesso antenato', 'True,True,7,8,3,3,True,True')]
    [TestCase('stretto specie diverse', 'True,True,7,8,1,2,True,False')]
    [TestCase('stretto senza flag', 'True,False,7,7,1,1,True,False')]
    procedure DovrebbeLasciarPassareLaStessaSpecie(AMoverFlag, AOtherFlag: Boolean; AMoverType, AOtherType,
      AMoverAncestor, AOtherAncestor: Integer; AStrict, AExpected: Boolean);
    [Test]
    procedure SenzaIndicarloDovrebbeValereLaRegolaDiRadX;
    [Test]
    [TestCase('sovrapposte', '0,0,20,32,True')]
    [TestCase('vicine', '51,-51,20,32,True')]
    [TestCase('a contatto esatto', '52,0,20,32,False')]
    [TestCase('lontane su y', '0,60,20,32,False')]
    [TestCase('lontane su x', '-60,0,20,32,False')]
    [TestCase('senza traboccare', '2147483647,0,2147483647,2147483647,True')]
    procedure DovrebbeDireSeDueScatoleSiToccano(ADeltaX, ADeltaY, AFirstRadius, ASecondRadius: Integer;
      AExpected: Boolean);
    [Test]
    [TestCase('stessa quota', '0,56,0,56,True')]
    [TestCase('appoggiata sopra', '56,56,0,56,True')]
    [TestCase('sopra', '57,56,0,56,False')]
    [TestCase('appoggiata sotto', '-56,56,0,56,True')]
    [TestCase('sotto', '-57,56,0,56,False')]
    procedure DovrebbeDireSeDueCoseSiToccanoInAltezza(AFirstZ, AFirstHeight, ASecondZ, ASecondHeight: Integer;
      AExpected: Boolean);
    [Test]
    [TestCase('senza limite', 'False,99999,10,True')]
    [TestCase('dentro', 'True,10,4096,True')]
    [TestCase('sul bordo', 'True,4096,4096,True')]
    [TestCase('fuori', 'True,4097,4096,False')]
    procedure UnNemicoDovrebbeCercareSoloNelSuoRaggioDiPattuglia(ALimited: Boolean; ADistance, ARange: Integer;
      AExpected: Boolean);
    [Test]
    // two sided, z, height, front floor, back floor, front ceiling, back ceiling, expected
    [TestCase('a un lato ferma sempre', 'False,500,8,0,0,0,0,True')]
    [TestCase('nell apertura passa', 'True,490,8,352,480,640,512,False')]
    [TestCase('sotto il pannello ferma', 'True,400,8,352,480,640,512,True')]
    [TestCase('appena sopra il pannello passa', 'True,480,8,352,480,640,512,False')]
    [TestCase('sopra l apertura ferma', 'True,505,8,352,480,640,512,True')]
    [TestCase('contro il soffitto passa', 'True,504,8,352,480,640,512,False')]
    [TestCase('settore chiuso ferma', 'True,512,8,352,512,640,512,True')]
    [TestCase('senza traboccare', 'True,2147483647,8,0,0,2147483647,2147483647,True')]
    procedure UnaLineaDovrebbeFermareUnMissileSoloSeNonCiPassa(ATwoSided: Boolean; AZ, AHeight, AFrontFloor,
      ABackFloor, AFrontCeiling, ABackCeiling: Integer; AExpected: Boolean);
  end;

implementation

{ TTestRadixPhysicsContact }

procedure TTestRadixPhysicsContact.DovrebbeLasciarPassareLaStessaSpecie(AMoverFlag, AOtherFlag: Boolean; AMoverType,
  AOtherType, AMoverAncestor, AOtherAncestor: Integer; AStrict, AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixContactRules.PassesSpecies(AMoverFlag, AOtherFlag, AMoverType, AOtherType,
    AMoverAncestor, AOtherAncestor, AStrict));
end;

procedure TTestRadixPhysicsContact.SenzaIndicarloDovrebbeValereLaRegolaDiRadX;
begin
  Assert.IsTrue(TRadixContactRules.PassesSpecies(True, True, 1, 2, 3, 4));
end;

procedure TTestRadixPhysicsContact.DovrebbeDireSeDueScatoleSiToccano(ADeltaX, ADeltaY, AFirstRadius,
  ASecondRadius: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixContactRules.BoxesTouch(ADeltaX, ADeltaY, AFirstRadius, ASecondRadius));
end;

procedure TTestRadixPhysicsContact.DovrebbeDireSeDueCoseSiToccanoInAltezza(AFirstZ, AFirstHeight, ASecondZ,
  ASecondHeight: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixContactRules.HeightsTouch(AFirstZ, AFirstHeight, ASecondZ, ASecondHeight));
end;

procedure TTestRadixPhysicsContact.UnNemicoDovrebbeCercareSoloNelSuoRaggioDiPattuglia(ALimited: Boolean; ADistance,
  ARange: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixContactRules.InPatrolRange(ALimited, ADistance, ARange));
end;

procedure TTestRadixPhysicsContact.UnaLineaDovrebbeFermareUnMissileSoloSeNonCiPassa(ATwoSided: Boolean; AZ, AHeight,
  AFrontFloor, ABackFloor, AFrontCeiling, ABackCeiling: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixContactRules.LineStopsMissile(ATwoSided, AZ, AHeight, AFrontFloor, ABackFloor,
    AFrontCeiling, ABackCeiling));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixPhysicsContact);

end.

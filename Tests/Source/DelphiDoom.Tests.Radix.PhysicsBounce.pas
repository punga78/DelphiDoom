{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixBounceRules                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.PhysicsBounce;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Physics.Bounce;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixPhysicsBounce = class(TObject)
  public
    [Test]
    procedure UnContoLimitatoDovrebbeFinireDopoISuoiRimbalzi;
    [Test]
    procedure UnContoNonLimitatoNonDovrebbeCambiare;
    [Test]
    procedure UnContoGiaAZeroDovrebbeToglierIRimbalzi;
    [Test]
    [TestCase('muro pieno', 'True,False,0,0,0,True')]
    [TestCase('muro pieno colpibile', 'True,True,0,0,0,False')]
    [TestCase('due lati dentro apertura', 'False,False,100,0,200,False')]
    [TestCase('due lati sul bordo basso', 'False,False,0,0,200,False')]
    [TestCase('due lati sul bordo alto', 'False,False,200,0,200,False')]
    [TestCase('due lati sotto il gradino', 'False,False,-1,0,200,True')]
    [TestCase('due lati sopra apertura', 'False,False,201,0,200,True')]
    [TestCase('due lati colpibile fuori apertura', 'False,True,300,0,200,False')]
    procedure DovrebbeDecidereSeUnaLineaFaDaSpecchio(ASolid, AShootable: Boolean; AZ, ABottom, ATop: Integer;
      AExpected: Boolean);
    [Test]
    [TestCase('attraversa', 'False,True,10,10,True')]
    [TestCase('si avvicina', 'True,True,100,50,True')]
    [TestCase('si allontana', 'True,True,50,100,False')]
    [TestCase('stessa distanza', 'False,False,50,50,False')]
    procedure DovrebbeRiflettereSoloVersoLaLinea(ASideNow, ASideNext: Boolean; ADistanceNow, ADistanceNext: Integer;
      AExpected: Boolean);
    [Test]
    [TestCase('dimezza', '655360,False,0,327680')]
    [TestCase('dimezza negativo tronca verso zero', '-5,False,0,-2')]
    [TestCase('fattore uno', '655360,True,65536,655360')]
    [TestCase('fattore mezzo', '655360,True,32768,327680')]
    [TestCase('fattore zero', '655360,True,0,0')]
    [TestCase('fattore su negativo arrotonda in giu', '-3,True,32768,-2')]
    procedure DovrebbeRallentareDopoUnRimbalzoSenzaLinea(AMomentum: Integer; AHasFactor: Boolean; AFactor,
      AExpected: Integer);
    [Test]
    procedure DovrebbeGirareIlMomentoSullAsseBloccato;
    [Test]
    [TestCase('non rimbalza', 'False,False,False,0')]
    [TestCase('rimbalza', 'True,False,False,1')]
    [TestCase('missile rimbalza', 'True,True,False,1')]
    [TestCase('missile sul cielo esplode', 'True,True,True,2')]
    [TestCase('cosa sul cielo si ferma', 'True,False,True,0')]
    [TestCase('missile senza rimbalzo sul cielo', 'False,True,True,0')]
    procedure DovrebbeDecidereCosaSuccedeSulPavimento(AFloorBounce, AMissile, ASky: Boolean; AExpected: Integer);
    [Test]
    [TestCase('rimbalza', 'True,False,1')]
    [TestCase('cielo', 'True,True,0')]
    [TestCase('senza rimbalzo', 'False,False,0')]
    procedure DovrebbeDecidereCosaSuccedeSulSoffitto(ACeilingBounce, ASky: Boolean; AExpected: Integer);
    [Test]
    [TestCase('missile tiene la velocita', '-655360,True,655360')]
    [TestCase('cosa ne perde meta', '-655360,False,327680')]
    [TestCase('verso il basso dal soffitto', '655360,False,-327680')]
    [TestCase('ferma', '0,True,0')]
    procedure DovrebbeInvertireIlMomentoVerticale(AMomentumZ: Integer; AMissile: Boolean; AExpected: Integer);
    [Test]
    procedure UnLiquidoDovrebbeFinireIRimbalzi;
    [Test]
    [TestCase('senza rimbalzi esplode', 'False,False,True,False,False,False,1')]
    [TestCase('sul pavimento riparte in su', 'True,False,True,False,False,False,3')]
    [TestCase('sul pavimento di cielo sparisce', 'True,False,True,False,True,False,2')]
    [TestCase('sul soffitto riparte in giu', 'False,True,False,True,False,False,4')]
    [TestCase('sul soffitto di cielo sparisce', 'False,True,False,True,False,True,2')]
    [TestCase('in aria continua', 'True,True,False,False,False,False,0')]
    [TestCase('solo soffitto ma sul pavimento continua', 'False,True,True,False,False,False,0')]
    [TestCase('pavimento prima del soffitto', 'True,True,True,True,False,True,3')]
    procedure UnMissileFermatoDaUnMuroDovrebbeSfiorare(AFloorBounce, ACeilingBounce, AOnFloor, AOnCeiling,
      AFloorSky, ACeilingSky: Boolean; AExpected: Integer);
    [Test]
    [TestCase('positivo', '98304,98304,147456')]
    [TestCase('segni diversi', '-98304,98304,-147456')]
    [TestCase('arrotonda in giu', '-1,1,-1')]
    [TestCase('zero', '0,65536,0')]
    [TestCase('grande senza traboccare', '2147418112,65536,2147418112')]
    procedure IlProdottoFixedDovrebbeArrotondareInGiu(AFirst, ASecond, AExpected: Integer);
  end;

implementation

{ TTestRadixPhysicsBounce }

procedure TTestRadixPhysicsBounce.UnContoLimitatoDovrebbeFinireDopoISuoiRimbalzi;
var
  LCount: Integer;
begin
  LCount := 3;
  Assert.IsFalse(TRadixBounceRules.CountDown(True, LCount));
  Assert.AreEqual(2, LCount);
  Assert.IsFalse(TRadixBounceRules.CountDown(True, LCount));
  Assert.IsTrue(TRadixBounceRules.CountDown(True, LCount), 'il terzo rimbalzo e'' l''ultimo');
  Assert.AreEqual(0, LCount);
end;

procedure TTestRadixPhysicsBounce.UnContoNonLimitatoNonDovrebbeCambiare;
var
  LCount: Integer;
begin
  LCount := 0;
  Assert.IsFalse(TRadixBounceRules.CountDown(False, LCount));
  Assert.AreEqual(0, LCount);
  LCount := 5;
  Assert.IsFalse(TRadixBounceRules.CountDown(False, LCount));
  Assert.AreEqual(5, LCount);
end;

procedure TTestRadixPhysicsBounce.UnContoGiaAZeroDovrebbeToglierIRimbalzi;
var
  LCount: Integer;
begin
  LCount := 0;
  Assert.IsTrue(TRadixBounceRules.CountDown(True, LCount));
  Assert.AreEqual(0, LCount);
  LCount := -2;
  Assert.IsFalse(TRadixBounceRules.CountDown(True, LCount), 'un conto negativo non finisce (come Rad-X)');
  Assert.AreEqual(-2, LCount);
end;

procedure TTestRadixPhysicsBounce.DovrebbeDecidereSeUnaLineaFaDaSpecchio(ASolid, AShootable: Boolean; AZ, ABottom,
  ATop: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixBounceRules.BouncesOnLine(ASolid, AShootable, AZ, ABottom, ATop));
end;

procedure TTestRadixPhysicsBounce.DovrebbeRiflettereSoloVersoLaLinea(ASideNow, ASideNext: Boolean; ADistanceNow,
  ADistanceNext: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixBounceRules.Reflects(ASideNow, ASideNext, ADistanceNow, ADistanceNext));
end;

procedure TTestRadixPhysicsBounce.DovrebbeRallentareDopoUnRimbalzoSenzaLinea(AMomentum: Integer; AHasFactor: Boolean;
  AFactor, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixBounceRules.SlowDown(AMomentum, AHasFactor, AFactor));
end;

procedure TTestRadixPhysicsBounce.DovrebbeGirareIlMomentoSullAsseBloccato;
var
  LMomentumX: Integer;
  LMomentumY: Integer;
begin
  LMomentumX := 100;
  LMomentumY := -200;
  TRadixBounceRules.Mirror(LMomentumX, LMomentumY, True);
  Assert.AreEqual(100, LMomentumX);
  Assert.AreEqual(200, LMomentumY);
  TRadixBounceRules.Mirror(LMomentumX, LMomentumY, False);
  Assert.AreEqual(-100, LMomentumX);
  Assert.AreEqual(200, LMomentumY);
end;

procedure TTestRadixPhysicsBounce.DovrebbeDecidereCosaSuccedeSulPavimento(AFloorBounce, AMissile, ASky: Boolean;
  AExpected: Integer);
begin
  Assert.AreEqual<Integer>(AExpected, Ord(TRadixBounceRules.FloorHit(AFloorBounce, AMissile, ASky)));
end;

procedure TTestRadixPhysicsBounce.DovrebbeDecidereCosaSuccedeSulSoffitto(ACeilingBounce, ASky: Boolean;
  AExpected: Integer);
begin
  Assert.AreEqual<Integer>(AExpected, Ord(TRadixBounceRules.CeilingHit(ACeilingBounce, ASky)));
end;

procedure TTestRadixPhysicsBounce.DovrebbeInvertireIlMomentoVerticale(AMomentumZ: Integer; AMissile: Boolean;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixBounceRules.PlaneMomentum(AMomentumZ, AMissile));
end;

procedure TTestRadixPhysicsBounce.UnLiquidoDovrebbeFinireIRimbalzi;
begin
  Assert.IsTrue(TRadixBounceRules.FloorEndsBounces(True));
  Assert.IsFalse(TRadixBounceRules.FloorEndsBounces(False));
end;

procedure TTestRadixPhysicsBounce.UnMissileFermatoDaUnMuroDovrebbeSfiorare(AFloorBounce, ACeilingBounce, AOnFloor,
  AOnCeiling, AFloorSky, ACeilingSky: Boolean; AExpected: Integer);
begin
  Assert.AreEqual<Integer>(AExpected, Ord(TRadixBounceRules.MissileSkim(AFloorBounce, ACeilingBounce, AOnFloor, AOnCeiling,
    AFloorSky, ACeilingSky)));
end;

procedure TTestRadixPhysicsBounce.IlProdottoFixedDovrebbeArrotondareInGiu(AFirst, ASecond, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixBounceRules.FixedMul(AFirst, ASecond));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixPhysicsBounce);

end.

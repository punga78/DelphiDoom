{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixCraftImpactRules                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.PhysicsImpact;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Physics.Impact;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixPhysicsImpact = class(TObject)
  public
    [Test]
    procedure UnMuroDovrebbeContareUnTicERaschiareInUnSettoreDiRadix;
    [Test]
    procedure UnMuroFuoriDaRadixDovrebbeSuonareLUrto;
    [Test]
    procedure UnMuroNonDovrebbeSuonareMentreIlSuonoPrecedenteDura;
    [Test]
    procedure UnaNavettaMutaDovrebbeContareSenzaSuono;
    [Test]
    [TestCase('fumo', '0,1')]
    [TestCase('ultimo numero col fumo', '127,1')]
    [TestCase('primo numero senza', '128,0')]
    [TestCase('senza', '255,0')]
    procedure IlFumoDelMuroDovrebbeNascereUnaVoltaSuDue(ARandom, AExpected: Integer);
    [Test]
    // on floor, floor solid, on ceiling, ceiling solid, speed, hit, penalty, smokes
    [TestCase('pavimento piano', 'True,True,False,False,262144,False,0,0')]
    [TestCase('pavimento leggero', 'True,True,False,False,262145,True,35,8')]
    [TestCase('pavimento al limite del forte', 'True,True,False,False,524288,True,35,8')]
    [TestCase('pavimento forte', 'True,True,False,False,524289,True,70,16')]
    [TestCase('pavimento in salita conta lo stesso', 'True,True,False,False,-600000,True,70,16')]
    [TestCase('pavimento liquido', 'True,False,False,False,600000,False,0,0')]
    [TestCase('in aria', 'False,True,False,True,600000,False,0,0')]
    [TestCase('soffitto leggero', 'False,False,True,True,300000,True,35,8')]
    [TestCase('soffitto forte', 'False,False,True,True,-600000,True,70,16')]
    [TestCase('soffitto non solido', 'False,False,True,False,600000,False,0,0')]
    [TestCase('pavimento liquido e soffitto solido', 'True,False,True,True,600000,True,70,16')]
    procedure DovrebbeMisurareLUrtoColPavimentoEColSoffitto(AOnFloor, AFloorSolid, AOnCeiling, ACeilingSolid: Boolean;
      ASpeed: Integer; AHit: Boolean; APenalty, ASmokes: Integer);
    [Test]
    procedure IlPavimentoDovrebbeSuonareSecondoIlSettore;
    [Test]
    procedure IlSoffittoDovrebbeSempreRaschiareEFarPartireIlTempoAncheDaMuta;
    [Test]
    procedure NessunUrtoDiPianoMentreIlSuonoPrecedenteDura;
    [Test]
    [TestCase('atterra', 'True,True,True,35')]
    [TestCase('era gia a terra', 'False,True,True,0')]
    [TestCase('ancora in volo', 'True,False,True,0')]
    [TestCase('sul bordo di un altro pavimento', 'True,True,False,0')]
    procedure DovrebbePenalizzareLAtterraggio(AWasAbove, AOnFloor, APlainFloor: Boolean; AExpected: Integer);
    [Test]
    procedure LaScivolataDovrebbeSospendereIlControlloDelleAltezze;
    [Test]
    procedure IlContoAllaRovesciaDovrebbeFermarsiAZero;
  end;

implementation

{ TTestRadixPhysicsImpact }

procedure TTestRadixPhysicsImpact.UnMuroDovrebbeContareUnTicERaschiareInUnSettoreDiRadix;
var
  LImpact: TRadixImpact;
begin
  LImpact := TRadixCraftImpactRules.WallHit(0, False, True, 200);
  Assert.IsTrue(LImpact.Hit);
  Assert.AreEqual(1, LImpact.Penalty);
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.Scrape), Ord(LImpact.Sound));
  Assert.IsTrue(LImpact.StartsSoundTimer);
  Assert.AreEqual(0, LImpact.Smokes);
end;

procedure TTestRadixPhysicsImpact.UnMuroFuoriDaRadixDovrebbeSuonareLUrto;
var
  LImpact: TRadixImpact;
begin
  LImpact := TRadixCraftImpactRules.WallHit(-3, False, False, 200);
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.PlaneHit), Ord(LImpact.Sound));
  Assert.IsTrue(LImpact.StartsSoundTimer);
end;

procedure TTestRadixPhysicsImpact.UnMuroNonDovrebbeSuonareMentreIlSuonoPrecedenteDura;
var
  LImpact: TRadixImpact;
begin
  LImpact := TRadixCraftImpactRules.WallHit(1, False, True, 0);
  Assert.IsTrue(LImpact.Hit);
  Assert.AreEqual(1, LImpact.Penalty, 'l''urto si conta lo stesso');
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.None), Ord(LImpact.Sound));
  Assert.IsFalse(LImpact.StartsSoundTimer);
  Assert.AreEqual(1, LImpact.Smokes);
end;

procedure TTestRadixPhysicsImpact.UnaNavettaMutaDovrebbeContareSenzaSuono;
var
  LImpact: TRadixImpact;
begin
  LImpact := TRadixCraftImpactRules.WallHit(0, True, True, 200);
  Assert.AreEqual(1, LImpact.Penalty);
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.None), Ord(LImpact.Sound));
  Assert.IsFalse(LImpact.StartsSoundTimer);
end;

procedure TTestRadixPhysicsImpact.IlFumoDelMuroDovrebbeNascereUnaVoltaSuDue(ARandom, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixCraftImpactRules.WallHit(0, False, True, ARandom).Smokes);
end;

procedure TTestRadixPhysicsImpact.DovrebbeMisurareLUrtoColPavimentoEColSoffitto(AOnFloor, AFloorSolid, AOnCeiling,
  ACeilingSolid: Boolean; ASpeed: Integer; AHit: Boolean; APenalty, ASmokes: Integer);
var
  LImpact: TRadixImpact;
begin
  LImpact := TRadixCraftImpactRules.PlaneHit(0, AOnFloor, AFloorSolid, AOnCeiling, ACeilingSolid, False, True, ASpeed);
  Assert.AreEqual(AHit, LImpact.Hit);
  Assert.AreEqual(APenalty, LImpact.Penalty);
  Assert.AreEqual(ASmokes, LImpact.Smokes);
  Assert.AreEqual(AHit, LImpact.StartsSoundTimer);
end;

procedure TTestRadixPhysicsImpact.IlPavimentoDovrebbeSuonareSecondoIlSettore;
var
  LImpact: TRadixImpact;
begin
  LImpact := TRadixCraftImpactRules.PlaneHit(0, True, True, False, False, False, True, 600000);
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.Scrape), Ord(LImpact.Sound));
  LImpact := TRadixCraftImpactRules.PlaneHit(0, True, True, False, False, False, False, 600000);
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.PlaneHit), Ord(LImpact.Sound));
  // a silent craft: no sound and no wait, the hit is counted
  LImpact := TRadixCraftImpactRules.PlaneHit(0, True, True, False, False, True, True, 600000);
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.None), Ord(LImpact.Sound));
  Assert.IsFalse(LImpact.StartsSoundTimer);
  Assert.AreEqual(70, LImpact.Penalty);
end;

procedure TTestRadixPhysicsImpact.IlSoffittoDovrebbeSempreRaschiareEFarPartireIlTempoAncheDaMuta;
var
  LImpact: TRadixImpact;
begin
  LImpact := TRadixCraftImpactRules.PlaneHit(0, False, False, True, True, False, False, 600000);
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.Scrape), Ord(LImpact.Sound), 'anche fuori dai settori di Radix');
  LImpact := TRadixCraftImpactRules.PlaneHit(0, False, False, True, True, True, False, 600000);
  Assert.AreEqual<Integer>(Ord(TRadixImpactSound.None), Ord(LImpact.Sound));
  Assert.IsTrue(LImpact.StartsSoundTimer);
end;

procedure TTestRadixPhysicsImpact.NessunUrtoDiPianoMentreIlSuonoPrecedenteDura;
begin
  Assert.IsFalse(TRadixCraftImpactRules.PlaneHit(1, True, True, True, True, False, True, 900000).Hit);
  Assert.IsTrue(TRadixCraftImpactRules.PlaneHit(-1, True, True, True, True, False, True, 900000).Hit);
end;

procedure TTestRadixPhysicsImpact.DovrebbePenalizzareLAtterraggio(AWasAbove, AOnFloor, APlainFloor: Boolean;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixCraftImpactRules.LandingPenalty(AWasAbove, AOnFloor, APlainFloor));
end;

procedure TTestRadixPhysicsImpact.LaScivolataDovrebbeSospendereIlControlloDelleAltezze;
begin
  Assert.IsTrue(TRadixCraftImpactRules.ChecksHeights(0));
  Assert.IsTrue(TRadixCraftImpactRules.ChecksHeights(-1));
  Assert.IsFalse(TRadixCraftImpactRules.ChecksHeights(1));
end;

procedure TTestRadixPhysicsImpact.IlContoAllaRovesciaDovrebbeFermarsiAZero;
begin
  Assert.AreEqual(4, TRadixCraftImpactRules.CountDown(5));
  Assert.AreEqual(0, TRadixCraftImpactRules.CountDown(1));
  Assert.AreEqual(0, TRadixCraftImpactRules.CountDown(0));
  Assert.AreEqual(-2, TRadixCraftImpactRules.CountDown(-2));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixPhysicsImpact);

end.

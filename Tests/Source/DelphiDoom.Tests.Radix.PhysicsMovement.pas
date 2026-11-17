{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixMovementRules                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.PhysicsMovement;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Physics.Movement;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixPhysicsMovement = class(TObject)
  public
    [Test]
    [TestCase('sotto il limite', '655360,False,655360')]
    [TestCase('sopra il limite', '3670016,False,1966080')]
    [TestCase('sotto il limite negativo', '-3670016,False,-1966080')]
    [TestCase('senza limite', '3670016,True,3670016')]
    [TestCase('senza limite negativo', '-3670016,True,-3670016')]
    [TestCase('al limite', '1966080,False,1966080')]
    procedure DovrebbeLimitareIlMomentoSoloACHiHaUnaVelocitaMassima(AMomentum: Integer; ANoMaxMove: Boolean;
      AExpected: Integer);
    [Test]
    procedure MissiliECoseSenzaLimiteDovrebberoMuoversiAPassi;
    [Test]
    [TestCase('senza raggio', '3670016,0,8')]
    [TestCase('ferma', '0,851968,1')]
    [TestCase('plasma: 56 unita, raggio 13', '3670016,851968,8')]
    [TestCase('un passo corto ha comunque otto prove', '851968,851968,8')]
    [TestCase('lontano', '6553600,65536,104')]
    [TestCase('quoziente che non entra', '2147418112,1,32771')]
    procedure DovrebbeContareIPassiDiUnaMossa(ADistance, ARadius, AExpected: Integer);
    [Test]
    procedure IPassiDovrebberoArrivareAllaMeta;
    [Test]
    [TestCase('asse x piu lungo', '300,100,350')]
    [TestCase('asse y piu lungo', '100,-300,350')]
    [TestCase('uguali', '-200,200,300')]
    [TestCase('fermo', '0,0,0')]
    procedure DovrebbeStimareLaDistanzaComeIlMotore(ADeltaX, ADeltaY, AExpected: Integer);
    [Test]
    [TestCase('ferma', '0,65536,3670016,1')]
    [TestCase('al limite', '65536,65536,3670016,1')]
    [TestCase('lenta', '65537,65536,3670016,2')]
    [TestCase('appena sotto un quarto', '917503,65536,3670016,2')]
    [TestCase('un quarto', '917504,65536,3670016,0')]
    [TestCase('veloce', '3670016,65536,3670016,0')]
    procedure UnaCosaFermaDovrebbeEsplodereEUnaLentaAccelerare(AVelocity, AIdleSpeed, ASpeed, AExpected: Integer);
    [Test]
    procedure DovrebbeAccelerareDiUnQuarto;
    [Test]
    [TestCase('missile nel cielo', 'True,True,False,False,4194304')]
    [TestCase('cosa che attraversa il cielo', 'True,False,True,False,4194304')]
    [TestCase('missile a cui e vietato', 'True,True,False,True,0')]
    [TestCase('cosa a cui e vietato', 'True,False,True,True,0')]
    [TestCase('cosa qualunque', 'True,False,False,False,0')]
    [TestCase('non e cielo', 'False,True,True,False,0')]
    procedure DovrebbeLasciarPassareOltreIlCielo(ASky, AMissile, AThruSky, APrevent: Boolean; AExpected: Integer);
    [Test]
    procedure IlSuperamentoDelCieloDovrebbeEssereQuelloDiPSectorJumpDelFork;
  end;

implementation

{ TTestRadixPhysicsMovement }

procedure TTestRadixPhysicsMovement.DovrebbeLimitareIlMomentoSoloACHiHaUnaVelocitaMassima(AMomentum: Integer;
  ANoMaxMove: Boolean; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixMovementRules.ClampMomentum(AMomentum, ANoMaxMove));
end;

procedure TTestRadixPhysicsMovement.MissiliECoseSenzaLimiteDovrebberoMuoversiAPassi;
begin
  Assert.IsTrue(TRadixMovementRules.MovesInSteps(True, False));
  Assert.IsTrue(TRadixMovementRules.MovesInSteps(False, True));
  Assert.IsFalse(TRadixMovementRules.MovesInSteps(False, False));
end;

procedure TTestRadixPhysicsMovement.DovrebbeContareIPassiDiUnaMossa(ADistance, ARadius, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixMovementRules.StepCount(ADistance, ARadius));
end;

procedure TTestRadixPhysicsMovement.IPassiDovrebberoArrivareAllaMeta;
var
  LStep: Integer;
  LPrevious: Integer;
  LPosition: Integer;
begin
  LPrevious := 1000 * 65536;
  for LStep := 1 to 8 do
  begin
    LPosition := TRadixMovementRules.StepPosition(1000 * 65536, 1056 * 65536, 8, LStep);
    Assert.AreEqual(7 * 65536, LPosition - LPrevious, 'passi uguali');
    LPrevious := LPosition;
  end;
  Assert.AreEqual(1056 * 65536, LPrevious);
  // the division of each end loses the remainder (as Rad-X)
  Assert.AreEqual(9, TRadixMovementRules.StepPosition(10, 10, 3, 3));
end;

procedure TTestRadixPhysicsMovement.DovrebbeStimareLaDistanzaComeIlMotore(ADeltaX, ADeltaY, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixMovementRules.ApproximateDistance(ADeltaX, ADeltaY));
end;

procedure TTestRadixPhysicsMovement.UnaCosaFermaDovrebbeEsplodereEUnaLentaAccelerare(AVelocity, AIdleSpeed, ASpeed,
  AExpected: Integer);
begin
  Assert.AreEqual<Integer>(AExpected, Ord(TRadixMovementRules.IdleAction(AVelocity, AIdleSpeed, ASpeed)));
end;

procedure TTestRadixPhysicsMovement.DovrebbeAccelerareDiUnQuarto;
begin
  Assert.AreEqual(5 * 65536, TRadixMovementRules.Accelerate(4 * 65536));
  Assert.AreEqual(-5 * 65536, TRadixMovementRules.Accelerate(-4 * 65536));
  Assert.AreEqual(3, TRadixMovementRules.Accelerate(3), 'tronca verso zero');
  Assert.AreEqual(0, TRadixMovementRules.Accelerate(0));
end;

procedure TTestRadixPhysicsMovement.DovrebbeLasciarPassareOltreIlCielo(ASky, AMissile, AThruSky, APrevent: Boolean;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixMovementRules.SkyOverhead(ASky, AMissile, AThruSky, APrevent));
end;

type
  // what P_SectorJumpOverhead and P_SectorJumpUnderhead of Rad-X read of a sector and of a thing
  TForkSector = record
    MidSector: Boolean;
    MidFloor, MidCeiling: Integer;
    CeilingIsSky, FloorIsSky: Boolean;
  end;
  TForkThing = record
    Z: Integer;
    Missile, ThruSky, PreventThruSky: Boolean;
  end;

// P_SectorJumpOverhead of Rad-X (p_map.pas), without the offset of the players under sloped ceilings
function ForkOverhead(const ASector: TForkSector; const AThing: TForkThing): Integer;
begin
  Result := 0;
  if ASector.MidSector then
    if AThing.Z < ASector.MidFloor then
      Exit;
  if ASector.CeilingIsSky then
    if AThing.Missile or AThing.ThruSky then
      if not AThing.PreventThruSky then
      begin
        Result := 64 * 65536;
        Exit;
      end;
end;

// P_SectorJumpUnderhead of Rad-X (p_map.pas), without the offset of the players under sloped floors
function ForkUnderhead(const ASector: TForkSector; const AThing: TForkThing): Integer;
begin
  Result := 0;
  if ASector.MidSector then
    if AThing.Z >= ASector.MidCeiling then
      Exit;
  if ASector.FloorIsSky then
    if AThing.Missile or AThing.ThruSky then
      if not AThing.PreventThruSky then
      begin
        Result := 64 * 65536;
        Exit;
      end;
end;

procedure TTestRadixPhysicsMovement.IlSuperamentoDelCieloDovrebbeEssereQuelloDiPSectorJumpDelFork;
var
  LIteration: Integer;
  LSector: TForkSector;
  LThing: TForkThing;
begin
  RandSeed := 169010;
  for LIteration := 1 to 20000 do
  begin
    LSector.MidSector := Random(3) = 0;
    LSector.MidFloor := Random(400) - 200;
    LSector.MidCeiling := LSector.MidFloor + Random(200);
    LSector.CeilingIsSky := Random(2) = 1;
    LSector.FloorIsSky := Random(2) = 1;
    LThing.Z := Random(600) - 300;
    LThing.Missile := Random(2) = 1;
    LThing.ThruSky := Random(2) = 1;
    LThing.PreventThruSky := Random(3) = 0;
    Assert.AreEqual(ForkOverhead(LSector, LThing),
      TRadixMovementRules.SectorSkyOffset(True, LSector.MidSector, LThing.Z, LSector.MidFloor, LSector.CeilingIsSky,
        LThing.Missile, LThing.ThruSky, LThing.PreventThruSky), 'soffitto ' + IntToStr(LIteration));
    Assert.AreEqual(ForkUnderhead(LSector, LThing),
      TRadixMovementRules.SectorSkyOffset(False, LSector.MidSector, LThing.Z, LSector.MidCeiling, LSector.FloorIsSky,
        LThing.Missile, LThing.ThruSky, LThing.PreventThruSky), 'pavimento ' + IntToStr(LIteration));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixPhysicsMovement);

end.

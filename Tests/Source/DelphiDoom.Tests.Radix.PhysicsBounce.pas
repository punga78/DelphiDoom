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
    [Test]
    procedure UnPavimentoDovrebbeFarRimbalzareComeNelFork;
    [Test]
    procedure UnSoffittoDovrebbeFarRimbalzareComeNelFork;
    [Test]
    procedure PavimentoESoffittoNelloStessoTicDovrebberoDividereIlRimbalzo;
    [Test]
    procedure UnMissileCheRimbalzaSulPavimentoNonDovrebbeEsplodere;
    [Test]
    procedure UnaCosaConRimbalziLimitatiDovrebbePerdereITreFlagAllUltimo;
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

const
  // the flags of Rad-X (p_mobj_h.pas)
  FORK_FLOORBOUNCE = 1;
  FORK_CEILINGBOUNCE = 2;
  FORK_WALLBOUNCE = 4;
  FORK_BOUNCE = FORK_FLOORBOUNCE or FORK_CEILINGBOUNCE or FORK_WALLBOUNCE;
  FORK_LIMITBOUNCECONTROL = 256;

type
  // the fields of mobj_t that the vertical bounces of P_ZMovement of Rad-X read and write
  TForkMobj = record
    Flags3: Integer;
    MomentumZ: Integer;
    ReactionTime: Integer;
    BounceCount: Integer;
    Missile: Boolean;
  end;

// P_ResolveBounceBehaviour of Rad-X, as it is in p_mobj.pas
procedure ForkResolveBounce(var AMobj: TForkMobj);
begin
  if AMobj.Flags3 and FORK_LIMITBOUNCECONTROL <> 0 then
  begin
    if AMobj.BounceCount > 0 then
      Dec(AMobj.BounceCount);
    if AMobj.BounceCount = 0 then
      AMobj.Flags3 := AMobj.Flags3 and not FORK_BOUNCE;
  end;
end;

// P_ZMovement of Rad-X, the floor: "if mo.z <= mo.floorz then" up to the splash. True: a missile exploded
function ForkFloor(var AMobj: TForkMobj; AFloorIsSky, ALiquid: Boolean; var ABouncing: Boolean): Boolean;
begin
  Result := False;
  if (AMobj.Flags3 and FORK_FLOORBOUNCE <> 0) and not AFloorIsSky then
  begin
    if AMobj.Missile then
      AMobj.MomentumZ := -AMobj.MomentumZ
    else
      AMobj.MomentumZ := -AMobj.MomentumZ div 2;
    AMobj.ReactionTime := AMobj.ReactionTime div 2;
    if ALiquid then
    begin
      AMobj.Flags3 := AMobj.Flags3 and not FORK_FLOORBOUNCE;
      ABouncing := False;
      AMobj.BounceCount := 0;
    end
    else
    begin
      ForkResolveBounce(AMobj);
      ABouncing := True;
    end;
  end
  else if AMobj.Missile and (AMobj.Flags3 and FORK_FLOORBOUNCE <> 0) and AFloorIsSky then
    Result := True;
end;

// P_ZMovement of Rad-X, the ceiling: "if mo.z + mo.height > ceilz then" up to "mo.z := ceilz - mo.height". True: a missile exploded
function ForkCeiling(var AMobj: TForkMobj; ACeilingIsSky: Boolean; var ABouncing: Boolean): Boolean;
begin
  Result := False;
  if AMobj.MomentumZ > 0 then
  begin
    if (AMobj.Flags3 and FORK_CEILINGBOUNCE <> 0) and not ACeilingIsSky then
    begin
      if AMobj.Missile then
        AMobj.MomentumZ := -AMobj.MomentumZ
      else
        AMobj.MomentumZ := -AMobj.MomentumZ div 2;
      ForkResolveBounce(AMobj);
    end
    else
    begin
      if AMobj.Missile then
      begin
        Result := True;
        Exit;
      end;
      AMobj.MomentumZ := 0;
    end;
    ABouncing := True;
  end;
end;

function RandomForkMobj: TForkMobj;
begin
  Result.Flags3 := Random(8) or (Random(2) * FORK_LIMITBOUNCECONTROL);
  Result.MomentumZ := Random(2000001) - 1000000;
  if Random(5) = 0 then
    Result.MomentumZ := 0;
  Result.ReactionTime := Random(40) - 5;
  Result.BounceCount := Random(7) - 2;
  Result.Missile := Random(2) = 1;
end;

function StateOf(const AMobj: TForkMobj): TRadixBounceState;
begin
  Result := Default(TRadixBounceState);
  Result.Missile := AMobj.Missile;
  Result.FloorBounce := AMobj.Flags3 and FORK_FLOORBOUNCE <> 0;
  Result.CeilingBounce := AMobj.Flags3 and FORK_CEILINGBOUNCE <> 0;
  Result.WallBounce := AMobj.Flags3 and FORK_WALLBOUNCE <> 0;
  Result.Limited := AMobj.Flags3 and FORK_LIMITBOUNCECONTROL <> 0;
  Result.Count := AMobj.BounceCount;
  Result.MomentumZ := AMobj.MomentumZ;
  Result.ReactionTime := AMobj.ReactionTime;
end;

procedure CompareWithFork(const AFork: TForkMobj; const AState: TRadixBounceState; const AMessage: string);
var
  LFlags: Integer;
begin
  LFlags := AFork.Flags3 and not FORK_BOUNCE;
  if AState.FloorBounce then
    LFlags := LFlags or FORK_FLOORBOUNCE;
  if AState.CeilingBounce then
    LFlags := LFlags or FORK_CEILINGBOUNCE;
  if AState.WallBounce then
    LFlags := LFlags or FORK_WALLBOUNCE;
  Assert.AreEqual(AFork.Flags3, LFlags, AMessage + ': flags');
  Assert.AreEqual(AFork.MomentumZ, AState.MomentumZ, AMessage + ': momz');
  Assert.AreEqual(AFork.ReactionTime, AState.ReactionTime, AMessage + ': reactiontime');
  if AState.Limited then
    Assert.AreEqual(AFork.BounceCount, AState.Count, AMessage + ': count');
end;

procedure TTestRadixPhysicsBounce.UnPavimentoDovrebbeFarRimbalzareComeNelFork;
var
  LIteration: Integer;
  LFork: TForkMobj;
  LState: TRadixBounceState;
  LSky, LLiquid, LForkBouncing, LForkExploded, LResult: Boolean;
begin
  RandSeed := 169001;
  for LIteration := 1 to 20000 do
  begin
    LFork := RandomForkMobj;
    LSky := Random(2) = 1;
    LLiquid := Random(2) = 1;
    LState := StateOf(LFork);
    LForkBouncing := False;
    LForkExploded := ForkFloor(LFork, LSky, LLiquid, LForkBouncing);
    LResult := TRadixBounceRules.FloorImpact(LState, LSky, LLiquid);
    Assert.AreEqual(not LForkExploded, LResult, 'esplosione');
    Assert.AreEqual(LForkBouncing, LState.Bouncing, 'rimbalza');
    CompareWithFork(LFork, LState, 'pavimento ' + IntToStr(LIteration));
  end;
end;

procedure TTestRadixPhysicsBounce.UnSoffittoDovrebbeFarRimbalzareComeNelFork;
var
  LIteration: Integer;
  LFork: TForkMobj;
  LState: TRadixBounceState;
  LSky, LForkBouncing, LForkExploded, LResult: Boolean;
begin
  RandSeed := 169002;
  for LIteration := 1 to 20000 do
  begin
    LFork := RandomForkMobj;
    LSky := Random(2) = 1;
    LState := StateOf(LFork);
    LForkBouncing := False;
    LForkExploded := ForkCeiling(LFork, LSky, LForkBouncing);
    LResult := TRadixBounceRules.CeilingImpact(LState, LSky);
    Assert.AreEqual(not LForkExploded, LResult, 'esplosione');
    Assert.AreEqual(LForkBouncing, LState.Bouncing, 'rimbalza');
    CompareWithFork(LFork, LState, 'soffitto ' + IntToStr(LIteration));
  end;
end;

procedure TTestRadixPhysicsBounce.PavimentoESoffittoNelloStessoTicDovrebberoDividereIlRimbalzo;
var
  LIteration: Integer;
  LFork: TForkMobj;
  LState: TRadixBounceState;
  LFloorSky, LCeilingSky, LLiquid, LForkBouncing, LForkExploded, LResult: Boolean;
begin
  // a thing between a floor and a ceiling that are near: both impacts of one P_ZMovement
  RandSeed := 169003;
  for LIteration := 1 to 20000 do
  begin
    LFork := RandomForkMobj;
    LFloorSky := Random(2) = 1;
    LCeilingSky := Random(2) = 1;
    LLiquid := Random(2) = 1;
    LState := StateOf(LFork);
    LForkBouncing := False;
    LForkExploded := ForkFloor(LFork, LFloorSky, LLiquid, LForkBouncing);
    LResult := TRadixBounceRules.FloorImpact(LState, LFloorSky, LLiquid);
    Assert.AreEqual(not LForkExploded, LResult);
    if not LForkExploded then
    begin
      LForkExploded := ForkCeiling(LFork, LCeilingSky, LForkBouncing);
      LResult := TRadixBounceRules.CeilingImpact(LState, LCeilingSky);
      Assert.AreEqual(not LForkExploded, LResult);
      // the missile that has not bounced explodes at the end of the tic
      Assert.AreEqual(LForkBouncing, LState.Bouncing, 'rimbalza');
    end;
    CompareWithFork(LFork, LState, 'entrambi ' + IntToStr(LIteration));
  end;
end;

procedure TTestRadixPhysicsBounce.UnMissileCheRimbalzaSulPavimentoNonDovrebbeEsplodere;
var
  LState: TRadixBounceState;
begin
  LState := Default(TRadixBounceState);
  LState.Missile := True;
  LState.FloorBounce := True;
  LState.MomentumZ := -655360;
  Assert.IsTrue(TRadixBounceRules.FloorImpact(LState, False, False));
  Assert.IsTrue(LState.Bouncing);
  Assert.AreEqual(655360, LState.MomentumZ, 'tiene la velocita''');
  LState := Default(TRadixBounceState);
  LState.Missile := True;
  LState.FloorBounce := True;
  Assert.IsFalse(TRadixBounceRules.FloorImpact(LState, True, False), 'sul cielo esplode');
end;

procedure TTestRadixPhysicsBounce.UnaCosaConRimbalziLimitatiDovrebbePerdereITreFlagAllUltimo;
var
  LState: TRadixBounceState;
begin
  LState := Default(TRadixBounceState);
  LState.FloorBounce := True;
  LState.CeilingBounce := True;
  LState.WallBounce := True;
  LState.Limited := True;
  LState.Count := 2;
  TRadixBounceRules.Resolve(LState);
  Assert.IsTrue(LState.FloorBounce and LState.CeilingBounce and LState.WallBounce);
  TRadixBounceRules.Resolve(LState);
  Assert.IsFalse(LState.FloorBounce or LState.CeilingBounce or LState.WallBounce, 'al secondo rimbalzo finiscono');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixPhysicsBounce);

end.

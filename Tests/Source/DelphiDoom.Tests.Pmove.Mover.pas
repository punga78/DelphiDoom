{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pmove library - the mover on small worlds made in  }
{  the test (a floor, a step, a wall, a ceiling), and the cases the golden of  }
{  the real code cannot reach                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Pmove.Mover;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Intf,
  DelphiDoom.Tests.Pmove.Support.World;

type
  [TestFixture]
  [Category('Pmove')]
  TTestPmoveMover = class
  strict private
    FWorld: TFakeWorld;
    FTrace: IPmoveTrace;
    FMover: IPmove;
    FPmove: TPmove;
    procedure NewMover(const ATuning: TPmoveTuning);
    procedure Step(const AMsec: Integer; const AForward, ARight, AUp: Integer);
    function HasEvent(const AEvent: Integer): Boolean;
    function Origin(const AIndex: Integer): Single;
    procedure Near(const AExpected, AActual, ATolerance: Double; const AMessage: string = '');
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeStareFermoSulPavimento;
    [Test]
    procedure DovrebbeSaltareEDareLEventoDelSalto;
    [Test]
    procedure DovrebbeTenereIlTastoDelSaltoPremutoPerTuttiIPassiDelComando;
    [Test]
    procedure DovrebbeAccovacciarsiEAlzarsi;
    [Test]
    procedure DovrebbeRestareAccovacciatoSottoUnSoffittoBasso;
    [Test]
    procedure DovrebbeSalireSuUnGradinoBassoEDareLEventoDelPasso;
    [Test]
    procedure DovrebbeFermarsiDavantiAUnGradinoTroppoAlto;
    [Test]
    procedure DovrebbeScivolareLungoUnMuro;
    [Test]
    procedure DovrebbeNonAttraversareUnAngoloDiDueMuri;
    [Test]
    procedure DovrebbeSentireUnaCadutaLungaSoloDaVivo;
    [Test]
    procedure DovrebbeNonDareDanniDiCadutaSuUnaSuperficieSenzaDanni;
    [Test]
    procedure DovrebbeAtterrareSenzaGravitaComeUnPassoSenzaEccezioni;
    [Test]
    procedure DovrebbeSmorzareUnCadavereSuTerra;
    [Test]
    procedure DovrebbeNonMuoversiInBloccoEInIntermissione;
    [Test]
    procedure DovrebbeDividereUnComandoLungoInPassiDa66Millisecondi;
    [Test]
    procedure DovrebbeUsareIlTempoFissoDelPasso;
    [Test]
    procedure DovrebbeLimitareUnPassoA200MillisecondiConUnTempoFissoLungo;
    [Test]
    procedure DovrebbeRifiutareUnTempoFissoMinoreDiUno;
    [Test]
    procedure DovrebbeIgnorareUnComandoPiuVecchioDelloStato;
    [Test]
    procedure DovrebbeRipartireDaMilleMillisecondiPrimaDelComando;
    [Test]
    procedure DovrebbeFarGirareIlContatoreDeiFotogrammiOgni64;
    [Test]
    procedure DovrebbeUsareIParametriDelTuningDelMovimento;
    [Test]
    procedure DovrebbeArrotondareLaVelocitaAllIntero;
    [Test]
    procedure DovrebbeNonSollevareEccezioniConUnoStatoNonFinito;
    [Test]
    procedure DovrebbeLasciareLaMascheraDelleEccezioniComeLAveva;
    [Test]
    procedure DovrebbeScrivereLeRigheDiDiagnosticaSoloConIlLivello;
    [Test]
    procedure DovrebbeIgnorareIlComandoSeIlTastoDelleChiacchiereEPremuto;
    [Test]
    procedure DovrebbeTornareSenzaArmaSeLArmaDelComandoNonELaSua;
  end;

implementation

uses
  System.Math, DelphiDoom.Collision.Q3.Types, DelphiDoom.Models.Q3Player.Types, DelphiDoom.Logging.Intf, DelphiDoom.Pmove.Factory,
  DelphiDoom.Tests.Pmove.Support.Golden;

procedure TTestPmoveMover.Setup;
begin
  FWorld := TFakeWorld.Create;
  FTrace := FWorld;
  // the floor, its top at z = 0
  FWorld.AddBox(-1000, -1000, -64, 1000, 1000, 0, Q3_CONTENTS_SOLID);
  NewMover(TPmoveTuning.Default);
end;

procedure TTestPmoveMover.TearDown;
begin
  FMover := nil;
  FTrace := nil;
  FWorld := nil;
end;

procedure TTestPmoveMover.NewMover(const ATuning: TPmoveTuning);
begin
  FMover := TPmoveFactory.CreateMover(FTrace, nil, ATuning, nil);
  FPmove := Default(TPmove);
  FPmove.TraceMask := Q3_MASK_PLAYERSOLID;
  FPmove.Ps.CommandTime := 1000;
  FPmove.Ps.Gravity := 800;
  FPmove.Ps.Speed := 320;
  FPmove.Ps.ViewHeight := Q3_DEFAULT_VIEWHEIGHT;
  FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_WORLD;
  FPmove.Ps.Stats[Q3_STAT_HEALTH] := 100;
  FPmove.Ps.Stats[Q3_STAT_MAX_HEALTH] := 100;
  FPmove.Ps.Stats[Q3_STAT_WEAPONS] := $3FE;
  FPmove.Ps.Weapon := Q3_WP_MACHINEGUN;
  // standing on the floor: the origin is 24 over it (a trace that only touches it does not start in it)
  FPmove.Ps.Origin[0] := 0;
  FPmove.Ps.Origin[1] := 0;
  FPmove.Ps.Origin[2] := 24.125;
end;

procedure TTestPmoveMover.Step(const AMsec: Integer; const AForward, ARight, AUp: Integer);
begin
  FPmove.Cmd.ServerTime := FPmove.Ps.CommandTime + AMsec;
  FPmove.Cmd.ForwardMove := AForward;
  FPmove.Cmd.RightMove := ARight;
  FPmove.Cmd.UpMove := AUp;
  FMover.Execute(FPmove);
end;

function TTestPmoveMover.HasEvent(const AEvent: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to Q3_MAX_PS_EVENTS - 1 do
    if FPmove.Ps.Events[LIndex] = AEvent then
      Result := True;
end;

function TTestPmoveMover.Origin(const AIndex: Integer): Single;
begin
  Result := FPmove.Ps.Origin[AIndex];
end;

procedure TTestPmoveMover.Near(const AExpected, AActual, ATolerance: Double; const AMessage: string);
begin
  Assert.IsTrue(Abs(AExpected - AActual) <= ATolerance,
    Format('%s: atteso %g ottenuto %g', [AMessage, AExpected, AActual]));
end;

procedure TTestPmoveMover.DovrebbeStareFermoSulPavimento;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 20 do
    Step(16, 0, 0, 0);
  Assert.AreEqual(Q3_ENTITYNUM_WORLD, FPmove.Ps.GroundEntityNum, 'terra');
  Near(24.125, Origin(2), 0.01);
  Near(0, FPmove.Ps.Velocity[2], 0.001);
  Near(0, FPmove.XySpeed, 0.001);
  Assert.AreEqual<Integer>(Q3_LEGS_IDLE, FPmove.Ps.LegsAnim and (not Q3_ANIM_TOGGLEBIT), 'animazione delle gambe');
end;

procedure TTestPmoveMover.DovrebbeSaltareEDareLEventoDelSalto;
begin
  Step(16, 0, 0, 127);
  Assert.IsTrue(HasEvent(Q3_EV_JUMP), 'evento');
  Assert.AreEqual(Q3_ENTITYNUM_NONE, FPmove.Ps.GroundEntityNum, 'in aria');
  Assert.IsTrue(FPmove.Ps.Velocity[2] > 200, 'velocita verso l''alto');
  Assert.IsTrue((FPmove.Ps.PmFlags and Q3_PMF_JUMP_HELD) <> 0, 'tasto tenuto');
  Assert.AreEqual<Integer>(Q3_LEGS_JUMP, FPmove.Ps.LegsAnim and (not Q3_ANIM_TOGGLEBIT), 'animazione');
end;

procedure TTestPmoveMover.DovrebbeTenereIlTastoDelSaltoPremutoPerTuttiIPassiDelComando;
begin
  // a command of 200 msec is cut in steps: after the first the jump is held and the next steps get upmove 20,
  // which the caller sees in the command (the original gives the same to the next command)
  Step(200, 0, 0, 127);
  Assert.AreEqual<Integer>(20, FPmove.Cmd.UpMove);
  Assert.IsTrue(FMover.Counter > 1, 'passi');
end;

procedure TTestPmoveMover.DovrebbeAccovacciarsiEAlzarsi;
begin
  Step(16, 0, 0, -127);
  Assert.IsTrue((FPmove.Ps.PmFlags and Q3_PMF_DUCKED) <> 0, 'accovacciato');
  Assert.AreEqual<Integer>(Q3_CROUCH_VIEWHEIGHT, FPmove.Ps.ViewHeight, 'altezza degli occhi');
  Near(16, FPmove.Maxs[2], 0, 'scatola');
  Step(16, 0, 0, 0);
  Assert.IsTrue((FPmove.Ps.PmFlags and Q3_PMF_DUCKED) = 0, 'in piedi');
  Assert.AreEqual<Integer>(Q3_DEFAULT_VIEWHEIGHT, FPmove.Ps.ViewHeight);
  Near(32, FPmove.Maxs[2], 0);
end;

procedure TTestPmoveMover.DovrebbeRestareAccovacciatoSottoUnSoffittoBasso;
begin
  // standing needs 56 units over the floor, the ceiling is at 44: ducked (40) fits
  FWorld.AddBox(-1000, -1000, 44, 1000, 1000, 200, Q3_CONTENTS_SOLID);
  Step(16, 0, 0, -127);
  Step(16, 0, 0, 0);
  Assert.IsTrue((FPmove.Ps.PmFlags and Q3_PMF_DUCKED) <> 0, 'resta accovacciato');
  Assert.AreEqual<Integer>(Q3_CROUCH_VIEWHEIGHT, FPmove.Ps.ViewHeight);
end;

procedure TTestPmoveMover.DovrebbeSalireSuUnGradinoBassoEDareLEventoDelPasso;
var
  LIndex: Integer;
  LStepped: Boolean;
begin
  // a step of 10 units at x = 100: it is 7 to 11 higher, EV_STEP_8
  FWorld.AddBox(100, -1000, -64, 1000, 1000, 10, Q3_CONTENTS_SOLID);
  FPmove.Cmd.Angles[Q3_YAW] := 0;
  LStepped := False;
  for LIndex := 1 to 60 do
  begin
    Step(16, 127, 0, 0);
    if HasEvent(Q3_EV_STEP_8) then
      LStepped := True;
  end;
  Assert.IsTrue(LStepped, 'evento del passo');
  Near(34.125, Origin(2), 0.2, 'sul gradino');
  Assert.IsTrue(Origin(0) > 100, 'oltre lo spigolo');
end;

procedure TTestPmoveMover.DovrebbeFermarsiDavantiAUnGradinoTroppoAlto;
var
  LIndex: Integer;
begin
  // 20 units is over the step size of 18
  FWorld.AddBox(100, -1000, -64, 1000, 1000, 20, Q3_CONTENTS_SOLID);
  for LIndex := 1 to 80 do
    Step(16, 127, 0, 0);
  Assert.IsTrue(Origin(0) <= 85.01, 'davanti al muro (la scatola e'' larga 15 per lato)');
  Near(24.125, Origin(2), 0.2, 'non e'' salito');
end;

procedure TTestPmoveMover.DovrebbeScivolareLungoUnMuro;
var
  LIndex: Integer;
begin
  // the wall at x = 100; running at it at 45 degrees leaves the speed along it
  FWorld.AddBox(100, -1000, 0, 1000, 1000, 200, Q3_CONTENTS_SOLID);
  FPmove.Cmd.Angles[Q3_YAW] := 8192;
  for LIndex := 1 to 80 do
    Step(16, 127, 0, 0);
  Assert.IsTrue(Origin(0) <= 85.01, 'non attraversa il muro');
  Assert.IsTrue(Origin(1) > 200, 'scivola lungo il muro');
end;

procedure TTestPmoveMover.DovrebbeNonAttraversareUnAngoloDiDueMuri;
var
  LIndex: Integer;
begin
  // two walls and the floor: running at the corner leaves nothing of the speed
  FWorld.AddBox(100, -1000, 0, 1000, 1000, 200, Q3_CONTENTS_SOLID);
  FWorld.AddBox(-1000, 100, 0, 1000, 1000, 200, Q3_CONTENTS_SOLID);
  FPmove.Ps.Origin[0] := 70;
  FPmove.Ps.Origin[1] := 70;
  FPmove.Cmd.Angles[Q3_YAW] := 8192;
  for LIndex := 1 to 60 do
    Step(16, 127, 0, 0);
  Assert.IsTrue(Origin(0) <= 85.01, 'x');
  Assert.IsTrue(Origin(1) <= 85.01, 'y');
  Near(0, FPmove.Ps.Velocity[0], 0.5, 'velocita x');
  Near(0, FPmove.Ps.Velocity[1], 0.5, 'velocita y');
end;

procedure TTestPmoveMover.DovrebbeSentireUnaCadutaLungaSoloDaVivo;
begin
  FPmove.Ps.Origin[2] := 500;
  FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  while FPmove.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE do
    Step(16, 0, 0, 0);
  Assert.IsTrue(HasEvent(Q3_EV_FALL_FAR), 'caduta lunga da vivo');

  // 276 units: a medium fall, the pain grunt that a dead player does not make
  NewMover(TPmoveTuning.Default);
  FPmove.Ps.Origin[2] := 300;
  FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  while FPmove.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE do
    Step(16, 0, 0, 0);
  Assert.IsTrue(HasEvent(Q3_EV_FALL_MEDIUM), 'caduta media da vivo');

  NewMover(TPmoveTuning.Default);
  FPmove.Ps.Origin[2] := 300;
  FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  FPmove.Ps.Stats[Q3_STAT_HEALTH] := 0;
  while FPmove.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE do
    Step(16, 0, 0, 0);
  Assert.IsFalse(HasEvent(Q3_EV_FALL_MEDIUM), 'il grugnito di dolore non c''e'' da morti');
end;

procedure TTestPmoveMover.DovrebbeNonDareDanniDiCadutaSuUnaSuperficieSenzaDanni;
begin
  FWorld := TFakeWorld.Create;
  FTrace := FWorld;
  FWorld.AddBox(-1000, -1000, -64, 1000, 1000, 0, Q3_CONTENTS_SOLID, Q3_SURF_NODAMAGE);
  NewMover(TPmoveTuning.Default);
  FPmove.Ps.Origin[2] := 500;
  FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  while FPmove.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE do
    Step(16, 0, 0, 0);
  Assert.IsFalse(HasEvent(Q3_EV_FALL_FAR) or HasEvent(Q3_EV_FALL_MEDIUM) or HasEvent(Q3_EV_FALL_SHORT));
end;

procedure TTestPmoveMover.DovrebbeAtterrareSenzaGravitaComeUnPassoSenzaEccezioni;
var
  LCount: Integer;
begin
  // with no gravity the landing divides by zero in the original: the time is infinite and the damage is
  // not a number, which gives a footstep; here it is the same and not an exception
  FPmove.Ps.Gravity := 0;
  FPmove.Ps.Origin[2] := 200;
  FPmove.Ps.Velocity[2] := -300;
  FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  LCount := 0;
  while (FPmove.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE) and (LCount < 200) do
  begin
    Step(16, 0, 0, 0);
    Inc(LCount);
  end;
  Assert.AreEqual(Q3_ENTITYNUM_WORLD, FPmove.Ps.GroundEntityNum, 'atterrato');
  Assert.IsTrue(HasEvent(Q3_EV_FOOTSTEP), 'passo');
  Assert.AreEqual<Integer>(0, FPmove.Ps.BobCycle, 'il ciclo dei passi ricomincia');
end;

procedure TTestPmoveMover.DovrebbeSmorzareUnCadavereSuTerra;
var
  LIndex: Integer;
begin
  FPmove.Ps.PmType := Q3_PM_DEAD;
  FPmove.Ps.Stats[Q3_STAT_HEALTH] := -10;
  FPmove.Ps.Velocity[0] := 300;
  for LIndex := 1 to 20 do
    Step(16, 127, 0, 0);
  Near(0, FPmove.Ps.Velocity[0], 0.001, 'fermo');
  Assert.AreEqual<Integer>(Q3_DEAD_VIEWHEIGHT, FPmove.Ps.ViewHeight, 'altezza degli occhi');
  Near(-8, FPmove.Maxs[2], 0, 'scatola');
end;

procedure TTestPmoveMover.DovrebbeNonMuoversiInBloccoEInIntermissione;
const
  TYPES: array[0..2] of Integer = (Q3_PM_FREEZE, Q3_PM_INTERMISSION, Q3_PM_SPINTERMISSION);
var
  LType, LIndex: Integer;
begin
  for LIndex := 0 to High(TYPES) do
  begin
    LType := TYPES[LIndex];
    NewMover(TPmoveTuning.Default);
    FPmove.Ps.PmType := LType;
    FPmove.Ps.Velocity[0] := 300;
    Step(16, 127, 0, 0);
    Near(0, Origin(0), 0, 'tipo ' + IntToStr(LType));
    Assert.AreEqual<Integer>(1016, FPmove.Ps.CommandTime, 'il tempo avanza');
  end;
end;

procedure TTestPmoveMover.DovrebbeDividereUnComandoLungoInPassiDa66Millisecondi;
begin
  Step(200, 0, 0, 0);
  // 66 + 66 + 66 + 2
  Assert.AreEqual<Integer>(4, FMover.Counter);
  Assert.AreEqual<Integer>(1200, FPmove.Ps.CommandTime);
end;

procedure TTestPmoveMover.DovrebbeUsareIlTempoFissoDelPasso;
begin
  FPmove.PmoveFixed := True;
  FPmove.PmoveMsec := 8;
  Step(100, 0, 0, 0);
  // 12 steps of 8 and one of 4
  Assert.AreEqual<Integer>(13, FMover.Counter);
end;

procedure TTestPmoveMover.DovrebbeLimitareUnPassoA200MillisecondiConUnTempoFissoLungo;
begin
  // the step takes 250 msec: PmoveSingle cuts it to 200 for the movement but the time goes to the command
  FPmove.PmoveFixed := True;
  FPmove.PmoveMsec := 250;
  FPmove.Ps.Velocity[0] := 0;
  FPmove.Ps.Origin[2] := 1000;
  FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  Step(250, 0, 0, 0);
  Assert.AreEqual<Integer>(1, FMover.Counter);
  // falling for 200 msec: v = 800 * 0.2 = 160 (the slide takes the half of it), not for 250
  Near(-160, FPmove.Ps.Velocity[2], 0.01);
end;

procedure TTestPmoveMover.DovrebbeRifiutareUnTempoFissoMinoreDiUno;
const
  MSECS: array[0..1] of Integer = (0, -5);
var
  LMsec, LIndex: Integer;
begin
  for LIndex := 0 to High(MSECS) do
  begin
    LMsec := MSECS[LIndex];
    FPmove.PmoveFixed := True;
    FPmove.PmoveMsec := LMsec;
    FPmove.Cmd.ServerTime := FPmove.Ps.CommandTime + 16;
    Assert.WillRaise(
      procedure
      begin
        FMover.Execute(FPmove);
      end, EPmoveException, 'tempo ' + IntToStr(LMsec));
  end;
  // with no time to cover it does not loop and does not raise
  FPmove.Cmd.ServerTime := FPmove.Ps.CommandTime;
  FMover.Execute(FPmove);
end;

procedure TTestPmoveMover.DovrebbeIgnorareUnComandoPiuVecchioDelloStato;
begin
  FPmove.Cmd.ServerTime := FPmove.Ps.CommandTime - 1;
  FPmove.Cmd.UpMove := 127;
  FMover.Execute(FPmove);
  Assert.AreEqual<Integer>(1000, FPmove.Ps.CommandTime);
  Assert.AreEqual<Integer>(0, FMover.Counter, 'nessun passo');
  Assert.AreEqual<Integer>(0, FPmove.Ps.PmoveFramecount, 'e nemmeno il contatore');
end;

procedure TTestPmoveMover.DovrebbeRipartireDaMilleMillisecondiPrimaDelComando;
begin
  FPmove.Cmd.ServerTime := FPmove.Ps.CommandTime + 5000;
  FMover.Execute(FPmove);
  // 1000 msec in steps of 66 are 16 steps (15 of 66 and one of 10)
  Assert.AreEqual<Integer>(16, FMover.Counter);
  Assert.AreEqual<Integer>(6000, FPmove.Ps.CommandTime);
end;

procedure TTestPmoveMover.DovrebbeFarGirareIlContatoreDeiFotogrammiOgni64;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 63 do
    Step(16, 0, 0, 0);
  Assert.AreEqual<Integer>(63, FPmove.Ps.PmoveFramecount);
  Step(16, 0, 0, 0);
  Assert.AreEqual<Integer>(0, FPmove.Ps.PmoveFramecount);
end;

procedure TTestPmoveMover.DovrebbeUsareIParametriDelTuningDelMovimento;
var
  LTuning: TPmoveTuning;
  LNormal, LNoFriction: Single;
begin
  FPmove.Ps.Velocity[0] := 200;
  Step(16, 0, 0, 0);
  LNormal := FPmove.Ps.Velocity[0];
  LTuning := TPmoveTuning.Default;
  LTuning.Friction := 0;
  NewMover(LTuning);
  FPmove.Ps.Velocity[0] := 200;
  Step(16, 0, 0, 0);
  LNoFriction := FPmove.Ps.Velocity[0];
  Assert.IsTrue(LNormal < 200, 'con l''attrito rallenta');
  Near(200, LNoFriction, 0.01, 'senza attrito no');
end;

procedure TTestPmoveMover.DovrebbeArrotondareLaVelocitaAllIntero;
begin
  // in the air with no gravity the velocity does not change but for the snap of the engine: to the nearest,
  // the ties to the even one (2.5 is 2, 3.5 is 4), and what does not fit 32 bits is the "integer indefinite"
  FPmove.Ps.Gravity := 0;
  FPmove.Ps.Origin[2] := 5000;
  FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  FPmove.Ps.Velocity[0] := 2.5;
  FPmove.Ps.Velocity[1] := 3.5;
  FPmove.Ps.Velocity[2] := 3.0E9;
  Step(8, 0, 0, 0);
  Near(2, FPmove.Ps.Velocity[0], 0, 'meta'' al pari, in giu''');
  Near(4, FPmove.Ps.Velocity[1], 0, 'meta'' al pari, in su''');
  Near(-2147483648.0, FPmove.Ps.Velocity[2], 0, 'fuori dai 32 bit');
end;

procedure TTestPmoveMover.DovrebbeNonSollevareEccezioniConUnoStatoNonFinito;
var
  LBits: TQ3FloatBits;
begin
  LBits.AsInteger := Integer($7FC00000);
  FPmove.Ps.Origin[0] := LBits.AsSingle;
  FPmove.Ps.Velocity[1] := 1.0E38;
  Step(16, 127, 127, 0);
  Assert.Pass('nessuna eccezione');
end;

procedure TTestPmoveMover.DovrebbeLasciareLaMascheraDelleEccezioniComeLAveva;
var
  LBefore, LAfter: TArithmeticExceptionMask;
begin
  LBefore := GetExceptionMask;
  Step(16, 127, 0, 0);
  LAfter := GetExceptionMask;
  Assert.IsTrue(LBefore = LAfter, 'maschera');
end;

procedure TTestPmoveMover.DovrebbeScrivereLeRigheDiDiagnosticaSoloConIlLivello;
var
  LText: TStringBuilder;
begin
  LText := TStringBuilder.Create;
  try
    FMover := TPmoveFactory.CreateMover(FTrace, nil, TGoldenLog.Create(LText));
    FPmove.Ps.Origin[2] := 100;
    FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
    while FPmove.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE do
      Step(16, 0, 0, 0);
    Assert.AreEqual('', LText.ToString, 'senza livello niente');
    FPmove.DebugLevel := 1;
    FPmove.Ps.Origin[2] := 100;
    FPmove.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
    FPmove.Ps.Velocity[2] := 0;
    while FPmove.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE do
      Step(16, 0, 0, 0);
    // the counter of the steps is in the line: the first line comes after the steps of the fall
    Assert.IsTrue(LText.ToString.Contains(':Land'#10), LText.ToString);
  finally
    FMover := nil;
    LText.Free;
  end;
end;

procedure TTestPmoveMover.DovrebbeIgnorareIlComandoSeIlTastoDelleChiacchiereEPremuto;
begin
  FPmove.Ps.Ammo[Q3_WP_MACHINEGUN] := 100;
  FPmove.Cmd.Buttons := Q3_BUTTON_TALK or Q3_BUTTON_ATTACK or Q3_BUTTON_WALKING;
  Step(16, 127, 0, 127);
  Assert.IsTrue((FPmove.Ps.EFlags and Q3_EF_TALK) <> 0, 'palloncino');
  Assert.AreEqual<Integer>(Q3_BUTTON_TALK, FPmove.Cmd.Buttons, 'solo il tasto delle chiacchiere resta');
  Near(0, Origin(0), 0, 'fermo');
  Assert.IsFalse(HasEvent(Q3_EV_JUMP), 'niente salto');
  Assert.IsFalse(HasEvent(Q3_EV_FIRE_WEAPON), 'niente colpo');
  // defect of the original, kept: the firing flag is set before the talk button clears the attack
  Assert.IsTrue((FPmove.Ps.EFlags and Q3_EF_FIRING) <> 0, 'EF_FIRING');
end;

procedure TTestPmoveMover.DovrebbeTornareSenzaArmaSeLArmaDelComandoNonELaSua;
begin
  // the weapon is lowered and the one asked for (the shotgun, 3) is not in the weapons of the player
  FPmove.Ps.WeaponState := Q3_WEAPON_DROPPING;
  FPmove.Ps.WeaponTime := 0;
  FPmove.Ps.Weapon := Q3_WP_MACHINEGUN;
  FPmove.Ps.Stats[Q3_STAT_WEAPONS] := 1 shl Q3_WP_MACHINEGUN;
  FPmove.Cmd.Weapon := Q3_WP_SHOTGUN;
  Step(16, 0, 0, 0);
  Assert.AreEqual(Q3_WP_NONE, FPmove.Ps.Weapon, 'nessun arma');
  Assert.AreEqual(Q3_WEAPON_RAISING, FPmove.Ps.WeaponState, 'la alza');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPmoveMover);

end.

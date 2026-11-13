{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the Quake III player models,   }
{  values worked out by hand and the cases the golden does not reach           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3PlayerValues;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Tests.Models.Q3PlayerSupport,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  [TestFixture]
  [Category('Models')]
  TTestQ3TokenReader = class
  public
    [Test]
    procedure DovrebbeLeggereLeParoleSeparateDaSpazi;
    [Test]
    procedure DovrebbeLasciareGliSpaziInUnaParolaTraVirgolette;
    [Test]
    procedure DovrebbeSaltareIDueTipiDiCommento;
    [Test]
    procedure DovrebbeDareParolaVuotaEFineAllaFineDelTesto;
    [Test]
    procedure DovrebbeScartareUnaParolaDiMilleventiquattroCaratteri;
    [Test]
    procedure DovrebbeFinireAUnByteNullo;
    [Test]
    procedure DovrebbeContareLeRighe;
    [Test]
    procedure DovrebbeTornareIndietroConLoStatoSalvato;
    [Test]
    procedure DovrebbeConfrontareIgnorandoLeMaiuscoleAscii;
  end;

  [TestFixture]
  [Category('Models')]
  TTestQ3FloatMath = class
  public
    [Test]
    procedure DovrebbeTroncareAIntConIlValoreIndefinitoFuoriIntervallo;
    [Test]
    procedure DovrebbeRiportareUnAngoloAZeroTrecentosessanta;
    [Test]
    procedure DovrebbeSottrarreGliAngoliTraMenoCentottantaECentottanta;
    [Test]
    procedure DovrebbeRifiutareUnAngoloCheNonSiRiduce;
    [Test]
    procedure DovrebbeDareGliAssiDiUnaRotazioneInImbardata;
    [Test]
    procedure DovrebbeDareLIdentitaPerAngoliNulli;
    [Test]
    procedure DovrebbeMoltiplicareLeMatriciRigaPerColonna;
  end;

  [TestFixture]
  [Category('Models')]
  TTestQ3AnimationParser = class
  strict private
    FLog: ILog;
    FFakeLog: TFakeQ3Log;
    function Warnings: TStringList;
    function Parse(const AText: AnsiString): IQ3AnimationConfig;
    function Fails(const AText: AnsiString; out ALine: Integer): string;
  public
    [Test]
    procedure DovrebbeDareIValoriPredefinitiSenzaParametriOpzionali;
    [Test]
    procedure DovrebbeLeggereITipiDiPassi;
    [Test]
    procedure DovrebbeLeggereSessoEOffsetDellaTesta;
    [Test]
    procedure DovrebbeLeggereLeGambeFissaETorsoFisso;
    [Test]
    procedure DovrebbeSottrarreIFotogrammiDelSoloBustoAlleGambe;
    [Test]
    procedure DovrebbeInvertireUnaAnimazioneConFotogrammiNegativi;
    [Test]
    procedure DovrebbeUsareUnFotogrammaAlSecondoSeLaFrequenzaEZero;
    [Test]
    procedure DovrebbeCopiareIlGestoPerLeAnimazioniDellaBandieraMancanti;
    [Test]
    procedure DovrebbeDerivareLeAnimazioniAIndietroEDellaBandiera;
    [Test]
    procedure DovrebbeSegnalareUnaParolaSconosciutaEUnPassoSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnFileVuotoOMancante;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoLungo;
    [Test]
    procedure DovrebbeRifiutareUnFileCheFinisceSenzaAnimazioniInvecDiGirareAVuoto;
    [Test]
    procedure DovrebbeRifiutareUnFileCheFinisceNelMezzoDiUnaAnimazione;
    [Test]
    procedure DovrebbeTacereSenzaRegistroDegliAvvisi;
    [Test]
    procedure DovrebbeNegareUnIndiceDiAnimazioneFuoriIntervallo;
    [Test]
    procedure DovrebbeCaricareDallaSorgenteDiTesto;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoPerUnTestoConLeRigheACapoDiWindows;
  end;

  [TestFixture]
  [Category('Models')]
  TTestQ3PlayerAnimation = class
  strict private
    FConfig: IQ3AnimationConfig;
    FRunner: IQ3LerpFrameRunner;
    FFrame: TQ3LerpFrame;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeIniziareAlPrimoFotogrammaDellaAnimazione;
    [Test]
    procedure DovrebbeAvanzareUnFotogrammaOgniPeriodo;
    [Test]
    procedure DovrebbeInterpolareFraDueFotogrammi;
    [Test]
    procedure DovrebbeFermarsiAllUltimoFotogrammaSenzaCiclo;
    [Test]
    procedure DovrebbeRipetereGliUltimiFotogrammiDelCiclo;
    [Test]
    procedure DovrebbeScorrereAllIndietroUnaAnimazioneInvertita;
    [Test]
    procedure DovrebbeAndareAPiuVelocitaConLaFretta;
    [Test]
    procedure DovrebbeCambiareAnimazioneEPartireDallIntervalloIniziale;
    [Test]
    procedure DovrebbeIgnorareIlBitDiAlternanzaNelNumero;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiAnimazioneSbagliato;
    [Test]
    procedure DovrebbeSpegnereLeAnimazioni;
    [Test]
    procedure DovrebbeRiportareIlTempoIndietroSeIlTempoTornaIndietro;
    [Test]
    procedure DovrebbeNonAvanzareConUnaFrequenzaDiMenoDiUnFotogrammaAlMillisecondo;
    [Test]
    procedure DovrebbeFarGirareLeGambeSulPostoSeStannoRuotando;
    [Test]
    procedure DovrebbeNonAnimareSeLeAnimazioniDelGiocatoreSonoSpente;
    [Test]
    procedure DovrebbeDareIFotogrammiDiGambeETorsoConLaFretta;
  end;

  [TestFixture]
  [Category('Models')]
  TTestQ3PlayerPose = class
  strict private
    function TwoFrameModel: IMd3Model;
    function Config: IQ3AnimationConfig;
    function Entity(const AX, AY, AZ: Single; const AYaw: Single): TQ3Entity;
  public
    [Test]
    procedure DovrebbeInterpolareOrigineEAssiDiUnTag;
    [Test]
    procedure DovrebbeNormalizzareGliAssiInterpolati;
    [Test]
    procedure DovrebbeUsareLUltimoFotogrammaPerUnFotogrammaOltreIlLimite;
    [Test]
    procedure DovrebbeDareFalsoEUnIdentitaPerUnTagMancanteOUnModelloNullo;
    [Test]
    procedure DovrebbeDistinguereLeMaiuscoleNelNomeDelTag;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaNegativo;
    [Test]
    procedure DovrebbePosizionareUnaEntitaSulTag;
    [Test]
    procedure DovrebbePosizionareUnaEntitaRuotataSulTag;
    [Test]
    procedure DovrebbeUnireGambeBustoETesta;
    [Test]
    procedure DovrebbePosizionareUnArmaSulBusto;
    [Test]
    procedure DovrebbeDareAssiNeutriConGiocatoreFermoEVistaDiritta;
    [Test]
    procedure DovrebbeRifiutareUnaDirezioneDiMovimentoFuoriIntervallo;
    [Test]
    procedure DovrebbeUsareDirezioneZeroPerUnCorpoMorto;
    [Test]
    procedure DovrebbeFarGirareLeGambeVersoLaVistaInPiuPassi;
    [Test]
    procedure DovrebbeCreareLeClassiDallaFabbrica;
  end;

implementation

uses
  System.Math,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Q3Player.Factory,
  DelphiDoom.Models.Q3Player.LerpFrameRunner,
  DelphiDoom.Models.Q3Player.PlayerAnimator,
  DelphiDoom.Models.Q3Player.FloatMath,
  DelphiDoom.Models.Q3Player.TokenReader,
  DelphiDoom.Models.Q3Player.AngleSwinger;

const
  EPSILON = 1e-5;

function AnimationLines(const AOverrides: array of string; const AFrom: Integer = 0;
  const ACount: Integer = Q3_MAX_ANIMATIONS): AnsiString;
var
  LIndex: Integer;
begin
  // every animation is "i*10 4 0 10" (four frames at ten per second) unless it is overridden
  Result := '';
  for LIndex := 0 to ACount - 1 do
    if (LIndex - AFrom >= 0) and (LIndex - AFrom <= High(AOverrides)) then
      Result := Result + AnsiString(AOverrides[LIndex - AFrom]) + #10
    else
      Result := Result + AnsiString(Format('%d 4 0 10'#10, [LIndex * 10]));
end;

function VectorNear(const AExpected, AActual: TIdVec3; const ATolerance: Single = EPSILON): Boolean;
begin
  Result := (Abs(AExpected.X - AActual.X) <= ATolerance) and (Abs(AExpected.Y - AActual.Y) <= ATolerance) and
    (Abs(AExpected.Z - AActual.Z) <= ATolerance);
end;

{ TTestQ3TokenReader }

procedure TTestQ3TokenReader.DovrebbeLeggereLeParoleSeparateDaSpazi;
var
  LReader: TQ3TokenReader;
begin
  LReader := TQ3TokenReader.Create('  one'#9'two'#13#10'three ');
  try
    Assert.AreEqual('one', string(LReader.Next));
    Assert.AreEqual('two', string(LReader.Next));
    Assert.AreEqual('three', string(LReader.Next));
    Assert.AreEqual('', string(LReader.Next));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TokenReader.DovrebbeLasciareGliSpaziInUnaParolaTraVirgolette;
var
  LReader: TQ3TokenReader;
begin
  LReader := TQ3TokenReader.Create('a "b c" "unterminated');
  try
    Assert.AreEqual('a', string(LReader.Next));
    Assert.AreEqual('b c', string(LReader.Next));
    Assert.AreEqual('unterminated', string(LReader.Next));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TokenReader.DovrebbeSaltareIDueTipiDiCommento;
var
  LReader: TQ3TokenReader;
begin
  LReader := TQ3TokenReader.Create('a // skip this'#10'b /* and'#10' this */ c /* open');
  try
    Assert.AreEqual('a', string(LReader.Next));
    Assert.AreEqual('b', string(LReader.Next));
    Assert.AreEqual('c', string(LReader.Next));
    Assert.AreEqual('', string(LReader.Next));
    Assert.IsTrue(LReader.Ended);
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TokenReader.DovrebbeDareParolaVuotaEFineAllaFineDelTesto;
var
  LReader: TQ3TokenReader;
begin
  LReader := TQ3TokenReader.Create('x');
  try
    Assert.IsFalse(LReader.Ended);
    LReader.Next;
    Assert.IsFalse(LReader.Ended);
    Assert.AreEqual('', string(LReader.Next));
    Assert.IsTrue(LReader.Ended);
    Assert.AreEqual('', string(LReader.Next), 'after the end every word is empty');
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TokenReader.DovrebbeScartareUnaParolaDiMilleventiquattroCaratteri;
var
  LReader: TQ3TokenReader;
begin
  LReader := TQ3TokenReader.Create(AnsiString(StringOfChar('x', 1024) + ' ok ' + StringOfChar('y', 1023)));
  try
    Assert.AreEqual('', string(LReader.Next), 'the long word is discarded');
    Assert.IsFalse(LReader.Ended, 'but it is not the end');
    Assert.AreEqual('ok', string(LReader.Next));
    Assert.AreEqual(1023, Length(LReader.Next));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TokenReader.DovrebbeFinireAUnByteNullo;
var
  LReader: TQ3TokenReader;
begin
  LReader := TQ3TokenReader.Create('a'#0'b');
  try
    Assert.AreEqual('a', string(LReader.Next));
    Assert.AreEqual('', string(LReader.Next));
    Assert.IsTrue(LReader.Ended);
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TokenReader.DovrebbeContareLeRighe;
var
  LReader: TQ3TokenReader;
begin
  LReader := TQ3TokenReader.Create('a'#10'b'#10#10'c');
  try
    Assert.AreEqual(1, LReader.Line);
    LReader.Next;
    LReader.Next;
    Assert.AreEqual(2, LReader.Line);
    LReader.Next;
    Assert.AreEqual(4, LReader.Line);
    LReader.Next;
    Assert.AreEqual(4, LReader.Line, 'at the end the line is the last one');
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TokenReader.DovrebbeTornareIndietroConLoStatoSalvato;
var
  LReader: TQ3TokenReader;
  LState: TQ3TokenState;
begin
  LReader := TQ3TokenReader.Create('one two');
  try
    LReader.Next;
    LState := LReader.SaveState;
    Assert.AreEqual('two', string(LReader.Next));
    LReader.RestoreState(LState);
    Assert.AreEqual('two', string(LReader.Next));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3TokenReader.DovrebbeConfrontareIgnorandoLeMaiuscoleAscii;
begin
  Assert.IsTrue(TQ3TokenReader.SameWord('FootSteps', 'footsteps'));
  Assert.IsTrue(TQ3TokenReader.SameWord('', ''));
  Assert.IsFalse(TQ3TokenReader.SameWord('boot', 'boots'));
  Assert.IsFalse(TQ3TokenReader.SameWord('boot', 'bomt'));
  Assert.IsFalse(TQ3TokenReader.SameWord(AnsiString(#$C9), AnsiString(#$E9)), 'only the ASCII letters');
end;

{ TTestQ3FloatMath }

procedure TTestQ3FloatMath.DovrebbeTroncareAIntConIlValoreIndefinitoFuoriIntervallo;
begin
  Assert.AreEqual(-3, TQ3FloatMath.ToInt(-3.9));
  Assert.AreEqual(3, TQ3FloatMath.ToInt(3.9));
  Assert.AreEqual(Integer($80000000), TQ3FloatMath.ToInt(3e10));
  Assert.AreEqual(Integer($80000000), TQ3FloatMath.ToInt(-3e10));
  Assert.AreEqual(Integer($80000000), TQ3FloatMath.ToInt(NaN));
end;

procedure TTestQ3FloatMath.DovrebbeRiportareUnAngoloAZeroTrecentosessanta;
begin
  Assert.AreEqual(Double(0), Double(TQ3FloatMath.AngleMod(0)), 0.0);
  // 370 degrees is 67356 units of 360/65536 (the units truncate, 1820 after the turn), -10 is 63716
  Assert.AreEqual(9.99756, Double(TQ3FloatMath.AngleMod(370)), 0.0001);
  Assert.AreEqual(350.00244, Double(TQ3FloatMath.AngleMod(-10)), 0.0001);
  Assert.AreEqual(90.0, Double(TQ3FloatMath.AngleMod(90)), 0.006);
end;

procedure TTestQ3FloatMath.DovrebbeSottrarreGliAngoliTraMenoCentottantaECentottanta;
begin
  Assert.AreEqual(-20.0, Double(TQ3FloatMath.AngleSubtract(350, 10)), 1e-6);
  Assert.AreEqual(20.0, Double(TQ3FloatMath.AngleSubtract(10, 350)), 1e-6);
  Assert.AreEqual(180.0, Double(TQ3FloatMath.AngleSubtract(180, 0)), 1e-6);
  Assert.AreEqual(0.0, Double(TQ3FloatMath.AngleSubtract(720, 0)), 1e-6);
  Assert.IsTrue(IsNan(TQ3FloatMath.AngleSubtract(NaN, 0)), 'NaN stays NaN (no loop)');
end;

procedure TTestQ3FloatMath.DovrebbeRifiutareUnAngoloCheNonSiRiduce;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3FloatMath.AngleSubtract(3e9, 0);
    end, EQ3PlayerException));
end;

procedure TTestQ3FloatMath.DovrebbeDareGliAssiDiUnaRotazioneInImbardata;
var
  LAxis: TQ3Axis;
begin
  // yaw 90: the forward axis points along +y, the left one (axis 1) along -x, up stays up
  TQ3FloatMath.AnglesToAxis(TIdVec3.Create(0, 90, 0), LAxis);
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 1, 0), LAxis[0]), 'forward');
  Assert.IsTrue(VectorNear(TIdVec3.Create(-1, 0, 0), LAxis[1]), 'left');
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 0, 1), LAxis[2]), 'up');
  // pitch 90: forward looks down (-z)
  TQ3FloatMath.AnglesToAxis(TIdVec3.Create(90, 0, 0), LAxis);
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 0, -1), LAxis[0]), 'forward of pitch 90');
end;

procedure TTestQ3FloatMath.DovrebbeDareLIdentitaPerAngoliNulli;
var
  LAxis, LIdentity: TQ3Axis;
  LIndex: Integer;
begin
  TQ3FloatMath.AnglesToAxis(TIdVec3.Create(0, 0, 0), LAxis);
  TQ3FloatMath.AxisClear(LIdentity);
  for LIndex := 0 to 2 do
    Assert.IsTrue(VectorNear(LIdentity[LIndex], LAxis[LIndex], 0), 'axis ' + IntToStr(LIndex));
end;

procedure TTestQ3FloatMath.DovrebbeMoltiplicareLeMatriciRigaPerColonna;
var
  LLeft, LRight, LResult: TQ3Axis;
begin
  LLeft[0] := TIdVec3.Create(1, 2, 3);
  LLeft[1] := TIdVec3.Create(4, 5, 6);
  LLeft[2] := TIdVec3.Create(7, 8, 9);
  LRight[0] := TIdVec3.Create(0, 1, 0);
  LRight[1] := TIdVec3.Create(1, 0, 0);
  LRight[2] := TIdVec3.Create(0, 0, 2);
  TQ3FloatMath.MatrixMultiply(LLeft, LRight, LResult);
  // the columns of the first two swap and the third is doubled
  Assert.IsTrue(VectorNear(TIdVec3.Create(2, 1, 6), LResult[0], 0));
  Assert.IsTrue(VectorNear(TIdVec3.Create(5, 4, 12), LResult[1], 0));
  Assert.IsTrue(VectorNear(TIdVec3.Create(8, 7, 18), LResult[2], 0));
  // the output may be an input
  TQ3FloatMath.MatrixMultiply(LLeft, LRight, LLeft);
  Assert.IsTrue(VectorNear(TIdVec3.Create(2, 1, 6), LLeft[0], 0));
  Assert.AreEqual(Double(32), Double(TQ3FloatMath.Dot(TIdVec3.Create(1, 2, 3), TIdVec3.Create(4, 5, 6))), 0.0);
end;

{ TTestQ3AnimationParser }

function TTestQ3AnimationParser.Parse(const AText: AnsiString): IQ3AnimationConfig;
begin
  FFakeLog := TFakeQ3Log.Create;
  FLog := FFakeLog;
  Result := TQ3PlayerFactory.CreateParser(FLog).Parse(AText, 'test.cfg');
end;

function TTestQ3AnimationParser.Warnings: TStringList;
begin
  Result := FFakeLog.Warnings;
end;

function TTestQ3AnimationParser.Fails(const AText: AnsiString; out ALine: Integer): string;
begin
  Result := '';
  ALine := -1;
  try
    Parse(AText);
  except
    on E: EQ3PlayerException do
    begin
      Result := E.Message;
      ALine := E.Line;
    end;
  end;
end;

procedure TTestQ3AnimationParser.DovrebbeDareIValoriPredefinitiSenzaParametriOpzionali;
var
  LConfig: IQ3AnimationConfig;
begin
  LConfig := Parse(AnimationLines([]));
  Assert.AreEqual(Ord(qfNormal), Ord(LConfig.Footsteps));
  Assert.AreEqual(Ord(qgMale), Ord(LConfig.Gender));
  Assert.IsFalse(LConfig.FixedLegs);
  Assert.IsFalse(LConfig.FixedTorso);
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 0, 0), LConfig.HeadOffset, 0));
  Assert.AreEqual(100, LConfig.Animations[Q3_TORSO_RAISE].FrameLerp, 'ten frames per second: 100 ms');
  Assert.AreEqual(100, LConfig.Animations[Q3_TORSO_RAISE].InitialLerp);
  Assert.AreEqual(Q3_TORSO_RAISE * 10, LConfig.Animations[Q3_TORSO_RAISE].FirstFrame);
  Assert.AreEqual(4, LConfig.Animations[Q3_TORSO_RAISE].NumFrames);
end;

procedure TTestQ3AnimationParser.DovrebbeLeggereITipiDiPassi;
begin
  Assert.AreEqual(Ord(qfBoot), Ord(Parse('footsteps BOOT'#10 + AnimationLines([])).Footsteps));
  Assert.AreEqual(Ord(qfFlesh), Ord(Parse('footsteps flesh'#10 + AnimationLines([])).Footsteps));
  Assert.AreEqual(Ord(qfMech), Ord(Parse('footsteps mech'#10 + AnimationLines([])).Footsteps));
  Assert.AreEqual(Ord(qfEnergy), Ord(Parse('footsteps energy'#10 + AnimationLines([])).Footsteps));
  Assert.AreEqual(Ord(qfNormal), Ord(Parse('footsteps boot footsteps default'#10 + AnimationLines([])).Footsteps));
  Assert.AreEqual(Ord(qfNormal), Ord(Parse('footsteps boot footsteps normal'#10 + AnimationLines([])).Footsteps));
  Assert.AreEqual(Ord(qfBoot), Ord(Parse('footsteps boot footsteps metal'#10 + AnimationLines([])).Footsteps),
    'metal is not a word of the file: the old value stays');
  Assert.AreEqual(1, Warnings.Count);
  Assert.AreEqual('Bad footsteps parm in test.cfg: metal', Warnings[0]);
end;

procedure TTestQ3AnimationParser.DovrebbeLeggereSessoEOffsetDellaTesta;
var
  LConfig: IQ3AnimationConfig;
begin
  LConfig := Parse('sex Female headoffset 1 2.5 -3'#10 + AnimationLines([]));
  Assert.AreEqual(Ord(qgFemale), Ord(LConfig.Gender));
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 2.5, -3), LConfig.HeadOffset, 0));
  Assert.AreEqual(Ord(qgNeuter), Ord(Parse('sex n'#10 + AnimationLines([])).Gender));
  Assert.AreEqual(Ord(qgMale), Ord(Parse('sex f sex x'#10 + AnimationLines([])).Gender), 'any other letter is male');
  Assert.AreEqual(Ord(qgMale), Ord(Parse('sex ""'#10 + AnimationLines([])).Gender), 'and so is an empty word');
end;

procedure TTestQ3AnimationParser.DovrebbeLeggereLeGambeFissaETorsoFisso;
var
  LConfig: IQ3AnimationConfig;
begin
  LConfig := Parse('fixedlegs'#10 + AnimationLines([]));
  Assert.IsTrue(LConfig.FixedLegs);
  Assert.IsFalse(LConfig.FixedTorso);
  LConfig := Parse('FIXEDTORSO'#10 + AnimationLines([]));
  Assert.IsFalse(LConfig.FixedLegs);
  Assert.IsTrue(LConfig.FixedTorso);
end;

procedure TTestQ3AnimationParser.DovrebbeSottrarreIFotogrammiDelSoloBustoAlleGambe;
var
  LConfig: IQ3AnimationConfig;
begin
  // TORSO_GESTURE at 90, six animations of the torso only, LEGS_WALKCR at 153: 63 frames are the torso's alone
  LConfig := Parse(AnimationLines(['90 5 0 10', '1 1 0 10', '1 1 0 10', '1 1 0 10', '1 1 0 10', '1 1 0 10',
    '1 1 0 10', '153 8 8 15', '161 12 12 20'], Q3_TORSO_GESTURE));
  Assert.AreEqual(90, LConfig.Animations[Q3_TORSO_GESTURE].FirstFrame, 'the torso is not adjusted');
  Assert.AreEqual(90, LConfig.Animations[Q3_LEGS_WALKCR].FirstFrame, '153 - (153 - 90)');
  Assert.AreEqual(98, LConfig.Animations[Q3_LEGS_WALK].FirstFrame, '161 - 63');
  Assert.AreEqual(Q3_LEGS_RUN * 10 - 63, LConfig.Animations[Q3_LEGS_RUN].FirstFrame, 'the next legs too');
  Assert.AreEqual(Q3_TORSO_GETFLAG * 10, LConfig.Animations[Q3_TORSO_GETFLAG].FirstFrame, 'the flag animations are not');
end;

procedure TTestQ3AnimationParser.DovrebbeInvertireUnaAnimazioneConFotogrammiNegativi;
var
  LAnimation: TQ3Animation;
begin
  LAnimation := Parse(AnimationLines(['20 -6 2 10'], Q3_TORSO_ATTACK)).Animations[Q3_TORSO_ATTACK];
  Assert.AreEqual(6, LAnimation.NumFrames);
  Assert.IsTrue(LAnimation.Reversed);
  Assert.AreEqual(2, LAnimation.LoopFrames);
  Assert.IsFalse(LAnimation.Flipflop);
end;

procedure TTestQ3AnimationParser.DovrebbeUsareUnFotogrammaAlSecondoSeLaFrequenzaEZero;
begin
  Assert.AreEqual(1000, Parse(AnimationLines(['0 4 0 0'], Q3_TORSO_ATTACK)).Animations[Q3_TORSO_ATTACK].FrameLerp);
  Assert.AreEqual(1000, Parse(AnimationLines(['0 4 0 0'], Q3_TORSO_ATTACK)).Animations[Q3_TORSO_ATTACK].InitialLerp);
  Assert.AreEqual(333, Parse(AnimationLines(['0 4 0 3'], Q3_TORSO_ATTACK)).Animations[Q3_TORSO_ATTACK].FrameLerp,
    '1000 / 3 truncates');
  Assert.AreEqual(0, Parse(AnimationLines(['0 4 0 2000'], Q3_TORSO_ATTACK)).Animations[Q3_TORSO_ATTACK].FrameLerp);
  Assert.AreEqual(54, Parse(AnimationLines(['0 4 0 18.5'], Q3_TORSO_ATTACK)).Animations[Q3_TORSO_ATTACK].FrameLerp);
  Assert.AreEqual(-100, Parse(AnimationLines(['0 4 0 -10'], Q3_TORSO_ATTACK)).Animations[Q3_TORSO_ATTACK].FrameLerp,
    'a negative rate is not checked by the original');
end;

procedure TTestQ3AnimationParser.DovrebbeCopiareIlGestoPerLeAnimazioniDellaBandieraMancanti;
var
  LConfig: IQ3AnimationConfig;
  LIndex: Integer;
begin
  // the file ends after LEGS_TURN (25 lines): the six animations of the flag are those of the gesture
  LConfig := Parse(AnimationLines(['7 9 3 12'], Q3_TORSO_GESTURE, Q3_TORSO_GETFLAG));
  for LIndex := Q3_TORSO_GETFLAG to Q3_TORSO_NEGATIVE do
  begin
    Assert.AreEqual(7, LConfig.Animations[LIndex].FirstFrame, 'first frame of ' + IntToStr(LIndex));
    Assert.AreEqual(9, LConfig.Animations[LIndex].NumFrames);
    Assert.AreEqual(3, LConfig.Animations[LIndex].LoopFrames);
    Assert.AreEqual(83, LConfig.Animations[LIndex].FrameLerp);
    Assert.AreEqual(83, LConfig.Animations[LIndex].InitialLerp);
    Assert.IsFalse(LConfig.Animations[LIndex].Reversed);
  end;
  // a file that ends before that point is an error
  Assert.IsTrue(Raises(
    procedure
    begin
      Parse(AnimationLines([], 0, Q3_TORSO_GETFLAG - 1));
    end, EQ3PlayerException));
end;

procedure TTestQ3AnimationParser.DovrebbeDerivareLeAnimazioniAIndietroEDellaBandiera;
var
  LConfig: IQ3AnimationConfig;
begin
  LConfig := Parse(AnimationLines([]));
  Assert.IsTrue(LConfig.Animations[Q3_LEGS_BACKCR].Reversed);
  Assert.AreEqual(LConfig.Animations[Q3_LEGS_WALKCR].FirstFrame, LConfig.Animations[Q3_LEGS_BACKCR].FirstFrame);
  Assert.IsTrue(LConfig.Animations[Q3_LEGS_BACKWALK].Reversed);
  Assert.AreEqual(LConfig.Animations[Q3_LEGS_WALK].NumFrames, LConfig.Animations[Q3_LEGS_BACKWALK].NumFrames);
  Assert.IsFalse(LConfig.Animations[Q3_LEGS_WALK].Reversed, 'the original is not touched');
  Assert.AreEqual(16, LConfig.Animations[Q3_FLAG_RUN].NumFrames);
  Assert.AreEqual(66, LConfig.Animations[Q3_FLAG_RUN].FrameLerp);
  Assert.AreEqual(5, LConfig.Animations[Q3_FLAG_STAND].NumFrames);
  Assert.AreEqual(50, LConfig.Animations[Q3_FLAG_STAND].FrameLerp);
  Assert.AreEqual(0, LConfig.Animations[Q3_FLAG_STAND].LoopFrames);
  Assert.IsTrue(LConfig.Animations[Q3_FLAG_STAND2RUN].Reversed);
  Assert.AreEqual(1, LConfig.Animations[Q3_FLAG_STAND2RUN].LoopFrames);
  Assert.AreEqual(0, LConfig.Animations[Q3_MAX_ANIMATIONS].NumFrames, 'the marker between the two groups is empty');
end;

procedure TTestQ3AnimationParser.DovrebbeSegnalareUnaParolaSconosciutaEUnPassoSbagliato;
begin
  Parse('mystery'#10'footsteps wood'#10 + AnimationLines([]));
  Assert.AreEqual(2, Warnings.Count);
  Assert.AreEqual('unknown token ''mystery'' is test.cfg', Warnings[0]);
  Assert.AreEqual('Bad footsteps parm in test.cfg: wood', Warnings[1]);
end;

procedure TTestQ3AnimationParser.DovrebbeRifiutareUnFileVuotoOMancante;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      Parse('');
    end, EQ3AnimationMissingException));
end;

procedure TTestQ3AnimationParser.DovrebbeRifiutareUnFileTroppoLungo;
var
  LLine: Integer;
begin
  Assert.AreEqual('File test.cfg too long', Fails(AnsiString(StringOfChar('1', 19999)), LLine));
  Assert.AreNotEqual('File test.cfg too long', Fails(AnsiString(StringOfChar(' ', 19997) + 'x'), LLine),
    'one byte less is fine');
end;

procedure TTestQ3AnimationParser.DovrebbeRifiutareUnFileCheFinisceSenzaAnimazioniInvecDiGirareAVuoto;
var
  LLine: Integer;
  LMessage: string;
begin
  // the original never leaves its loop on a file with no number; here it is an error with the line
  LMessage := Fails('sex male'#10'fixedlegs'#10, LLine);
  Assert.IsTrue(LMessage.Contains('ends before the first animation'), LMessage);
  Assert.AreEqual(3, LLine);
  LMessage := Fails('footsteps', LLine);
  Assert.IsTrue(LMessage.Contains('ends before the first animation'), LMessage);
  Assert.AreEqual(1, Warnings.Count, 'the original warns about the empty word before it loops');
end;

procedure TTestQ3AnimationParser.DovrebbeRifiutareUnFileCheFinisceNelMezzoDiUnaAnimazione;
var
  LLine: Integer;
begin
  Assert.AreEqual('Error parsing animation file: test.cfg', Fails('0 4 0 10'#10'4 4 0'#10, LLine));
  Assert.AreEqual(3, LLine);
  Assert.AreEqual('Error parsing animation file: test.cfg', Fails('0 4'#10, LLine));
  Assert.AreEqual('Error parsing animation file: test.cfg', Fails('0'#10, LLine));
  Assert.AreEqual('Error parsing animation file: test.cfg', Fails('0 4 0 10'#10'1 1 1 1', LLine), 'too few animations');
end;

procedure TTestQ3AnimationParser.DovrebbeTacereSenzaRegistroDegliAvvisi;
begin
  Assert.AreEqual(Ord(qfNormal),
    Ord(TQ3PlayerFactory.CreateParser(nil).Parse('mystery'#10'footsteps x'#10 + AnimationLines([]), 'a.cfg').Footsteps));
end;

procedure TTestQ3AnimationParser.DovrebbeNegareUnIndiceDiAnimazioneFuoriIntervallo;
var
  LConfig: IQ3AnimationConfig;
begin
  LConfig := Parse(AnimationLines([]));
  Assert.IsTrue(Raises(
    procedure
    var
      LAnimation: TQ3Animation;
    begin
      LAnimation := LConfig.Animations[Q3_MAX_TOTAL_ANIMATIONS];
    end, EArgumentOutOfRangeException));
  Assert.IsTrue(Raises(
    procedure
    var
      LAnimation: TQ3Animation;
    begin
      LAnimation := LConfig.Animations[-1];
    end, EArgumentOutOfRangeException));
end;

procedure TTestQ3AnimationParser.DovrebbeCaricareDallaSorgenteDiTesto;
var
  LSource: TFakeQ3TextSource;
  LSourceIntf: IQ3TextSource;
  LLoader: IQ3AnimationLoader;
begin
  LSource := TFakeQ3TextSource.Create;
  LSourceIntf := LSource;
  LSource.Add('models/players/x/animation.cfg', 'sex f'#10 + AnimationLines([]));
  LLoader := TQ3PlayerFactory.CreateLoader(LSourceIntf, nil);
  Assert.AreEqual(Ord(qgFemale), Ord(LLoader.Load('models/players/x/animation.cfg').Gender));
  Assert.IsTrue(Raises(
    procedure
    begin
      LLoader.Load('models/players/y/animation.cfg');
    end, EQ3AnimationMissingException));
end;

procedure TTestQ3AnimationParser.DovrebbeDareLoStessoRisultatoPerUnTestoConLeRigheACapoDiWindows;
var
  LUnix, LWindows: AnsiString;
begin
  LUnix := AnimationLines([]);
  LWindows := AnsiString(StringReplace(string(LUnix), #10, #13#10, [rfReplaceAll]));
  Assert.AreEqual(Parse(LUnix).Animations[Q3_LEGS_RUN].FirstFrame, Parse(LWindows).Animations[Q3_LEGS_RUN].FirstFrame);
end;

{ TTestQ3PlayerAnimation }

procedure TTestQ3PlayerAnimation.Setup;
begin
  // every animation is four frames from i * 10 at 10 fps; TORSO_ATTACK is ten frames from 20 without a loop;
  // the legs lose the 70 frames between TORSO_GESTURE (60) and LEGS_WALKCR (130): LEGS_RUN starts at 150 - 70 = 80
  FConfig := TQ3PlayerFactory.CreateParser(nil).Parse(AnimationLines(['20 10 0 10'], Q3_TORSO_ATTACK), 'a.cfg');
  FRunner := TQ3PlayerFactory.CreateLerpFrameRunner(FConfig);
  FillChar(FFrame, SizeOf(FFrame), 0);
end;

procedure TTestQ3PlayerAnimation.DovrebbeIniziareAlPrimoFotogrammaDellaAnimazione;
begin
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 1000);
  Assert.AreEqual(20, FFrame.Frame);
  Assert.AreEqual(20, FFrame.OldFrame);
  Assert.AreEqual(1000, FFrame.FrameTime);
  Assert.AreEqual(1100, FFrame.AnimationTime, 'the first frame is exact after the initial lerp');
  Assert.IsTrue(FFrame.HasAnimation);
  Assert.AreEqual(Q3_TORSO_ATTACK, FFrame.AnimationIndex);
end;

procedure TTestQ3PlayerAnimation.DovrebbeAvanzareUnFotogrammaOgniPeriodo;
begin
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 1000);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1000);
  Assert.AreEqual(20, FFrame.Frame, 'still in the initial lerp');
  Assert.AreEqual(1100, FFrame.FrameTime);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1100);
  Assert.AreEqual(20, FFrame.OldFrame);
  Assert.AreEqual(1200, FFrame.FrameTime);
  Assert.AreEqual(21, FFrame.Frame);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1200);
  Assert.AreEqual(22, FFrame.Frame);
  Assert.AreEqual(21, FFrame.OldFrame);
end;

procedure TTestQ3PlayerAnimation.DovrebbeInterpolareFraDueFotogrammi;
begin
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 1000);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1100);
  Assert.AreEqual(0.0, Double(FFrame.BackLerp), 1e-6, 'the new frame is exactly on at the time of the frame');
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1125);
  Assert.AreEqual(0.75, Double(FFrame.BackLerp), 1e-6);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1150);
  Assert.AreEqual(0.5, Double(FFrame.BackLerp), 1e-6);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1199);
  Assert.AreEqual(0.01, Double(FFrame.BackLerp), 1e-6);
end;

procedure TTestQ3PlayerAnimation.DovrebbeFermarsiAllUltimoFotogrammaSenzaCiclo;
var
  LTime: Integer;
begin
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 1000);
  for LTime := 0 to 40 do
    FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1000 + LTime * 100);
  Assert.AreEqual(29, FFrame.Frame, '20 + 10 - 1: stuck at the end');
  Assert.AreEqual(5000, FFrame.FrameTime, 'the frame time follows the time so that another animation can start at once');
end;

procedure TTestQ3PlayerAnimation.DovrebbeRipetereGliUltimiFotogrammiDelCiclo;
var
  LTime: Integer;
  LFrames: string;
begin
  // 8 frames from 0, the last 3 loop, at 10 fps
  FConfig := TQ3PlayerFactory.CreateParser(nil).Parse(AnimationLines(['0 8 3 10'], Q3_TORSO_ATTACK), 'a.cfg');
  FRunner := TQ3PlayerFactory.CreateLerpFrameRunner(FConfig);
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 0);
  LFrames := '';
  for LTime := 0 to 13 do
  begin
    FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 100 + LTime * 100);
    LFrames := LFrames + IntToStr(FFrame.Frame) + ' ';
  end;
  Assert.AreEqual('0 1 2 3 4 5 6 7 5 6 7 5 6 7 ', LFrames);
end;

procedure TTestQ3PlayerAnimation.DovrebbeScorrereAllIndietroUnaAnimazioneInvertita;
var
  LTime: Integer;
  LFrames: string;
begin
  FConfig := TQ3PlayerFactory.CreateParser(nil).Parse(AnimationLines(['10 -4 0 10'], Q3_TORSO_ATTACK), 'a.cfg');
  FRunner := TQ3PlayerFactory.CreateLerpFrameRunner(FConfig);
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 0);
  LFrames := '';
  for LTime := 0 to 5 do
  begin
    FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 100 + LTime * 100);
    LFrames := LFrames + IntToStr(FFrame.Frame) + ' ';
  end;
  Assert.AreEqual('13 12 11 10 10 10 ', LFrames);
end;

procedure TTestQ3PlayerAnimation.DovrebbeAndareAPiuVelocitaConLaFretta;
var
  LTime: Integer;
  LFrames: string;
begin
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 0);
  LFrames := '';
  for LTime := 0 to 4 do
  begin
    FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1.5, 100 + LTime * 100);
    LFrames := LFrames + IntToStr(FFrame.Frame) + ' ';
  end;
  // the frame number f is truncated of f * 1.5: 0, 1, 3, 4, 6
  Assert.AreEqual('20 21 23 24 26 ', LFrames);
end;

procedure TTestQ3PlayerAnimation.DovrebbeCambiareAnimazioneEPartireDallIntervalloIniziale;
begin
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 1000);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1100);
  FRunner.Run(FFrame, Q3_TORSO_STAND, 1, 1150);
  Assert.AreEqual(Q3_TORSO_STAND, FFrame.AnimationNumber);
  Assert.AreEqual(1100 + 100, FFrame.AnimationTime, 'the current lerp finishes (frame time 1100), then the new one starts');
end;

procedure TTestQ3PlayerAnimation.DovrebbeIgnorareIlBitDiAlternanzaNelNumero;
begin
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK or Q3_ANIM_TOGGLEBIT, 1000);
  Assert.AreEqual(Q3_TORSO_ATTACK, FFrame.AnimationIndex);
  Assert.AreEqual(Q3_TORSO_ATTACK or Q3_ANIM_TOGGLEBIT, FFrame.AnimationNumber);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK or Q3_ANIM_TOGGLEBIT, 1, 1100);
  Assert.AreEqual(Q3_TORSO_ATTACK or Q3_ANIM_TOGGLEBIT, FFrame.AnimationNumber, 'the same number: no restart');
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1110);
  Assert.AreEqual(Q3_TORSO_ATTACK, FFrame.AnimationNumber, 'the toggled number is another number: it restarts');
end;

procedure TTestQ3PlayerAnimation.DovrebbeRifiutareUnNumeroDiAnimazioneSbagliato;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      FRunner.Clear(FFrame, 99, 0);
    end, EQ3PlayerException));
  Assert.IsTrue(Raises(
    procedure
    begin
      FRunner.SetAnimation(FFrame, Q3_MAX_TOTAL_ANIMATIONS);
    end, EQ3PlayerException));
  Assert.IsTrue(Raises(
    procedure
    begin
      FRunner.SetAnimation(FFrame, -1);
    end, EQ3PlayerException));
end;

procedure TTestQ3PlayerAnimation.DovrebbeSpegnereLeAnimazioni;
begin
  FRunner := TQ3LerpFrameRunner.Create(FConfig, False);
  FFrame.Frame := 5;
  FFrame.OldFrame := 4;
  FFrame.BackLerp := 0.5;
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1000);
  Assert.AreEqual(0, FFrame.Frame);
  Assert.AreEqual(0, FFrame.OldFrame);
  Assert.AreEqual(0.0, Double(FFrame.BackLerp), 0.0);
  Assert.IsFalse(FFrame.HasAnimation, 'nothing else is touched');
end;

procedure TTestQ3PlayerAnimation.DovrebbeRiportareIlTempoIndietroSeIlTempoTornaIndietro;
begin
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 1000);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 1100);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 900);
  Assert.IsTrue(FFrame.OldFrameTime <= 900, 'the old frame time is not in the future');
  Assert.IsTrue(FFrame.FrameTime <= 1100, 'and the frame time is at most 200 ms ahead');
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 100);
  Assert.AreEqual(100, FFrame.FrameTime, 'a frame time more than 200 ms ahead is the time');
end;

procedure TTestQ3PlayerAnimation.DovrebbeNonAvanzareConUnaFrequenzaDiMenoDiUnFotogrammaAlMillisecondo;
begin
  FConfig := TQ3PlayerFactory.CreateParser(nil).Parse(AnimationLines(['0 8 0 5000'], Q3_TORSO_ATTACK), 'a.cfg');
  FRunner := TQ3PlayerFactory.CreateLerpFrameRunner(FConfig);
  Assert.AreEqual(0, FConfig.Animations[Q3_TORSO_ATTACK].FrameLerp);
  FRunner.Clear(FFrame, Q3_TORSO_ATTACK, 0);
  FRunner.Run(FFrame, Q3_TORSO_ATTACK, 1, 500);
  Assert.AreEqual(0, FFrame.Frame, 'the original returns at once: the frame stays');
end;

procedure TTestQ3PlayerAnimation.DovrebbeFarGirareLeGambeSulPostoSeStannoRuotando;
var
  LAnimator: IQ3PlayerAnimator;
  LPlayer: TQ3PlayerEntity;
  LFrames: TQ3PlayerFrames;
begin
  LAnimator := TQ3PlayerFactory.CreateAnimator(FConfig);
  FillChar(LPlayer, SizeOf(LPlayer), 0);
  LPlayer.Legs.Yawing := True;
  LAnimator.Animate(LPlayer, 1000, Q3_LEGS_IDLE or Q3_ANIM_TOGGLEBIT, Q3_TORSO_STAND, False, LFrames);
  Assert.AreEqual(Q3_LEGS_TURN, LPlayer.Legs.AnimationNumber);
  Assert.AreEqual(Q3_TORSO_STAND, LPlayer.Torso.AnimationNumber);
  LPlayer.Legs.Yawing := False;
  LAnimator.Animate(LPlayer, 1010, Q3_LEGS_IDLE, Q3_TORSO_STAND, False, LFrames);
  Assert.AreEqual(Q3_LEGS_IDLE, LPlayer.Legs.AnimationNumber);
  LPlayer.Legs.Yawing := True;
  LAnimator.Animate(LPlayer, 1020, Q3_LEGS_RUN, Q3_TORSO_STAND, False, LFrames);
  Assert.AreEqual(Q3_LEGS_RUN, LPlayer.Legs.AnimationNumber, 'only the idle legs turn');
end;

procedure TTestQ3PlayerAnimation.DovrebbeNonAnimareSeLeAnimazioniDelGiocatoreSonoSpente;
var
  LAnimator: IQ3PlayerAnimator;
  LPlayer: TQ3PlayerEntity;
  LFrames: TQ3PlayerFrames;
begin
  LAnimator := TQ3PlayerAnimator.Create(FRunner, True);
  FillChar(LPlayer, SizeOf(LPlayer), 0);
  FillChar(LFrames, SizeOf(LFrames), 255);
  LAnimator.Animate(LPlayer, 1000, Q3_LEGS_RUN, Q3_TORSO_ATTACK, True, LFrames);
  Assert.AreEqual(0, LFrames.Legs);
  Assert.AreEqual(0, LFrames.LegsOld);
  Assert.AreEqual(0, LFrames.Torso);
  Assert.AreEqual(0, LFrames.TorsoOld);
  Assert.AreEqual(0.0, Double(LFrames.LegsBackLerp), 0.0);
  Assert.IsFalse(LPlayer.Legs.HasAnimation, 'no animation was run');
end;

procedure TTestQ3PlayerAnimation.DovrebbeDareIFotogrammiDiGambeETorsoConLaFretta;
var
  LAnimator: IQ3PlayerAnimator;
  LPlayer: TQ3PlayerEntity;
  LFrames: TQ3PlayerFrames;
begin
  LAnimator := TQ3PlayerFactory.CreateAnimator(FConfig);
  FillChar(LPlayer, SizeOf(LPlayer), 0);
  LAnimator.Animate(LPlayer, 1000, Q3_LEGS_RUN, Q3_TORSO_ATTACK, True, LFrames);
  Assert.AreEqual(Q3_LEGS_RUN * 10 - 70, LFrames.Legs);
  Assert.AreEqual(20, LFrames.Torso);
end;

{ TTestQ3PlayerPose }

function TTestQ3PlayerPose.TwoFrameModel: IMd3Model;
var
  LTags: array[0..3] of TQ3TestTag;
  LIndex: Integer;
begin
  // frame 0: tag_a at the origin, tag_b at (1,0,0) with axes of length 2; frame 1: tag_a at (10,20,30)
  LTags[0] := TagAt('tag_a', 0, 0, 0);
  LTags[1] := TagAt('tag_b', 1, 0, 0);
  for LIndex := 0 to 8 do
    LTags[1].Axis[LIndex] := 2 * Ord(LIndex mod 4 = 0);
  LTags[2] := TagAt('tag_a', 10, 20, 30);
  LTags[3] := LTags[1];
  Result := ReadMd3(BuildTagsMd3(2, 2, LTags));
end;

function TTestQ3PlayerPose.Entity(const AX, AY, AZ: Single; const AYaw: Single): TQ3Entity;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Origin := TIdVec3.Create(AX, AY, AZ);
  TQ3FloatMath.AnglesToAxis(TIdVec3.Create(0, AYaw, 0), Result.Axis);
end;

procedure TTestQ3PlayerPose.DovrebbeInterpolareOrigineEAssiDiUnTag;
var
  LTag: TQ3Orientation;
begin
  Assert.IsTrue(TQ3PlayerFactory.CreateTagLerper.LerpTag(TwoFrameModel, 0, 1, 0.25, 'tag_a', LTag));
  Assert.IsTrue(VectorNear(TIdVec3.Create(2.5, 5, 7.5), LTag.Origin));
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 0, 0), LTag.Axis[0]));
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 1, 0), LTag.Axis[1]));
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 0, 1), LTag.Axis[2]));
  Assert.IsTrue(TQ3PlayerFactory.CreateTagLerper.LerpTag(TwoFrameModel, 1, 0, 0, 'tag_a', LTag));
  Assert.IsTrue(VectorNear(TIdVec3.Create(10, 20, 30), LTag.Origin), 'a fraction of 0 is the start frame');
  Assert.IsTrue(TQ3PlayerFactory.CreateTagLerper.LerpTag(TwoFrameModel, 0, 1, 1, 'tag_a', LTag));
  Assert.IsTrue(VectorNear(TIdVec3.Create(10, 20, 30), LTag.Origin), 'and 1 is the end frame');
end;

procedure TTestQ3PlayerPose.DovrebbeNormalizzareGliAssiInterpolati;
var
  LTag: TQ3Orientation;
begin
  Assert.IsTrue(TQ3PlayerFactory.CreateTagLerper.LerpTag(TwoFrameModel, 0, 1, 0.5, 'tag_b', LTag));
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 0, 0), LTag.Axis[0]), 'length 2 becomes 1');
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 1, 0), LTag.Axis[1]));
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 0, 1), LTag.Axis[2]));
end;

procedure TTestQ3PlayerPose.DovrebbeUsareLUltimoFotogrammaPerUnFotogrammaOltreIlLimite;
var
  LTag: TQ3Orientation;
begin
  Assert.IsTrue(TQ3PlayerFactory.CreateTagLerper.LerpTag(TwoFrameModel, 7, 5, 0.5, 'tag_a', LTag));
  Assert.IsTrue(VectorNear(TIdVec3.Create(10, 20, 30), LTag.Origin));
end;

procedure TTestQ3PlayerPose.DovrebbeDareFalsoEUnIdentitaPerUnTagMancanteOUnModelloNullo;
var
  LTag: TQ3Orientation;
  LIdentity: TQ3Axis;
  LIndex: Integer;
begin
  TQ3FloatMath.AxisClear(LIdentity);
  LTag.Origin := TIdVec3.Create(5, 5, 5);
  Assert.IsFalse(TQ3PlayerFactory.CreateTagLerper.LerpTag(TwoFrameModel, 0, 1, 0.5, 'tag_missing', LTag));
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 0, 0), LTag.Origin, 0));
  for LIndex := 0 to 2 do
    Assert.IsTrue(VectorNear(LIdentity[LIndex], LTag.Axis[LIndex], 0));
  LTag.Origin := TIdVec3.Create(5, 5, 5);
  Assert.IsFalse(TQ3PlayerFactory.CreateTagLerper.LerpTag(nil, 0, 1, 0.5, 'tag_a', LTag));
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 0, 0), LTag.Origin, 0));
end;

procedure TTestQ3PlayerPose.DovrebbeDistinguereLeMaiuscoleNelNomeDelTag;
var
  LTag: TQ3Orientation;
begin
  Assert.IsFalse(TQ3PlayerFactory.CreateTagLerper.LerpTag(TwoFrameModel, 0, 1, 0.5, 'TAG_A', LTag));
end;

procedure TTestQ3PlayerPose.DovrebbeRifiutareUnFotogrammaNegativo;
begin
  Assert.IsTrue(Raises(
    procedure
    var
      LTag: TQ3Orientation;
    begin
      TQ3PlayerFactory.CreateTagLerper.LerpTag(TwoFrameModel, -1, 0, 0.5, 'tag_a', LTag);
    end, EQ3PlayerException));
end;

procedure TTestQ3PlayerPose.DovrebbePosizionareUnaEntitaSulTag;
var
  LParent, LEntity: TQ3Entity;
begin
  // the parent looks along +y: its axes are x = (0,1,0), y = (-1,0,0), z = (0,0,1)
  LParent := Entity(100, 0, 0, 90);
  LParent.OldFrame := 0;
  LParent.Frame := 1;
  LParent.BackLerp := 0.75;
  FillChar(LEntity, SizeOf(LEntity), 0);
  TQ3PlayerFactory.CreateTagPositioner.PositionEntityOnTag(LEntity, LParent, TwoFrameModel, 'tag_a');
  // the tag is at (2.5, 5, 7.5) in the axes of the parent: 100 - 5 in x, 2.5 in y, 7.5 in z
  Assert.IsTrue(VectorNear(TIdVec3.Create(95, 2.5, 7.5), LEntity.Origin, 1e-4), 'origin');
  Assert.IsTrue(VectorNear(LParent.Axis[0], LEntity.Axis[0]), 'the identity tag keeps the axes of the parent');
  Assert.IsTrue(VectorNear(LParent.Axis[1], LEntity.Axis[1]));
  Assert.AreEqual(0.75, Double(LEntity.BackLerp), 0.0);
end;

procedure TTestQ3PlayerPose.DovrebbePosizionareUnaEntitaRuotataSulTag;
var
  LParent, LEntity: TQ3Entity;
begin
  LParent := Entity(0, 0, 0, 90);
  LEntity := Entity(0, 0, 0, 90);
  LEntity.BackLerp := 0.125;
  TQ3PlayerFactory.CreateTagPositioner.PositionRotatedEntityOnTag(LEntity, LParent, TwoFrameModel, 'tag_a');
  // two turns of 90 degrees
  Assert.IsTrue(VectorNear(TIdVec3.Create(-1, 0, 0), LEntity.Axis[0], 1e-4), 'forward after 180 degrees');
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 0, 1), LEntity.Axis[2], 1e-4));
  Assert.AreEqual(0.125, Double(LEntity.BackLerp), 0.0, 'the rotated variant leaves the back lerp alone');
end;

procedure TTestQ3PlayerPose.DovrebbeUnireGambeBustoETesta;
var
  LLegsModel, LTorsoModel: IMd3Model;
  LLegsTags: array[0..0] of TQ3TestTag;
  LTorsoTags: array[0..1] of TQ3TestTag;
  LIdentity: TQ3Axis;
  LFrames: TQ3PlayerFrames;
  LLegs, LTorso, LHead: TQ3Entity;
begin
  LLegsTags[0] := TagAt('tag_torso', 0, 0, 10);
  LTorsoTags[0] := TagAt('tag_head', 0, 0, 5);
  LTorsoTags[1] := TagAt('tag_weapon', 8, 0, 0);
  LLegsModel := ReadMd3(BuildTagsMd3(1, 1, LLegsTags));
  LTorsoModel := ReadMd3(BuildTagsMd3(1, 2, LTorsoTags));
  TQ3FloatMath.AxisClear(LIdentity);
  FillChar(LFrames, SizeOf(LFrames), 0);
  LFrames.Legs := 3;
  LFrames.LegsOld := 2;
  LFrames.LegsBackLerp := 0.25;
  LFrames.Torso := 5;
  LFrames.TorsoOld := 4;
  LFrames.TorsoBackLerp := 0.5;
  TQ3PlayerFactory.CreateAssembler.Assemble(LLegsModel, LTorsoModel, TIdVec3.Create(1, 2, 3), LIdentity, LIdentity,
    LIdentity, LFrames, LLegs, LTorso, LHead);
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 2, 3), LLegs.Origin), 'legs at the player');
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 2, 13), LTorso.Origin), 'torso 10 above the legs');
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 2, 18), LHead.Origin), 'head 5 above the torso');
  Assert.AreEqual(2, LLegs.OldFrame);
  Assert.AreEqual(3, LLegs.Frame);
  Assert.AreEqual(0.25, Double(LLegs.BackLerp), 0.0);
  Assert.AreEqual(4, LTorso.OldFrame);
  Assert.AreEqual(5, LTorso.Frame);
  Assert.AreEqual(0, LHead.Frame, 'the head has one frame');
end;

procedure TTestQ3PlayerPose.DovrebbePosizionareUnArmaSulBusto;
var
  LTorsoModel: IMd3Model;
  LTorsoTags: array[0..0] of TQ3TestTag;
  LTorso, LGun: TQ3Entity;
begin
  LTorsoTags[0] := TagAt('tag_weapon', 8, 0, 0);
  LTorsoModel := ReadMd3(BuildTagsMd3(1, 1, LTorsoTags));
  LTorso := Entity(1, 2, 13, 90);
  TQ3PlayerFactory.CreateAssembler.PositionWeapon(LTorso, LTorsoModel, LGun);
  // 8 along the forward axis of the torso, (0,1,0)
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 10, 13), LGun.Origin, 1e-4));
  Assert.IsTrue(VectorNear(LTorso.Axis[0], LGun.Axis[0]));
end;

procedure TTestQ3PlayerPose.DovrebbeDareAssiNeutriConGiocatoreFermoEVistaDiritta;
var
  LAngles: IQ3PlayerAngles;
  LPlayer: TQ3PlayerEntity;
  LInput: TQ3PlayerAngleInput;
  LLegs, LTorso, LHead: TQ3Axis;
begin
  LAngles := TQ3PlayerFactory.CreateAngles(Config);
  FillChar(LPlayer, SizeOf(LPlayer), 0);
  FillChar(LInput, SizeOf(LInput), 0);
  LPlayer.Legs.YawAngle := 90;
  LPlayer.Torso.YawAngle := 90;
  LInput.LerpAngles := TIdVec3.Create(0, 90, 0);
  LInput.LegsAnim := Q3_LEGS_IDLE;
  LInput.TorsoAnim := Q3_TORSO_STAND;
  LInput.FrameTime := 20;
  LInput.Time := 1000;
  LPlayer.PainTime := -100000;
  LAngles.Compute(LInput, LPlayer, LLegs, LTorso, LHead);
  Assert.IsTrue(VectorNear(TIdVec3.Create(0, 1, 0), LLegs[0], 2e-3), 'the legs look along +y');
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 0, 0), LTorso[0], 2e-3), 'the torso is on the legs');
  Assert.IsTrue(VectorNear(TIdVec3.Create(1, 0, 0), LHead[0], 2e-3), 'the head is on the torso');
  Assert.IsFalse(LPlayer.Legs.Yawing);
  Assert.IsFalse(LPlayer.Torso.Pitching);
end;

procedure TTestQ3PlayerPose.DovrebbeRifiutareUnaDirezioneDiMovimentoFuoriIntervallo;
var
  LAngles: IQ3PlayerAngles;
  LPlayer: TQ3PlayerEntity;
  LInput: TQ3PlayerAngleInput;
  LLegs, LTorso, LHead: TQ3Axis;
begin
  LAngles := TQ3PlayerFactory.CreateAngles(Config);
  FillChar(LPlayer, SizeOf(LPlayer), 0);
  FillChar(LInput, SizeOf(LInput), 0);
  LInput.MovementDirection := 8;
  Assert.IsTrue(Raises(
    procedure
    begin
      LAngles.Compute(LInput, LPlayer, LLegs, LTorso, LHead);
    end, EQ3PlayerException));
  LInput.MovementDirection := -1;
  Assert.IsTrue(Raises(
    procedure
    begin
      LAngles.Compute(LInput, LPlayer, LLegs, LTorso, LHead);
    end, EQ3PlayerException));
  LInput.MovementDirection := 7;
  LAngles.Compute(LInput, LPlayer, LLegs, LTorso, LHead);
end;

procedure TTestQ3PlayerPose.DovrebbeUsareDirezioneZeroPerUnCorpoMorto;
var
  LAngles: IQ3PlayerAngles;
  LPlayer: TQ3PlayerEntity;
  LInput: TQ3PlayerAngleInput;
  LLegs, LTorso, LHead: TQ3Axis;
begin
  LAngles := TQ3PlayerFactory.CreateAngles(Config);
  FillChar(LPlayer, SizeOf(LPlayer), 0);
  FillChar(LInput, SizeOf(LInput), 0);
  LInput.Dead := True;
  LInput.MovementDirection := 99;
  LAngles.Compute(LInput, LPlayer, LLegs, LTorso, LHead);
  Assert.IsTrue(True, 'no error for a dead body whatever the direction');
end;

procedure TTestQ3PlayerPose.DovrebbeFarGirareLeGambeVersoLaVistaInPiuPassi;
var
  LAngles: IQ3PlayerAngles;
  LPlayer: TQ3PlayerEntity;
  LInput: TQ3PlayerAngleInput;
  LLegs, LTorso, LHead: TQ3Axis;
  LStep: Integer;
begin
  LAngles := TQ3PlayerFactory.CreateAngles(Config);
  FillChar(LPlayer, SizeOf(LPlayer), 0);
  FillChar(LInput, SizeOf(LInput), 0);
  LInput.LerpAngles := TIdVec3.Create(0, 90, 0);
  LInput.LegsAnim := Q3_LEGS_IDLE;
  LInput.TorsoAnim := Q3_TORSO_STAND;
  LInput.FrameTime := 20;
  LInput.Time := 1000;
  LPlayer.PainTime := -100000;
  // the legs are 90 degrees off: more than the 40 of the tolerance, so they start to swing at 20 * 2 * 0.3 = 12 degrees a step
  LAngles.Compute(LInput, LPlayer, LLegs, LTorso, LHead);
  Assert.IsTrue(LPlayer.Legs.Yawing);
  Assert.AreEqual(12.0, Double(LPlayer.Legs.YawAngle), 0.01);
  for LStep := 1 to 30 do
    LAngles.Compute(LInput, LPlayer, LLegs, LTorso, LHead);
  Assert.AreEqual(90.0, Double(LPlayer.Legs.YawAngle), 0.02, 'it arrives at the view');
  Assert.IsFalse(LPlayer.Legs.Yawing, 'and stops swinging');
end;

procedure TTestQ3PlayerPose.DovrebbeCreareLeClassiDallaFabbrica;
begin
  Assert.IsNotNull(TQ3PlayerFactory.CreateParser(nil));
  Assert.IsNotNull(TQ3PlayerFactory.CreateLoader(TFakeQ3TextSource.Create, nil));
  Assert.IsNotNull(TQ3PlayerFactory.CreateLerpFrameRunner(Config));
  Assert.IsNotNull(TQ3PlayerFactory.CreateAnimator(Config));
  Assert.IsNotNull(TQ3PlayerFactory.CreateAngles(Config));
  Assert.IsNotNull(TQ3PlayerFactory.CreateTagLerper);
  Assert.IsNotNull(TQ3PlayerFactory.CreateTagPositioner);
  Assert.IsNotNull(TQ3PlayerFactory.CreateAssembler);
end;

function TTestQ3PlayerPose.Config: IQ3AnimationConfig;
begin
  Result := TQ3PlayerFactory.CreateParser(nil).Parse(AnimationLines([]), 'a.cfg');
end;

end.

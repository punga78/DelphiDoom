{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixActionRules and of TRadixMessages                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.ActionRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Action.Rules, DelphiDoom.Radix.Messages;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixActionRules = class(TObject)
  strict private
    class function Wave(ABytesPerSecond, ADataSize: Integer; AExtraChunk: Boolean): TBytes; static;
  public
    [Test]
    [TestCase('buio', '0,200')]
    [TestCase('meta', '32,216')]
    [TestCase('pieno', '63,231')]
    procedure DovrebbeTenereChiaroUnSettoreSenzaNebbia(ALevel, AExpected: Integer);
    [Test]
    [TestCase('buio', '0,2')]
    [TestCase('meta', '32,130')]
    [TestCase('pieno', '63,254')]
    [TestCase('oltre', '64,255')]
    [TestCase('molto oltre', '200,255')]
    procedure DovrebbeStendereLaLuceDiUnSettoreConNebbia(ALevel, AExpected: Integer);
    [Test]
    procedure DovrebbeUsareLaStessaScalaPerIlBuio;
    [Test]
    procedure DovrebbeFarOscillareLaLuceTraIDueLivelli;
    [Test]
    [TestCase('fermo', '0,False,1')]
    [TestCase('tre', '3,False,8')]
    [TestCase('soglia', '10,False,1024')]
    [TestCase('oltre', '12,False,1024')]
    [TestCase('trentacinque vecchio', '35,False,1024')]
    [TestCase('trentacinque nuovo', '35,True,10')]
    [TestCase('nuovo lento', '4,True,16')]
    procedure DovrebbeDareIlPassoDiUnaSuperficie(ASpeed: Integer; ANew: Boolean; AExpected: Integer);
    [Test]
    procedure DovrebbePortareUnPuntoDiRadixNellaMappa;
    [Test]
    procedure DovrebbePortareUnPuntoDellaSecondaMetaDelLivelloDiviso;
    [Test]
    procedure DovrebbeAndareAlLivelloSeguente;
    [Test]
    procedure DovrebbeAndareAlLivelloSegreto;
    [Test]
    procedure DovrebbeTornareDalLivelloSegretoAlLivelloNominato;
    [Test]
    procedure DovrebbeFinireLEpisodio;
    [Test]
    procedure DovrebbeRaggiungereLaPercentualeDiUccisioni;
    [Test]
    procedure DovrebbeContareINemiciAncoraVivi;
    [Test]
    procedure DovrebbeDareIlDannoDiUnEsplosioneSecondoLaDistanza;
    [Test]
    procedure DovrebbeSpingereLaNavettaNelSettoreConGravita;
    [Test]
    procedure DovrebbeNonRipetereUnMessaggioSubito;
    [Test]
    procedure DovrebbeDareIlDannoDiUnColpoAUnMuro;
    [Test]
    procedure DovrebbeDareLaDurataDiUnSuono;
    [Test]
    procedure DovrebbeSaltareIChunkPrimaDeiDati;
    [Test]
    procedure DovrebbeDareMenoUnoSeNonEUnWave;
    [Test]
    procedure DovrebbeDareIlNomeDelLumpDiUnSuono;
    [Test]
    procedure DovrebbeAccelerareLaNavettaNelTrasportatore;
    [Test]
    procedure DovrebbePercorrereTuttaLaDistanzaDelTrasportatore;
    [Test]
    procedure DovrebbeFermareIlTrasportatoreAllaFine;
    [Test]
    procedure DovrebbeGirareLaNavettaVersoLAngoloDiArrivo;
    [Test]
    procedure DovrebbeGirareDalLatoCortoAttraversoLoZero;
    [Test]
    procedure DovrebbeVedereIlMuroDavantiAlColpo;
    [Test]
    procedure DovrebbeNonVedereIlMuroDietroAlColpo;
    [Test]
    procedure DovrebbeMisurareLaDistanzaDallEstremoDelMuro;
    [Test]
    procedure DovrebbeVedereIlMuroCheIlColpoToccaGia;
    [Test]
    procedure IlColpoCheAttraversaIlMuroDovrebbeAverloSullaStrada;
    [Test]
    procedure IlColpoCheSiFermaPrimaDelMuroNonDovrebbeAverloSullaStrada;
    [Test]
    procedure IlMuroDiFiancoODietroNonDovrebbeEssereSullaStrada;
    [Test]
    procedure IlColpoCheSfioraLEstremoDelMuroDovrebbeContareEntroIlMargine;
    [Test]
    procedure UnColpoFermoOUnMuroPuntoNonDovrebberoDareErrori;
  end;

  [TestFixture]
  [Category('radix')]
  TTestRadixThingSpawnRules = class(TObject)
  public
    [Test]
    [TestCase('abilita uguale', '2,2,False,True')]
    [TestCase('abilita piu alta del gioco', '1,3,False,True')]
    [TestCase('cosa piu difficile', '3,2,False,False')]
    [TestCase('la piu difficile in rete', '4,1,True,True')]
    [TestCase('difficile in rete', '3,1,True,False')]
    [TestCase('la piu difficile da soli', '4,1,False,False')]
    procedure DovrebbeGenerareLaCosaSecondoLAbilita(ARadixSkill, AGameSkill: Integer; ANetGame, AExpected: Boolean);
    [Test]
    procedure DovrebbeMettereLaCosaSopraIlPavimento;
    [Test]
    procedure DovrebbeMettereLaNavettaAllaSuaQuotaMaNonSottoIlPavimento;
    [Test]
    procedure DovrebbeDareUnIdentificatoreAlNumeroDiRadix;
  end;

  [TestFixture]
  [Category('radix')]
  TTestRadixMessages = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereTrediciMessaggi;
    [Test]
    procedure DovrebbeDareUnMessaggioVuotoFuoriDallaTabella;
    [Test]
    procedure DovrebbeMostrareUnaVoltaSolaGliObiettiviCompletati;
    [Test]
    procedure DovrebbeAvereISuoniDeiNomiGiusti;
    [Test]
    [TestCase('primo livello', '1,1,True')]
    [TestCase('quarto del primo', '1,4,True')]
    [TestCase('quinto del primo', '1,5,False')]
    [TestCase('terzo del secondo', '2,3,True')]
    [TestCase('quarto del secondo', '2,4,False')]
    [TestCase('primo del terzo', '3,1,True')]
    [TestCase('secondo del terzo', '3,2,False')]
    [TestCase('altro episodio', '4,1,False')]
    procedure DovrebbeNominareLAiutoNeiPrimiLivelli(AEpisode, AMap: Integer; AWithHelp: Boolean);
  end;

implementation

uses
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.SoundPart, DelphiDoom.Radix.Thing.Spawn;

{ TTestRadixActionRules }

class function TTestRadixActionRules.Wave(ABytesPerSecond, ADataSize: Integer; AExtraChunk: Boolean): TBytes;
var
  LPosition: Integer;

  procedure Put(const AText: AnsiString);
  begin
    Move(AText[1], Result[LPosition], Length(AText));
    Inc(LPosition, Length(AText));
  end;

  procedure PutInteger(AValue: Integer);
  begin
    Move(AValue, Result[LPosition], SizeOf(AValue));
    Inc(LPosition, SizeOf(AValue));
  end;

begin
  SetLength(Result, 12 + 8 + 16 + 8 + ADataSize + 12 * Ord(AExtraChunk));
  LPosition := 0;
  Put('RIFF');
  PutInteger(Length(Result) - 8);
  Put('WAVE');
  Put('fmt ');
  PutInteger(16);
  PutInteger($00010001);
  PutInteger(ABytesPerSecond);
  PutInteger(ABytesPerSecond);
  PutInteger($00080001);
  if AExtraChunk then
  begin
    // an odd chunk: one byte of padding follows it
    Put('LIST');
    PutInteger(3);
    Inc(LPosition, 4);
  end;
  Put('data');
  PutInteger(ADataSize);
end;

procedure TTestRadixActionRules.DovrebbeTenereChiaroUnSettoreSenzaNebbia(ALevel, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, Integer(TRadixActionRules.LightLevel(ALevel, 0)));
  Assert.AreEqual(AExpected, Integer(TRadixActionRules.LightLevel(ALevel, RSF_CEILINGSKY)));
end;

procedure TTestRadixActionRules.DovrebbeStendereLaLuceDiUnSettoreConNebbia(ALevel, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, Integer(TRadixActionRules.LightLevel(ALevel, RSF_FOG)));
end;

procedure TTestRadixActionRules.DovrebbeUsareLaStessaScalaPerIlBuio;
begin
  Assert.AreEqual(42, Integer(TRadixActionRules.LightLevel(10, RSF_DARKNESS)));
  Assert.AreEqual(42, Integer(TRadixActionRules.LightLevel(10, RSF_DARKNESS or RSF_FOG or RSF_HIDDEN)));
end;

procedure TTestRadixActionRules.DovrebbeFarOscillareLaLuceTraIDueLivelli;
var
  LRising: Boolean;
  LLevel: Integer;
begin
  LRising := True;
  LLevel := TRadixActionRules.Oscillate(10, 10, 12, LRising);
  Assert.AreEqual(11, LLevel);
  Assert.IsTrue(LRising);
  LLevel := TRadixActionRules.Oscillate(LLevel, 10, 12, LRising);
  Assert.AreEqual(12, LLevel);
  Assert.IsFalse(LRising);
  LLevel := TRadixActionRules.Oscillate(LLevel, 10, 12, LRising);
  Assert.AreEqual(11, LLevel);
  LLevel := TRadixActionRules.Oscillate(LLevel, 10, 12, LRising);
  Assert.AreEqual(10, LLevel);
  Assert.IsTrue(LRising);
  // a level outside the two is brought inside
  Assert.AreEqual(10, TRadixActionRules.Oscillate(0, 10, 12, LRising));
end;

procedure TTestRadixActionRules.DovrebbeDareIlPassoDiUnaSuperficie(ASpeed: Integer; ANew: Boolean;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixActionRules.SurfaceStep(ASpeed, ANew));
end;

procedure TTestRadixActionRules.DovrebbePortareUnPuntoDiRadixNellaMappa;
begin
  Assert.AreEqual(1000 - 32767, TRadixActionRules.RadixToDoomX(1000, False));
  Assert.AreEqual(-2000, TRadixActionRules.RadixToDoomY(1000, 2000, False));
  // past the split, in a level that is not split
  Assert.AreEqual(50000 - 32767, TRadixActionRules.RadixToDoomX(50000, False));
  Assert.AreEqual(-2000, TRadixActionRules.RadixToDoomY(50000, 2000, False));
end;

procedure TTestRadixActionRules.DovrebbePortareUnPuntoDellaSecondaMetaDelLivelloDiviso;
begin
  Assert.AreEqual(1000 - 32767, TRadixActionRules.RadixToDoomX(1000, True));
  Assert.AreEqual(-2000, TRadixActionRules.RadixToDoomY(1000, 2000, True));
  Assert.AreEqual(50000 - 65536, TRadixActionRules.RadixToDoomX(50000, True));
  Assert.AreEqual(-2000 - 4096, TRadixActionRules.RadixToDoomY(50000, 2000, True));
  Assert.AreEqual(48000 - 32767, TRadixActionRules.RadixToDoomX(E3M2_SPLIT_X, True));
end;

procedure TTestRadixActionRules.DovrebbeAndareAlLivelloSeguente;
var
  LExit: TRadixExit;
begin
  LExit := TRadixActionRules.ExitOf(0, 1);
  Assert.AreEqual(Ord(rekNextLevel), Ord(LExit.Kind));
  Assert.AreEqual(2, LExit.Map);
end;

procedure TTestRadixActionRules.DovrebbeAndareAlLivelloSegreto;
var
  LExit: TRadixExit;
begin
  LExit := TRadixActionRules.ExitOf(9, 3);
  Assert.AreEqual(Ord(rekSecretLevel), Ord(LExit.Kind));
  Assert.AreEqual(9, LExit.Map);
end;

procedure TTestRadixActionRules.DovrebbeTornareDalLivelloSegretoAlLivelloNominato;
var
  LExit: TRadixExit;
begin
  LExit := TRadixActionRules.ExitOf(4, 9);
  Assert.AreEqual(Ord(rekNamedLevel), Ord(LExit.Kind));
  Assert.AreEqual(4, LExit.Map);
end;

procedure TTestRadixActionRules.DovrebbeFinireLEpisodio;
begin
  Assert.AreEqual(Ord(rekVictory), Ord(TRadixActionRules.ExitOf(-1, 3).Kind));
  // the eighth level ends the episode whatever the action says
  Assert.AreEqual(Ord(rekVictory), Ord(TRadixActionRules.ExitOf(0, 8).Kind));
  Assert.AreEqual(0, TRadixActionRules.ExitOf(0, 8).Map);
end;

procedure TTestRadixActionRules.DovrebbeRaggiungereLaPercentualeDiUccisioni;
begin
  Assert.IsFalse(TRadixActionRules.KillRatioReached(20, 20, 9, 50));
  Assert.IsTrue(TRadixActionRules.KillRatioReached(20, 20, 10, 50));
  Assert.IsTrue(TRadixActionRules.KillRatioReached(20, 20, 25, 100));
  // a level without enemies
  Assert.IsTrue(TRadixActionRules.KillRatioReached(0, 20, 0, 50));
  Assert.IsTrue(TRadixActionRules.KillRatioReached(20, 0, 0, 50));
end;

procedure TTestRadixActionRules.DovrebbeContareINemiciAncoraVivi;
begin
  // kept from the old code: enemies - (living * 100 div total)
  Assert.IsTrue(TRadixActionRules.KillRatioReachedByLiving(60, 2, 20, 50));
  Assert.IsFalse(TRadixActionRules.KillRatioReachedByLiving(60, 3, 20, 50));
  Assert.IsTrue(TRadixActionRules.KillRatioReachedByLiving(5, 3, 0, 50));
end;

procedure TTestRadixActionRules.DovrebbeDareIlDannoDiUnEsplosioneSecondoLaDistanza;
begin
  Assert.AreEqual(100, TRadixActionRules.ExplosionDamage(300, 100, 90, 0));
  Assert.AreEqual(50, TRadixActionRules.ExplosionDamage(300, 100, 90, 45));
  Assert.AreEqual(0, TRadixActionRules.ExplosionDamage(300, 100, 90, 90));
  Assert.AreEqual(0, TRadixActionRules.ExplosionDamage(300, 100, 90, 200));
  Assert.AreEqual(0, TRadixActionRules.ExplosionDamage(300, 100, 0, 0));
  // a stronger shield of the game makes the explosions stronger
  Assert.AreEqual(200, TRadixActionRules.ExplosionDamage(300, 200, 90, 0));
end;

procedure TTestRadixActionRules.DovrebbeSpingereLaNavettaNelSettoreConGravita;
const
  LIMIT = TRadixActionRules.GRAVITY_MOMENTUM_LIMIT;
begin
  Assert.AreEqual(8192, TRadixActionRules.GravityMomentum(0, 1, 0));
  Assert.AreEqual(-65536, TRadixActionRules.GravityMomentum(0, -1, 3));
  Assert.AreEqual(LIMIT, TRadixActionRules.GravityMomentum(LIMIT - 100, 1, 3));
  Assert.AreEqual(-LIMIT, TRadixActionRules.GravityMomentum(-LIMIT + 100, -1, 3));
  // a craft that already goes faster is left alone
  Assert.AreEqual(LIMIT + 1, TRadixActionRules.GravityMomentum(LIMIT + 1, -1, 3));
end;

procedure TTestRadixActionRules.DovrebbeNonRipetereUnMessaggioSubito;
begin
  Assert.IsTrue(TRadixActionRules.CanShowMessage(0, 5));
  Assert.IsFalse(TRadixActionRules.CanShowMessage(100, 100 + TRadixActionRules.MESSAGE_TIMEOUT));
  Assert.IsTrue(TRadixActionRules.CanShowMessage(100, 101 + TRadixActionRules.MESSAGE_TIMEOUT));
end;

procedure TTestRadixActionRules.DovrebbeDareIlDannoDiUnColpoAUnMuro;
begin
  Assert.AreEqual(10, TRadixActionRules.WallDamage(10, 0));
  Assert.AreEqual(20, TRadixActionRules.WallDamage(10, 128));
  Assert.AreEqual(29, TRadixActionRules.WallDamage(10, 255));
end;

procedure TTestRadixActionRules.DovrebbeDareLaDurataDiUnSuono;
begin
  Assert.AreEqual(70, TRadixActionRules.WaveDurationTics(Wave(11025, 22050, False)));
  Assert.AreEqual(18, TRadixActionRules.WaveDurationTics(Wave(11025, 5513, False)));
end;

procedure TTestRadixActionRules.DovrebbeSaltareIChunkPrimaDeiDati;
begin
  Assert.AreEqual(35, TRadixActionRules.WaveDurationTics(Wave(22050, 22050, True)));
end;

procedure TTestRadixActionRules.DovrebbeDareMenoUnoSeNonEUnWave;
var
  LBytes: TBytes;
begin
  Assert.AreEqual(-1, TRadixActionRules.WaveDurationTics(nil));
  SetLength(LBytes, 64);
  Assert.AreEqual(-1, TRadixActionRules.WaveDurationTics(LBytes));
  // without a data chunk, or with a format without bytes per second
  LBytes := Wave(11025, 100, False);
  SetLength(LBytes, 36);
  Assert.AreEqual(-1, TRadixActionRules.WaveDurationTics(LBytes));
  Assert.AreEqual(-1, TRadixActionRules.WaveDurationTics(Wave(0, 100, False)));
end;

procedure TTestRadixActionRules.DovrebbeDareIlNomeDelLumpDiUnSuono;
begin
  Assert.AreEqual('DS_00016', TRadixActionRules.SoundLumpName(TRadixMessages.SOUND_END_OF_LEVEL));
  Assert.AreEqual('DS_00000', TRadixActionRules.SoundLumpName(0));
end;

procedure TTestRadixActionRules.DovrebbeAccelerareLaNavettaNelTrasportatore;
const
  UNIT_ = 65536;
begin
  // 1000 units in 20 tics: 50 a tic on average, from 0 to 100
  Assert.AreEqual(0, TRadixActionRules.TranspoMomentum(0, 1000 * UNIT_, 20, 20));
  Assert.AreEqual(5 * UNIT_, TRadixActionRules.TranspoMomentum(0, 1000 * UNIT_, 20, 19));
  Assert.AreEqual(50 * UNIT_, TRadixActionRules.TranspoMomentum(0, 1000 * UNIT_, 20, 10));
  Assert.AreEqual(95 * UNIT_, TRadixActionRules.TranspoMomentum(0, 1000 * UNIT_, 20, 1));
  Assert.AreEqual(-50 * UNIT_, TRadixActionRules.TranspoMomentum(1000 * UNIT_, 0, 20, 10));
end;

procedure TTestRadixActionRules.DovrebbePercorrereTuttaLaDistanzaDelTrasportatore;
const
  UNIT_ = 65536;
var
  LTics: Integer;
  LSum: Int64;
begin
  // from one end of the map to the other
  LSum := 0;
  for LTics := 19 downto 1 do
    LSum := LSum + TRadixActionRules.TranspoMomentum(-16000 * UNIT_, 16000 * UNIT_, 20, LTics);
  // the sum of 19 steps of a way of 20: 0 + 1 + ... + 19 tenths of the mean speed
  Assert.AreEqual(Int64(32000) * UNIT_ * 190 div 200, LSum);
end;

procedure TTestRadixActionRules.DovrebbeFermareIlTrasportatoreAllaFine;
begin
  Assert.AreEqual(0, TRadixActionRules.TranspoMomentum(0, 65536000, 20, 0));
  Assert.AreEqual(0, TRadixActionRules.TranspoMomentum(0, 65536000, 0, 5));
  // a way of one tic divided by zero in the old code
  Assert.AreEqual(0, TRadixActionRules.TranspoMomentum(0, 65536000, 1, 1));
end;

procedure TTestRadixActionRules.DovrebbeGirareLaNavettaVersoLAngoloDiArrivo;
const
  QUARTER = Cardinal($40000000);
begin
  Assert.AreEqual(QUARTER, TRadixActionRules.TranspoAngle(QUARTER, QUARTER, 5, 20));
  Assert.AreEqual(Cardinal($60000000), TRadixActionRules.TranspoAngle(QUARTER, Cardinal($80000000), 10, 20));
  Assert.AreEqual(Cardinal($60000000), TRadixActionRules.TranspoAngle(Cardinal($80000000), QUARTER, 10, 20));
  Assert.AreEqual(Cardinal($80000000), TRadixActionRules.TranspoAngle(QUARTER, Cardinal($80000000), 0, 20));
  Assert.AreEqual(QUARTER, TRadixActionRules.TranspoAngle(QUARTER, Cardinal($80000000), 20, 20));
end;

procedure TTestRadixActionRules.DovrebbeGirareDalLatoCortoAttraversoLoZero;
begin
  // from 1/16 of a turn before 0 to 1/16 after it: half way is 0, not half a turn
  Assert.AreEqual(Cardinal(0), TRadixActionRules.TranspoAngle(Cardinal($F0000000), Cardinal($10000000), 10, 20));
  Assert.AreEqual(Cardinal(0), TRadixActionRules.TranspoAngle(Cardinal($10000000), Cardinal($F0000000), 10, 20));
  Assert.AreEqual(Cardinal($F8000000),
    TRadixActionRules.TranspoAngle(Cardinal($F0000000), Cardinal($10000000), 15, 20));
end;

procedure TTestRadixActionRules.DovrebbeVedereIlMuroDavantiAlColpo;
var
  LDistance: Double;
begin
  // a wall along x = 100, a shot at the origin that goes east
  Assert.IsTrue(TRadixActionRules.WallAhead(0, 0, 30, 0, 100, -50, 100, 50, LDistance));
  Assert.AreEqual(100.0, LDistance, 0.0001);
  Assert.IsTrue(TRadixActionRules.WallAhead(0, 20, 5, 5, 100, -50, 100, 50, LDistance));
  Assert.AreEqual(100.0, LDistance, 0.0001);
end;

procedure TTestRadixActionRules.DovrebbeNonVedereIlMuroDietroAlColpo;
var
  LDistance: Double;
begin
  Assert.IsFalse(TRadixActionRules.WallAhead(0, 0, -30, 0, 100, -50, 100, 50, LDistance));
  Assert.AreEqual(100.0, LDistance, 0.0001);
  // along the wall: neither in front nor behind
  Assert.IsFalse(TRadixActionRules.WallAhead(0, 0, 0, 30, 100, -50, 100, 50, LDistance));
end;

procedure TTestRadixActionRules.DovrebbeMisurareLaDistanzaDallEstremoDelMuro;
var
  LDistance: Double;
begin
  // past the end of the wall: the nearest point is its end (100, 50)
  Assert.IsTrue(TRadixActionRules.WallAhead(70, 90, 1, -1, 100, -50, 100, 50, LDistance));
  Assert.AreEqual(50.0, LDistance, 0.0001);
  // a wall that is a point
  Assert.IsTrue(TRadixActionRules.WallAhead(0, 0, 1, 0, 3, 4, 3, 4, LDistance));
  Assert.AreEqual(5.0, LDistance, 0.0001);
end;

procedure TTestRadixActionRules.DovrebbeVedereIlMuroCheIlColpoToccaGia;
var
  LDistance: Double;
begin
  Assert.IsTrue(TRadixActionRules.WallAhead(99.5, 0, -30, 0, 100, -50, 100, 50, LDistance));
  Assert.AreEqual(0.5, LDistance, 0.0001);
end;

procedure TTestRadixActionRules.IlColpoCheAttraversaIlMuroDovrebbeAverloSullaStrada;
var
  LDistance: Double;
begin
  // the computer of E1M1: a wall along x = 10369, the shot seen at x = 10354 that flies east 56 a tic
  Assert.IsTrue(TRadixActionRules.WallOnPath(10354, -541, 10354 + 86, -541, 10369, -512, 10369, -640, 14,
    LDistance));
  Assert.AreEqual(15.0, LDistance, 0.0001);
  // across, at an angle
  Assert.IsTrue(TRadixActionRules.WallOnPath(0, 0, 200, 40, 100, -50, 100, 50, 0.001, LDistance));
  Assert.AreEqual(Sqrt(100.0 * 100.0 + 20.0 * 20.0), LDistance, 0.0001);
end;

procedure TTestRadixActionRules.IlColpoCheSiFermaPrimaDelMuroNonDovrebbeAverloSullaStrada;
var
  LDistance: Double;
begin
  Assert.IsFalse(TRadixActionRules.WallOnPath(0, 0, 80, 0, 100, -50, 100, 50, 14, LDistance));
  // near enough with its radius
  Assert.IsTrue(TRadixActionRules.WallOnPath(0, 0, 90, 0, 100, -50, 100, 50, 14, LDistance));
  Assert.AreEqual(90.0, LDistance, 0.0001);
end;

procedure TTestRadixActionRules.IlMuroDiFiancoODietroNonDovrebbeEssereSullaStrada;
var
  LDistance: Double;
begin
  // the shot flies along the wall, 30 units beside it: WallAhead would take it
  Assert.IsFalse(TRadixActionRules.WallOnPath(70, -40, 70, 40, 100, -50, 100, 50, 14, LDistance));
  // the wall is behind the start
  Assert.IsFalse(TRadixActionRules.WallOnPath(130, 0, 230, 0, 100, -50, 100, 50, 14, LDistance));
  // the exploded missile is left past the wall: from there the wall is not on the way
  Assert.IsFalse(TRadixActionRules.WallOnPath(10410, -541, 10496, -541, 10369, -512, 10369, -640, 14, LDistance));
end;

procedure TTestRadixActionRules.IlColpoCheSfioraLEstremoDelMuroDovrebbeContareEntroIlMargine;
var
  LDistance: Double;
begin
  // the way passes 10 units past the end (100, 50) of the wall
  Assert.IsTrue(TRadixActionRules.WallOnPath(0, 60, 200, 60, 100, -50, 100, 50, 14, LDistance));
  Assert.AreEqual(100.0, LDistance, 0.0001);
  Assert.IsFalse(TRadixActionRules.WallOnPath(0, 60, 200, 60, 100, -50, 100, 50, 5, LDistance));
end;

procedure TTestRadixActionRules.UnColpoFermoOUnMuroPuntoNonDovrebberoDareErrori;
var
  LDistance: Double;
begin
  // a shot that does not move is on a wall only if it touches it
  Assert.IsTrue(TRadixActionRules.WallOnPath(95, 0, 95, 0, 100, -50, 100, 50, 14, LDistance));
  Assert.AreEqual(0.0, LDistance, 0.0001);
  Assert.IsFalse(TRadixActionRules.WallOnPath(50, 0, 50, 0, 100, -50, 100, 50, 14, LDistance));
  // a wall that is a point
  Assert.IsTrue(TRadixActionRules.WallOnPath(0, 0, 10, 0, 6, 3, 6, 3, 4, LDistance));
  Assert.AreEqual(6.0, LDistance, 0.0001);
  // both without length
  Assert.IsTrue(TRadixActionRules.WallOnPath(1, 1, 1, 1, 2, 1, 2, 1, 2, LDistance));
end;

{ TTestRadixThingSpawnRules }

procedure TTestRadixThingSpawnRules.DovrebbeGenerareLaCosaSecondoLAbilita(ARadixSkill, AGameSkill: Integer;
  ANetGame, AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixThingSpawnRules.IsSpawnedAtSkill(ARadixSkill, AGameSkill, ANetGame));
end;

procedure TTestRadixThingSpawnRules.DovrebbeMettereLaCosaSopraIlPavimento;
begin
  Assert.AreEqual(64 * 65536 + 96 * 65536, TRadixThingSpawnRules.Height(96, 64 * 65536, False));
  Assert.AreEqual(-32 * 65536, TRadixThingSpawnRules.Height(0, -32 * 65536, False));
end;

procedure TTestRadixThingSpawnRules.DovrebbeMettereLaNavettaAllaSuaQuotaMaNonSottoIlPavimento;
begin
  Assert.AreEqual(400 * 65536, TRadixThingSpawnRules.Height(400, 64 * 65536, True));
  Assert.AreEqual(64 * 65536, TRadixThingSpawnRules.Height(10, 64 * 65536, True));
end;

procedure TTestRadixThingSpawnRules.DovrebbeDareUnIdentificatoreAlNumeroDiRadix;
begin
  // the thing 0 of RADIX.DAT is a thing: its identifier is not "none"
  Assert.AreEqual(1, TRadixThingSpawnRules.ThingId(0));
  Assert.AreEqual(52, TRadixThingSpawnRules.ThingId(51));
  Assert.AreEqual(TRadixThingSpawnRules.NO_THING_ID, TRadixThingSpawnRules.ThingId(-1));
  Assert.AreEqual(51, TRadixThingSpawnRules.RadixId(TRadixThingSpawnRules.ThingId(51)));
  Assert.AreEqual(-1, TRadixThingSpawnRules.RadixId(TRadixThingSpawnRules.NO_THING_ID));
end;

{ TTestRadixMessages }

procedure TTestRadixMessages.DovrebbeAvereTrediciMessaggi;
var
  LIndex: Integer;
begin
  for LIndex := 0 to TRadixMessages.COUNT - 1 do
  begin
    Assert.IsTrue(TRadixMessages.IsMessage(LIndex));
    Assert.IsTrue(TRadixMessages.Get(LIndex).Text <> '', 'message ' + IntToStr(LIndex));
  end;
  Assert.AreEqual('Primary target ahead', TRadixMessages.Get(0).Text);
  Assert.AreEqual('Shoot doors to gain entry', TRadixMessages.Get(2).Text);
  Assert.AreEqual('Secondary Objective Completed',
    TRadixMessages.Get(TRadixMessages.SECONDARY_OBJECTIVE_COMPLETED).Text);
end;

procedure TTestRadixMessages.DovrebbeDareUnMessaggioVuotoFuoriDallaTabella;
begin
  Assert.IsFalse(TRadixMessages.IsMessage(-1));
  Assert.IsFalse(TRadixMessages.IsMessage(TRadixMessages.COUNT));
  Assert.AreEqual('', TRadixMessages.Get(TRadixMessages.COUNT).Text);
  Assert.AreEqual(TRadixMessages.NO_SOUND, TRadixMessages.Get(-1).Sound);
end;

procedure TTestRadixMessages.DovrebbeMostrareUnaVoltaSolaGliObiettiviCompletati;
var
  LIndex: Integer;
begin
  for LIndex := 0 to TRadixMessages.COUNT - 1 do
    Assert.AreEqual((LIndex = 9) or (LIndex = 12), TRadixMessages.Get(LIndex).AutoDisable,
      'message ' + IntToStr(LIndex));
end;

procedure TTestRadixMessages.DovrebbeAvereISuoniDeiNomiGiusti;
var
  LNames: TArray<string>;
begin
  // the numbers are the places in the list of the sounds that the translation writes
  LNames := TRadixSoundPart.SoundNames;
  Assert.AreEqual(TRadixMessages.SOUND_COUNT, Integer(Length(LNames)));
  Assert.AreEqual('SndGravityWell', LNames[TRadixMessages.SOUND_GRAVITY_WELL]);
  Assert.AreEqual('SndEndOfLevel', LNames[TRadixMessages.SOUND_END_OF_LEVEL]);
  Assert.AreEqual('SndPrimAhead', LNames[TRadixMessages.Get(0).Sound]);
  Assert.AreEqual('SndSecAhead', LNames[TRadixMessages.Get(1).Sound]);
  Assert.AreEqual('SndTargetsAhead', LNames[TRadixMessages.Get(3).Sound]);
  Assert.AreEqual('SndEnemy', LNames[TRadixMessages.Get(4).Sound]);
  Assert.AreEqual('SndPrimComplete', LNames[TRadixMessages.Get(9).Sound]);
  Assert.AreEqual('SndPrimInComplete', LNames[TRadixMessages.Get(10).Sound]);
  Assert.AreEqual('SndSecComplete', LNames[TRadixMessages.Get(12).Sound]);
  Assert.AreEqual(TRadixMessages.NO_SOUND, TRadixMessages.Get(2).Sound);
end;

procedure TTestRadixMessages.DovrebbeNominareLAiutoNeiPrimiLivelli(AEpisode, AMap: Integer; AWithHelp: Boolean);
begin
  Assert.AreEqual(AWithHelp, Pos('F1 ', TRadixMessages.StartUp(AEpisode, AMap)) > 0);
  Assert.IsTrue(Pos('F12', TRadixMessages.StartUp(AEpisode, AMap)) > 0);
end;

end.

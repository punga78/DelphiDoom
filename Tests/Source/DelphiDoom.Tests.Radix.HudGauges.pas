{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixHudGauges                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.HudGauges;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Hud.Gauges;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixHudGauges = class(TObject)
  public
    [Test]
    [TestCase('barra di stato', '10,False,False,2')]
    [TestCase('vista ridotta', '5,False,False,2')]
    [TestCase('cabina', '11,False,False,3')]
    [TestCase('mezza cabina', '12,False,False,4')]
    [TestCase('piccolo', '13,False,False,5')]
    [TestCase('niente', '14,False,False,0')]
    [TestCase('niente ma morto', '14,False,True,1')]
    [TestCase('automap con la cabina', '11,True,False,2')]
    [TestCase('automap a schermo pieno', '14,True,True,2')]
    procedure DovrebbeScegliereIlDisplayDallaDimensioneDellaVista(ABlocks: Integer; AAutomap, ADead: Boolean;
      AExpected: Integer);
    [Test]
    procedure DovrebbeDareMinutiESecondiDelLivello;
    [Test]
    procedure DovrebbeSegnalareLOrologioOltreNovantanoveMinuti;
    [Test]
    procedure DovrebbeNonDisegnareColonneDaFermoNellaBarraDiStato;
    [Test]
    procedure DovrebbeDisegnareTutteLeColonneDaFermoNellaCabina;
    [Test]
    procedure DovrebbeRiempireLIndicatoreAllaVelocitaMassima;
    [Test]
    procedure DovrebbeContareAncheLaVelocitaVerticale;
    [Test]
    [TestCase('vuota', '62,0,0')]
    [TestCase('negativa', '62,-5,0')]
    [TestCase('meta', '62,50,31')]
    [TestCase('uno', '62,1,0')]
    [TestCase('piena', '62,100,62')]
    [TestCase('oltre', '62,150,62')]
    procedure DovrebbeDareLeColonneDiUnaBarra(AWidth, APercent, AExpected: Integer);
    [Test]
    procedure DovrebbeFarLampeggiareLIconaNegliUltimiTic;
    [Test]
    procedure DovrebbeFarPulsareIlColoreDelRadar;
    [Test]
    procedure DovrebbeOscurareIlRadarSeMortoODisturbato;
    [Test]
    procedure DovrebbeMettereDavantiCioCheStaDavantiAllaNavetta;
    [Test]
    procedure DovrebbeMettereADestraCioCheStaADestraDellaNavetta;
    [Test]
    procedure DovrebbeScartareCioCheEOltreLaPortataDelRadar;
    [Test]
    procedure DovrebbeArrotondareAlPixelPiuVicino;
    [Test]
    procedure DovrebbeFarAvanzareIlMirinoMentreAggancia;
    [Test]
    procedure DovrebbeFarLampeggiareLaSpiaDiMinaccia;
  end;

implementation

const
  FRACUNIT = 65536;
  // sine and cosine of (90 degrees - angle) for a craft that looks east (angle 0) and north (90)
  EAST_SINE = FRACUNIT;
  EAST_COSINE = 0;
  NORTH_SINE = 0;
  NORTH_COSINE = FRACUNIT;
  PIXEL = 128 * FRACUNIT;

{ TTestRadixHudGauges }

procedure TTestRadixHudGauges.DovrebbeScegliereIlDisplayDallaDimensioneDellaVista(ABlocks: Integer;
  AAutomap, ADead: Boolean; AExpected: Integer);
begin
  Assert.AreEqual<Integer>(AExpected, Ord(TRadixHudGauges.Mode(ABlocks, AAutomap, ADead)));
end;

procedure TTestRadixHudGauges.DovrebbeDareMinutiESecondiDelLivello;
var
  LClock: TRadixHudClock;
begin
  LClock := TRadixHudGauges.Clock((2 * 60 + 7) * 35 + 34);
  Assert.IsFalse(LClock.Overflow);
  Assert.AreEqual(2, LClock.Minutes);
  Assert.AreEqual(7, LClock.Seconds);
end;

procedure TTestRadixHudGauges.DovrebbeSegnalareLOrologioOltreNovantanoveMinuti;
begin
  Assert.IsFalse(TRadixHudGauges.Clock((99 * 60 + 59) * 35).Overflow);
  Assert.IsTrue(TRadixHudGauges.Clock((99 * 60 + 59) * 35 + 1).Overflow);
end;

procedure TTestRadixHudGauges.DovrebbeNonDisegnareColonneDaFermoNellaBarraDiStato;
var
  LBars: TRadixSpeedBars;
begin
  LBars := TRadixHudGauges.SpeedBars(0, 0, 0, True);
  Assert.AreEqual(0, LBars.Count);
  Assert.AreEqual(2, LBars.Step);
end;

procedure TTestRadixHudGauges.DovrebbeDisegnareTutteLeColonneDaFermoNellaCabina;
var
  LBars: TRadixSpeedBars;
begin
  LBars := TRadixHudGauges.SpeedBars(0, 0, 0, False);
  Assert.AreEqual(TRadixHudGauges.SPEED_COLUMNS, LBars.Count);
  Assert.AreEqual(-2, LBars.Step);
end;

procedure TTestRadixHudGauges.DovrebbeRiempireLIndicatoreAllaVelocitaMassima;
const
  MAX_MOVE = TRadixHudGauges.MAX_MOVE_UNITS * FRACUNIT;
begin
  Assert.AreEqual(TRadixHudGauges.SPEED_COLUMNS, TRadixHudGauges.SpeedBars(MAX_MOVE, MAX_MOVE, 0, True).Count);
  Assert.AreEqual(0, TRadixHudGauges.SpeedBars(MAX_MOVE, MAX_MOVE, 0, False).Count);
  // on one axis only: 18 / (18 * sqrt 2) of 15 columns = 10.6, rounded to 11
  Assert.AreEqual(11, TRadixHudGauges.SpeedBars(MAX_MOVE, 0, 0, True).Count);
  Assert.AreEqual(4, TRadixHudGauges.SpeedBars(-MAX_MOVE, 0, 0, False).Count);
  // faster than the limit (afterburner): the indicator stays full
  Assert.AreEqual(TRadixHudGauges.SPEED_COLUMNS, TRadixHudGauges.SpeedBars(3 * MAX_MOVE, 0, 0, True).Count);
end;

procedure TTestRadixHudGauges.DovrebbeContareAncheLaVelocitaVerticale;
const
  MAX_MOVE = TRadixHudGauges.MAX_MOVE_UNITS * FRACUNIT;
begin
  Assert.AreEqual(11, TRadixHudGauges.SpeedBars(0, 0, -MAX_MOVE, True).Count);
end;

procedure TTestRadixHudGauges.DovrebbeDareLeColonneDiUnaBarra(AWidth, APercent, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixHudGauges.BarFill(AWidth, APercent));
end;

procedure TTestRadixHudGauges.DovrebbeFarLampeggiareLIconaNegliUltimiTic;
begin
  Assert.IsTrue(TRadixHudGauges.PowerUpVisible(129), 'fissa oltre 128 tic');
  Assert.IsFalse(TRadixHudGauges.PowerUpVisible(128), 'a 128 il bit 8 e'' spento');
  Assert.IsTrue(TRadixHudGauges.PowerUpVisible(8));
  Assert.IsTrue(TRadixHudGauges.PowerUpVisible(15));
  Assert.IsFalse(TRadixHudGauges.PowerUpVisible(7));
  Assert.IsFalse(TRadixHudGauges.PowerUpVisible(0), 'senza il potenziamento niente icona');
end;

procedure TTestRadixHudGauges.DovrebbeFarPulsareIlColoreDelRadar;
begin
  Assert.AreEqual(123, Integer(TRadixHudGauges.RadarGlowColor(0)));
  Assert.AreEqual(124, Integer(TRadixHudGauges.RadarGlowColor(8)));
  Assert.AreEqual(125, Integer(TRadixHudGauges.RadarGlowColor(16)));
  Assert.AreEqual(124, Integer(TRadixHudGauges.RadarGlowColor(24)));
  Assert.AreEqual(123, Integer(TRadixHudGauges.RadarGlowColor(32)));
end;

procedure TTestRadixHudGauges.DovrebbeOscurareIlRadarSeMortoODisturbato;
begin
  Assert.IsTrue(TRadixHudGauges.RadarJammed(True, False, 0));
  Assert.IsFalse(TRadixHudGauges.RadarJammed(False, False, 16));
  Assert.IsTrue(TRadixHudGauges.RadarJammed(False, True, 16));
  Assert.IsFalse(TRadixHudGauges.RadarJammed(False, True, 32), 'il disturbo lampeggia');
end;

procedure TTestRadixHudGauges.DovrebbeMettereDavantiCioCheStaDavantiAllaNavetta;
var
  LX, LY: Integer;
begin
  // the craft looks north; a thing 5 pixels north is 5 rows up
  Assert.IsTrue(TRadixHudGauges.RadarOffset(0, 0, 0, 5 * PIXEL, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
  Assert.AreEqual(0, LX);
  Assert.AreEqual(-5, LY);
  // the craft looks east; a thing 5 pixels east is 5 rows up too
  Assert.IsTrue(TRadixHudGauges.RadarOffset(0, 0, 5 * PIXEL, 0, EAST_SINE, EAST_COSINE, 12, LX, LY));
  Assert.AreEqual(0, LX);
  Assert.AreEqual(-5, LY);
end;

procedure TTestRadixHudGauges.DovrebbeMettereADestraCioCheStaADestraDellaNavetta;
var
  LX, LY: Integer;
begin
  // looking north, east is on the right
  Assert.IsTrue(TRadixHudGauges.RadarOffset(0, 0, 3 * PIXEL, 0, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
  Assert.AreEqual(3, LX);
  Assert.AreEqual(0, LY);
  // looking east, south is on the right
  Assert.IsTrue(TRadixHudGauges.RadarOffset(100 * PIXEL, 100 * PIXEL, 100 * PIXEL, 97 * PIXEL, EAST_SINE,
    EAST_COSINE, 12, LX, LY));
  Assert.AreEqual(3, LX);
  Assert.AreEqual(0, LY);
end;

procedure TTestRadixHudGauges.DovrebbeScartareCioCheEOltreLaPortataDelRadar;
var
  LX, LY: Integer;
begin
  Assert.IsTrue(TRadixHudGauges.RadarOffset(0, 0, 12 * PIXEL, 0, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
  Assert.IsFalse(TRadixHudGauges.RadarOffset(0, 0, 13 * PIXEL, 0, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
  Assert.AreEqual(0, LX);
  Assert.AreEqual(0, LY);
  // the range is a circle: 9 and 9 are 12.7 pixels away
  Assert.IsFalse(TRadixHudGauges.RadarOffset(0, 0, 9 * PIXEL, 9 * PIXEL, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
  Assert.IsTrue(TRadixHudGauges.RadarOffset(0, 0, 8 * PIXEL, 8 * PIXEL, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
end;

procedure TTestRadixHudGauges.DovrebbeArrotondareAlPixelPiuVicino;
var
  LX, LY: Integer;
begin
  Assert.IsTrue(TRadixHudGauges.RadarOffset(0, 0, PIXEL div 2, 0, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
  Assert.AreEqual(1, LX, 'mezzo pixel a est');
  Assert.IsTrue(TRadixHudGauges.RadarOffset(0, 0, PIXEL div 2 - 256, 0, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
  Assert.AreEqual(0, LX, 'meno di mezzo pixel');
  Assert.IsTrue(TRadixHudGauges.RadarOffset(0, 0, -(PIXEL div 2), 0, NORTH_SINE, NORTH_COSINE, 12, LX, LY));
  Assert.AreEqual(-1, LX, 'mezzo pixel a ovest');
end;

procedure TTestRadixHudGauges.DovrebbeFarAvanzareIlMirinoMentreAggancia;
begin
  Assert.AreEqual(0, TRadixHudGauges.CrossHairIndex(False, 100, 90));
  Assert.AreEqual(1, TRadixHudGauges.CrossHairIndex(True, 100, 100));
  Assert.AreEqual(4, TRadixHudGauges.CrossHairIndex(True, 103, 100));
  Assert.AreEqual(6, TRadixHudGauges.CrossHairIndex(True, 105, 100));
  Assert.AreEqual(6, TRadixHudGauges.CrossHairIndex(True, 500, 100));
end;

procedure TTestRadixHudGauges.DovrebbeFarLampeggiareLaSpiaDiMinaccia;
begin
  Assert.IsFalse(TRadixHudGauges.ThreatLit(False, 16));
  Assert.IsFalse(TRadixHudGauges.ThreatLit(True, 0));
  Assert.IsTrue(TRadixHudGauges.ThreatLit(True, 16));
  Assert.IsFalse(TRadixHudGauges.ThreatLit(True, 32));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixHudGauges);

end.

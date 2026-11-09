{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingParticles                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.Particles;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Tests.Racing.Fakes;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingParticles = class(TObject)
  strict private
    FWorld: TRacingTestWorld;
    function CarOnColumn(AColumn: Integer): TRacingCarState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonFareNullaSeNonESuperatoIlTempoDellaProssimaParticella;
    [Test]
    procedure DovrebbeNonFareScintilleSeLeRuoteNonPattinano;
    [Test]
    procedure DovrebbeFareScintilleQuandoLeRuotePattinanoSulLAsfalto;
    [Test]
    procedure DovrebbeFareFumoQuandoLeRuotePattinanoForte;
    [Test]
    procedure DovrebbeLanciareLeParticelleDietroLaAuto;
    [Test]
    procedure DovrebbeAspettareUnSecondoDopoLeScintille;
    [Test]
    procedure DovrebbeFareTerraSullErba;
    [Test]
    procedure DovrebbeFareTerraSullaTerra;
    [Test]
    procedure DovrebbeFareTerraSullaSabbia;
    [Test]
    procedure DovrebbeAspettareMezzoSecondoDopoLaTerra;
    [Test]
    procedure DovrebbeNonFareNullaSuUnTerrenoSconosciuto;
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Trigonometry, DelphiDoom.Racing.Factory,
  DelphiDoom.Tests.Racing.Scenarios;

{ TTestRacingParticles }

procedure TTestRacingParticles.Setup;
begin
  FWorld := TRacingTestWorld.Create;
  FWorld.Ground.SetMap(TRacingScenarios.GroundMap, RACING_GROUND_BYTES);
end;

procedure TTestRacingParticles.TearDown;
begin
  FWorld.Free;
end;

function TTestRacingParticles.CarOnColumn(AColumn: Integer): TRacingCarState;
begin
  // The row 0 of the map is the top line of the track; the wheels are a little behind the car
  Result := TRacingScenarios.NewCar(0, (AColumn * 2 + 40) * FIXED_ONE, (RACING_GROUND_SIZE - 1) * 2 * FIXED_ONE, 0);
end;

procedure TTestRacingParticles.DovrebbeNonFareNullaSeNonESuperatoIlTempoDellaProssimaParticella;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(130);
  LCar.NextParticle := 10;
  FWorld.Race.SetLevelTime(9);
  FWorld.Particles.Check(LCar, 0, 0);
  Assert.AreEqual(0, FWorld.EffectLog.Log.Count);
  Assert.AreEqual(10, LCar.NextParticle);
end;

procedure TTestRacingParticles.DovrebbeNonFareScintilleSeLeRuoteNonPattinano;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(0);
  FWorld.Particles.Check(LCar, 0, 4 * FIXED_ONE);
  Assert.AreEqual(0, FWorld.EffectLog.Log.Count);
end;

procedure TTestRacingParticles.DovrebbeFareScintilleQuandoLeRuotePattinanoSulLAsfalto;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(0);
  FWorld.Particles.Check(LCar, 0, 4 * FIXED_ONE + 1);
  Assert.AreEqual(1, FWorld.EffectLog.Log.Count);
  Assert.IsTrue(Pos('P spark', FWorld.EffectLog.Log[0]) = 1);
end;

procedure TTestRacingParticles.DovrebbeFareFumoQuandoLeRuotePattinanoForte;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(0);
  FWorld.Particles.Check(LCar, 0, 8 * FIXED_ONE + 1);
  Assert.AreEqual(3, FWorld.EffectLog.Log.Count);
  Assert.IsTrue(Pos('P spark', FWorld.EffectLog.Log[0]) = 1);
  Assert.IsTrue(Pos('P smoke', FWorld.EffectLog.Log[1]) = 1);
  Assert.IsTrue(Pos('P smoke', FWorld.EffectLog.Log[2]) = 1);
end;

procedure TTestRacingParticles.DovrebbeLanciareLeParticelleDietroLaAuto;
var
  LCar: TRacingCarState;
begin
  // The car looks to the east: the wheels are 32 times the cosine of the angle behind it and the spark goes back
  LCar := CarOnColumn(0);
  FWorld.Particles.Check(LCar, 0, 5 * FIXED_ONE);
  Assert.AreEqual(TRacingScenarios.FormatParticle('spark', LCar.X - 32 * TTrigonometry.FineCosine(0),
    LCar.Y - 32 * TTrigonometry.FineSine(0), 0, -2 * TTrigonometry.FineCosine(0),
    -2 * TTrigonometry.FineSine(0)), FWorld.EffectLog.Log[0]);
end;

procedure TTestRacingParticles.DovrebbeAspettareUnSecondoDopoLeScintille;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(0);
  FWorld.Race.SetLevelTime(100);
  FWorld.Particles.Check(LCar, 0, 5 * FIXED_ONE);
  Assert.AreEqual(100 + RACING_TICKS_PER_SECOND, LCar.NextParticle);
end;

procedure TTestRacingParticles.DovrebbeFareTerraSullErba;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(130);
  FWorld.Particles.Check(LCar, 0, 0);
  Assert.AreEqual(1, FWorld.EffectLog.Log.Count);
  Assert.IsTrue(Pos('P grass', FWorld.EffectLog.Log[0]) = 1);
end;

procedure TTestRacingParticles.DovrebbeFareTerraSullaTerra;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(390);
  FWorld.Particles.Check(LCar, 0, 0);
  Assert.IsTrue(Pos('P dirt', FWorld.EffectLog.Log[0]) = 1);
end;

procedure TTestRacingParticles.DovrebbeFareTerraSullaSabbia;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(520);
  FWorld.Particles.Check(LCar, 0, 0);
  Assert.IsTrue(Pos('P sand', FWorld.EffectLog.Log[0]) = 1);
end;

procedure TTestRacingParticles.DovrebbeAspettareMezzoSecondoDopoLaTerra;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(130);
  FWorld.Race.SetLevelTime(50);
  FWorld.Particles.Check(LCar, 0, 0);
  Assert.AreEqual(50 + RACING_TICKS_PER_SECOND div 2, LCar.NextParticle);
end;

procedure TTestRacingParticles.DovrebbeNonFareNullaSuUnTerrenoSconosciuto;
var
  LCar: TRacingCarState;
begin
  LCar := CarOnColumn(780);
  FWorld.Particles.Check(LCar, 0, 0);
  Assert.AreEqual(0, FWorld.EffectLog.Log.Count);
end;

procedure TTestRacingParticles.DovrebbeRifiutareGliOggettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateParticles(nil, FWorld.Race, FWorld.Effects);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateParticles(FWorld.Ground, nil, FWorld.Effects);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateParticles(FWorld.Ground, FWorld.Race, nil);
    end, EArgumentNilException);
end;

end.

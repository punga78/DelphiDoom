{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingGround                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.Ground;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Intf, DelphiDoom.Racing.Types,
  DelphiDoom.Racing.Intf;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingGround = class(TObject)
  strict private
    FRandom: IGameRandom;
    FGround: IRacingGround;
    function AtColumn(AColumn, ARow: Integer): TRacingGroundType;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeEssereAsfaltoSenzaMappa;
    [Test]
    procedure DovrebbeEssereAsfaltoSeLaMappaHaUnaDimensioneDiversa;
    [Test]
    procedure DovrebbeRiconoscereOgniTipoDiTerreno;
    [Test]
    procedure DovrebbeLeggereLaRigaDalBasso;
    [Test]
    procedure DovrebbeTenereLeCoordinateDentroLaMappa;
    [Test]
    procedure DovrebbeDareUnaAderenzaNelCampoDelTerreno;
    [Test]
    procedure DovrebbeDareLaStessaAderenzaConLoStessoSeme;
    [Test]
    procedure DovrebbeDareIlCampoDiOgniTerreno;
    [Test]
    procedure DovrebbeCalcolareLaForzaCheIlTerrenoLasciaPassare;
    [Test]
    procedure DovrebbeConservareIlGiroDelProdottoAVentiduebit;
    [Test]
    procedure DovrebbeRifiutareUnGeneratoreNil;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Factory, DelphiDoom.Racing.Factory,
  DelphiDoom.Racing.Ground, DelphiDoom.Tests.Racing.Scenarios;

{ TTestRacingGround }

procedure TTestRacingGround.Setup;
begin
  FRandom := TMathCoreFactory.CreateGameRandom;
  FGround := TRacingFactory.CreateGround(FRandom);
  FGround.SetMap(TRacingScenarios.GroundMap, RACING_GROUND_BYTES);
end;

function TTestRacingGround.AtColumn(AColumn, ARow: Integer): TRacingGroundType;
begin
  // The map has two map units for a pixel and the first line is at the top of the track
  Result := FGround.GroundTypeAt(AColumn * 2 * FIXED_ONE, (RACING_GROUND_SIZE - 1 - ARow) * 2 * FIXED_ONE);
end;

procedure TTestRacingGround.DovrebbeEssereAsfaltoSenzaMappa;
begin
  FGround.SetMap(nil, 0);
  Assert.AreEqual(Ord(TRacingGroundType.Asphalt), Ord(FGround.GroundTypeAt(5 * FIXED_ONE, 5 * FIXED_ONE)));
end;

procedure TTestRacingGround.DovrebbeEssereAsfaltoSeLaMappaHaUnaDimensioneDiversa;
begin
  FGround.SetMap(TRacingScenarios.GroundMap, RACING_GROUND_BYTES - 1);
  Assert.AreEqual(Ord(TRacingGroundType.Asphalt), Ord(AtColumn(200, 0)));
end;

procedure TTestRacingGround.DovrebbeRiconoscereOgniTipoDiTerreno;
begin
  Assert.AreEqual(Ord(TRacingGroundType.Asphalt), Ord(AtColumn(0, 0)));
  Assert.AreEqual(Ord(TRacingGroundType.Grass), Ord(AtColumn(130, 0)));
  Assert.AreEqual(Ord(TRacingGroundType.Dirt), Ord(AtColumn(390, 0)));
  Assert.AreEqual(Ord(TRacingGroundType.Sand), Ord(AtColumn(520, 0)));
  Assert.AreEqual(Ord(TRacingGroundType.Unknown), Ord(AtColumn(780, 0)));
end;

procedure TTestRacingGround.DovrebbeLeggereLaRigaDalBasso;
begin
  // The rows 0..255 of the map have grass at the columns 128..255; the rows 256..511 have it at 0..127
  Assert.AreEqual(Ord(TRacingGroundType.Grass), Ord(AtColumn(5, 300)));
  Assert.AreEqual(Ord(TRacingGroundType.Asphalt), Ord(AtColumn(5, 5)));
end;

procedure TTestRacingGround.DovrebbeTenereLeCoordinateDentroLaMappa;
begin
  Assert.AreEqual(Ord(TRacingGroundType.Asphalt), Ord(FGround.GroundTypeAt(-500 * FIXED_ONE, High(Integer))));
  Assert.AreEqual(Ord(AtColumn(4095, 0)), Ord(FGround.GroundTypeAt(High(Integer), (RACING_GROUND_SIZE - 1) * 2 * FIXED_ONE)));
end;

procedure TTestRacingGround.DovrebbeDareUnaAderenzaNelCampoDelTerreno;
var
  LIndex: Integer;
  LSlip: Byte;
begin
  for LIndex := 1 to 200 do
  begin
    LSlip := FGround.SlipperFactorAt(0, (RACING_GROUND_SIZE - 1) * 2 * FIXED_ONE);
    Assert.IsTrue(LSlip >= 224);
  end;
end;

procedure TTestRacingGround.DovrebbeDareLaStessaAderenzaConLoStessoSeme;
var
  LOther: IRacingGround;
  LSecond: IGameRandom;
  LIndex: Integer;
begin
  FRandom.SystemSeed := 3;
  FRandom.SystemIndex := 100;
  LSecond := TMathCoreFactory.CreateGameRandom;
  LSecond.SystemSeed := 3;
  LSecond.SystemIndex := 100;
  LOther := TRacingFactory.CreateGround(LSecond);
  LOther.SetMap(TRacingScenarios.GroundMap, RACING_GROUND_BYTES);
  for LIndex := 1 to 50 do
    Assert.AreEqual(Integer(FGround.SlipperFactorAt(130 * 2 * FIXED_ONE, 0)),
      Integer(LOther.SlipperFactorAt(130 * 2 * FIXED_ONE, 0)));
end;

procedure TTestRacingGround.DovrebbeDareIlCampoDiOgniTerreno;
var
  LMinimum, LMaximum: Byte;
begin
  TRacingGround.SlipRange(TRacingGroundType.Asphalt, LMinimum, LMaximum);
  Assert.AreEqual(224, Integer(LMinimum));
  Assert.AreEqual(255, Integer(LMaximum));
  TRacingGround.SlipRange(TRacingGroundType.Grass, LMinimum, LMaximum);
  Assert.AreEqual(150, Integer(LMinimum));
  Assert.AreEqual(220, Integer(LMaximum));
  TRacingGround.SlipRange(TRacingGroundType.Dirt, LMinimum, LMaximum);
  Assert.AreEqual(100, Integer(LMinimum));
  Assert.AreEqual(180, Integer(LMaximum));
  TRacingGround.SlipRange(TRacingGroundType.Sand, LMinimum, LMaximum);
  Assert.AreEqual(80, Integer(LMinimum));
  Assert.AreEqual(150, Integer(LMaximum));
  TRacingGround.SlipRange(TRacingGroundType.Unknown, LMinimum, LMaximum);
  Assert.AreEqual(100, Integer(LMinimum));
  Assert.AreEqual(200, Integer(LMaximum));
end;

procedure TTestRacingGround.DovrebbeCalcolareLaForzaCheIlTerrenoLasciaPassare;
begin
  Assert.AreEqual(FIXED_ONE, TRacingGround.SlipCalculation(FIXED_ONE, 255));
  Assert.AreEqual(32896, TRacingGround.SlipCalculation(FIXED_ONE, 128));
  Assert.AreEqual(0, TRacingGround.SlipCalculation(FIXED_ONE, 0));
  Assert.AreEqual(-32896, TRacingGround.SlipCalculation(-FIXED_ONE, 128));
end;

procedure TTestRacingGround.DovrebbeConservareIlGiroDelProdottoAVentiduebit;
begin
  // The old code multiplied two 32 bit numbers before widening: a big force changes sign
  Assert.AreEqual(-7843009, TRacingGround.SlipCalculation(9000000, 255));
end;

procedure TTestRacingGround.DovrebbeRifiutareUnGeneratoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateGround(nil);
    end, EArgumentNilException);
end;

end.

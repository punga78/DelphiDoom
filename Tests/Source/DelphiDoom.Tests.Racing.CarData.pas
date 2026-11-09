{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the data of the cars, the championship, the state of   }
{  the race and the factory                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.CarData;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingCarData = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereQuaranteAuto;
    [Test]
    procedure DovrebbeAvereLeFormulaPrimaELeAutoDiSerieDopo;
    [Test]
    procedure DovrebbeAvereIDatiDellaPrimaFormula;
    [Test]
    procedure DovrebbeAvereIDatiDellUltimaAutoDiSerie;
    [Test]
    procedure DovrebbeAvereDatiPossibiliPerOgniAuto;
    [Test]
    procedure DovrebbeUsareIModelliDelleDueFamiglie;
  end;

  [TestFixture]
  [Category('racing')]
  TTestRacingChampionship = class(TObject)
  public
    [Test]
    procedure DovrebbeCopiareLeImpostazioni;
    [Test]
    procedure DovrebbeTenereIGiriNelLimite;
    [Test]
    procedure DovrebbeTenereLaFamigliaDiAutoNelLimite;
    [Test]
    procedure DovrebbeTagliareIlNomeDelPilota;
  end;

  [TestFixture]
  [Category('racing')]
  TTestRacingRaceState = class(TObject)
  public
    [Test]
    procedure DovrebbePartireInAttesa;
    [Test]
    procedure DovrebbeTenereCioCheIlGiocoScrive;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf, DelphiDoom.Racing.CarData,
  DelphiDoom.Racing.Championship, DelphiDoom.Racing.Factory;

{ TTestRacingCarData }

procedure TTestRacingCarData.DovrebbeAvereQuaranteAuto;
begin
  Assert.AreEqual(40, Length(RACING_CAR_DATA));
  Assert.AreEqual(RACING_CAR_COUNT, Length(RACING_CAR_DATA));
end;

procedure TTestRacingCarData.DovrebbeAvereLeFormulaPrimaELeAutoDiSerieDopo;
var
  LIndex: Integer;
begin
  for LIndex := 0 to RACING_FORMULA_CAR_COUNT - 1 do
    Assert.AreEqual(Ord(TRacingCarType.Formula), Ord(RACING_CAR_DATA[LIndex].CarType));
  for LIndex := RACING_FORMULA_CAR_COUNT to RACING_CAR_COUNT - 1 do
    Assert.AreEqual(Ord(TRacingCarType.Stock), Ord(RACING_CAR_DATA[LIndex].CarType));
end;

procedure TTestRacingCarData.DovrebbeAvereIDatiDellaPrimaFormula;
begin
  Assert.AreEqual('PHOENIX ENGINE', RACING_CAR_DATA[0].Name);
  Assert.AreEqual(27, RACING_CAR_DATA[0].Number);
  Assert.AreEqual(305 * RACING_KMH_TO_FIXED, RACING_CAR_DATA[0].MaxSpeed);
  Assert.AreEqual(-50 * RACING_KMH_TO_FIXED, RACING_CAR_DATA[0].MaxReverseSpeed);
  Assert.AreEqual(8 * 1024, RACING_CAR_DATA[0].BaseAcceleration);
  Assert.AreEqual(64 * 1024, RACING_CAR_DATA[0].BaseDeceleration);
  Assert.AreEqual(Cardinal(448 * FIXED_ONE), RACING_CAR_DATA[0].TurnSpeed);
  Assert.AreEqual('CAR0N0A.I3D', RACING_CAR_DATA[0].Model3d);
  Assert.AreEqual(20, RACING_CAR_DATA[0].MaxDrift);
  Assert.AreEqual('f_1_4', RACING_CAR_DATA[0].OriginalTexture1);
  Assert.AreEqual('', RACING_CAR_DATA[0].Texture1);
end;

procedure TTestRacingCarData.DovrebbeAvereIDatiDellUltimaAutoDiSerie;
begin
  Assert.AreEqual('BOOM BOOM', RACING_CAR_DATA[RACING_CAR_COUNT - 1].Name);
  Assert.AreEqual(92, RACING_CAR_DATA[RACING_CAR_COUNT - 1].Number);
  Assert.AreEqual(260 * RACING_KMH_TO_FIXED, RACING_CAR_DATA[RACING_CAR_COUNT - 1].MaxSpeed);
  Assert.AreEqual(6 * 1024, RACING_CAR_DATA[RACING_CAR_COUNT - 1].BaseAcceleration);
  Assert.AreEqual(45, RACING_CAR_DATA[RACING_CAR_COUNT - 1].MaxDrift);
  Assert.AreEqual('d_6_5_02_92.png', RACING_CAR_DATA[RACING_CAR_COUNT - 1].Texture1);
end;

procedure TTestRacingCarData.DovrebbeAvereDatiPossibiliPerOgniAuto;
var
  LIndex: Integer;
begin
  for LIndex := 0 to RACING_CAR_COUNT - 1 do
  begin
    Assert.IsTrue(RACING_CAR_DATA[LIndex].MaxSpeed > 0, IntToStr(LIndex));
    Assert.IsTrue(RACING_CAR_DATA[LIndex].MaxReverseSpeed < 0, IntToStr(LIndex));
    Assert.IsTrue(RACING_CAR_DATA[LIndex].BaseAcceleration > 0, IntToStr(LIndex));
    Assert.IsTrue(RACING_CAR_DATA[LIndex].BaseDeceleration > 0, IntToStr(LIndex));
    Assert.IsTrue(RACING_CAR_DATA[LIndex].MaxDrift > 0, IntToStr(LIndex));
    Assert.IsTrue(RACING_CAR_DATA[LIndex].Name <> '', IntToStr(LIndex));
    Assert.IsTrue(RACING_CAR_DATA[LIndex].Model3d <> '', IntToStr(LIndex));
  end;
end;

procedure TTestRacingCarData.DovrebbeUsareIModelliDelleDueFamiglie;
begin
  Assert.IsTrue(Pos('CAR0', RACING_CAR_DATA[5].Model3d) = 1);
  Assert.IsTrue(Pos('CAR1', RACING_CAR_DATA[25].Model3d) = 1);
end;

{ TTestRacingChampionship }

procedure TTestRacingChampionship.DovrebbeCopiareLeImpostazioni;
var
  LSettings: TRacingChampionship;
begin
  LSettings := TRacingChampionshipSettings.Build(TRacingGameType.SingleRace, RACING_TRANSMISSION_MANUAL, 4, 1,
    5, 6, 7, 'ANN');
  Assert.AreEqual(4, LSettings.NumLaps);
  Assert.AreEqual(Ord(TRacingCarType.Stock), Ord(LSettings.RaceCarType));
  Assert.AreEqual(Ord(TRacingGameType.SingleRace), Ord(LSettings.GameType));
  Assert.AreEqual(RACING_TRANSMISSION_MANUAL, LSettings.TransmissionType);
  Assert.AreEqual(5, LSettings.DefaultFormulaCar);
  Assert.AreEqual(6, LSettings.DefaultStockCar);
  Assert.AreEqual(7, LSettings.DefaultAnyCar);
  Assert.AreEqual('ANN', LSettings.PilotName);
end;

procedure TTestRacingChampionship.DovrebbeTenereIGiriNelLimite;
begin
  Assert.AreEqual(RACING_MIN_LAPS, TRacingChampionshipSettings.Build(TRacingGameType.Practice, 0, 0, 0, 0, 0, 0, '').NumLaps);
  Assert.AreEqual(RACING_MAX_LAPS, TRacingChampionshipSettings.Build(TRacingGameType.Practice, 0, 99, 0, 0, 0, 0, '').NumLaps);
end;

procedure TTestRacingChampionship.DovrebbeTenereLaFamigliaDiAutoNelLimite;
begin
  Assert.AreEqual(Ord(TRacingCarType.Any),
    Ord(TRacingChampionshipSettings.Build(TRacingGameType.Practice, 0, 3, 99, 0, 0, 0, '').RaceCarType));
  Assert.AreEqual(Ord(TRacingCarType.Formula),
    Ord(TRacingChampionshipSettings.Build(TRacingGameType.Practice, 0, 3, -4, 0, 0, 0, '').RaceCarType));
end;

procedure TTestRacingChampionship.DovrebbeTagliareIlNomeDelPilota;
begin
  Assert.AreEqual('ABCDEFGHIJKLMNOP',
    TRacingChampionshipSettings.Build(TRacingGameType.Practice, 0, 3, 0, 0, 0, 0, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ').PilotName);
end;

{ TTestRacingRaceState }

procedure TTestRacingRaceState.DovrebbePartireInAttesa;
var
  LRace: IRacingRaceSettings;
begin
  LRace := TRacingFactory.CreateRaceState;
  Assert.AreEqual(Ord(TRacingStatus.Waiting), Ord(LRace.Status));
  Assert.AreEqual(0, LRace.RaceTime);
  Assert.AreEqual(RACING_TRANSMISSION_AUTOMATIC, LRace.TransmissionType);
end;

procedure TTestRacingRaceState.DovrebbeTenereCioCheIlGiocoScrive;
var
  LRace: IRacingRaceSettings;
begin
  LRace := TRacingFactory.CreateRaceState;
  LRace.SetStatus(TRacingStatus.PlayerFinished);
  LRace.SetCarType(TRacingCarType.Stock);
  LRace.SetGameType(TRacingGameType.Practice);
  LRace.SetTransmissionType(RACING_TRANSMISSION_MANUAL);
  LRace.SetNumLaps(7);
  LRace.SetRaceTime(11);
  LRace.SetLevelTime(22);
  LRace.SetSkill(TRacingSkill.Nightmare);
  LRace.SetEpisode(3);
  LRace.SetMap(4);
  Assert.AreEqual(Ord(TRacingStatus.PlayerFinished), Ord(LRace.Status));
  Assert.AreEqual(Ord(TRacingCarType.Stock), Ord(LRace.CarType));
  Assert.AreEqual(Ord(TRacingGameType.Practice), Ord(LRace.GameType));
  Assert.AreEqual(RACING_TRANSMISSION_MANUAL, LRace.TransmissionType);
  Assert.AreEqual(7, LRace.NumLaps);
  Assert.AreEqual(11, LRace.RaceTime);
  Assert.AreEqual(22, LRace.LevelTime);
  Assert.AreEqual(Ord(TRacingSkill.Nightmare), Ord(LRace.Skill));
  Assert.AreEqual(3, LRace.Episode);
  Assert.AreEqual(4, LRace.Map);
end;

end.

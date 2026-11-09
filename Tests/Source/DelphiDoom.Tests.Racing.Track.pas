{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingTrack                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.Track;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf,
  DelphiDoom.Tests.Racing.Fakes;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingTrack = class(TObject)
  strict private
    FWorld: TRacingTestWorld;
    function CarAt(APath: Integer; ACarInfo: Integer): TRacingCarState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnPercorsoSenzaPunti;
    [Test]
    procedure DovrebbeLegareIPuntiInUnGiro;
    [Test]
    procedure DovrebbeSommareLeDistanzeDelGiro;
    [Test]
    procedure DovrebbeMandareUnaAutoSuUnPuntoAlPuntoSuccessivo;
    [Test]
    procedure DovrebbeTrovareIlPuntoDavantiAUnaAuto;
    [Test]
    procedure DovrebbeConservareIDifettiDegliIdSeIPuntiNonSonoInOrdine;
    [Test]
    procedure DovrebbeDareErroreSeUnPuntoNonEsiste;
    [Test]
    procedure DovrebbeDareErroreSeLaPistaNonECaricata;
    [Test]
    procedure DovrebbeContareUnGiroAlPassaggioDelTraguardo;
    [Test]
    procedure DovrebbeTogliereUnGiroSeSiPassaIlTraguardoAlContrario;
    [Test]
    procedure DovrebbeNonContareIGiriOltreIlNumeroDellaGara;
    [Test]
    procedure DovrebbeDareITempiDeiGiri;
    [Test]
    procedure DovrebbeDareZeroPerIGiriNonFiniti;
    [Test]
    procedure DovrebbeMettereInOrdineLeAutoPerGiriEDistanza;
    [Test]
    procedure DovrebbeMettereInPrimaUnAutoChePassaIlTraguardoPrima;
    [Test]
    procedure DovrebbeDecidereLaParitaConLaChiave;
    [Test]
    procedure DovrebbeMettereInPrimaLAutoChehaFinitoPrima;
    [Test]
    procedure DovrebbeLimitareLaDistanzaALunghezzaDellaGara;
    [Test]
    procedure DovrebbeTenereLeGiraDiUnaAutoFinitaDallUltimoCalcolo;
    [Test]
    procedure DovrebbeRifiutareTroppeAuto;
    [Test]
    procedure DovrebbeRifiutareLOrdineSenzaPercorso;
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Factory, DelphiDoom.Tests.Racing.Scenarios;

{ TTestRacingTrack }

procedure TTestRacingTrack.Setup;
begin
  FWorld := TRacingTestWorld.Create;
  FWorld.LoadSimpleTrack;
  FWorld.StartRace;
end;

procedure TTestRacingTrack.TearDown;
begin
  FWorld.Free;
end;

function TTestRacingTrack.CarAt(APath: Integer; ACarInfo: Integer): TRacingCarState;
begin
  Result := TRacingScenarios.NewCar(ACarInfo, FWorld.Track.GetPath(APath).X, FWorld.Track.GetPath(APath).Y, 0);
  Result.CurrentPath := APath;
end;

procedure TTestRacingTrack.DovrebbeRifiutareUnPercorsoSenzaPunti;
var
  LTrack: IRacingTrack;
begin
  LTrack := TRacingFactory.CreateTrack(FWorld.Race, FWorld.Geometry);
  Assert.IsFalse(LTrack.Load([]));
  Assert.AreEqual(0, LTrack.PathCount);
end;

procedure TTestRacingTrack.DovrebbeLegareIPuntiInUnGiro;
var
  LIndex: Integer;
begin
  Assert.AreEqual(8, FWorld.Track.PathCount);
  for LIndex := 0 to 7 do
  begin
    Assert.AreEqual(LIndex, FWorld.Track.GetPath(LIndex).Id);
    Assert.AreEqual((LIndex + 1) mod 8, FWorld.Track.GetPath(LIndex).Next);
    Assert.AreEqual((LIndex + 7) mod 8, FWorld.Track.GetPath(LIndex).Previous);
  end;
end;

procedure TTestRacingTrack.DovrebbeSommareLeDistanzeDelGiro;
var
  LIndex: Integer;
  LSum: Int64;
begin
  // The first point starts at the distance of the last one to it
  Assert.AreEqual(Int64(FWorld.Track.GetPath(7).DistanceToNext), FWorld.Track.GetPath(0).DistanceToHere);
  LSum := FWorld.Track.GetPath(0).DistanceToHere;
  for LIndex := 1 to 7 do
  begin
    LSum := LSum + FWorld.Track.GetPath(LIndex - 1).DistanceToNext;
    Assert.AreEqual(LSum, FWorld.Track.GetPath(LIndex).DistanceToHere);
  end;
end;

procedure TTestRacingTrack.DovrebbeMandareUnaAutoSuUnPuntoAlPuntoSuccessivo;
begin
  Assert.AreEqual(4, FWorld.Track.GetNextPath(FWorld.Track.GetPath(3).X, FWorld.Track.GetPath(3).Y));
end;

procedure TTestRacingTrack.DovrebbeTrovareIlPuntoDavantiAUnaAuto;
var
  LX, LY: Integer;
begin
  // A little before the point 2, on the line to it
  LX := (FWorld.Track.GetPath(1).X + FWorld.Track.GetPath(2).X) div 2;
  LY := (FWorld.Track.GetPath(1).Y + FWorld.Track.GetPath(2).Y) div 2;
  Assert.AreEqual(2, FWorld.Track.GetNextPath(LX, LY));
end;

procedure TTestRacingTrack.DovrebbeConservareIDifettiDegliIdSeIPuntiNonSonoInOrdine;
var
  LTrack: IRacingTrack;
  LIndex: Integer;
  LDifferent: Boolean;
begin
  // The points are reordered but not their numbers: the id of a point is the place that it had in the map
  LTrack := TRacingFactory.CreateTrack(FWorld.Race, FWorld.Geometry);
  Assert.IsTrue(LTrack.Load(TRacingScenarios.Circuit(12, 1500, True)));
  LDifferent := False;
  for LIndex := 0 to LTrack.PathCount - 1 do
    if LTrack.GetPath(LIndex).Id <> LIndex then
      LDifferent := True;
  Assert.IsTrue(LDifferent);
end;

procedure TTestRacingTrack.DovrebbeDareErroreSeUnPuntoNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FWorld.Track.GetPath(8);
    end, ERacingException);
  Assert.WillRaise(
    procedure
    begin
      FWorld.Track.GetPath(-1);
    end, ERacingException);
end;

procedure TTestRacingTrack.DovrebbeDareErroreSeLaPistaNonECaricata;
var
  LTrack: IRacingTrack;
  LCar: TRacingCarState;
  LTimes: TRacingLapTimes;
begin
  LTrack := TRacingFactory.CreateTrack(FWorld.Race, FWorld.Geometry);
  LCar := TRacingScenarios.NewCar(0, 0, 0, 0);
  Assert.WillRaise(
    procedure
    begin
      LTrack.GetNextPath(0, 0);
    end, ERacingException);
  Assert.WillRaise(
    procedure
    begin
      LTrack.Notify(LCar);
    end, ERacingException);
  Assert.WillRaise(
    procedure
    begin
      LTrack.GetLapTimes(LCar, LTimes);
    end, ERacingException);
end;

procedure TTestRacingTrack.DovrebbeContareUnGiroAlPassaggioDelTraguardo;
var
  LCar: TRacingCarState;
begin
  LCar := CarAt(0, 3);
  LCar.PreviousPath := 7;
  FWorld.Race.SetRaceTime(500);
  FWorld.Track.Notify(LCar);
  Assert.AreEqual(1, LCar.LapsCompleted);
  Assert.AreEqual(0, LCar.PreviousPath);
end;

procedure TTestRacingTrack.DovrebbeTogliereUnGiroSeSiPassaIlTraguardoAlContrario;
var
  LCar: TRacingCarState;
begin
  LCar := CarAt(7, 3);
  LCar.PreviousPath := 0;
  LCar.LapsCompleted := 1;
  FWorld.Track.Notify(LCar);
  Assert.AreEqual(0, LCar.LapsCompleted);
  Assert.AreEqual(7, LCar.PreviousPath);
end;

procedure TTestRacingTrack.DovrebbeNonContareIGiriOltreIlNumeroDellaGara;
var
  LCar: TRacingCarState;
  LTimes: TRacingLapTimes;
begin
  LCar := CarAt(0, 3);
  LCar.LapsCompleted := 3;
  LCar.PreviousPath := 7;
  FWorld.Race.SetRaceTime(900);
  FWorld.Track.Notify(LCar);
  // A fourth lap is counted but it is not in the times of a race of three laps
  Assert.AreEqual(4, LCar.LapsCompleted);
  FWorld.Track.GetLapTimes(LCar, LTimes);
  Assert.AreEqual(0, LTimes[0]);
end;

procedure TTestRacingTrack.DovrebbeDareITempiDeiGiri;
var
  LCar: TRacingCarState;
  LTimes: TRacingLapTimes;
begin
  LCar := CarAt(0, 3);
  LCar.PreviousPath := 7;
  FWorld.Race.SetRaceTime(500);
  FWorld.Track.Notify(LCar);
  LCar.PreviousPath := 7;
  FWorld.Race.SetRaceTime(1400);
  FWorld.Track.Notify(LCar);
  FWorld.Track.GetLapTimes(LCar, LTimes);
  Assert.AreEqual(500, LTimes[0]);
  Assert.AreEqual(900, LTimes[1]);
  Assert.AreEqual(0, LTimes[2]);
end;

procedure TTestRacingTrack.DovrebbeDareZeroPerIGiriNonFiniti;
var
  LCar: TRacingCarState;
  LTimes: TRacingLapTimes;
  LIndex: Integer;
begin
  LCar := CarAt(0, 5);
  FWorld.Track.GetLapTimes(LCar, LTimes);
  for LIndex := 0 to RACING_MAX_LAPS - 1 do
    Assert.AreEqual(0, LTimes[LIndex]);
end;

procedure TTestRacingTrack.DovrebbeMettereInOrdineLeAutoPerGiriEDistanza;
var
  LCars: array[0..2] of TRacingPositionInput;
  LItems: TArray<TRacingPositionItem>;
begin
  LCars[0].Key := 10;
  LCars[0].CarInfo := 0;
  LCars[0].LapsCompleted := 0;
  LCars[0].CurrentPath := 2;
  LCars[0].X := FWorld.Track.GetPath(1).X;
  LCars[0].Y := FWorld.Track.GetPath(1).Y;
  LCars[1] := LCars[0];
  LCars[1].Key := 11;
  LCars[1].CurrentPath := 4;
  LCars[1].X := FWorld.Track.GetPath(3).X;
  LCars[1].Y := FWorld.Track.GetPath(3).Y;
  LCars[2] := LCars[0];
  LCars[2].Key := 12;
  LCars[2].CurrentPath := 1;
  LCars[2].X := FWorld.Track.GetPath(0).X;
  LCars[2].Y := FWorld.Track.GetPath(0).Y;
  LItems := FWorld.Track.CalculatePositions(LCars);
  Assert.AreEqual(3, Length(LItems));
  Assert.AreEqual(1, LItems[0].Index);
  Assert.AreEqual(0, LItems[1].Index);
  Assert.AreEqual(2, LItems[2].Index);
end;

procedure TTestRacingTrack.DovrebbeMettereInPrimaUnAutoChePassaIlTraguardoPrima;
var
  LCars: array[0..1] of TRacingPositionInput;
  LItems: TArray<TRacingPositionItem>;
begin
  LCars[0].Key := 1;
  LCars[0].CarInfo := 0;
  LCars[0].LapsCompleted := 0;
  LCars[0].CurrentPath := 6;
  LCars[0].X := FWorld.Track.GetPath(5).X;
  LCars[0].Y := FWorld.Track.GetPath(5).Y;
  LCars[1] := LCars[0];
  LCars[1].Key := 2;
  LCars[1].LapsCompleted := 1;
  LCars[1].CurrentPath := 1;
  LCars[1].X := FWorld.Track.GetPath(0).X;
  LCars[1].Y := FWorld.Track.GetPath(0).Y;
  LItems := FWorld.Track.CalculatePositions(LCars);
  Assert.AreEqual(1, LItems[0].Index);
  Assert.AreEqual(1, LItems[0].LapsCompleted);
end;

procedure TTestRacingTrack.DovrebbeDecidereLaParitaConLaChiave;
var
  LCars: array[0..1] of TRacingPositionInput;
  LItems: TArray<TRacingPositionItem>;
begin
  LCars[0].Key := 50;
  LCars[0].CarInfo := 0;
  LCars[0].LapsCompleted := 0;
  LCars[0].CurrentPath := 2;
  LCars[0].X := FWorld.Track.GetPath(1).X;
  LCars[0].Y := FWorld.Track.GetPath(1).Y;
  LCars[1] := LCars[0];
  LCars[1].Key := 51;
  LItems := FWorld.Track.CalculatePositions(LCars);
  // Two cars at the same place: the lower key comes first
  Assert.AreEqual(0, LItems[0].Index);
  Assert.AreEqual(1, LItems[1].Index);
end;

procedure TTestRacingTrack.DovrebbeMettereInPrimaLAutoChehaFinitoPrima;
var
  LCars: array[0..1] of TRacingPositionInput;
  LCar: TRacingCarState;
  LItems: TArray<TRacingPositionItem>;
begin
  FWorld.Race.SetNumLaps(2);
  // The first one finishes at 3000, the second one at 2000
  LCar := CarAt(0, 1);
  LCar.PreviousPath := 7;
  LCar.LapsCompleted := 1;
  FWorld.Race.SetRaceTime(3000);
  FWorld.Track.Notify(LCar);
  LCar := CarAt(0, 2);
  LCar.PreviousPath := 7;
  LCar.LapsCompleted := 1;
  FWorld.Race.SetRaceTime(2000);
  FWorld.Track.Notify(LCar);

  LCars[0].Key := 1;
  LCars[0].CarInfo := 1;
  LCars[0].LapsCompleted := 2;
  LCars[0].CurrentPath := 0;
  LCars[0].X := 0;
  LCars[0].Y := 0;
  LCars[1] := LCars[0];
  LCars[1].Key := 2;
  LCars[1].CarInfo := 2;
  LItems := FWorld.Track.CalculatePositions(LCars);
  Assert.AreEqual(1, LItems[0].Index);
  Assert.AreEqual(2000, LItems[0].FinishTime);
  Assert.AreEqual(3000, LItems[1].FinishTime);
end;

procedure TTestRacingTrack.DovrebbeLimitareLaDistanzaALunghezzaDellaGara;
var
  LCars: array[0..0] of TRacingPositionInput;
  LItems: TArray<TRacingPositionItem>;
begin
  LCars[0].Key := 1;
  LCars[0].CarInfo := 0;
  LCars[0].LapsCompleted := 2;
  LCars[0].CurrentPath := 7;
  LCars[0].X := FWorld.Track.GetPath(7).X;
  LCars[0].Y := FWorld.Track.GetPath(7).Y;
  LItems := FWorld.Track.CalculatePositions(LCars);
  Assert.IsTrue(LItems[0].TotalDistance <= FWorld.Track.GetPath(7).DistanceToHere * 3);
end;

procedure TTestRacingTrack.DovrebbeTenereLeGiraDiUnaAutoFinitaDallUltimoCalcolo;
var
  LCars: array[0..1] of TRacingPositionInput;
  LItems: TArray<TRacingPositionItem>;
begin
  LCars[0].Key := 1;
  LCars[0].CarInfo := 0;
  LCars[0].LapsCompleted := 2;
  LCars[0].CurrentPath := 3;
  LCars[0].X := FWorld.Track.GetPath(3).X;
  LCars[0].Y := FWorld.Track.GetPath(3).Y;
  LCars[1] := LCars[0];
  LCars[1].Key := 2;
  LCars[1].LapsCompleted := 1;
  FWorld.Track.CalculatePositions(LCars);
  // Now the first car has finished: the laps of the table are the ones that it had in the last call
  LCars[0].LapsCompleted := 3;
  LItems := FWorld.Track.CalculatePositions(LCars);
  Assert.AreEqual(0, LItems[0].Index);
  Assert.AreEqual(2, LItems[0].LapsCompleted);
end;

procedure TTestRacingTrack.DovrebbeRifiutareTroppeAuto;
var
  LCars: array[0..RACING_CAR_COUNT] of TRacingPositionInput;
begin
  FillChar(LCars, SizeOf(LCars), 0);
  Assert.WillRaise(
    procedure
    begin
      FWorld.Track.CalculatePositions(LCars);
    end, ERacingException);
end;

procedure TTestRacingTrack.DovrebbeRifiutareLOrdineSenzaPercorso;
var
  LTrack: IRacingTrack;
  LCars: array[0..0] of TRacingPositionInput;
begin
  LTrack := TRacingFactory.CreateTrack(FWorld.Race, FWorld.Geometry);
  FillChar(LCars, SizeOf(LCars), 0);
  Assert.WillRaise(
    procedure
    begin
      LTrack.CalculatePositions(LCars);
    end, ERacingException);
end;

procedure TTestRacingTrack.DovrebbeRifiutareGliOggettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateTrack(nil, FWorld.Geometry);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateTrack(FWorld.Race, nil);
    end, EArgumentNilException);
end;

end.

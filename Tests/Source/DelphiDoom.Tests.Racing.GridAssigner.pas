{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingGridAssigner                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.GridAssigner;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Intf, DelphiDoom.Racing.Types,
  DelphiDoom.Racing.Intf;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingGridAssigner = class(TObject)
  strict private
    FAssigner: IRacingGridAssigner;
    function Contains(const AValues: TArray<Integer>; AValue: Integer): Boolean;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareUnaAutoPerOgniPosizione;
    [Test]
    procedure DovrebbeNonRipetereUnaAutoFinoAdEsaurirle;
    [Test]
    procedure DovrebbeUsareSoloLeAutoDellaFamigliaDellaGara;
    [Test]
    procedure DovrebbeUsareTutteLeAutoSeLaFamigliaENonImporta;
    [Test]
    procedure DovrebbeLasciareLeAutoDeiGiocatori;
    [Test]
    procedure DovrebbeRipetereLeAutoQuandoNonCeNeSonoAbbastanza;
    [Test]
    procedure DovrebbeDareLeStesseAutoConLoStessoSeme;
    [Test]
    procedure DovrebbeRifiutareTroppePosizioni;
    [Test]
    procedure DovrebbeDareUnElencoVuotoSenzaPosizioni;
    [Test]
    procedure DovrebbeRifiutareUnGeneratoreNil;
  end;

implementation

uses
  DelphiDoom.MathCore.Factory, DelphiDoom.Racing.Factory;

{ TTestRacingGridAssigner }

procedure TTestRacingGridAssigner.Setup;
begin
  FAssigner := TRacingFactory.CreateGridAssigner(TMathCoreFactory.CreateGameRandom);
end;

function TTestRacingGridAssigner.Contains(const AValues: TArray<Integer>; AValue: Integer): Boolean;
var
  LValue: Integer;
begin
  Result := False;
  for LValue in AValues do
    if LValue = AValue then
      Result := True;
end;

procedure TTestRacingGridAssigner.DovrebbeDareUnaAutoPerOgniPosizione;
begin
  Assert.AreEqual<Integer>(7, Length(FAssigner.Assign(7, TRacingCarType.Formula, [])));
end;

procedure TTestRacingGridAssigner.DovrebbeNonRipetereUnaAutoFinoAdEsaurirle;
var
  LCars: TArray<Integer>;
  LIndex, LOther: Integer;
begin
  LCars := FAssigner.Assign(19, TRacingCarType.Formula, []);
  for LIndex := 0 to High(LCars) do
    for LOther := LIndex + 1 to High(LCars) do
      Assert.AreNotEqual(LCars[LIndex], LCars[LOther]);
end;

procedure TTestRacingGridAssigner.DovrebbeUsareSoloLeAutoDellaFamigliaDellaGara;
var
  LCar: Integer;
begin
  for LCar in FAssigner.Assign(10, TRacingCarType.Stock, []) do
    Assert.IsTrue(LCar >= RACING_FORMULA_CAR_COUNT);
  for LCar in FAssigner.Assign(10, TRacingCarType.Formula, []) do
    Assert.IsTrue(LCar < RACING_FORMULA_CAR_COUNT);
end;

procedure TTestRacingGridAssigner.DovrebbeUsareTutteLeAutoSeLaFamigliaENonImporta;
var
  LCar: Integer;
  LStock: Boolean;
begin
  LStock := False;
  for LCar in FAssigner.Assign(19, TRacingCarType.Any, []) do
    if LCar >= RACING_FORMULA_CAR_COUNT then
      LStock := True;
  Assert.IsTrue(LStock);
end;

procedure TTestRacingGridAssigner.DovrebbeLasciareLeAutoDeiGiocatori;
var
  LCars: TArray<Integer>;
begin
  LCars := FAssigner.Assign(16, TRacingCarType.Formula, [3, 4, 5, 6]);
  Assert.IsFalse(Contains(LCars, 3));
  Assert.IsFalse(Contains(LCars, 4));
  Assert.IsFalse(Contains(LCars, 5));
  Assert.IsFalse(Contains(LCars, 6));
end;

procedure TTestRacingGridAssigner.DovrebbeRipetereLeAutoQuandoNonCeNeSonoAbbastanza;
var
  LCars: TArray<Integer>;
begin
  // Formula cars: 20, minus the 4 of the players; after the 16th the old code took the number of the position
  LCars := FAssigner.Assign(19, TRacingCarType.Formula, [3, 4, 5, 6]);
  Assert.AreEqual(16, LCars[16]);
  Assert.AreEqual(17, LCars[17]);
  Assert.AreEqual(18, LCars[18]);
end;

procedure TTestRacingGridAssigner.DovrebbeDareLeStesseAutoConLoStessoSeme;
var
  LFirst, LSecond: IGameRandom;
  LA, LB: TArray<Integer>;
  LIndex: Integer;
begin
  LFirst := TMathCoreFactory.CreateGameRandom;
  LFirst.SystemSeed := 7;
  LSecond := TMathCoreFactory.CreateGameRandom;
  LSecond.SystemSeed := 7;
  LA := TRacingFactory.CreateGridAssigner(LFirst).Assign(10, TRacingCarType.Any, []);
  LB := TRacingFactory.CreateGridAssigner(LSecond).Assign(10, TRacingCarType.Any, []);
  for LIndex := 0 to 9 do
    Assert.AreEqual(LA[LIndex], LB[LIndex]);
end;

procedure TTestRacingGridAssigner.DovrebbeRifiutareTroppePosizioni;
begin
  Assert.WillRaise(
    procedure
    begin
      FAssigner.Assign(RACING_MAX_CARS, TRacingCarType.Formula, []);
    end, ERacingException);
end;

procedure TTestRacingGridAssigner.DovrebbeDareUnElencoVuotoSenzaPosizioni;
begin
  Assert.AreEqual<Integer>(0, Length(FAssigner.Assign(0, TRacingCarType.Formula, [])));
end;

procedure TTestRacingGridAssigner.DovrebbeRifiutareUnGeneratoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateGridAssigner(nil);
    end, EArgumentNilException);
end;

end.

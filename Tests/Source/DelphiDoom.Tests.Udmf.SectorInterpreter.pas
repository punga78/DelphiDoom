{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the interpreter of the extra values of a sector        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.SectorInterpreter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Udmf.Apply.Types,
  DelphiDoom.Udmf.Apply.Intf;

type
  [TestFixture]
  [Category('udmf')]
  TTestUdmfSectorInterpreter = class(TObject)
  private
    FInterpreter: IUdmfSectorInterpreter;
    function PlanesWith(AFlags: Integer; AC: Single): TUdmfSectorPlanes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareFalsoSeNonCiSonoPianiNelleFlag;
    [Test]
    procedure DovrebbeDareFalsoSeMancaUnoDeiQuattroValoriDelSoffitto;
    [Test]
    procedure DovrebbeDareFalsoSeMancaUnoDeiQuattroValoriDelPavimento;
    [Test]
    procedure DovrebbeDareFalsoSeCDelSoffittoEZero;
    [Test]
    procedure DovrebbeDareFalsoSeCDelPavimentoEZero;
    [Test]
    procedure DovrebbeDareIlPianoDelSoffittoConCInvertito;
    [Test]
    procedure DovrebbeDareIlPianoDelPavimentoConCInvertito;
    [Test]
    procedure DovrebbeTenerePavimentoESoffittoSeparati;
    [Test]
    procedure DovrebbeDareNessunEffettoSenzaFlag;
    [Test]
    procedure DovrebbeDareOgniEffettoDalSuoBit;
    [Test]
    procedure DovrebbeIgnorareIBitDeiPiani;
  end;

implementation

uses
  DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Apply.Factory;

const
  ALL_CEILING = UDMF_SF_CEILINGPLANE_A or UDMF_SF_CEILINGPLANE_B or UDMF_SF_CEILINGPLANE_C or
    UDMF_SF_CEILINGPLANE_D;
  ALL_FLOOR = UDMF_SF_FLOORPLANE_A or UDMF_SF_FLOORPLANE_B or UDMF_SF_FLOORPLANE_C or
    UDMF_SF_FLOORPLANE_D;

{ TTestUdmfSectorInterpreter }

procedure TTestUdmfSectorInterpreter.Setup;
begin
  FInterpreter := TUdmfApplyFactory.CreateSectorInterpreter;
end;

procedure TTestUdmfSectorInterpreter.TearDown;
begin
  FInterpreter := nil;
end;

function TTestUdmfSectorInterpreter.PlanesWith(AFlags: Integer; AC: Single): TUdmfSectorPlanes;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Flags := AFlags;
  Result.CeilingA := 0.5;
  Result.CeilingB := 0.25;
  Result.CeilingC := AC;
  Result.CeilingD := -64;
  Result.FloorA := 0.125;
  Result.FloorB := 0.75;
  Result.FloorC := AC;
  Result.FloorD := 32;
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareFalsoSeNonCiSonoPianiNelleFlag;
var
  LPlane: TUdmfPlane;
begin
  Assert.IsFalse(FInterpreter.TryGetCeilingPlane(PlanesWith(0, 2), LPlane));
  Assert.IsFalse(FInterpreter.TryGetFloorPlane(PlanesWith(0, 2), LPlane));
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareFalsoSeMancaUnoDeiQuattroValoriDelSoffitto;
var
  LPlane: TUdmfPlane;
begin
  Assert.IsFalse(FInterpreter.TryGetCeilingPlane(
    PlanesWith(ALL_CEILING and not UDMF_SF_CEILINGPLANE_D, 2), LPlane));
  Assert.IsFalse(FInterpreter.TryGetCeilingPlane(
    PlanesWith(ALL_CEILING and not UDMF_SF_CEILINGPLANE_A, 2), LPlane));
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareFalsoSeMancaUnoDeiQuattroValoriDelPavimento;
var
  LPlane: TUdmfPlane;
begin
  Assert.IsFalse(FInterpreter.TryGetFloorPlane(
    PlanesWith(ALL_FLOOR and not UDMF_SF_FLOORPLANE_C, 2), LPlane));
  Assert.IsFalse(FInterpreter.TryGetFloorPlane(
    PlanesWith(ALL_FLOOR and not UDMF_SF_FLOORPLANE_B, 2), LPlane));
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareFalsoSeCDelSoffittoEZero;
var
  LPlane: TUdmfPlane;
begin
  Assert.IsFalse(FInterpreter.TryGetCeilingPlane(PlanesWith(ALL_CEILING, 0), LPlane));
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareFalsoSeCDelPavimentoEZero;
var
  LPlane: TUdmfPlane;
begin
  Assert.IsFalse(FInterpreter.TryGetFloorPlane(PlanesWith(ALL_FLOOR, 0), LPlane));
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareIlPianoDelSoffittoConCInvertito;
var
  LPlane: TUdmfPlane;
begin
  Assert.IsTrue(FInterpreter.TryGetCeilingPlane(PlanesWith(ALL_CEILING, 4), LPlane));
  Assert.AreEqual(Single(0.5), LPlane.A);
  Assert.AreEqual(Single(0.25), LPlane.B);
  Assert.AreEqual(Single(0.25), LPlane.InverseC);
  Assert.AreEqual(Single(-64), LPlane.D);
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareIlPianoDelPavimentoConCInvertito;
var
  LPlane: TUdmfPlane;
begin
  Assert.IsTrue(FInterpreter.TryGetFloorPlane(PlanesWith(ALL_FLOOR, -2), LPlane));
  Assert.AreEqual(Single(0.125), LPlane.A);
  Assert.AreEqual(Single(0.75), LPlane.B);
  Assert.AreEqual(Single(-0.5), LPlane.InverseC);
  Assert.AreEqual(Single(32), LPlane.D);
end;

procedure TTestUdmfSectorInterpreter.DovrebbeTenerePavimentoESoffittoSeparati;
var
  LPlane: TUdmfPlane;
begin
  Assert.IsTrue(FInterpreter.TryGetCeilingPlane(PlanesWith(ALL_CEILING, 2), LPlane));
  Assert.IsFalse(FInterpreter.TryGetFloorPlane(PlanesWith(ALL_CEILING, 2), LPlane));
  Assert.IsTrue(FInterpreter.TryGetFloorPlane(PlanesWith(ALL_FLOOR, 2), LPlane));
  Assert.IsFalse(FInterpreter.TryGetCeilingPlane(PlanesWith(ALL_FLOOR, 2), LPlane));
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareNessunEffettoSenzaFlag;
begin
  Assert.IsTrue(FInterpreter.GetEffects(0) = []);
end;

procedure TTestUdmfSectorInterpreter.DovrebbeDareOgniEffettoDalSuoBit;
begin
  Assert.IsTrue(FInterpreter.GetEffects(UDMF_SF_RIPPLECEILING) = [seRippleCeiling]);
  Assert.IsTrue(FInterpreter.GetEffects(UDMF_SF_RIPPLEFLOOR) = [seRippleFloor]);
  Assert.IsTrue(FInterpreter.GetEffects(UDMF_SF_FOG) = [seFog]);
  Assert.IsTrue(FInterpreter.GetEffects(UDMF_SF_HIDDEN) = [seHidden]);
  Assert.IsTrue(FInterpreter.GetEffects(UDMF_SF_NOJUMP) = [seNoJump]);
  Assert.IsTrue(FInterpreter.GetEffects(UDMF_SF_NOCROUCH) = [seNoCrouch]);
  Assert.IsTrue(FInterpreter.GetEffects(UDMF_SF_FOG or UDMF_SF_NOJUMP) = [seFog, seNoJump]);
end;

procedure TTestUdmfSectorInterpreter.DovrebbeIgnorareIBitDeiPiani;
begin
  Assert.IsTrue(FInterpreter.GetEffects(ALL_CEILING or ALL_FLOOR) = []);
end;

end.

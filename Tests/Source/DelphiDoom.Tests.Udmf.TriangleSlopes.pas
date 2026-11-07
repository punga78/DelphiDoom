{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the slopes of a triangular sector                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.TriangleSlopes;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Udmf.Apply.Types,
  DelphiDoom.Udmf.Apply.Intf;

type
  [TestFixture]
  [Category('udmf')]
  TTestUdmfTriangleSlopes = class(TObject)
  private
    FSlopes: IUdmfTriangleSlopes;
    function Corner(AX, AY, AFlags, AZFloor, AZCeiling: Integer): TUdmfTriangleCorner;
    function Triangle(const A, B, C: TUdmfTriangleCorner): TUdmfTriangle;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNonDareInclinazioniSenzaAltezzeNeiVertexi;
    [Test]
    procedure DovrebbeInclinareSoloIlPavimentoSeSoloIlPavimentoHaAltezze;
    [Test]
    procedure DovrebbeInclinareSoloIlSoffittoSeSoloIlSoffittoHaAltezze;
    [Test]
    procedure DovrebbeUsareLAltezzaDelSettorePerIVertexiSenzaAltezza;
    [Test]
    procedure DovrebbeDareUnPianoCheSiAdattaAiTreVertexi;
    [Test]
    procedure DovrebbeIgnorareLAltezzaDiUnVertexSenzaFlag;
  end;

implementation

uses
  DelphiDoom.Udmf.Types, DelphiDoom.Udmf.Apply.Factory;

{ TTestUdmfTriangleSlopes }

procedure TTestUdmfTriangleSlopes.Setup;
begin
  FSlopes := TUdmfApplyFactory.CreateTriangleSlopes;
end;

procedure TTestUdmfTriangleSlopes.TearDown;
begin
  FSlopes := nil;
end;

function TTestUdmfTriangleSlopes.Corner(AX, AY, AFlags, AZFloor, AZCeiling: Integer): TUdmfTriangleCorner;
begin
  Result.X := AX * FRACUNIT;
  Result.Y := AY * FRACUNIT;
  Result.Flags := AFlags;
  Result.ZFloor := AZFloor * FRACUNIT;
  Result.ZCeiling := AZCeiling * FRACUNIT;
end;

function TTestUdmfTriangleSlopes.Triangle(const A, B, C: TUdmfTriangleCorner): TUdmfTriangle;
begin
  Result[0] := A;
  Result[1] := B;
  Result[2] := C;
end;

procedure TTestUdmfTriangleSlopes.DovrebbeNonDareInclinazioniSenzaAltezzeNeiVertexi;
var
  LResult: TUdmfSurfaceSlopes;
begin
  LResult := FSlopes.Solve(
    Triangle(Corner(0, 0, 0, 99, 99), Corner(64, 0, 0, 99, 99), Corner(0, 64, 0, 99, 99)),
    0, 128 * FRACUNIT);
  Assert.IsFalse(LResult.HasFloor);
  Assert.IsFalse(LResult.HasCeiling);
end;

procedure TTestUdmfTriangleSlopes.DovrebbeInclinareSoloIlPavimentoSeSoloIlPavimentoHaAltezze;
var
  LResult: TUdmfSurfaceSlopes;
begin
  LResult := FSlopes.Solve(
    Triangle(Corner(0, 0, UDMF_VF_ZFLOOR, 0, 0), Corner(64, 0, 0, 0, 0), Corner(0, 64, 0, 0, 0)),
    0, 128 * FRACUNIT);
  Assert.IsTrue(LResult.HasFloor);
  Assert.IsFalse(LResult.HasCeiling);
end;

procedure TTestUdmfTriangleSlopes.DovrebbeInclinareSoloIlSoffittoSeSoloIlSoffittoHaAltezze;
var
  LResult: TUdmfSurfaceSlopes;
begin
  LResult := FSlopes.Solve(
    Triangle(Corner(0, 0, 0, 0, 0), Corner(64, 0, UDMF_VF_ZCEILING, 0, 160), Corner(0, 64, 0, 0, 0)),
    0, 128 * FRACUNIT);
  Assert.IsFalse(LResult.HasFloor);
  Assert.IsTrue(LResult.HasCeiling);
end;

procedure TTestUdmfTriangleSlopes.DovrebbeUsareLAltezzaDelSettorePerIVertexiSenzaAltezza;
var
  LResult: TUdmfSurfaceSlopes;
begin
  // the floor of the sector is 8, one corner is at 40: z = 8 + 32 x / 64
  LResult := FSlopes.Solve(
    Triangle(Corner(0, 0, 0, 0, 0), Corner(64, 0, UDMF_VF_ZFLOOR, 40, 0), Corner(0, 64, 0, 0, 0)),
    8 * FRACUNIT, 128 * FRACUNIT);
  Assert.IsTrue(LResult.HasFloor);
  // at (0, 0) the plane is at 8
  Assert.AreEqual(8.0, -(LResult.Floor.A * 0 + LResult.Floor.B * 0 + LResult.Floor.D) / (1 / LResult.Floor.InverseC), 0.001);
  // at (64, 0) it is at 40
  Assert.AreEqual(40.0, -(LResult.Floor.A * 64 + LResult.Floor.B * 0 + LResult.Floor.D) / (1 / LResult.Floor.InverseC), 0.001);
  // and it does not change along y
  Assert.AreEqual(8.0, -(LResult.Floor.A * 0 + LResult.Floor.B * 64 + LResult.Floor.D) / (1 / LResult.Floor.InverseC), 0.001);
end;

procedure TTestUdmfTriangleSlopes.DovrebbeDareUnPianoCheSiAdattaAiTreVertexi;
var
  LResult: TUdmfSurfaceSlopes;
  LC: Double;
begin
  LResult := FSlopes.Solve(
    Triangle(Corner(100, 100, UDMF_VF_ZCEILING, 0, 150), Corner(200, 100, UDMF_VF_ZCEILING, 0, 90),
      Corner(150, 200, UDMF_VF_ZCEILING, 0, 120)),
    0, 128 * FRACUNIT);
  Assert.IsTrue(LResult.HasCeiling);
  LC := 1 / LResult.Ceiling.InverseC;
  Assert.AreEqual(0.0, LResult.Ceiling.A * 100 + LResult.Ceiling.B * 100 + LC * 150 + LResult.Ceiling.D, 0.5);
  Assert.AreEqual(0.0, LResult.Ceiling.A * 200 + LResult.Ceiling.B * 100 + LC * 90 + LResult.Ceiling.D, 0.5);
  Assert.AreEqual(0.0, LResult.Ceiling.A * 150 + LResult.Ceiling.B * 200 + LC * 120 + LResult.Ceiling.D, 0.5);
end;

procedure TTestUdmfTriangleSlopes.DovrebbeIgnorareLAltezzaDiUnVertexSenzaFlag;
var
  LWith, LWithout: TUdmfSurfaceSlopes;
begin
  LWith := FSlopes.Solve(
    Triangle(Corner(0, 0, UDMF_VF_ZFLOOR, 24, 0), Corner(64, 0, 0, 500, 0), Corner(0, 64, 0, 700, 0)),
    8 * FRACUNIT, 128 * FRACUNIT);
  LWithout := FSlopes.Solve(
    Triangle(Corner(0, 0, UDMF_VF_ZFLOOR, 24, 0), Corner(64, 0, 0, 0, 0), Corner(0, 64, 0, 0, 0)),
    8 * FRACUNIT, 128 * FRACUNIT);
  Assert.AreEqual(LWithout.Floor.A, LWith.Floor.A);
  Assert.AreEqual(LWithout.Floor.B, LWith.Floor.B);
  Assert.AreEqual(LWithout.Floor.InverseC, LWith.Floor.InverseC);
  Assert.AreEqual(LWithout.Floor.D, LWith.Floor.D);
end;

end.

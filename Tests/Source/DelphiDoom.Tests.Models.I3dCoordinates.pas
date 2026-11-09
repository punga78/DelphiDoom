{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the coordinates of I3D models  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dCoordinates;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Models.Types, DelphiDoom.Models.I3d.Types;

type
  /// <summary>The formulas of the old RenderGL for the vertexes and the texture points</summary>
  [TestFixture]
  [Category('models')]
  TTestModelsI3dCoordinates = class(TObject)
  strict private
    FHeader: TI3dHeader;
    FPlacement: TModelPlacement;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLasciareLeCoordinateConScalaDiDefaultECentroZero;
    [Test]
    procedure DovrebbeApplicareCentroScalaDelFileEScalaDelPosizionamento;
    [Test]
    procedure DovrebbeCambiareSegnoAllaZ;
    [Test]
    procedure DovrebbeConvertireIPuntiDiTexturaCambiandoSegnoAllaU;
    [Test]
    procedure DovrebbeTornareAiPuntiDiTexturaDelFile;
  end;

implementation

uses
  DelphiDoom.Models.I3d.Coordinates;

{ TTestModelsI3dCoordinates }

procedure TTestModelsI3dCoordinates.Setup;
begin
  FHeader := Default(TI3dHeader);
  FHeader.ScaleX := I3D_DEFAULT_SCALE;
  FHeader.ScaleY := I3D_DEFAULT_SCALE;
  FHeader.ScaleZ := I3D_DEFAULT_SCALE;
  FPlacement.ScaleX := 1.0;
  FPlacement.ScaleY := 1.0;
  FPlacement.ScaleZ := 1.0;
  FPlacement.OffsetX := 0.0;
  FPlacement.OffsetY := 0.0;
  FPlacement.OffsetZ := 0.0;
end;

procedure TTestModelsI3dCoordinates.DovrebbeLasciareLeCoordinateConScalaDiDefaultECentroZero;
begin
  Assert.AreEqual(Single(7), TI3dCoordinates.WorldX(FHeader, FPlacement, 7));
  Assert.AreEqual(Single(-8), TI3dCoordinates.WorldY(FHeader, FPlacement, -8));
end;

procedure TTestModelsI3dCoordinates.DovrebbeApplicareCentroScalaDelFileEScalaDelPosizionamento;
begin
  FHeader.CenterX := 100;
  FHeader.ScaleX := I3D_DEFAULT_SCALE * 2;
  FHeader.CenterY := -200;
  FHeader.ScaleY := 3000000;
  FPlacement.ScaleX := 0.5;
  FPlacement.OffsetX := 2.0;
  FPlacement.ScaleY := 2.0;
  FPlacement.OffsetY := 1.0;
  // (4 - 100) * 2 * 0.5 + 2
  Assert.AreEqual(Single(-94), TI3dCoordinates.WorldX(FHeader, FPlacement, 4));
  // the center goes to the offset
  Assert.AreEqual(Single(1), TI3dCoordinates.WorldY(FHeader, FPlacement, -200));
  Assert.IsTrue(Abs(200.0 * 3000000 / I3D_DEFAULT_SCALE * 2 + 1 -
    TI3dCoordinates.WorldY(FHeader, FPlacement, 0)) < 0.001);
end;

procedure TTestModelsI3dCoordinates.DovrebbeCambiareSegnoAllaZ;
begin
  FHeader.CenterZ := 300;
  FPlacement.OffsetZ := 5.0;
  Assert.AreEqual(Single(5), TI3dCoordinates.WorldZ(FHeader, FPlacement, 300));
  Assert.AreEqual(Single(-95), TI3dCoordinates.WorldZ(FHeader, FPlacement, 400));
  Assert.AreEqual(Single(105), TI3dCoordinates.WorldZ(FHeader, FPlacement, 200));
end;

procedure TTestModelsI3dCoordinates.DovrebbeConvertireIPuntiDiTexturaCambiandoSegnoAllaU;
var
  LU, LV: Single;
begin
  TI3dCoordinates.TextureToGl(16777216, -16777216, LU, LV);
  Assert.AreEqual(Single(-1), LU);
  Assert.AreEqual(Single(-1), LV);
  TI3dCoordinates.TextureToGl(0, 8388608, LU, LV);
  Assert.IsTrue(LU = 0, 'u is zero (minus zero)');
  Assert.AreEqual(Single(0.5), LV);
end;

procedure TTestModelsI3dCoordinates.DovrebbeTornareAiPuntiDiTexturaDelFile;
var
  LTextureX, LTextureY: Integer;
begin
  TI3dCoordinates.GlToTexture(-1.0, -1.0, LTextureX, LTextureY);
  Assert.AreEqual(16777216, LTextureX);
  Assert.AreEqual(-16777216, LTextureY);
  TI3dCoordinates.GlToTexture(0.25, 0.5, LTextureX, LTextureY);
  Assert.AreEqual(-4194304, LTextureX);
  Assert.AreEqual(8388608, LTextureY);
end;

end.

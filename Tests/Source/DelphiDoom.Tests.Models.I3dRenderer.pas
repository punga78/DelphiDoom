{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the drawing of I3D models      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dRenderer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Models.Types, DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.I3d.Intf, DelphiDoom.Tests.Models.I3dRecorder;

type
  /// <summary>
  ///   The calls to the target for a model, one case at a time (the whole drawing of the old RenderGL is
  ///   compared with the golden file in the tests of the reader)
  /// </summary>
  [TestFixture]
  [Category('models')]
  TTestModelsI3dRenderer = class(TObject)
  strict private
    FRenderer: II3dModelRenderer;
    FRecorder: TI3dRecorder;
    FTarget: II3dRenderTarget;
    function Identity: TModelPlacement;
    function CountOf(const APrefix: string): Integer;
    function ParseBytes(const ABytes: TBytes): II3dModel;
    function TriangleModel(const AMaterialKind: Integer; const AFaceCount: Integer): II3dModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDisegnareUnaFacciaPiattaComeUnTriangleFan;
    [Test]
    procedure DovrebbeUsareLaTexturaDelMaterialeEIlColoreBianco;
    [Test]
    procedure DovrebbeLegareUnaTexturaUnaSolaVoltaPerFacceConsecutive;
    [Test]
    procedure DovrebbeDisegnareBiancaUnaFacciaSenzaMateriale;
    [Test]
    procedure DovrebbeDareMezzaTrasparenzaAUnMaterialeTrasparente;
    [Test]
    procedure DovrebbeSaltareLeFacceNascosteELaFacciaSelezionata;
    [Test]
    procedure DovrebbeContareITriangoliDelleFacce;
    [Test]
    procedure DovrebbeGirareLeGommeAttornoAlLoroCentro;
    [Test]
    procedure DovrebbeFarSterzareSoloLeGommeAnteriori;
    [Test]
    procedure DovrebbeNonGirareLeGommeSenzaIlFlag;
    [Test]
    procedure DovrebbeRipristinareLaTexturaAllaFine;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Models.I3d.Factory, DelphiDoom.Models.I3d.Coordinates,
  DelphiDoom.Models.I3d.Palette, DelphiDoom.Tests.Models.I3dFileBuilder;

{ TTestModelsI3dRenderer }

procedure TTestModelsI3dRenderer.Setup;
begin
  FRenderer := TI3dFactory.CreateRenderer;
  FRecorder := TI3dRecorder.Create(True);
  FTarget := FRecorder;
end;

procedure TTestModelsI3dRenderer.TearDown;
begin
  FTarget := nil;
  FRecorder := nil;
  FRenderer := nil;
end;

function TTestModelsI3dRenderer.Identity: TModelPlacement;
begin
  Result.ScaleX := 1.0;
  Result.ScaleY := 1.0;
  Result.ScaleZ := 1.0;
  Result.OffsetX := 0.0;
  Result.OffsetY := 0.0;
  Result.OffsetZ := 0.0;
end;

function TTestModelsI3dRenderer.CountOf(const APrefix: string): Integer;
var
  LLine: string;
begin
  Result := 0;
  for LLine in FRecorder.Log do
    if LLine.StartsWith(APrefix) then
      Inc(Result);
end;

function TTestModelsI3dRenderer.ParseBytes(const ABytes: TBytes): II3dModel;
begin
  Result := TI3dFactory.CreateParser.Parse(ABytes);
end;

function TTestModelsI3dRenderer.TriangleModel(const AMaterialKind: Integer;
  const AFaceCount: Integer): II3dModel;
var
  LBuilder: TI3dFileBuilder;
  LIndex: Integer;
begin
  LBuilder := TI3dFileBuilder.Create;
  try
    LBuilder.SetScale(I3D_DEFAULT_SCALE, I3D_DEFAULT_SCALE, I3D_DEFAULT_SCALE);
    LBuilder.AddVertex(0, 0, 0);
    LBuilder.AddVertex(1, 0, 0);
    LBuilder.AddVertex(0, 2, 1);
    case AMaterialKind of
      0: LBuilder.AddMaterial(1, 0, 'FLAT', -1);
      1: LBuilder.AddMaterial(1, 0, 'TEX', 1);
      2: LBuilder.AddMaterial(1, I3D_MATERIAL_TRANSLUCENT, 'GLASS', -1);
    end;
    for LIndex := 1 to AFaceCount do
      LBuilder.AddFace(Ord(AMaterialKind >= 0) - 1, 0, [TI3dFileBuilder.Corner(0, -1, 0, 0),
        TI3dFileBuilder.Corner(1, -1, 16777216, 0), TI3dFileBuilder.Corner(2, -1, 0, -16777216)]);
    Result := ParseBytes(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestModelsI3dRenderer.DovrebbeDisegnareUnaFacciaPiattaComeUnTriangleFan;
var
  LModel: II3dModel;
begin
  LModel := TriangleModel(0, 1);
  Assert.AreEqual(1, FRenderer.Render(LModel, FTarget, Identity, -1, Default(TI3dTireState)));
  Assert.AreEqual('texturing False', FRecorder.Log[0]);
  // the palette index 1 is (0, 63, 0) of 6 bits
  Assert.AreEqual(Format('color %g %g %g %g', [0.5 / 64, 63.5 / 64, 0.5 / 64, 1.0]), FRecorder.Log[1]);
  Assert.AreEqual('begin 6', FRecorder.Log[2]);
  Assert.AreEqual('texcoord', FRecorder.Log[3]);
  Assert.AreEqual('vertex 0 0 0', FRecorder.Log[4]);
  Assert.AreEqual('vertex 1 0 0', FRecorder.Log[6]);
  // the z changes sign
  Assert.AreEqual('vertex 0 2 -1', FRecorder.Log[8]);
  Assert.AreEqual('end', FRecorder.Log[9]);
end;

procedure TTestModelsI3dRenderer.DovrebbeUsareLaTexturaDelMaterialeEIlColoreBianco;
var
  LModel: II3dModel;
begin
  LModel := TriangleModel(1, 1);
  FRenderer.Render(LModel, FTarget, Identity, -1, Default(TI3dTireState));
  Assert.AreEqual('texturing True', FRecorder.Log[0]);
  Assert.AreEqual(Format('color %g %g %g %g', [1.0, 1.0, 1.0, 1.0]), FRecorder.Log[1]);
  Assert.AreEqual('bind 0', FRecorder.Log[2]);
  Assert.AreEqual('begin 6', FRecorder.Log[3]);
end;

procedure TTestModelsI3dRenderer.DovrebbeLegareUnaTexturaUnaSolaVoltaPerFacceConsecutive;
var
  LModel: II3dModel;
begin
  LModel := TriangleModel(1, 3);
  FRenderer.Render(LModel, FTarget, Identity, -1, Default(TI3dTireState));
  Assert.AreEqual(1, CountOf('bind '), 'the same texture is bound once');
  Assert.AreEqual(3, CountOf('begin '));
end;

procedure TTestModelsI3dRenderer.DovrebbeDisegnareBiancaUnaFacciaSenzaMateriale;
var
  LModel: II3dModel;
begin
  LModel := TriangleModel(-1, 1);
  FRenderer.Render(LModel, FTarget, Identity, -1, Default(TI3dTireState));
  Assert.AreEqual('texturing False', FRecorder.Log[0]);
  Assert.AreEqual(Format('color %g %g %g %g', [1.0, 1.0, 1.0, 1.0]), FRecorder.Log[1]);
end;

procedure TTestModelsI3dRenderer.DovrebbeDareMezzaTrasparenzaAUnMaterialeTrasparente;
var
  LModel: II3dModel;
  LColor: TI3dColor3f;
begin
  LModel := TriangleModel(2, 1);
  FRenderer.Render(LModel, FTarget, Identity, -1, Default(TI3dTireState));
  LColor := TI3dPalette.Color3f(1);
  Assert.AreEqual(Format('color %g %g %g %g', [LColor.R, LColor.G, LColor.B, 0.5]), FRecorder.Log[1]);
end;

procedure TTestModelsI3dRenderer.DovrebbeSaltareLeFacceNascosteELaFacciaSelezionata;
var
  LModel: II3dModel;
  LCorrection: TI3dCorrection;
begin
  LModel := ParseBytes(TI3dFileBuilder.PlainModel);
  FRenderer.Render(LModel, FTarget, Identity, -1, Default(TI3dTireState));
  Assert.AreEqual(70, CountOf('begin '));

  LCorrection := Default(TI3dCorrection);
  LCorrection.Face := 4;
  LCorrection.Vertex := 0;
  LCorrection.Visible := False;
  LModel.ApplyCorrections([LCorrection]);
  FRecorder.Log.Clear;
  FRenderer.Render(LModel, FTarget, Identity, 7, Default(TI3dTireState));
  Assert.AreEqual(68, CountOf('begin '), 'the hidden face and the selected one are not drawn');
end;

procedure TTestModelsI3dRenderer.DovrebbeContareITriangoliDelleFacce;
var
  LModel: II3dModel;
begin
  // a triangle (1), a quad (2), a face with no vertexes (-2 as in the old code) and a triangle (1)
  LModel := ParseBytes(TI3dFileBuilder.SmallModel);
  Assert.AreEqual(2, FRenderer.Render(LModel, FTarget, Identity, -1, Default(TI3dTireState)));
end;

procedure TTestModelsI3dRenderer.DovrebbeGirareLeGommeAttornoAlLoroCentro;
var
  LModel: II3dModel;
  LState: TI3dTireState;
  LStart: Integer;
  LHeader: TI3dHeader;
  LX, LY, LZ: Single;
begin
  LModel := ParseBytes(TI3dFileBuilder.CarModel);
  LState := Default(TI3dTireState);
  LState.Rotation[0] := 30.0;
  LState.Angle := 15.0;
  FRenderer.Render(LModel, FTarget, Identity, -1, LState);
  Assert.AreEqual(64, CountOf('push'));
  Assert.AreEqual(64, CountOf('pop'));
  Assert.AreEqual(128, CountOf('translate'));

  LHeader := LModel.Header;
  LX := TI3dCoordinates.WorldX(LHeader, Identity, LModel.Tires[0].CenterX);
  LY := TI3dCoordinates.WorldY(LHeader, Identity, LModel.Tires[0].CenterY);
  LZ := TI3dCoordinates.WorldZ(LHeader, Identity, LModel.Tires[0].CenterZ);
  LStart := FRecorder.Log.IndexOf('push');
  Assert.AreEqual(Format('translate %g %g %g', [LX, LY, LZ]), FRecorder.Log[LStart + 1]);
  Assert.AreEqual('rotate 15 0 1 0', FRecorder.Log[LStart + 2]);
  Assert.AreEqual('rotate 30 1 0 0', FRecorder.Log[LStart + 3]);
  Assert.AreEqual(Format('translate %g %g %g', [-LX, -LY, -LZ]), FRecorder.Log[LStart + 4]);
end;

procedure TTestModelsI3dRenderer.DovrebbeFarSterzareSoloLeGommeAnteriori;
var
  LModel: II3dModel;
  LState: TI3dTireState;
begin
  LModel := ParseBytes(TI3dFileBuilder.CarModel);
  LState := Default(TI3dTireState);
  LState.Angle := 15.0;
  FRenderer.Render(LModel, FTarget, Identity, -1, LState);
  // 32 faces of the front tires turn two times, 32 of the rear tires once
  Assert.AreEqual(32 * 2 + 32, CountOf('rotate'));
  Assert.AreEqual(32, CountOf('rotate 15 0 1 0'));
end;

procedure TTestModelsI3dRenderer.DovrebbeNonGirareLeGommeSenzaIlFlag;
var
  LModel: II3dModel;
  LState: TI3dTireState;
begin
  LModel := ParseBytes(TI3dFileBuilder.PlainModel);
  LState := Default(TI3dTireState);
  LState.Angle := 15.0;
  LState.Rotation[0] := 40.0;
  FRenderer.Render(LModel, FTarget, Identity, -1, LState);
  Assert.AreEqual(0, CountOf('push'));
  Assert.AreEqual(0, CountOf('rotate'));
end;

procedure TTestModelsI3dRenderer.DovrebbeRipristinareLaTexturaAllaFine;
var
  LModel: II3dModel;
begin
  LModel := ParseBytes(TI3dFileBuilder.SmallModel);
  FRenderer.Render(LModel, FTarget, Identity, -1, Default(TI3dTireState));
  Assert.AreEqual('texturing True', FRecorder.Log[FRecorder.Log.Count - 2]);
  Assert.AreEqual('reset', FRecorder.Log[FRecorder.Log.Count - 1]);
end;

end.


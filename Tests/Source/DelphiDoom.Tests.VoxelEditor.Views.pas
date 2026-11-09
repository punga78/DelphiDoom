{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorViews (issue #167)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Views;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorViews = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeVedereUnVoxelDaOgniFaccia;
    [Test]
    procedure DovrebbeVedereSoloIlPrimoVoxelDelRaggio;
    [Test]
    procedure DovrebbeDarePerVuotaUnaVistaSenzaVoxel;
    [Test]
    procedure DovrebbeDipingereIlPrimoVoxelDelRaggio;
    [Test]
    procedure DovrebbeDipingereLUltimaCellaDoveIlRaggioNonIncontraNulla;
    [Test]
    procedure DovrebbeNonDipingereLaVistaDalBassoSeIlRaggioEVuoto;
    [Test]
    procedure DovrebbeDareProfonditaEIndiceDiUnaCellaVuota;
    [Test]
    procedure DovrebbeDareLaCellaDavantiAlPrimoVoxel;
    [Test]
    procedure DovrebbeDareUnaVistaVuotaSenzaVista;
    [Test]
    procedure DovrebbeTrovareLaCellaDelPrimoVoxelOQuellaInFondo;
    [Test]
    procedure DovrebbeTenereLeCoordinateDentroIlCubo;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Views;

{ TTestVoxelEditorViews }

procedure TTestVoxelEditorViews.Setup;
begin
  FModel := TVoxelEditorModel.Create(4);
  FModel.Put(1, 2, 3, 77);
end;

procedure TTestVoxelEditorViews.TearDown;
begin
  FModel.Free;
end;

procedure TTestVoxelEditorViews.DovrebbeVedereUnVoxelDaOgniFaccia;
begin
  // the pictures are indexed [i * 4 + j]
  Assert.AreEqual(Cardinal(77), TVoxelEditorViews.GetView(FModel, vevFront)[1 * 4 + 2]);
  Assert.AreEqual(Cardinal(77), TVoxelEditorViews.GetView(FModel, vevBack)[1 * 4 + 2]);
  Assert.AreEqual(Cardinal(77), TVoxelEditorViews.GetView(FModel, vevLeft)[(4 - 1 - 3) * 4 + 2]);
  Assert.AreEqual(Cardinal(77), TVoxelEditorViews.GetView(FModel, vevRight)[3 * 4 + 2]);
  Assert.AreEqual(Cardinal(77), TVoxelEditorViews.GetView(FModel, vevTop)[1 * 4 + (4 - 1 - 3)]);
  Assert.AreEqual(Cardinal(77), TVoxelEditorViews.GetView(FModel, vevDown)[1 * 4 + 3]);
end;

procedure TTestVoxelEditorViews.DovrebbeVedereSoloIlPrimoVoxelDelRaggio;
begin
  FModel.Put(1, 2, 0, 11);
  Assert.AreEqual(Cardinal(11), TVoxelEditorViews.GetView(FModel, vevFront)[1 * 4 + 2]);
  Assert.AreEqual(Cardinal(77), TVoxelEditorViews.GetView(FModel, vevBack)[1 * 4 + 2]);
end;

procedure TTestVoxelEditorViews.DovrebbeDarePerVuotaUnaVistaSenzaVoxel;
begin
  Assert.AreEqual(Cardinal(0), TVoxelEditorViews.GetView(FModel, vevFront)[0]);
  Assert.AreEqual(Cardinal(0), TVoxelEditorViews.GetView(FModel, vevDown)[0]);
  FModel.Clear;
  Assert.AreEqual(Cardinal(0), TVoxelEditorViews.GetView(FModel, vevFront)[1 * 4 + 2]);
  Assert.AreEqual(16, Integer(Length(TVoxelEditorViews.GetView(FModel, vevNone))));
end;

procedure TTestVoxelEditorViews.DovrebbeDipingereIlPrimoVoxelDelRaggio;
var
  LImage: TVoxelEditorImage;
begin
  SetLength(LImage, 16);
  LImage[1 * 4 + 2] := 5;
  FModel.Put(1, 2, 1, 9);
  TVoxelEditorViews.SetView(FModel, vevFront, LImage);
  Assert.AreEqual(Cardinal(5), FModel.Get(1, 2, 1));
  Assert.AreEqual(Cardinal(77), FModel.Get(1, 2, 3));
end;

procedure TTestVoxelEditorViews.DovrebbeDipingereLUltimaCellaDoveIlRaggioNonIncontraNulla;
var
  LImage: TVoxelEditorImage;
begin
  SetLength(LImage, 16);
  LImage[0] := 6;
  TVoxelEditorViews.SetView(FModel, vevFront, LImage);
  Assert.AreEqual(Cardinal(6), FModel.Get(0, 0, 3));
  FModel.Clear;
  TVoxelEditorViews.SetView(FModel, vevBack, LImage);
  Assert.AreEqual(Cardinal(6), FModel.Get(0, 0, 0));
end;

procedure TTestVoxelEditorViews.DovrebbeNonDipingereLaVistaDalBassoSeIlRaggioEVuoto;
var
  LImage: TVoxelEditorImage;
begin
  SetLength(LImage, 16);
  LImage[0] := 6;
  LImage[1 * 4 + 3] := 8;
  TVoxelEditorViews.SetView(FModel, vevDown, LImage);
  // the ray (0, 0) has no voxel and gets none; the ray of the voxel takes the color
  Assert.AreEqual(1, FModel.CountVoxels);
  Assert.AreEqual(Cardinal(8), FModel.Get(1, 2, 3));
end;

procedure TTestVoxelEditorViews.DovrebbeDareProfonditaEIndiceDiUnaCellaVuota;
var
  LDepth: TArray<TVoxelEditorDepthItem>;
begin
  LDepth := TVoxelEditorViews.GetDepthView(FModel, vevFront);
  Assert.AreEqual(Cardinal(4), LDepth[0].Depth);
  Assert.AreEqual(Cardinal(0), LDepth[0].Color);
  Assert.AreEqual(FModel.IndexOf(0, 0, 3), LDepth[0].Previous);
end;

procedure TTestVoxelEditorViews.DovrebbeDareLaCellaDavantiAlPrimoVoxel;
var
  LDepth: TArray<TVoxelEditorDepthItem>;
begin
  LDepth := TVoxelEditorViews.GetDepthView(FModel, vevFront);
  Assert.AreEqual(Cardinal(3), LDepth[1 * 4 + 2].Depth);
  Assert.AreEqual(Cardinal(77), LDepth[1 * 4 + 2].Color);
  Assert.AreEqual(FModel.IndexOf(1, 2, 2), LDepth[1 * 4 + 2].Previous);
  LDepth := TVoxelEditorViews.GetDepthView(FModel, vevBack);
  Assert.AreEqual(FModel.IndexOf(1, 2, 3), LDepth[1 * 4 + 2].Previous); // the voxel is at the border
end;

procedure TTestVoxelEditorViews.DovrebbeDareUnaVistaVuotaSenzaVista;
var
  LDepth: TArray<TVoxelEditorDepthItem>;
begin
  LDepth := TVoxelEditorViews.GetDepthView(FModel, vevNone);
  Assert.AreEqual(16, Integer(Length(LDepth)));
  Assert.AreEqual(-1, LDepth[5].Previous);
  Assert.AreEqual(Cardinal(4), LDepth[5].Depth);
end;

procedure TTestVoxelEditorViews.DovrebbeTrovareLaCellaDelPrimoVoxelOQuellaInFondo;
begin
  Assert.AreEqual(FModel.IndexOf(1, 2, 3), TVoxelEditorViews.DepthIndexAtXY(FModel, 1, 2, vevFront));
  Assert.AreEqual(FModel.IndexOf(0, 0, 3), TVoxelEditorViews.DepthIndexAtXY(FModel, 0, 0, vevFront));
  Assert.AreEqual(FModel.IndexOf(0, 0, 0), TVoxelEditorViews.DepthIndexAtXY(FModel, 0, 0, vevBack));
  Assert.AreEqual(FModel.IndexOf(3, 0, 3), TVoxelEditorViews.DepthIndexAtXY(FModel, 0, 0, vevLeft));
  Assert.AreEqual(FModel.IndexOf(0, 0, 0), TVoxelEditorViews.DepthIndexAtXY(FModel, 0, 0, vevRight));
  Assert.AreEqual(FModel.IndexOf(1, 2, 3), TVoxelEditorViews.DepthIndexAtXY(FModel, 1, 0, vevTop));
  Assert.AreEqual(FModel.IndexOf(1, 0, 0), TVoxelEditorViews.DepthIndexAtXY(FModel, 1, 0, vevDown));
end;

procedure TTestVoxelEditorViews.DovrebbeTenereLeCoordinateDentroIlCubo;
begin
  Assert.AreEqual(FModel.IndexOf(0, 0, 0), TVoxelEditorViews.DepthIndexAtXYZ(FModel, -5, -5, -5, vevFront));
  Assert.AreEqual(FModel.IndexOf(3, 3, 3), TVoxelEditorViews.DepthIndexAtXYZ(FModel, 9, 9, 9, vevBack));
  // the left view shows x reversed on z, the right one does not
  Assert.AreEqual(FModel.IndexOf(2, 1, 3), TVoxelEditorViews.DepthIndexAtXYZ(FModel, 0, 1, 2, vevLeft));
  Assert.AreEqual(FModel.IndexOf(2, 1, 0), TVoxelEditorViews.DepthIndexAtXYZ(FModel, 0, 1, 2, vevRight));
  Assert.AreEqual(FModel.IndexOf(1, 2, 3), TVoxelEditorViews.DepthIndexAtXYZ(FModel, 1, 0, 2, vevTop));
  Assert.AreEqual(FModel.IndexOf(1, 2, 3), TVoxelEditorViews.DepthIndexAtXYZ(FModel, 1, 3, 2, vevDown));
  Assert.AreEqual(-1, TVoxelEditorViews.DepthIndexAtXYZ(FModel, 1, 3, 2, vevNone));
  Assert.AreEqual(-1, TVoxelEditorViews.DepthIndexAtXY(FModel, 1, 3, vevNone));
end;

end.

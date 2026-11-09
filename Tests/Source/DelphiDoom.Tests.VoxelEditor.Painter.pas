{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorPainter (issue #167)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Painter;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model,
  DelphiDoom.VoxelEditor.Painter;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorPainter = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
    FPainter: TVoxelEditorPainter;
    FBeforeChange: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareIlModelloNil;
    [Test]
    procedure DovrebbeNonFareNienteSenzaPiano;
    [Test]
    procedure DovrebbeDipingereUnaCellaDiUnaSezione;
    [Test]
    procedure DovrebbeUsareIlColoreDelBottoneDestro;
    [Test]
    procedure DovrebbeAvvisareUnaVoltaPrimaDiCambiare;
    [Test]
    procedure DovrebbeTenereLeCoordinateDentroIlCubo;
    [Test]
    procedure DovrebbeDipingereSullaProfonditaDiPartenzaDelTratto;
    [Test]
    procedure DovrebbeDipingereLaCellaDelPrimoVoxelInUnaVista;
    [Test]
    procedure DovrebbeFareUnaLineaTraDuePunti;
    [Test]
    procedure DovrebbeCancellareLUltimoPuntoAncheSeIlTrattoEPiccolo;
    [Test]
    procedure DovrebbeAlzareSoloInUnaVistaEMaiConIlNero;
    [Test]
    procedure DovrebbeRiempireInUnaVista;
    [Test]
    procedure DovrebbeNonRiempireConLoStessoColore;
    [Test]
    procedure DovrebbeDareIlColoreDelPrimoVoxelInUnaVista;
    [Test]
    procedure DovrebbeDireDoveSiEESuCheColore;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Views;

procedure TTestVoxelEditorPainter.Setup;
begin
  FModel := TVoxelEditorModel.Create(8);
  FPainter := TVoxelEditorPainter.Create(FModel);
  FPainter.Zoom := 10;
  FPainter.Color1 := 11;
  FPainter.Color2 := 22;
  FBeforeChange := 0;
  FPainter.OnBeforeChange := procedure begin Inc(FBeforeChange); end;
end;

procedure TTestVoxelEditorPainter.TearDown;
begin
  FPainter.Free;
  FModel.Free;
end;

procedure TTestVoxelEditorPainter.DovrebbeRifiutareIlModelloNil;
begin
  Assert.WillRaise(procedure begin TVoxelEditorPainter.Create(nil); end, EArgumentNilException);
end;

procedure TTestVoxelEditorPainter.DovrebbeNonFareNienteSenzaPiano;
begin
  FPainter.Plane := TVoxelEditorPlane.OfView(vevNone);
  FPainter.MouseDown(vebLeft, 5, 5);
  FPainter.MouseMove(15, 15);
  FPainter.MouseUp;
  Assert.AreEqual(0, FModel.CountVoxels);
  Assert.AreEqual('', FPainter.StatusAt(5, 5));
end;

procedure TTestVoxelEditorPainter.DovrebbeDipingereUnaCellaDiUnaSezione;
begin
  FPainter.Plane := TVoxelEditorPlane.Slice(veaX, 2);
  FPainter.MouseDown(vebLeft, 35, 45);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(11), FModel.Get(2, 3, 4));
  FPainter.Plane := TVoxelEditorPlane.Slice(veaY, 2);
  FPainter.MouseDown(vebLeft, 35, 45);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(11), FModel.Get(3, 2, 4));
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 2);
  FPainter.MouseDown(vebLeft, 35, 45);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(11), FModel.Get(3, 4, 2));
  Assert.IsTrue(FPainter.Changed);
end;

procedure TTestVoxelEditorPainter.DovrebbeUsareIlColoreDelBottoneDestro;
begin
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 0);
  FPainter.MouseDown(vebRight, 5, 5);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(22), FModel.Get(0, 0, 0));
end;

procedure TTestVoxelEditorPainter.DovrebbeAvvisareUnaVoltaPrimaDiCambiare;
begin
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 0);
  FPainter.MouseDown(vebLeft, 5, 5);
  FPainter.MouseMove(25, 5);
  FPainter.MouseMove(45, 5);
  FPainter.MouseUp;
  Assert.AreEqual(1, FBeforeChange);
end;

procedure TTestVoxelEditorPainter.DovrebbeTenereLeCoordinateDentroIlCubo;
begin
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 0);
  FPainter.MouseDown(vebLeft, 500, 700);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(11), FModel.Get(7, 7, 0));
  FPainter.MouseDown(vebLeft, -5, -5);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(11), FModel.Get(0, 0, 0));
end;

// the old editor read the depths at the start of the stroke: a second click on the same cell of the view does not dig
// into the voxel that the first one made
procedure TTestVoxelEditorPainter.DovrebbeDipingereSullaProfonditaDiPartenzaDelTratto;
begin
  FModel.Put(2, 3, 5, 1);
  FPainter.Plane := TVoxelEditorPlane.OfView(vevFront);
  FPainter.RefreshDepth;
  FPainter.MouseDown(vebLeft, 25, 35);
  FPainter.MouseMove(25, 35);
  FPainter.MouseUp;
  Assert.AreEqual(1, FModel.CountVoxels);
  Assert.AreEqual(Cardinal(11), FModel.Get(2, 3, 5));
end;

procedure TTestVoxelEditorPainter.DovrebbeDipingereLaCellaDelPrimoVoxelInUnaVista;
begin
  FModel.Put(2, 3, 5, 1);
  FModel.Put(2, 3, 6, 2);
  FPainter.Plane := TVoxelEditorPlane.OfView(vevBack);
  FPainter.RefreshDepth;
  FPainter.MouseDown(vebLeft, 25, 35);
  FPainter.MouseUp;
  // from the back the first voxel is the one at z = 6
  Assert.AreEqual(Cardinal(11), FModel.Get(2, 3, 6));
  Assert.AreEqual(Cardinal(1), FModel.Get(2, 3, 5));
end;

procedure TTestVoxelEditorPainter.DovrebbeFareUnaLineaTraDuePunti;
begin
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 0);
  FPainter.MouseDown(vebLeft, 5, 5);
  FPainter.MouseMove(65, 5);
  FPainter.MouseUp;
  Assert.AreEqual(7, FModel.CountVoxels);
  Assert.AreEqual(Cardinal(11), FModel.Get(3, 0, 0));
  Assert.AreEqual(Cardinal(11), FModel.Get(6, 0, 0));
end;

procedure TTestVoxelEditorPainter.DovrebbeCancellareLUltimoPuntoAncheSeIlTrattoEPiccolo;
begin
  FModel.Put(1, 0, 0, 5);
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 0);
  FPainter.Tool := vetEraser;
  FPainter.MouseDown(vebLeft, 5, 5);
  FPainter.MouseMove(15, 5);
  FPainter.MouseUp;
  Assert.AreEqual(0, FModel.CountVoxels);
end;

procedure TTestVoxelEditorPainter.DovrebbeAlzareSoloInUnaVistaEMaiConIlNero;
begin
  FModel.Put(2, 3, 5, 1);
  FPainter.Tool := vetElevate;
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 0);
  FPainter.MouseDown(vebLeft, 25, 35);
  FPainter.MouseUp;
  Assert.AreEqual(1, FModel.CountVoxels);
  FPainter.Plane := TVoxelEditorPlane.OfView(vevFront);
  FPainter.RefreshDepth;
  FPainter.Color1 := 0;
  FPainter.MouseDown(vebLeft, 25, 35);
  FPainter.MouseUp;
  Assert.AreEqual(1, FModel.CountVoxels);
  FPainter.Color1 := 7;
  FPainter.MouseDown(vebLeft, 25, 35);
  FPainter.MouseMove(45, 35);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(7), FModel.Get(2, 3, 4));
  // along the stroke the rays have no voxel: the cell that is raised is the one at the end of the ray
  Assert.AreEqual(Cardinal(7), FModel.Get(3, 3, 7));
  Assert.AreEqual(Cardinal(7), FModel.Get(4, 3, 7));
end;

procedure TTestVoxelEditorPainter.DovrebbeRiempireInUnaVista;
begin
  FPainter.Tool := vetFloodFill;
  FPainter.Plane := TVoxelEditorPlane.OfView(vevFront);
  FPainter.RefreshDepth;
  FPainter.MouseDown(vebLeft, 5, 5);
  FPainter.MouseUp;
  // an empty view: the last cell of each ray takes the color
  Assert.AreEqual(64, FModel.CountVoxels);
  Assert.AreEqual(Cardinal(11), FModel.Get(4, 4, 7));
end;

procedure TTestVoxelEditorPainter.DovrebbeNonRiempireConLoStessoColore;
begin
  FPainter.Tool := vetFloodFill;
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 0);
  FPainter.Color1 := 0;
  FPainter.MouseDown(vebLeft, 5, 5);
  FPainter.MouseUp;
  Assert.AreEqual(0, FBeforeChange);
  Assert.IsFalse(FPainter.Changed);
end;

procedure TTestVoxelEditorPainter.DovrebbeDareIlColoreDelPrimoVoxelInUnaVista;
begin
  FModel.Put(2, 3, 5, 99);
  FPainter.Tool := vetColorPicker;
  FPainter.Plane := TVoxelEditorPlane.OfView(vevFront);
  FPainter.RefreshDepth;
  FPainter.MouseDown(vebRight, 25, 35);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(99), FPainter.Color2);
  Assert.AreEqual(Cardinal(11), FPainter.Color1);
  FPainter.Plane := TVoxelEditorPlane.Slice(veaX, 2);
  FPainter.MouseDown(vebLeft, 35, 55);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(99), FPainter.Color1);
  FPainter.Plane := TVoxelEditorPlane.Slice(veaY, 3);
  FPainter.MouseDown(vebLeft, 25, 55);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(99), FPainter.Color1);
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 5);
  FPainter.MouseDown(vebLeft, 25, 35);
  FPainter.MouseUp;
  Assert.AreEqual(Cardinal(99), FPainter.Color1);
  Assert.IsFalse(FPainter.Changed);
end;

procedure TTestVoxelEditorPainter.DovrebbeDireDoveSiEESuCheColore;
begin
  FModel.Put(2, 3, 5, $030201);
  FPainter.Plane := TVoxelEditorPlane.Slice(veaZ, 5);
  Assert.AreEqual('x=2, y=3, depth=5, color=(1, 2, 3)', FPainter.StatusAt(25, 35));
  FPainter.Plane := TVoxelEditorPlane.OfView(vevFront);
  FPainter.RefreshDepth;
  Assert.AreEqual('x=2, y=3, depth=5, color=(1, 2, 3)', FPainter.StatusAt(25, 35));
  FPainter.Plane := TVoxelEditorPlane.Slice(veaX, 2);
  Assert.AreEqual('x=3, y=5, depth=2, color=(1, 2, 3)', FPainter.StatusAt(35, 55));
  FPainter.Plane := TVoxelEditorPlane.Slice(veaY, 3);
  Assert.AreEqual('x=2, y=5, depth=3, color=(1, 2, 3)', FPainter.StatusAt(25, 55));
end;

end.

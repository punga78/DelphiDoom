{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorPlanes (issue #167)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Planes;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorPlanes = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLeTreSezioni;
    [Test]
    procedure DovrebbeLeggereUnaVista;
    [Test]
    procedure DovrebbeDareUnaPicturaVuotaSenzaPiano;
    [Test]
    procedure DovrebbeScrivereLeTreSezioni;
    [Test]
    procedure DovrebbeScrivereUnaVista;
    [Test]
    procedure DovrebbeDireDiNoSeNonCEIlPiano;
    [Test]
    procedure DovrebbeSvuotareUnPiano;
    [Test]
    procedure DovrebbeSaperSeUnPianoEValido;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Planes;

procedure TTestVoxelEditorPlanes.Setup;
begin
  FModel := TVoxelEditorModel.Create(4);
  FModel.Put(1, 2, 3, 77);
end;

procedure TTestVoxelEditorPlanes.TearDown;
begin
  FModel.Free;
end;

procedure TTestVoxelEditorPlanes.DovrebbeLeggereLeTreSezioni;
begin
  Assert.AreEqual(Cardinal(77), TVoxelEditorPlanes.Read(FModel, TVoxelEditorPlane.Slice(veaX, 1))[2 * 4 + 3]);
  Assert.AreEqual(Cardinal(77), TVoxelEditorPlanes.Read(FModel, TVoxelEditorPlane.Slice(veaY, 2))[1 * 4 + 3]);
  Assert.AreEqual(Cardinal(77), TVoxelEditorPlanes.Read(FModel, TVoxelEditorPlane.Slice(veaZ, 3))[1 * 4 + 2]);
  Assert.AreEqual(Cardinal(0), TVoxelEditorPlanes.Read(FModel, TVoxelEditorPlane.Slice(veaZ, 0))[1 * 4 + 2]);
end;

procedure TTestVoxelEditorPlanes.DovrebbeLeggereUnaVista;
begin
  Assert.AreEqual(Cardinal(77), TVoxelEditorPlanes.Read(FModel, TVoxelEditorPlane.OfView(vevFront))[1 * 4 + 2]);
end;

procedure TTestVoxelEditorPlanes.DovrebbeDareUnaPicturaVuotaSenzaPiano;
var
  LImage: TVoxelEditorImage;
begin
  LImage := TVoxelEditorPlanes.Read(FModel, TVoxelEditorPlane.OfView(vevNone));
  Assert.AreEqual(16, Integer(Length(LImage)));
  Assert.AreEqual(Cardinal(0), LImage[1 * 4 + 2]);
end;

procedure TTestVoxelEditorPlanes.DovrebbeScrivereLeTreSezioni;
var
  LImage: TVoxelEditorImage;
begin
  SetLength(LImage, 16);
  LImage[1 * 4 + 1] := 5;
  Assert.IsTrue(TVoxelEditorPlanes.Write(FModel, TVoxelEditorPlane.Slice(veaX, 2), LImage));
  Assert.AreEqual(Cardinal(5), FModel.Get(2, 1, 1));
  Assert.IsTrue(TVoxelEditorPlanes.Write(FModel, TVoxelEditorPlane.Slice(veaY, 2), LImage));
  Assert.AreEqual(Cardinal(5), FModel.Get(1, 2, 1));
  Assert.IsTrue(TVoxelEditorPlanes.Write(FModel, TVoxelEditorPlane.Slice(veaZ, 2), LImage));
  Assert.AreEqual(Cardinal(5), FModel.Get(1, 1, 2));
  // the plane is written whole: the cell that was in the plane y = 2 is gone
  Assert.AreEqual(Cardinal(0), FModel.Get(1, 2, 3));
  Assert.AreEqual(Cardinal(0), FModel.Get(2, 2, 2));
end;

procedure TTestVoxelEditorPlanes.DovrebbeScrivereUnaVista;
var
  LImage: TVoxelEditorImage;
begin
  SetLength(LImage, 16);
  LImage[1 * 4 + 2] := 9;
  Assert.IsTrue(TVoxelEditorPlanes.Write(FModel, TVoxelEditorPlane.OfView(vevFront), LImage));
  Assert.AreEqual(Cardinal(9), FModel.Get(1, 2, 3));
end;

procedure TTestVoxelEditorPlanes.DovrebbeDireDiNoSeNonCEIlPiano;
var
  LImage: TVoxelEditorImage;
begin
  SetLength(LImage, 16);
  Assert.IsFalse(TVoxelEditorPlanes.Write(FModel, TVoxelEditorPlane.OfView(vevNone), LImage));
  Assert.AreEqual(Cardinal(77), FModel.Get(1, 2, 3));
end;

procedure TTestVoxelEditorPlanes.DovrebbeSvuotareUnPiano;
begin
  TVoxelEditorPlanes.Erase(FModel, TVoxelEditorPlane.Slice(veaX, 1));
  Assert.AreEqual(0, FModel.CountVoxels);
end;

procedure TTestVoxelEditorPlanes.DovrebbeSaperSeUnPianoEValido;
begin
  Assert.IsTrue(TVoxelEditorPlane.Slice(veaX, 0).IsValid);
  Assert.IsTrue(TVoxelEditorPlane.OfView(vevTop).IsValid);
  Assert.IsFalse(TVoxelEditorPlane.OfView(vevNone).IsValid);
end;

end.

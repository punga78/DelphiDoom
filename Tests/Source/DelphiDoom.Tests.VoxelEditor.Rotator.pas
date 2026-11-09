{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorRotator (issue #167)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Rotator;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorRotator = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLasciareIlVoxelCongruoSenzaRotazione;
    [Test]
    procedure DovrebbeGirareDiNovantaGradi;
    [Test]
    procedure DovrebbeTenereLAltezzaDiOgniVoxel;
    [Test]
    procedure DovrebbeScartareIVoxelCheUsciDalCubo;
    [Test]
    procedure DovrebbeLasciareIlVoxelCongruoSenzaRotazioneInAltaQualita;
    [Test]
    procedure DovrebbeMediareIColoriInAltaQualita;
    [Test]
    procedure DovrebbeSvuotareUnCuboVuoto;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Rotator;

procedure TTestVoxelEditorRotator.Setup;
begin
  FModel := TVoxelEditorModel.Create(8);
end;

procedure TTestVoxelEditorRotator.TearDown;
begin
  FModel.Free;
end;

procedure TTestVoxelEditorRotator.DovrebbeLasciareIlVoxelCongruoSenzaRotazione;
begin
  FModel.Put(2, 3, 5, 9);
  TVoxelEditorRotator.Rotate(FModel, 0);
  Assert.AreEqual(1, FModel.CountVoxels);
  Assert.AreEqual(Cardinal(9), FModel.Get(2, 3, 5));
end;

procedure TTestVoxelEditorRotator.DovrebbeGirareDiNovantaGradi;
begin
  FModel.Put(2, 3, 5, 9);
  TVoxelEditorRotator.Rotate(FModel, Pi / 2);
  // each target cell (x, z) takes the cell (size - z, x): the voxel (a, b) lands on (x = b, z = size - a)
  Assert.AreEqual(1, FModel.CountVoxels);
  Assert.AreEqual(Cardinal(9), FModel.Get(5, 3, 6));
end;

procedure TTestVoxelEditorRotator.DovrebbeTenereLAltezzaDiOgniVoxel;
var
  LY: Integer;
begin
  for LY := 0 to 7 do
    FModel.Put(2, LY, 5, 9 + LY);
  TVoxelEditorRotator.Rotate(FModel, Pi / 2);
  for LY := 0 to 7 do
    Assert.AreEqual(Cardinal(9 + LY), FModel.Get(5, LY, 6));
end;

procedure TTestVoxelEditorRotator.DovrebbeScartareIVoxelCheUsciDalCubo;
begin
  FModel.Put(0, 0, 0, 9);
  TVoxelEditorRotator.Rotate(FModel, Pi / 2);
  // the cell (0, 0) takes (size - 0, 0) = outside the cube; the cell (0, 0) went to (0, size): outside
  Assert.AreEqual(0, FModel.CountVoxels);
end;

procedure TTestVoxelEditorRotator.DovrebbeLasciareIlVoxelCongruoSenzaRotazioneInAltaQualita;
begin
  FModel.Put(2, 3, 5, $102030);
  TVoxelEditorRotator.RotateHighQuality(FModel, 0);
  Assert.AreEqual(1, FModel.CountVoxels);
  Assert.AreEqual(Cardinal($102030), FModel.Get(2, 3, 5));
end;

procedure TTestVoxelEditorRotator.DovrebbeMediareIColoriInAltaQualita;
var
  LX, LZ: Integer;
begin
  // a lone voxel has too little weight in the mean of the 3 x 3 blocks and goes away; a block of 3 x 3 keeps its middle
  for LX := 2 to 4 do
    for LZ := 2 to 4 do
      FModel.Put(LX, 3, LZ, $000000FF);
  TVoxelEditorRotator.RotateHighQuality(FModel, Pi / 8);
  Assert.AreEqual(Cardinal($000000FF), FModel.Get(3, 3, 3));
end;

procedure TTestVoxelEditorRotator.DovrebbeSvuotareUnCuboVuoto;
begin
  TVoxelEditorRotator.Rotate(FModel, 1);
  TVoxelEditorRotator.RotateHighQuality(FModel, 1);
  Assert.AreEqual(0, FModel.CountVoxels);
end;

end.

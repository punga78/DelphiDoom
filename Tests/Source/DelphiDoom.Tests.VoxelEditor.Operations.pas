{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorOperations (issue #167)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Operations;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorOperations = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
    procedure Fill(AColor: Cardinal);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeSvuotareSoloIlVoxelCircondatoDaTuttiIVicini;
    [Test]
    procedure DovrebbeLasciareIlCuboSeNonCeNienteDaTogliere;
    [Test]
    procedure DovrebbeTagliareLAltezzaTenendoLaPrimaCella;
    [Test]
    procedure DovrebbeLasciareIlVoxelSeIlTaglioEIlPienoIntervallo;
    [Test]
    procedure DovrebbeScambiareIDueEstremiDelTaglio;
    [Test]
    procedure DovrebbeStringereLAltezza;
    [Test]
    procedure DovrebbeFermarsiAllUltimaRigaStringendoVicinoA255;
    [Test]
    procedure DovrebbeFareLaScalaDiGrigiDalCanaleRosso;
    [Test]
    procedure DovrebbeNonCambiareUnGrigioGia;
    [Test]
    procedure DovrebbeContareIColoriDiversi;
    [Test]
    procedure DovrebbeRidurreAUnaPalettaSenzaMaiIlNero;
    [Test]
    procedure DovrebbeDareIlColoreDellaTexturaAllaColonna;
    [Test]
    procedure DovrebbeFareLaMappaDelleAltezze;
    [Test]
    procedure DovrebbeScegliereLaDimensioneDelCuboPerUnaImmagine;
    [Test]
    procedure DovrebbeDareIlGrigioDiUnColore;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Operations,
  DelphiDoom.VoxelEditor.Palettes;

procedure TTestVoxelEditorOperations.Setup;
begin
  FModel := TVoxelEditorModel.Create(4);
end;

procedure TTestVoxelEditorOperations.TearDown;
begin
  FModel.Free;
end;

procedure TTestVoxelEditorOperations.Fill(AColor: Cardinal);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FModel.Cells) do
    FModel.Cells[LIndex] := AColor;
end;

procedure TTestVoxelEditorOperations.DovrebbeSvuotareSoloIlVoxelCircondatoDaTuttiIVicini;
begin
  Fill(5);
  TVoxelEditorOperations.RemoveNonVisible(FModel);
  // inside a cube of 4 only the four cells (1..2, 1..2, 1..2) can have six neighbors, and all do
  Assert.AreEqual(64 - 8, FModel.CountVoxels);
  Assert.AreEqual(Cardinal(0), FModel.Get(1, 1, 1));
  Assert.AreEqual(Cardinal(5), FModel.Get(0, 1, 1));
end;

procedure TTestVoxelEditorOperations.DovrebbeLasciareIlCuboSeNonCeNienteDaTogliere;
begin
  FModel.Put(1, 1, 1, 5);
  TVoxelEditorOperations.RemoveNonVisible(FModel);
  Assert.AreEqual(1, FModel.CountVoxels);
end;

procedure TTestVoxelEditorOperations.DovrebbeTagliareLAltezzaTenendoLaPrimaCella;
begin
  FModel.Put(0, 0, 0, 1);
  FModel.Put(0, 1, 0, 2);
  FModel.Put(0, 3, 0, 3);
  // the heights 64 and 191 of 256 are the rows 1 and 3 of 4 (2.99 is rounded)
  TVoxelEditorOperations.CropHeight(FModel, 64, 191);
  Assert.AreEqual(Cardinal(0), FModel.Get(0, 0, 0));
  Assert.AreEqual(Cardinal(1), FModel.Get(0, 1, 0));
  Assert.AreEqual(Cardinal(3), FModel.Get(0, 3, 0));
end;

procedure TTestVoxelEditorOperations.DovrebbeLasciareIlVoxelSeIlTaglioEIlPienoIntervallo;
begin
  FModel.Put(0, 0, 0, 1);
  TVoxelEditorOperations.CropHeight(FModel, 0, 255);
  TVoxelEditorOperations.CropHeight(FModel, 255, 0);
  TVoxelEditorOperations.ShrinkHeight(FModel, 0, 255);
  TVoxelEditorOperations.ShrinkHeight(FModel, 255, 0);
  Assert.AreEqual(Cardinal(1), FModel.Get(0, 0, 0));
end;

procedure TTestVoxelEditorOperations.DovrebbeScambiareIDueEstremiDelTaglio;
begin
  FModel.Put(0, 0, 0, 1);
  FModel.Put(0, 3, 0, 3);
  TVoxelEditorOperations.CropHeight(FModel, 191, 64);
  Assert.AreEqual(Cardinal(1), FModel.Get(0, 1, 0));
  Assert.AreEqual(Cardinal(3), FModel.Get(0, 3, 0));
end;

procedure TTestVoxelEditorOperations.DovrebbeStringereLAltezza;
begin
  FModel.Reset(16);
  FModel.Put(0, 0, 0, 1);
  FModel.Put(0, 15, 0, 2);
  TVoxelEditorOperations.ShrinkHeight(FModel, 0, 127);
  Assert.AreEqual(Cardinal(1), FModel.Get(0, 0, 0));
  // the column is 16 cells squeezed in half: the row 15 goes to Round(15 * 127 / 256) = 7
  Assert.AreEqual(Cardinal(2), FModel.Get(0, 7, 0));
end;

procedure TTestVoxelEditorOperations.DovrebbeFermarsiAllUltimaRigaStringendoVicinoA255;
begin
  // the old code wrote one cell after the last row of the cube (index 16 of 16): the voxel goes to the last row
  FModel.Reset(16);
  FModel.Put(0, 2, 0, 3);
  FModel.Put(0, 7, 0, 4);
  TVoxelEditorOperations.ShrinkHeight(FModel, 255, 255);
  Assert.AreEqual(Cardinal(3), FModel.Get(0, 15, 0));
  Assert.AreEqual(1, FModel.CountVoxels);
end;

procedure TTestVoxelEditorOperations.DovrebbeFareLaScalaDiGrigiDalCanaleRosso;
begin
  FModel.Put(0, 0, 0, $FF0064);
  FModel.Put(1, 0, 0, $010000);
  FModel.Put(2, 0, 0, $000000FF);
  Assert.IsTrue(TVoxelEditorOperations.ToGrayScale(FModel));
  // the old command took the red channel (the low byte) for the three
  Assert.AreEqual(Cardinal($646464), FModel.Get(0, 0, 0));
  // a gray of 0 would be "no voxel": it becomes 1
  Assert.AreEqual(Cardinal($010101), FModel.Get(1, 0, 0));
  Assert.AreEqual(Cardinal($FFFFFF), FModel.Get(2, 0, 0));
end;

procedure TTestVoxelEditorOperations.DovrebbeNonCambiareUnGrigioGia;
begin
  FModel.Put(0, 0, 0, $808080);
  Assert.IsFalse(TVoxelEditorOperations.ToGrayScale(FModel));
  Assert.IsFalse(TVoxelEditorOperations.ToGrayScale(FModel));
end;

procedure TTestVoxelEditorOperations.DovrebbeContareIColoriDiversi;
begin
  Assert.AreEqual(0, TVoxelEditorOperations.CountColors(FModel));
  FModel.Put(0, 0, 0, 5);
  FModel.Put(1, 0, 0, 5);
  FModel.Put(2, 0, 0, 6);
  Assert.AreEqual(2, TVoxelEditorOperations.CountColors(FModel));
end;

procedure TTestVoxelEditorOperations.DovrebbeRidurreAUnaPalettaSenzaMaiIlNero;
var
  LPalette: TVoxelEditorPalette;
begin
  LPalette := TVoxelEditorPalettes.Gray;
  FModel.Put(0, 0, 0, $010000);
  FModel.Put(1, 0, 0, $808080);
  Assert.IsTrue(TVoxelEditorOperations.ApplyPalette(FModel, LPalette));
  // 0 is "no voxel": the nearest color of the gray ramp is black, it becomes 1
  Assert.AreEqual(Cardinal(1), FModel.Get(0, 0, 0));
  Assert.AreEqual(Cardinal($808080), FModel.Get(1, 0, 0));
  FModel.Put(0, 0, 0, 0);
  Assert.IsFalse(TVoxelEditorOperations.ApplyPalette(FModel, LPalette));
end;

procedure TTestVoxelEditorOperations.DovrebbeDareIlColoreDellaTexturaAllaColonna;
var
  LImage: TVoxelEditorImage;
begin
  SetLength(LImage, 16);
  LImage[1 * 4 + 2] := $0A0B0C;
  FModel.Put(1, 0, 2, 9);
  FModel.Put(1, 3, 2, 9);
  FModel.Put(1, 3, 3, 9);
  TVoxelEditorOperations.ApplyTerrainTexture(FModel, LImage);
  Assert.AreEqual(Cardinal($0A0B0C), FModel.Get(1, 0, 2));
  Assert.AreEqual(Cardinal($0A0B0C), FModel.Get(1, 3, 2));
  // the texture is black there: 1
  Assert.AreEqual(VOXEL_EDITOR_NEAR_BLACK, FModel.Get(1, 3, 3));
  Assert.AreEqual(Cardinal(0), FModel.Get(2, 3, 3));
end;

procedure TTestVoxelEditorOperations.DovrebbeFareLaMappaDelleAltezze;
var
  LImage: TVoxelEditorImage;
  LIndex: Integer;
begin
  FModel.Reset(16);
  SetLength(LImage, 256);
  for LIndex := 0 to 255 do
    LImage[LIndex] := $FFFFFF;
  LImage[5 * 16 + 5] := 0;
  TVoxelEditorOperations.BuildHeightmap(FModel, LImage);
  // white is the highest column (the whole height); black is one cell high, colored 1
  Assert.AreEqual(Cardinal($FFFFFF), FModel.Get(0, 0, 0));
  Assert.AreEqual(Cardinal($FFFFFF), FModel.Get(0, 15, 0));
  Assert.AreEqual(VOXEL_EDITOR_NEAR_BLACK, FModel.Get(5, 15, 5));
  Assert.AreEqual(Cardinal(0), FModel.Get(5, 14, 5));
  // the cells inside the mass are removed
  Assert.AreEqual(Cardinal(0), FModel.Get(1, 7, 1));
end;

procedure TTestVoxelEditorOperations.DovrebbeScegliereLaDimensioneDelCuboPerUnaImmagine;
begin
  Assert.AreEqual(32, TVoxelEditorOperations.HeightmapSize(20, 30));
  Assert.AreEqual(64, TVoxelEditorOperations.HeightmapSize(64, 3));
  Assert.AreEqual(256, TVoxelEditorOperations.HeightmapSize(1000, 5));
  Assert.AreEqual(1, TVoxelEditorOperations.HeightmapSize(1, 1));
end;

procedure TTestVoxelEditorOperations.DovrebbeDareIlGrigioDiUnColore;
begin
  Assert.AreEqual(0, TVoxelEditorOperations.Gray256(0));
  Assert.AreEqual(255, TVoxelEditorOperations.Gray256($FFFFFF));
  Assert.AreEqual(3, TVoxelEditorOperations.Gray256($000306)); // (6 + 3 + 0) / 3
end;

end.

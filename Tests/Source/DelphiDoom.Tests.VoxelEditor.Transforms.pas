{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorTransforms (issue #167)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Transforms;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorTransforms = class(TObject)
  strict private
    FImage: TVoxelEditorImage;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeSpecchiareInOrizzontale;
    [Test]
    procedure DovrebbeSpecchiareInVerticale;
    [Test]
    procedure DovrebbeGirareInSensoAntiorario;
    [Test]
    procedure DovrebbeGirareInSensoOrario;
    [Test]
    procedure DovrebbeTornareIndietroConLaRotazioneContraria;
    [Test]
    procedure DovrebbeTornareAllOriginaleDopoQuattroRotazioni;
    [Test]
    procedure DovrebbeTornareAllOriginaleDopoDueSpecchiate;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Transforms;

procedure TTestVoxelEditorTransforms.Setup;
var
  LIndex: Integer;
begin
  SetLength(FImage, 9);
  for LIndex := 0 to 8 do
    FImage[LIndex] := LIndex + 1; // the pixel (i, j) is i * 3 + j + 1
end;

procedure TTestVoxelEditorTransforms.DovrebbeSpecchiareInOrizzontale;
var
  LResult: TVoxelEditorImage;
begin
  LResult := TVoxelEditorTransforms.FlipHorizontal(FImage, 3);
  Assert.AreEqual(Cardinal(7), LResult[0]);
  Assert.AreEqual(Cardinal(5), LResult[4]);
  Assert.AreEqual(Cardinal(3), LResult[8]);
end;

procedure TTestVoxelEditorTransforms.DovrebbeSpecchiareInVerticale;
var
  LResult: TVoxelEditorImage;
begin
  LResult := TVoxelEditorTransforms.FlipVertical(FImage, 3);
  Assert.AreEqual(Cardinal(3), LResult[0]);
  Assert.AreEqual(Cardinal(5), LResult[4]);
  Assert.AreEqual(Cardinal(7), LResult[8]);
end;

procedure TTestVoxelEditorTransforms.DovrebbeGirareInSensoAntiorario;
var
  LResult: TVoxelEditorImage;
begin
  // the pixel (x, y) goes to (y, size - 1 - x)
  LResult := TVoxelEditorTransforms.RotateCounterClockwise(FImage, 3);
  Assert.AreEqual(Cardinal(1), LResult[0 * 3 + 2]);
  Assert.AreEqual(Cardinal(9), LResult[2 * 3 + 0]);
  Assert.AreEqual(Cardinal(5), LResult[4]);
end;

procedure TTestVoxelEditorTransforms.DovrebbeGirareInSensoOrario;
var
  LResult: TVoxelEditorImage;
begin
  // the pixel (x, y) goes to (size - 1 - y, x)
  LResult := TVoxelEditorTransforms.RotateClockwise(FImage, 3);
  Assert.AreEqual(Cardinal(1), LResult[2 * 3 + 0]);
  Assert.AreEqual(Cardinal(9), LResult[0 * 3 + 2]);
end;

procedure TTestVoxelEditorTransforms.DovrebbeTornareIndietroConLaRotazioneContraria;
begin
  Assert.AreEqual(Cardinal(1),
    TVoxelEditorTransforms.RotateClockwise(TVoxelEditorTransforms.RotateCounterClockwise(FImage, 3), 3)[0]);
  Assert.AreEqual(Cardinal(8),
    TVoxelEditorTransforms.RotateCounterClockwise(TVoxelEditorTransforms.RotateClockwise(FImage, 3), 3)[7]);
end;

procedure TTestVoxelEditorTransforms.DovrebbeTornareAllOriginaleDopoQuattroRotazioni;
var
  LResult: TVoxelEditorImage;
  LIndex: Integer;
begin
  LResult := FImage;
  for LIndex := 1 to 4 do
    LResult := TVoxelEditorTransforms.RotateClockwise(LResult, 3);
  for LIndex := 0 to 8 do
    Assert.AreEqual(FImage[LIndex], LResult[LIndex]);
end;

procedure TTestVoxelEditorTransforms.DovrebbeTornareAllOriginaleDopoDueSpecchiate;
var
  LIndex: Integer;
  LResult: TVoxelEditorImage;
begin
  LResult := TVoxelEditorTransforms.FlipHorizontal(TVoxelEditorTransforms.FlipHorizontal(FImage, 3), 3);
  for LIndex := 0 to 8 do
    Assert.AreEqual(FImage[LIndex], LResult[LIndex]);
  LResult := TVoxelEditorTransforms.FlipVertical(TVoxelEditorTransforms.FlipVertical(FImage, 3), 3);
  for LIndex := 0 to 8 do
    Assert.AreEqual(FImage[LIndex], LResult[LIndex]);
end;

end.

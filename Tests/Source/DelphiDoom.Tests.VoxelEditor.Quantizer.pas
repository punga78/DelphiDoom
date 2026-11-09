{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorQuantizer (issue #167)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Quantizer;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorQuantizer = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
    procedure FillWithManyColors;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLaPalettaEsattaSeIColoriSonoPochi;
    [Test]
    procedure DovrebbeRifiutarePiuDi256Colori;
    [Test]
    procedure DovrebbeRidurreIColoriAlNumeroChiesto;
    [Test]
    procedure DovrebbeDareUnaPalettaDeiColoriRidotti;
    [Test]
    procedure DovrebbePoterRidurreDiNuovoNellaStessaSessione;
    [Test]
    procedure DovrebbeNonDareMaiZeroComeColore;
    [Test]
    procedure DovrebbeTenereUnColoreVicinoAQuelloDiPartenza;
    [Test]
    procedure DovrebbeNonCambiareUnCuboVuoto;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Quantizer,
  DelphiDoom.VoxelEditor.Operations;

procedure TTestVoxelEditorQuantizer.Setup;
begin
  FModel := TVoxelEditorModel.Create(16);
end;

procedure TTestVoxelEditorQuantizer.TearDown;
begin
  FModel.Free;
end;

procedure TTestVoxelEditorQuantizer.FillWithManyColors;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2999 do
    FModel.Cells[LIndex] := Cardinal((LIndex * 2654435) and $FFFFFF) or 1;
end;

procedure TTestVoxelEditorQuantizer.DovrebbeDareLaPalettaEsattaSeIColoriSonoPochi;
var
  LPalette: TVoxelEditorPalette;
begin
  FillChar(LPalette, SizeOf(LPalette), 0);
  FModel.Put(0, 0, 0, 30);
  FModel.Put(0, 0, 1, 20);
  FModel.Put(0, 0, 2, 30);
  Assert.IsTrue(TVoxelEditorQuantizer.GetPalette(FModel, 255, LPalette));
  // in the order that the colors are met
  Assert.AreEqual(Cardinal(30), LPalette[0]);
  Assert.AreEqual(Cardinal(20), LPalette[1]);
  Assert.AreEqual(Cardinal(0), LPalette[2]);
end;

procedure TTestVoxelEditorQuantizer.DovrebbeRifiutarePiuDi256Colori;
var
  LPalette: TVoxelEditorPalette;
begin
  Assert.IsFalse(TVoxelEditorQuantizer.GetPalette(FModel, 257, LPalette));
end;

procedure TTestVoxelEditorQuantizer.DovrebbeRidurreIColoriAlNumeroChiesto;
begin
  FillWithManyColors;
  Assert.IsTrue(TVoxelEditorOperations.CountColors(FModel) > 255);
  TVoxelEditorQuantizer.Quantize(FModel, 255);
  Assert.IsTrue(TVoxelEditorOperations.CountColors(FModel) <= 255);
  Assert.AreEqual(3000, FModel.CountVoxels);
end;

procedure TTestVoxelEditorQuantizer.DovrebbeDareUnaPalettaDeiColoriRidotti;
var
  LPalette: TVoxelEditorPalette;
  LIndex, LUsed: Integer;
begin
  FillWithManyColors;
  FillChar(LPalette, SizeOf(LPalette), 0);
  Assert.IsTrue(TVoxelEditorQuantizer.GetPalette(FModel, 16, LPalette));
  LUsed := 0;
  for LIndex := 0 to 255 do
    if LPalette[LIndex] <> 0 then
      Inc(LUsed);
  Assert.IsTrue((LUsed >= 1) and (LUsed <= 16));
end;

// the old code did not reset its pool of nodes after the first reduction: the second one of a session crashed
procedure TTestVoxelEditorQuantizer.DovrebbePoterRidurreDiNuovoNellaStessaSessione;
var
  LRound: Integer;
begin
  for LRound := 1 to 3 do
  begin
    FillWithManyColors;
    TVoxelEditorQuantizer.Quantize(FModel, 100);
    Assert.IsTrue(TVoxelEditorOperations.CountColors(FModel) <= 100);
  end;
end;

procedure TTestVoxelEditorQuantizer.DovrebbeNonDareMaiZeroComeColore;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 999 do
    FModel.Cells[LIndex] := Cardinal(LIndex mod 7 + 1); // near black colors
  TVoxelEditorQuantizer.Quantize(FModel, 2);
  for LIndex := 0 to 999 do
    Assert.AreNotEqual(Cardinal(0), FModel.Cells[LIndex]);
end;

procedure TTestVoxelEditorQuantizer.DovrebbeTenereUnColoreVicinoAQuelloDiPartenza;
var
  LIndex: Integer;
begin
  FillWithManyColors;
  FModel.Put(15, 15, 15, $0000FF);
  TVoxelEditorQuantizer.Quantize(FModel, 255);
  LIndex := FModel.Get(15, 15, 15) and $FF;
  Assert.IsTrue(LIndex > 128, 'the red channel stays red');
end;

procedure TTestVoxelEditorQuantizer.DovrebbeNonCambiareUnCuboVuoto;
begin
  TVoxelEditorQuantizer.Quantize(FModel, 255);
  Assert.AreEqual(0, FModel.CountVoxels);
end;

end.

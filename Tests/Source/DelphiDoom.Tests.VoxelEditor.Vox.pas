{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorVoxFormat (issue #167)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Vox;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorVoxFormat = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereUnCuboConIlLatoPiuGrande;
    [Test]
    procedure DovrebbeMetterePiuVoxelAlCentro;
    [Test]
    procedure DovrebbeRifiutareLatiFuoriDaiLimiti;
    [Test]
    procedure DovrebbeRifiutareDatiPiuCortiDelleDimensioni;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaPaletta;
    [Test]
    procedure DovrebbeScrivereIlFileConLaPalettaDeiColoriUsati;
    [Test]
    procedure DovrebbeRileggereCioCheHaScritto;
    [Test]
    procedure DovrebbeRidurreA255ColoriConLOctree;
    [Test]
    procedure DovrebbeTogliereUnaFilaAUnCuboDi256;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Format.Vox,
  DelphiDoom.Tests.VoxelEditor.Scenarios;

procedure TTestVoxelEditorVoxFormat.Setup;
begin
  FModel := TVoxelEditorModel.Create(1);
end;

procedure TTestVoxelEditorVoxFormat.TearDown;
begin
  FModel.Free;
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeLeggereUnCuboConIlLatoPiuGrande;
begin
  TVoxelEditorVoxFormat.Read(TVoxelScenarios.VoxBytes(1), FModel); // 10 x 6 x 12
  Assert.AreEqual(12, FModel.Size);
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeMetterePiuVoxelAlCentro;
begin
  TVoxelEditorVoxFormat.Read(TVoxelScenarios.VoxBytes(4), FModel); // 1 x 5 x 2
  Assert.AreEqual(5, FModel.Size);
  Assert.IsTrue(FModel.CountVoxels > 0);
  // x has 1 cell in 5: it is at the middle, 2
  Assert.AreEqual(Cardinal(0), FModel.Get(0, 0, 0));
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeRifiutareLatiFuoriDaiLimiti;
var
  LBytes: TBytes;
begin
  LBytes := TVoxelScenarios.VoxBytes(0);
  PInteger(@LBytes[0])^ := 0;
  Assert.WillRaise(procedure begin TVoxelEditorVoxFormat.Read(LBytes, FModel); end, EVoxelEditorException);
  PInteger(@LBytes[0])^ := 257;
  Assert.WillRaise(procedure begin TVoxelEditorVoxFormat.Read(LBytes, FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeRifiutareDatiPiuCortiDelleDimensioni;
var
  LBytes: TBytes;
begin
  LBytes := TVoxelScenarios.VoxBytes(0);
  PInteger(@LBytes[0])^ := 100;
  Assert.WillRaise(procedure begin TVoxelEditorVoxFormat.Read(LBytes, FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeRifiutareUnFileSenzaPaletta;
begin
  Assert.WillRaise(procedure begin TVoxelEditorVoxFormat.Read(TBytes.Create(1, 0, 0, 0), FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeScrivereIlFileConLaPalettaDeiColoriUsati;
var
  LBytes: TBytes;
begin
  FModel.Reset(4);
  FModel.Put(1, 2, 3, $040302); // R = 2, G = 3, B = 4
  LBytes := TVoxelEditorVoxFormat.Write(FModel);
  Assert.AreEqual(12 + 64 + 768, Integer(Length(LBytes)));
  Assert.AreEqual(4, Integer(PInteger(@LBytes[0])^));
  // the first color of the palette is the color of the voxel
  Assert.AreEqual(2, Integer(LBytes[12 + 64]));
  Assert.AreEqual(3, Integer(LBytes[12 + 64 + 1]));
  Assert.AreEqual(4, Integer(LBytes[12 + 64 + 2]));
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeRileggereCioCheHaScritto;
var
  LRead: TVoxelEditorModel;
begin
  FModel.Reset(4);
  FModel.Put(1, 2, 3, $040302);
  FModel.Put(0, 0, 0, $FFFFFF);
  LRead := TVoxelEditorModel.Create(1);
  try
    TVoxelEditorVoxFormat.Read(TVoxelEditorVoxFormat.Write(FModel), LRead);
    Assert.AreEqual(4, LRead.Size);
    Assert.AreEqual(2, LRead.CountVoxels);
    // a palette whose largest channel is not 255 would be stretched: the white keeps it as it is
    Assert.AreEqual(Cardinal($040302), LRead.Get(1, 2, 3));
    Assert.AreEqual(Cardinal($FFFFFF), LRead.Get(0, 0, 0));
  finally
    LRead.Free;
  end;
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeRidurreA255ColoriConLOctree;
var
  LIndex: Integer;
  LBytes: TBytes;
begin
  FModel.Reset(16);
  for LIndex := 0 to 1999 do
    FModel.Cells[LIndex] := Cardinal(LIndex * 7919 + 1) and $FFFFFF or 1;
  LBytes := TVoxelEditorVoxFormat.Write(FModel);
  Assert.AreEqual(12 + 16 * 16 * 16 + 768, Integer(Length(LBytes)));
end;

procedure TTestVoxelEditorVoxFormat.DovrebbeTogliereUnaFilaAUnCuboDi256;
var
  LBytes: TBytes;
begin
  FModel.Reset(256);
  FModel.Put(255, 255, 255, 5);
  LBytes := TVoxelEditorVoxFormat.Write(FModel);
  // the format holds up to 255
  Assert.AreEqual(255, Integer(PInteger(@LBytes[0])^));
  Assert.AreEqual(12 + 255 * 255 * 255 + 768, Integer(Length(LBytes)));
end;

end.

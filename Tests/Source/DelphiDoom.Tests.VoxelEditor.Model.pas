{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorModel (issue #167)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Model;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorModel = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeCrearsiVuotoDellaDimensioneChiesta;
    [Test]
    procedure DovrebbeRifiutareDimensioniFuoriDa1A256;
    [Test]
    procedure DovrebbeLeggereEScrivereUnaCella;
    [Test]
    procedure DovrebbeUsareLIndiceXPoiYPoiZ;
    [Test]
    procedure DovrebbeSvuotarsiEContareIVoxel;
    [Test]
    procedure DovrebbeRipartireVuotoConReset;
    [Test]
    procedure DovrebbeFareLoSnapshotEIlRipristino;
    [Test]
    procedure DovrebbeRipristinareAncheUnaDimensioneDiversa;
    [Test]
    procedure DovrebbeRifiutareUnoSnapshotMalformato;
    [Test]
    procedure DovrebbeCopiareUnAltroModello;
    [Test]
    procedure DovrebbeRifiutareIlModelloNilInAssignFrom;
  end;

implementation

{ TTestVoxelEditorModel }

procedure TTestVoxelEditorModel.Setup;
begin
  FModel := TVoxelEditorModel.Create(8);
end;

procedure TTestVoxelEditorModel.TearDown;
begin
  FModel.Free;
end;

procedure TTestVoxelEditorModel.DovrebbeCrearsiVuotoDellaDimensioneChiesta;
begin
  Assert.AreEqual(8, FModel.Size);
  Assert.AreEqual(512, Integer(Length(FModel.Cells)));
  Assert.AreEqual(0, FModel.CountVoxels);
end;

procedure TTestVoxelEditorModel.DovrebbeRifiutareDimensioniFuoriDa1A256;
begin
  Assert.WillRaise(procedure begin TVoxelEditorModel.Create(0).Free; end, EVoxelEditorException);
  Assert.WillRaise(procedure begin TVoxelEditorModel.Create(257).Free; end, EVoxelEditorException);
  TVoxelEditorModel.Create(256).Free;
  TVoxelEditorModel.Create(1).Free;
end;

procedure TTestVoxelEditorModel.DovrebbeLeggereEScrivereUnaCella;
begin
  FModel.Put(1, 2, 3, $123456);
  Assert.AreEqual(Cardinal($123456), FModel.Get(1, 2, 3));
  Assert.AreEqual(Cardinal(0), FModel.Get(3, 2, 1));
end;

procedure TTestVoxelEditorModel.DovrebbeUsareLIndiceXPoiYPoiZ;
begin
  FModel.Put(1, 2, 3, 7);
  Assert.AreEqual((1 * 8 + 2) * 8 + 3, FModel.IndexOf(1, 2, 3));
  Assert.AreEqual(Cardinal(7), FModel.Cells[FModel.IndexOf(1, 2, 3)]);
end;

procedure TTestVoxelEditorModel.DovrebbeSvuotarsiEContareIVoxel;
begin
  FModel.Put(0, 0, 0, 1);
  FModel.Put(7, 7, 7, 2);
  Assert.AreEqual(2, FModel.CountVoxels);
  FModel.Clear;
  Assert.AreEqual(0, FModel.CountVoxels);
end;

procedure TTestVoxelEditorModel.DovrebbeRipartireVuotoConReset;
begin
  FModel.Put(1, 1, 1, 5);
  FModel.Reset(16);
  Assert.AreEqual(16, FModel.Size);
  Assert.AreEqual(0, FModel.CountVoxels);
end;

procedure TTestVoxelEditorModel.DovrebbeFareLoSnapshotEIlRipristino;
var
  LSnapshot: TBytes;
begin
  FModel.Put(1, 2, 3, $ABCDEF);
  FModel.Put(7, 0, 4, 9);
  LSnapshot := FModel.Snapshot;
  // 4 + 1 + 3 entries of 7 bytes (two voxels and the closing one)
  Assert.AreEqual(5 + 3 * 7, Integer(Length(LSnapshot)));
  FModel.Clear;
  FModel.Restore(LSnapshot);
  Assert.AreEqual(Cardinal($ABCDEF), FModel.Get(1, 2, 3));
  Assert.AreEqual(Cardinal(9), FModel.Get(7, 0, 4));
  Assert.AreEqual(2, FModel.CountVoxels);
end;

procedure TTestVoxelEditorModel.DovrebbeRipristinareAncheUnaDimensioneDiversa;
var
  LSnapshot: TBytes;
begin
  LSnapshot := FModel.Snapshot;
  FModel.Reset(32);
  FModel.Restore(LSnapshot);
  Assert.AreEqual(8, FModel.Size);
end;

procedure TTestVoxelEditorModel.DovrebbeRifiutareUnoSnapshotMalformato;
begin
  Assert.WillRaise(procedure begin FModel.Restore(nil); end, EVoxelEditorException);
  Assert.WillRaise(procedure begin FModel.Restore(TBytes.Create(8, 0, 0, 0, Ord('x'), 0, 0, 0, 0, 0, 0, 0)); end,
    EVoxelEditorException);
end;

procedure TTestVoxelEditorModel.DovrebbeCopiareUnAltroModello;
var
  LOther: TVoxelEditorModel;
begin
  LOther := TVoxelEditorModel.Create(4);
  try
    LOther.Put(1, 1, 1, 3);
    FModel.AssignFrom(LOther);
    Assert.AreEqual(4, FModel.Size);
    Assert.AreEqual(Cardinal(3), FModel.Get(1, 1, 1));
    LOther.Put(1, 1, 1, 4);
    Assert.AreEqual(Cardinal(3), FModel.Get(1, 1, 1));
  finally
    LOther.Free;
  end;
end;

procedure TTestVoxelEditorModel.DovrebbeRifiutareIlModelloNilInAssignFrom;
begin
  Assert.WillRaise(procedure begin FModel.AssignFrom(nil); end, EArgumentNilException);
end;

end.

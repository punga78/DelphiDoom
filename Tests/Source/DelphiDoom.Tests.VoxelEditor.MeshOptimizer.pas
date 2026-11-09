{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorMeshOptimizer (issue #167)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.MeshOptimizer;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Model,
  DelphiDoom.VoxelEditor.MeshOptimizer;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorMeshOptimizer = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
    FMesh: TVoxelEditorMeshOptimizer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFareSeiQuadriPerUnVoxelSolo;
    [Test]
    procedure DovrebbeNonFareLeFacceCoperteDaUnVicino;
    [Test]
    procedure DovrebbeUnireIQuadriDelloStessoColoreNelloStessoPiano;
    [Test]
    procedure DovrebbeNonUnireQuadriDiColoriDiversi;
    [Test]
    procedure DovrebbeDirePerCheCosaLaMeshESceCosiPiccola;
    [Test]
    procedure DovrebbeRifiutareZeroPassate;
    [Test]
    procedure DovrebbeNonPerdereIlPrimoQuadroEnonRipetereLUltimo;
    [Test]
    procedure DovrebbeFermarsiDopoLeAlmenoPassateChieste;
    [Test]
    procedure DovrebbeScrivereIlFileDdmesh;
    [Test]
    procedure DovrebbeNonScrivereIVoxelSepolti;
    [Test]
    procedure DovrebbeOrdinareIVerticiDiUnQuadro;
  end;

implementation

uses
  System.Generics.Collections,
  DelphiDoom.VoxelEditor.Types;

procedure TTestVoxelEditorMeshOptimizer.Setup;
begin
  FModel := TVoxelEditorModel.Create(8);
  FMesh := TVoxelEditorMeshOptimizer.Create;
end;

procedure TTestVoxelEditorMeshOptimizer.TearDown;
begin
  FMesh.Free;
  FModel.Free;
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeFareSeiQuadriPerUnVoxelSolo;
begin
  FModel.Put(3, 3, 3, 5);
  FMesh.LoadVoxel(FModel);
  Assert.AreEqual(6, FMesh.QuadCount);
  Assert.AreEqual(Cardinal(5), FMesh.Quads[0].Color);
  Assert.IsTrue(FMesh.Quads[0].Valid);
  Assert.AreEqual('z', string(FMesh.Quads[0].Orientation));
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeNonFareLeFacceCoperteDaUnVicino;
begin
  FModel.Put(3, 3, 3, 5);
  FModel.Put(4, 3, 3, 6);
  FMesh.LoadVoxel(FModel);
  Assert.AreEqual(10, FMesh.QuadCount);
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeUnireIQuadriDelloStessoColoreNelloStessoPiano;
begin
  FModel.Put(3, 3, 3, 5);
  FModel.Put(4, 3, 3, 5);
  FMesh.LoadVoxel(FModel);
  FMesh.Optimize;
  // the four sides of the two voxels join into one each, and the two ends stay
  Assert.AreEqual(6, FMesh.QuadCount);
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeNonUnireQuadriDiColoriDiversi;
begin
  FModel.Put(3, 3, 3, 5);
  FModel.Put(4, 3, 3, 6);
  FMesh.LoadVoxel(FModel);
  FMesh.Optimize;
  Assert.AreEqual(10, FMesh.QuadCount);
  Assert.AreEqual('', FMesh.Message);
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeDirePerCheCosaLaMeshESceCosiPiccola;
begin
  FModel.Put(3, 3, 3, 5);
  FModel.Put(4, 3, 3, 5);
  FMesh.LoadVoxel(FModel);
  FMesh.Optimize;
  Assert.AreEqual(Format(SVoxelEditorMeshReduced, [10, 6, 2]), FMesh.Message);
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeRifiutareZeroPassate;
begin
  FModel.Put(3, 3, 3, 5);
  FMesh.LoadVoxel(FModel);
  FMesh.PassCount := 0;
  FMesh.Optimize;
  Assert.AreEqual(SVoxelEditorMeshNoPasses, FMesh.Message);
  Assert.AreEqual(6, FMesh.QuadCount);
end;

// the old compaction (when the room of the array did not change) shifted the squares down by one: the first one
// was lost, the last one was repeated and the count was left as it was
procedure TTestVoxelEditorMeshOptimizer.DovrebbeNonPerdereIlPrimoQuadroEnonRipetereLUltimo;
var
  LSeen: TDictionary<string, Boolean>;
  LIndex, LVertex: Integer;
  LKey: string;
begin
  FModel.Put(1, 1, 1, 5);
  FModel.Put(5, 5, 5, 6);
  FMesh.LoadVoxel(FModel);
  FMesh.Optimize;
  Assert.AreEqual(12, FMesh.QuadCount);
  Assert.AreEqual(Cardinal(5), FMesh.Quads[0].Color);
  LSeen := TDictionary<string, Boolean>.Create;
  try
    for LIndex := 0 to FMesh.QuadCount - 1 do
    begin
      LKey := IntToStr(FMesh.Quads[LIndex].Color);
      for LVertex := 0 to 3 do
        LKey := LKey + Format(' %d,%d,%d', [FMesh.Quads[LIndex].Vertices[LVertex].X,
          FMesh.Quads[LIndex].Vertices[LVertex].Y, FMesh.Quads[LIndex].Vertices[LVertex].Z]);
      Assert.IsFalse(LSeen.ContainsKey(LKey), 'the same quad twice: ' + LKey);
      LSeen.Add(LKey, True);
    end;
  finally
    LSeen.Free;
  end;
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeFermarsiDopoLeAlmenoPassateChieste;
begin
  FModel.Put(3, 3, 3, 5);
  FModel.Put(4, 3, 3, 5);
  FMesh.LoadVoxel(FModel);
  FMesh.PassCount := 1;
  FMesh.Optimize;
  Assert.AreEqual(6, FMesh.QuadCount);
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeScrivereIlFileDdmesh;
var
  LBytes: TBytes;
begin
  FModel.Put(3, 3, 3, 5);
  FMesh.LoadVoxel(FModel);
  LBytes := FMesh.ToBytes;
  // the header, the 6 quads (a color and 4 vertices of 3 integers), the number of voxels and the voxel
  Assert.AreEqual(16 + 6 * 52 + 4 + 7, Integer(Length(LBytes)));
  Assert.AreEqual(Cardinal(VOXEL_EDITOR_DDMESH_MAGIC), PCardinal(@LBytes[0])^);
  Assert.AreEqual(1, Integer(PInteger(@LBytes[4])^));
  Assert.AreEqual(8, Integer(PInteger(@LBytes[8])^));
  Assert.AreEqual(6, Integer(PInteger(@LBytes[12])^));
  Assert.AreEqual(1, Integer(PInteger(@LBytes[16 + 6 * 52])^));
  Assert.AreEqual(3, Integer(LBytes[16 + 6 * 52 + 4]));
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeNonScrivereIVoxelSepolti;
var
  LX, LY, LZ: Integer;
  LBytes: TBytes;
begin
  for LX := 2 to 4 do
    for LY := 2 to 4 do
      for LZ := 2 to 4 do
        FModel.Put(LX, LY, LZ, 5);
  FMesh.LoadVoxel(FModel);
  LBytes := FMesh.ToBytes;
  // the one in the middle has the six sides taken
  Assert.AreEqual(26, Integer(PInteger(@LBytes[16 + FMesh.QuadCount * 52])^));
end;

procedure TTestVoxelEditorMeshOptimizer.DovrebbeOrdinareIVerticiDiUnQuadro;
begin
  FModel.Put(3, 3, 3, 5);
  FMesh.LoadVoxel(FModel);
  FMesh.Optimize;
  // the first vertex of a square is the one with the smallest coordinates
  Assert.AreEqual(3, FMesh.Quads[0].Vertices[0].X);
  Assert.AreEqual(3, FMesh.Quads[0].Vertices[0].Y);
  Assert.AreEqual(3, FMesh.Quads[0].Vertices[0].Z);
end;

end.

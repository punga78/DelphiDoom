{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - parity with the old code
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Parity;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Voxel.Golden;

type
  /// <summary>
  ///   The fingerprints of the old loaders of the three renderers (software, sprites, OpenGL),
  ///   of the sprite patch and of the VOXELDEF parser (Tests\Data\Voxel\voxel.golden.txt)
  /// </summary>
  [TestFixture]
  [Category('voxel')]
  TTestVoxelParity = class(TObject)
  strict private
    FGolden: TGoldenFile;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseCelleDelVecchioLettoreDiDdvox;
    [Test]
    procedure DovrebbeDareLeStesseCelleELeFacceDelVecchioLettoreDiDdmesh;
    [Test]
    procedure DovrebbeDareLeStesseCelleDelVecchioLettoreDiKvxPerIlRenderer;
    [Test]
    procedure DovrebbeDareLeStesseCelleDelVecchioLettoreDiKvxPerGliSprite;
    [Test]
    procedure DovrebbeDareLaStessaGrigliaDelVecchioLettoreDiKvxDiOpenGl;
    [Test]
    procedure DovrebbeDareLeStesseCelleDelVecchioLettoreDiVoxDiSlab6;
    [Test]
    procedure DovrebbeRifiutareGliStessiFileDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLeStessePatchDelVecchioCodice;
    [Test]
    procedure DovrebbeDareGliStessiEventiDelVecchioParserDiVoxeldef;
  end;

implementation

uses
  DelphiDoom.Tests.Voxel.Subject;

{ TTestVoxelParity }

procedure TTestVoxelParity.Setup;
begin
  FGolden := TGoldenFile.Create('voxel.golden.txt');
end;

procedure TTestVoxelParity.TearDown;
begin
  FGolden.Free;
end;

procedure TTestVoxelParity.DovrebbeDareLeStesseCelleDelVecchioLettoreDiDdvox;
begin
  FGolden.Check('ddvox.cubes', TVoxelSubject.DdvoxCubes);
end;

procedure TTestVoxelParity.DovrebbeDareLeStesseCelleELeFacceDelVecchioLettoreDiDdmesh;
begin
  FGolden.Check('ddmesh.cubes', TVoxelSubject.DdmeshCubes);
  FGolden.Check('ddmesh.quads', TVoxelSubject.DdmeshQuads);
end;

procedure TTestVoxelParity.DovrebbeDareLeStesseCelleDelVecchioLettoreDiKvxPerIlRenderer;
begin
  FGolden.Check('kvx.cubes.renderer', TVoxelSubject.KvxCubesForRenderer);
  FGolden.Check('kvx.extreme.cubes.renderer', TVoxelSubject.KvxExtremeCubesForRenderer);
end;

procedure TTestVoxelParity.DovrebbeDareLeStesseCelleDelVecchioLettoreDiKvxPerGliSprite;
begin
  FGolden.Check('kvx.cubes.sprite', TVoxelSubject.KvxCubesForSprite);
end;

procedure TTestVoxelParity.DovrebbeDareLaStessaGrigliaDelVecchioLettoreDiKvxDiOpenGl;
begin
  FGolden.Check('kvx.grids', TVoxelSubject.KvxGrids);
  FGolden.Check('kvx.extreme.grids', TVoxelSubject.KvxExtremeGrids);
end;

procedure TTestVoxelParity.DovrebbeDareLeStesseCelleDelVecchioLettoreDiVoxDiSlab6;
begin
  FGolden.Check('slab6.cubes', TVoxelSubject.Slab6Cubes);
end;

procedure TTestVoxelParity.DovrebbeRifiutareGliStessiFileDelVecchioCodice;
begin
  FGolden.Check('rejects', TVoxelSubject.Rejects);
end;

procedure TTestVoxelParity.DovrebbeDareLeStessePatchDelVecchioCodice;
begin
  FGolden.Check('patches.ddvox', TVoxelSubject.DdvoxPatches);
  FGolden.Check('patches.ddmesh', TVoxelSubject.DdmeshPatches);
  FGolden.Check('patches.kvx', TVoxelSubject.KvxPatches);
  FGolden.Check('patches.slab6', TVoxelSubject.Slab6Patches);
end;

procedure TTestVoxelParity.DovrebbeDareGliStessiEventiDelVecchioParserDiVoxeldef;
begin
  FGolden.Check('definitions', TVoxelSubject.Definitions);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelParity);

end.
{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - from a model to a cube
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.CubeBuilder;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Intf;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelCubeBuilder = class(TObject)
  strict private
    FBuilder: IVoxelCubeBuilder;
    function Solid(const AFormat: TVoxelFormatKind; const ASizeX, ASizeY, ASizeZ: Integer;
      const APivotX, APivotY, APivotZ: Integer): IVoxelModel;
    function CountCells(const ACube: IVoxelCube): Integer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeCopiareUnModelloDdvoxCosiComeE;
    [Test]
    procedure DovrebbeMettereUnKvxInUnCuboPiuGrandeDiUnoPerIlRenderer;
    [Test]
    procedure DovrebbeTenereIlKvxDentroIlCuboPerIlRenderer;
    [Test]
    procedure DovrebbeFareUnCuboDiLatoPariPerGliSprite;
    [Test]
    procedure DovrebbeScambiareGliAssiDelKvx;
    [Test]
    procedure DovrebbeCentrareUnModelloSlab6;
    [Test]
    procedure DovrebbePerdereIVoxelFuoriDalCuboDegliSprite;
    [Test]
    procedure DovrebbeDareEccezioneSeIlModelloManca;
  end;

implementation

uses
  DelphiDoom.Voxel.Model, DelphiDoom.Voxel.Factory;

function TTestVoxelCubeBuilder.Solid(const AFormat: TVoxelFormatKind; const ASizeX, ASizeY,
  ASizeZ: Integer; const APivotX, APivotY, APivotZ: Integer): IVoxelModel;
var
  LCells: TArray<Cardinal>;
  LIndex: Integer;
begin
  SetLength(LCells, ASizeX * ASizeY * ASizeZ);
  for LIndex := 0 to High(LCells) do
    LCells[LIndex] := 5;
  Result := TVoxelModel.Create(AFormat, ASizeX, ASizeY, ASizeZ, APivotX, APivotY, APivotZ, LCells, nil);
end;

function TTestVoxelCubeBuilder.CountCells(const ACube: IVoxelCube): Integer;
var
  LCell: Cardinal;
begin
  Result := 0;
  for LCell in ACube.Cells do
    if LCell <> 0 then
      Inc(Result);
end;

procedure TTestVoxelCubeBuilder.Setup;
begin
  FBuilder := TVoxelFactory.CreateCubeBuilder;
end;

procedure TTestVoxelCubeBuilder.DovrebbeCopiareUnModelloDdvoxCosiComeE;
var
  LCells: TArray<Cardinal>;
  LCube: IVoxelCube;
begin
  SetLength(LCells, 8);
  LCells[(1 * 2 + 0) * 2 + 1] := 9;
  LCube := FBuilder.Build(TVoxelModel.Create(vfDdvox, 2, 2, 2, 0, 0, 0, LCells, nil), cfRenderer);
  Assert.AreEqual(2, LCube.Size);
  Assert.AreEqual(Cardinal(9), LCube.Cell(1, 0, 1));
  Assert.AreEqual(1, CountCells(LCube));
end;

procedure TTestVoxelCubeBuilder.DovrebbeMettereUnKvxInUnCuboPiuGrandeDiUnoPerIlRenderer;
var
  LCube: IVoxelCube;
begin
  LCube := FBuilder.Build(Solid(vfKvx, 2, 2, 2, 256, 256, 0), cfRenderer);
  Assert.AreEqual(3, LCube.Size);
  Assert.AreEqual(8, CountCells(LCube));
end;

procedure TTestVoxelCubeBuilder.DovrebbeTenereIlKvxDentroIlCuboPerIlRenderer;
var
  LCube: IVoxelCube;
begin
  // a pivot that would put the model outside: the renderer moves it back
  LCube := FBuilder.Build(Solid(vfKvx, 2, 2, 2, -5000, 9000, -9000), cfRenderer);
  Assert.AreEqual(8, CountCells(LCube));
end;

procedure TTestVoxelCubeBuilder.DovrebbeFareUnCuboDiLatoPariPerGliSprite;
begin
  Assert.AreEqual(4, FBuilder.Build(Solid(vfKvx, 3, 1, 1, 384, 128, 0), cfSprite).Size);
  Assert.AreEqual(6, FBuilder.Build(Solid(vfKvx, 4, 1, 1, 512, 128, 0), cfSprite).Size);
end;

procedure TTestVoxelCubeBuilder.DovrebbeScambiareGliAssiDelKvx;
var
  LCells: TArray<Cardinal>;
  LCube: IVoxelCube;
begin
  // one voxel at (x, y, z) = (0, 1, 0) of a 1 x 2 x 1 model, pivot in the middle
  SetLength(LCells, 2);
  LCells[1] := 7;
  LCube := FBuilder.Build(TVoxelModel.Create(vfKvx, 1, 2, 1, 128, 256, 128, LCells, nil), cfRenderer);
  // side 3: x1 = 1 - 0, y1 = 1 - 1, z1 = 3 - 0 -> 1 after the clamp;
  // cube (x, z, side - y - 1) = (1 + 0, 1 + 0, 3 - (0 + 1) - 1) = (1, 1, 1)
  Assert.AreEqual(3, LCube.Size);
  Assert.AreEqual(Cardinal(7), LCube.Cell(1, 1, 1));
  Assert.AreEqual(1, CountCells(LCube));
end;

procedure TTestVoxelCubeBuilder.DovrebbeCentrareUnModelloSlab6;
var
  LCube: IVoxelCube;
begin
  LCube := FBuilder.Build(Solid(vfSlab6, 1, 1, 4, 0, 0, 0), cfRenderer);
  Assert.AreEqual(4, LCube.Size);
  Assert.AreEqual(Cardinal(5), LCube.Cell(1, 2, 2));
  Assert.AreEqual(Cardinal(0), LCube.Cell(0, 2, 2));
  Assert.AreEqual(4, CountCells(LCube));
end;

procedure TTestVoxelCubeBuilder.DovrebbePerdereIVoxelFuoriDalCuboDegliSprite;
var
  LCube: IVoxelCube;
begin
  // the pivot at zero puts the model above the cube: the old code wrote them out of the cube
  LCube := FBuilder.Build(Solid(vfKvx, 1, 1, 4, 128, 128, 0), cfSprite);
  Assert.AreEqual(6, LCube.Size);
  Assert.AreEqual(0, CountCells(LCube));
end;

procedure TTestVoxelCubeBuilder.DovrebbeDareEccezioneSeIlModelloManca;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(nil, cfRenderer);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelCubeBuilder);

end.
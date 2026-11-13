{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the patch of a sprite
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.PatchBuilder;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.Intf;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelPatchBuilder = class(TObject)
  strict private
    FBuilder: IVoxelPatchBuilder;
    function CubeWithCell(const ASide, AX, AY, AZ: Integer; const AColor: Cardinal): IVoxelCube;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeScrivereLaPatchDiUnCuboDiDueVoxelPerLato;
    [Test]
    procedure DovrebbeFareUnaPatchDiLatoPariDaUnCuboDiLatoDispari;
    [Test]
    procedure DovrebbeUsareIlPrimoVoxelLungoZ;
    [Test]
    procedure DovrebbeDareColonneVuoteSeIlCuboEVuoto;
    [Test]
    procedure DovrebbeDareEccezioneSeManca;
  end;

implementation

uses
  DelphiDoom.Voxel.Cube, DelphiDoom.Voxel.Factory, DelphiDoom.Tests.Voxel.Samples,
  DelphiDoom.Tests.Voxel.Fakes;

function TTestVoxelPatchBuilder.CubeWithCell(const ASide, AX, AY, AZ: Integer;
  const AColor: Cardinal): IVoxelCube;
var
  LCube: TVoxelCube;
  LCells: TArray<Cardinal>;
begin
  LCube := TVoxelCube.Create(ASide);
  Result := LCube;
  LCells := LCube.Cells;
  LCells[(AX * ASide + AY) * ASide + AZ] := AColor;
end;

procedure TTestVoxelPatchBuilder.Setup;
begin
  FBuilder := TVoxelFactory.CreatePatchBuilder(TVoxelFakeMapper.Create);
end;

procedure TTestVoxelPatchBuilder.DovrebbeScrivereLaPatchDiUnCuboDiDueVoxelPerLato;
var
  LBytes, LExpected: TBytes;
  LPixel: Byte;
begin
  LPixel := TVoxelSamples.PaletteIndexOf($0A0B0C);
  LBytes := FBuilder.Build(CubeWithCell(2, 0, 0, 0, $0A0B0C));
  // width, height, left, top; the offsets of the two columns; a post of one pixel and the end
  // of the first column; the end of the second
  LExpected := TBytes.Create(2, 0, 2, 0, 1, 0, 2, 0, 16, 0, 0, 0, 23, 0, 0, 0,
    0, 1, 0, LPixel, 0, 255, 0, 255, 0);
  Assert.AreEqual(Length(LExpected), Length(LBytes));
  Assert.IsTrue(CompareMem(@LExpected[0], @LBytes[0], Length(LExpected)));
end;

procedure TTestVoxelPatchBuilder.DovrebbeFareUnaPatchDiLatoPariDaUnCuboDiLatoDispari;
var
  LBytes: TBytes;
begin
  LBytes := FBuilder.Build(CubeWithCell(3, 0, 0, 0, $010203));
  Assert.AreEqual(4, Integer(LBytes[0]));
  Assert.AreEqual(4, Integer(LBytes[2]));
  Assert.AreEqual(2, Integer(LBytes[4]));
  Assert.AreEqual(4, Integer(LBytes[6]));
end;

procedure TTestVoxelPatchBuilder.DovrebbeUsareIlPrimoVoxelLungoZ;
var
  LCube: IVoxelCube;
  LFirst, LSecond: TBytes;
begin
  LCube := CubeWithCell(2, 1, 1, 1, $000001);
  LFirst := FBuilder.Build(LCube);
  LSecond := FBuilder.Build(CubeWithCell(2, 1, 1, 0, $000001));
  Assert.AreEqual(Length(LSecond), Length(LFirst));
  Assert.IsTrue(CompareMem(@LFirst[0], @LSecond[0], Length(LFirst)));
end;

procedure TTestVoxelPatchBuilder.DovrebbeDareColonneVuoteSeIlCuboEVuoto;
var
  LBytes: TBytes;
begin
  LBytes := FBuilder.Build(TVoxelCube.Create(2));
  // header, two offsets and two ends of column
  Assert.AreEqual<Integer>(8 + 8 + 4, Length(LBytes));
end;

procedure TTestVoxelPatchBuilder.DovrebbeDareEccezioneSeManca;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TVoxelFactory.CreatePatchBuilder(nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelPatchBuilder);

end.
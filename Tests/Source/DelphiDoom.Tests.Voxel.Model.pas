{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - a voxel model
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Model;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Intf;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelModel = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLaCellaDalSuoIndice;
    [Test]
    procedure DovrebbeDareZeroFuoriDalModello;
    [Test]
    procedure DovrebbeDareEccezioneSeLeCelleNonSonoQuelleDelleDimensioni;
    [Test]
    procedure DovrebbeDareLeFacceDellaMesh;
  end;

implementation

uses
  DelphiDoom.Voxel.Model;

procedure TTestVoxelModel.DovrebbeDareLaCellaDalSuoIndice;
var
  LModel: IVoxelModel;
begin
  // 2 x 3 x 2: the index is (x * 3 + y) * 2 + z
  LModel := TVoxelModel.Create(vfKvx, 2, 3, 2, 10, 20, 30,
    TArray<Cardinal>.Create(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11), nil);
  Assert.AreEqual(Cardinal(7), LModel.Cell(1, 0, 1));
  Assert.AreEqual(Cardinal(11), LModel.Cell(1, 2, 1));
  Assert.AreEqual(Cardinal(4), LModel.Cell(0, 2, 0));
  Assert.AreEqual(20, LModel.PivotY);
  Assert.AreEqual(Ord(vfKvx), Ord(LModel.Format));
end;

procedure TTestVoxelModel.DovrebbeDareZeroFuoriDalModello;
var
  LModel: IVoxelModel;
begin
  LModel := TVoxelModel.Create(vfSlab6, 1, 1, 1, 0, 0, 0, TArray<Cardinal>.Create(5), nil);
  Assert.AreEqual(Cardinal(0), LModel.Cell(1, 0, 0));
  Assert.AreEqual(Cardinal(0), LModel.Cell(0, -1, 0));
  Assert.AreEqual(Cardinal(0), LModel.Cell(0, 0, 9));
end;

procedure TTestVoxelModel.DovrebbeDareEccezioneSeLeCelleNonSonoQuelleDelleDimensioni;
begin
  Assert.WillRaise(
    procedure
    begin
      TVoxelModel.Create(vfSlab6, 2, 2, 2, 0, 0, 0, TArray<Cardinal>.Create(1, 2, 3), nil);
    end, EVoxelException);
end;

procedure TTestVoxelModel.DovrebbeDareLeFacceDellaMesh;
var
  LQuads: TArray<TVoxelQuad>;
  LModel: IVoxelModel;
begin
  SetLength(LQuads, 2);
  LQuads[1].Color := $123456;
  LQuads[1].Vertexes[2].Y := -4;
  LModel := TVoxelModel.Create(vfDdmesh, 1, 1, 1, 0, 0, 0, TArray<Cardinal>.Create(0), LQuads);
  Assert.AreEqual(2, LModel.QuadCount);
  Assert.AreEqual(Cardinal($123456), LModel.Quad(1).Color);
  Assert.AreEqual(-4, LModel.Quad(1).Vertexes[2].Y);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelModel);

end.
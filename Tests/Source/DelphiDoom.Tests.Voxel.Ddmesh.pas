{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the DDMESH format
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Ddmesh;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Intf;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelDdmesh = class(TObject)
  strict private
    FFormat: IVoxelFormat;
    function Mesh(const AMagic, AVersion: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereLeFacceEIVoxel;
    [Test]
    procedure DovrebbeIgnorareUnVoxelFuoriDalCubo;
    [Test]
    procedure DovrebbeRifiutareUnaMagiaSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneSconosciuta;
    [Test]
    procedure DovrebbeRifiutareUnFileTroncato;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiFacceImpossibile;
  end;

implementation

uses
  DelphiDoom.Voxel.Format.Ddmesh, DelphiDoom.Tests.Voxel.Samples;

procedure TTestVoxelDdmesh.Setup;
begin
  FFormat := TVoxelDdmeshFormat.Create;
end;

function TTestVoxelDdmesh.Mesh(const AMagic, AVersion: Integer): TBytes;
begin
  // side 2, one quad (the color and 12 numbers), two voxels: (1, 0, 1) and one outside
  Result := TVoxelSamples.Integers([AMagic, AVersion, 2, 1, $112233, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 2]);
  Result := TVoxelSamples.Join(Result, TBytes.Create(1, 0, 1, $AA, 0, 0, 0));
  Result := TVoxelSamples.Join(Result, TBytes.Create(5, 0, 0, $BB, 0, 0, 0));
end;

procedure TTestVoxelDdmesh.DovrebbeLeggereLeFacceEIVoxel;
var
  LModel: IVoxelModel;
begin
  LModel := FFormat.Decode(Mesh(Integer(DDMESH_MAGIC), 1));
  Assert.AreEqual(2, LModel.SizeX);
  Assert.AreEqual(1, LModel.QuadCount);
  Assert.AreEqual(Cardinal($332211), LModel.Quad(0).Color);
  Assert.AreEqual(1, LModel.Quad(0).Vertexes[0].Y);
  Assert.AreEqual(11, LModel.Quad(0).Vertexes[3].Z);
  Assert.AreEqual(Cardinal($AA0000), LModel.Cell(1, 0, 1));
  Assert.IsTrue(FFormat.Handles('.DDMESH'));
end;

procedure TTestVoxelDdmesh.DovrebbeIgnorareUnVoxelFuoriDalCubo;
var
  LModel: IVoxelModel;
  LCell: Cardinal;
  LCount: Integer;
begin
  LModel := FFormat.Decode(Mesh(Integer(DDMESH_MAGIC), 1));
  LCount := 0;
  for LCell in LModel.Cells do
    if LCell <> 0 then
      Inc(LCount);
  Assert.AreEqual(1, LCount);
end;

procedure TTestVoxelDdmesh.DovrebbeRifiutareUnaMagiaSbagliata;
begin
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(Mesh($12345678, 1));
    end, EVoxelException, SVoxelDdmeshMagic);
end;

procedure TTestVoxelDdmesh.DovrebbeRifiutareUnaVersioneSconosciuta;
begin
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(Mesh(Integer(DDMESH_MAGIC), 2));
    end, EVoxelException);
end;

procedure TTestVoxelDdmesh.DovrebbeRifiutareUnFileTroncato;
var
  LBytes: TBytes;
begin
  LBytes := Mesh(Integer(DDMESH_MAGIC), 1);
  SetLength(LBytes, Length(LBytes) - 3);
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(LBytes);
    end, EVoxelException);
end;

procedure TTestVoxelDdmesh.DovrebbeRifiutareUnNumeroDiFacceImpossibile;
begin
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(TVoxelSamples.Integers([Integer(DDMESH_MAGIC), 1, 2, 100000]));
    end, EVoxelException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelDdmesh);

end.
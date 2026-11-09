{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorDdmeshFormat (issue #167)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Ddmesh;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorDdmeshFormat = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
    function Mesh(AMagic: Cardinal; AVersion, ASize, AQuads: Integer; AVoxels: Integer; AX, AY, AZ: Byte): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIVoxelDopoIQuadri;
    [Test]
    procedure DovrebbeSaltareIQuadri;
    [Test]
    procedure DovrebbeRifiutareUnaIntestazioneSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneSconosciuta;
    [Test]
    procedure DovrebbeRifiutareUnVoxelFuoriDalCubo;
    [Test]
    procedure DovrebbeRifiutareUnElencoCheSuperaIlFile;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiQuadriNegativo;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Format.Ddmesh;

procedure TTestVoxelEditorDdmeshFormat.Setup;
begin
  FModel := TVoxelEditorModel.Create(1);
end;

procedure TTestVoxelEditorDdmeshFormat.TearDown;
begin
  FModel.Free;
end;

function TTestVoxelEditorDdmeshFormat.Mesh(AMagic: Cardinal; AVersion, ASize, AQuads, AVoxels: Integer;
  AX, AY, AZ: Byte): TBytes;
var
  LStream: TBytesStream;
  LColor: Cardinal;
  LIndex: Integer;
begin
  LStream := TBytesStream.Create;
  try
    LStream.Write(AMagic, 4);
    LStream.Write(AVersion, 4);
    LStream.Write(ASize, 4);
    LStream.Write(AQuads, 4);
    for LIndex := 1 to AQuads * 52 do
      LStream.Write(LIndex, 1);
    LStream.Write(AVoxels, 4);
    LColor := $0A0B0C;
    LStream.Write(AX, 1);
    LStream.Write(AY, 1);
    LStream.Write(AZ, 1);
    LStream.Write(LColor, 4);
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

procedure TTestVoxelEditorDdmeshFormat.DovrebbeLeggereIVoxelDopoIQuadri;
begin
  TVoxelEditorDdmeshFormat.Read(Mesh(VOXEL_EDITOR_DDMESH_MAGIC, 1, 8, 0, 1, 1, 2, 3), FModel);
  Assert.AreEqual(8, FModel.Size);
  Assert.AreEqual(Cardinal($0A0B0C), FModel.Get(1, 2, 3));
  Assert.AreEqual(1, FModel.CountVoxels);
end;

procedure TTestVoxelEditorDdmeshFormat.DovrebbeSaltareIQuadri;
begin
  TVoxelEditorDdmeshFormat.Read(Mesh(VOXEL_EDITOR_DDMESH_MAGIC, 1, 8, 3, 1, 7, 7, 7), FModel);
  Assert.AreEqual(Cardinal($0A0B0C), FModel.Get(7, 7, 7));
end;

procedure TTestVoxelEditorDdmeshFormat.DovrebbeRifiutareUnaIntestazioneSbagliata;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdmeshFormat.Read(Mesh($12345678, 1, 8, 0, 1, 1, 2, 3), FModel); end,
    EVoxelEditorException);
  Assert.WillRaise(procedure begin TVoxelEditorDdmeshFormat.Read(nil, FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorDdmeshFormat.DovrebbeRifiutareUnaVersioneSconosciuta;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdmeshFormat.Read(Mesh(VOXEL_EDITOR_DDMESH_MAGIC, 2, 8, 0, 1, 1, 2, 3), FModel); end,
    EVoxelEditorException);
end;

procedure TTestVoxelEditorDdmeshFormat.DovrebbeRifiutareUnVoxelFuoriDalCubo;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdmeshFormat.Read(Mesh(VOXEL_EDITOR_DDMESH_MAGIC, 1, 8, 0, 1, 8, 0, 0), FModel); end,
    EVoxelEditorException);
end;

procedure TTestVoxelEditorDdmeshFormat.DovrebbeRifiutareUnElencoCheSuperaIlFile;
var
  LBytes: TBytes;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdmeshFormat.Read(Mesh(VOXEL_EDITOR_DDMESH_MAGIC, 1, 8, 0, 5, 1, 2, 3), FModel); end,
    EVoxelEditorException);
  // a count of quads that is more than the file holds
  LBytes := Mesh(VOXEL_EDITOR_DDMESH_MAGIC, 1, 8, 0, 1, 1, 2, 3);
  PInteger(@LBytes[12])^ := 1000;
  Assert.WillRaise(procedure begin TVoxelEditorDdmeshFormat.Read(LBytes, FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorDdmeshFormat.DovrebbeRifiutareUnNumeroDiQuadriNegativo;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdmeshFormat.Read(Mesh(VOXEL_EDITOR_DDMESH_MAGIC, 1, 8, -1, 1, 1, 2, 3), FModel); end,
    EVoxelEditorException);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the VOX format of Slab6
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Slab6;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Intf;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelSlab6 = class(TObject)
  strict private
    FFormat: IVoxelFormat;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereIVoxelEIlVuoto;
    [Test]
    procedure DovrebbeRiconoscereLEstensioneVox;
    [Test]
    procedure DovrebbeRifiutareUnFileCorto;
    [Test]
    procedure DovrebbeRifiutareUnLatoDiZeroOOltre256;
    [Test]
    procedure DovrebbeRifiutareIVoxelCheNonCiSono;
    [Test]
    procedure DovrebbeCercareSoloNelleCartelleDeiVoxel;
  end;

implementation

uses
  DelphiDoom.Voxel.Format.Slab6, DelphiDoom.Tests.Voxel.Samples, DelphiDoom.Tests.Voxel.Fakes;

procedure TTestVoxelSlab6.Setup;
begin
  FFormat := TVoxelSlab6Format.Create;
end;

procedure TTestVoxelSlab6.DovrebbeLeggereIVoxelEIlVuoto;
var
  LModel: IVoxelModel;
begin
  LModel := FFormat.Decode(TVoxelSamples.Join(TVoxelSamples.Join(TVoxelSamples.Integers([1, 1, 2]),
    TBytes.Create(255, 7)), TVoxelSamples.Palette(True, 0)));
  Assert.AreEqual(Cardinal(0), LModel.Cell(0, 0, 0));
  Assert.AreEqual(Cardinal($070301), LModel.Cell(0, 0, 1));
end;

procedure TTestVoxelSlab6.DovrebbeRiconoscereLEstensioneVox;
begin
  Assert.IsTrue(FFormat.Handles('.VOX'));
  Assert.IsFalse(FFormat.Handles('.KVX'));
end;

procedure TTestVoxelSlab6.DovrebbeRifiutareUnFileCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(TBytes.Create(1, 0, 0, 0));
    end, EVoxelException);
end;

procedure TTestVoxelSlab6.DovrebbeRifiutareUnLatoDiZeroOOltre256;
begin
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(TVoxelSamples.Join(TVoxelSamples.Integers([0, 1, 1]), TVoxelSamples.Palette(True, 0)));
    end, EVoxelException);
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(TVoxelSamples.Join(TVoxelSamples.Integers([1, 257, 1]), TVoxelSamples.Palette(True, 0)));
    end, EVoxelException);
end;

procedure TTestVoxelSlab6.DovrebbeRifiutareIVoxelCheNonCiSono;
begin
  // 2 x 2 x 2 voxels declared, three present
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(TVoxelSamples.Join(TVoxelSamples.Join(TVoxelSamples.Integers([2, 2, 2]),
        TBytes.Create(1, 2, 3)), TVoxelSamples.Palette(True, 0)));
    end, EVoxelException);
end;

procedure TTestVoxelSlab6.DovrebbeCercareSoloNelleCartelleDeiVoxel;
var
  LSource: TVoxelFakeSource;
  LSourceIntf: IVoxelFileSource;
  LBytes: TBytes;
begin
  LSource := TVoxelFakeSource.Create;
  LSourceIntf := LSource;
  Assert.IsFalse(FFormat.Locate(LSourceIntf, 'a.vox', LBytes));
  Assert.AreEqual(1, LSource.Calls.Count);
  Assert.AreEqual('file a.vox', LSource.Calls[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelSlab6);

end.
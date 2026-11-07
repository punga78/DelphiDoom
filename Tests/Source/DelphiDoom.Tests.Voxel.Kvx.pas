{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the KVX format
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Kvx;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Intf;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelKvx = class(TObject)
  strict private
    FFormat: IVoxelFormat;
    /// <summary>A model of 1 x 1 x 2 with one slab: top, length 2, the palette indexes 3 and 4</summary>
    function Small(const ATop: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereLeSlabDelModello;
    [Test]
    procedure DovrebbeLeggereIPivot;
    [Test]
    procedure DovrebbeRiconoscereLEstensioneKvxEQuellaVuota;
    [Test]
    procedure DovrebbeRifiutareUnaSlabFuoriDalModello;
    [Test]
    procedure DovrebbeRifiutareUnFileCortoDellaPalette;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneOltre256;
    [Test]
    procedure DovrebbeRifiutareUnConteggioDiByteImpossibile;
    [Test]
    procedure DovrebbeCercareIlFileLaCartellaLEstensioneEIlLump;
    [Test]
    procedure DovrebbeCercareIlLumpSenzaCartelleEEstensione;
    [Test]
    procedure DovrebbeFermarsiAlPrimoFileTrovato;
  end;

implementation

uses
  DelphiDoom.Voxel.Format.Kvx, DelphiDoom.Tests.Voxel.Samples, DelphiDoom.Tests.Voxel.Fakes;

procedure TTestVoxelKvx.Setup;
begin
  FFormat := TVoxelKvxFormat.Create;
end;

function TTestVoxelKvx.Small(const ATop: Integer): TBytes;
var
  LHeader: TBytes;
begin
  // tables: 2 offsets of x and 2 offsets of y (words); the data are the 5 bytes of the slab
  LHeader := TVoxelSamples.Integers([41, 1, 1, 2, 128, 128, 0, 12, 17]);
  Result := TVoxelSamples.Join(LHeader, TBytes.Create(0, 0, 5, 0));
  Result := TVoxelSamples.Join(Result, TBytes.Create(ATop, 2, 0, 3, 4));
  Result := TVoxelSamples.Join(Result, TVoxelSamples.Palette(True, 0));
end;

procedure TTestVoxelKvx.DovrebbeLeggereLeSlabDelModello;
var
  LModel: IVoxelModel;
begin
  LModel := FFormat.Decode(Small(0));
  Assert.AreEqual(1, LModel.SizeX);
  Assert.AreEqual(2, LModel.SizeZ);
  Assert.AreEqual(Cardinal($030101), LModel.Cell(0, 0, 0));
  Assert.AreEqual(Cardinal($040201), LModel.Cell(0, 0, 1));
end;

procedure TTestVoxelKvx.DovrebbeLeggereIPivot;
var
  LModel: IVoxelModel;
begin
  LModel := FFormat.Decode(Small(0));
  Assert.AreEqual(128, LModel.PivotX);
  Assert.AreEqual(128, LModel.PivotY);
  Assert.AreEqual(0, LModel.PivotZ);
end;

procedure TTestVoxelKvx.DovrebbeRiconoscereLEstensioneKvxEQuellaVuota;
begin
  Assert.IsTrue(FFormat.Handles('.KVX'));
  Assert.IsTrue(FFormat.Handles(''));
  Assert.IsFalse(FFormat.Handles('.VOX'));
end;

procedure TTestVoxelKvx.DovrebbeRifiutareUnaSlabFuoriDalModello;
begin
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(Small(1));
    end, EVoxelException);
end;

procedure TTestVoxelKvx.DovrebbeRifiutareUnFileCortoDellaPalette;
begin
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(TBytes.Create(1, 2, 3, 4));
    end, EVoxelException);
end;

procedure TTestVoxelKvx.DovrebbeRifiutareUnaDimensioneOltre256;
var
  LBytes: TBytes;
begin
  LBytes := TVoxelSamples.Join(TVoxelSamples.Integers([41, 300, 1, 2, 0, 0, 0, 12, 17]),
    TVoxelSamples.Palette(True, 0));
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(LBytes);
    end, EVoxelException);
end;

procedure TTestVoxelKvx.DovrebbeRifiutareUnConteggioDiByteImpossibile;
var
  LBytes: TBytes;
begin
  LBytes := Small(0);
  LBytes[0] := 200;
  Assert.WillRaise(
    procedure
    begin
      FFormat.Decode(LBytes);
    end, EVoxelException);
end;

procedure TTestVoxelKvx.DovrebbeCercareIlFileLaCartellaLEstensioneEIlLump;
var
  LSource: TVoxelFakeSource;
  LSourceIntf: IVoxelFileSource;
  LBytes: TBytes;
begin
  LSource := TVoxelFakeSource.Create;
  LSourceIntf := LSource;
  Assert.IsFalse(FFormat.Locate(LSourceIntf, 'PROP', LBytes));
  Assert.AreEqual('file PROP|directory PROP|file PROP.KVX|directory PROP.KVX|lump PROP',
    LSource.Calls.CommaText.Replace(',', '|').Replace('"', ''));
end;

procedure TTestVoxelKvx.DovrebbeCercareIlLumpSenzaCartelleEEstensione;
var
  LSource: TVoxelFakeSource;
  LSourceIntf: IVoxelFileSource;
  LBytes: TBytes;
begin
  LSource := TVoxelFakeSource.Create;
  LSourceIntf := LSource;
  LSource.AddLump('BARREL', Small(0));
  Assert.IsTrue(FFormat.Locate(LSourceIntf, 'voxels\barrel.kvx', LBytes));
  Assert.AreEqual(Length(Small(0)), Length(LBytes));
  Assert.AreEqual('lump barrel', LSource.Calls[LSource.Calls.Count - 1]);
end;

procedure TTestVoxelKvx.DovrebbeFermarsiAlPrimoFileTrovato;
var
  LSource: TVoxelFakeSource;
  LSourceIntf: IVoxelFileSource;
  LBytes: TBytes;
begin
  LSource := TVoxelFakeSource.Create;
  LSourceIntf := LSource;
  LSource.AddDirectoryFile('a.kvx', Small(0));
  Assert.IsTrue(FFormat.Locate(LSourceIntf, 'a.kvx', LBytes));
  Assert.AreEqual(2, LSource.Calls.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelKvx);

end.
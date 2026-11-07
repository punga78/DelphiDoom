{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the palette of KVX and VOX files
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.KvxPalette;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Voxel.KvxPalette;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelKvxPalette = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereLaPaletteDagliUltimi768Byte;
    [Test]
    procedure DovrebbeMettereUnoAlPostoDelNero;
    [Test]
    procedure DovrebbeScalareUnaPaletteChePartePocoAlto;
    [Test]
    procedure DovrebbeScalareAlMassimoQuattroVolte;
    [Test]
    procedure DovrebbeNonScalareUnaPaletteCheArrivaA255;
    [Test]
    procedure DovrebbeDareEccezioneSeIlFileECortoDellaPalette;
  end;

implementation

uses
  DelphiDoom.Voxel.Types, DelphiDoom.Tests.Voxel.Samples;

procedure TTestVoxelKvxPalette.DovrebbeLeggereLaPaletteDagliUltimi768Byte;
var
  LBytes: TBytes;
  LPalette: TArray<Cardinal>;
begin
  LBytes := TVoxelSamples.Join(TBytes.Create(9, 9, 9), TVoxelSamples.Palette(False, 255));
  LPalette := TVoxelKvxPalette.Read(LBytes);
  Assert.AreEqual(256, Length(LPalette));
  Assert.AreEqual(Cardinal($FFFFFF), LPalette[0]);
end;

procedure TTestVoxelKvxPalette.DovrebbeMettereUnoAlPostoDelNero;
var
  LPalette: TArray<Cardinal>;
begin
  LPalette := TVoxelKvxPalette.Read(TVoxelSamples.Palette(False, 0));
  Assert.AreEqual(Cardinal(VOXEL_BLACK_COLOR), LPalette[0]);
  Assert.AreEqual(Cardinal(VOXEL_BLACK_COLOR), LPalette[255]);
end;

procedure TTestVoxelKvxPalette.DovrebbeScalareUnaPaletteChePartePocoAlto;
var
  LPalette: TArray<Cardinal>;
begin
  // the biggest component is 63: 255 / 63 is 4.05, the factor is 4 (the most), so 63 becomes 252
  LPalette := TVoxelKvxPalette.Read(TVoxelSamples.Palette(False, 63));
  Assert.AreEqual(Cardinal($FCFCFC), LPalette[0]);
  // the biggest component is 100: the factor is 2.55 and 100 becomes 255
  LPalette := TVoxelKvxPalette.Read(TVoxelSamples.Palette(False, 100));
  Assert.AreEqual(Cardinal($FFFFFF), LPalette[0]);
end;

procedure TTestVoxelKvxPalette.DovrebbeScalareAlMassimoQuattroVolte;
var
  LPalette: TArray<Cardinal>;
begin
  // the biggest component is 10: the factor would be 25.5, it is 4
  LPalette := TVoxelKvxPalette.Read(TVoxelSamples.Palette(False, 10));
  Assert.AreEqual(Cardinal($282828), LPalette[0]);
end;

procedure TTestVoxelKvxPalette.DovrebbeNonScalareUnaPaletteCheArrivaA255;
var
  LPalette: TArray<Cardinal>;
begin
  LPalette := TVoxelKvxPalette.Read(TVoxelSamples.Palette(True, 0));
  Assert.AreEqual(Cardinal($020101), LPalette[2]);
end;

procedure TTestVoxelKvxPalette.DovrebbeDareEccezioneSeIlFileECortoDellaPalette;
begin
  Assert.WillRaise(
    procedure
    begin
      TVoxelKvxPalette.Read(TBytes.Create(1, 2, 3));
    end, EVoxelException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelKvxPalette);

end.
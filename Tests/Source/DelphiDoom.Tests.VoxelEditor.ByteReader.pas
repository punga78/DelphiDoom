{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorByteReader and TVoxelEditorSlabPalette      }
{  (issue #167)                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.ByteReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorByteReader = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereNumeriLittleEndian;
    [Test]
    procedure DovrebbeRifiutareUnaLetturaOltreLaFine;
    [Test]
    procedure DovrebbeSaltareAUnaPosizione;
    [Test]
    procedure DovrebbeRifiutareUnaPosizioneNegativa;
    [Test]
    procedure DovrebbeLeggereLaPalettaInFondoAlFile;
    [Test]
    procedure DovrebbeStirareUnaPalettaDelVga;
    [Test]
    procedure DovrebbeNonStirareOltreQuattroVolte;
    [Test]
    procedure DovrebbeFareUnoDelNero;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaPaletta;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.ByteReader,
  DelphiDoom.VoxelEditor.Format.SlabPalette;

procedure TTestVoxelEditorByteReader.DovrebbeLeggereNumeriLittleEndian;
var
  LReader: TVoxelEditorByteReader;
begin
  LReader := TVoxelEditorByteReader.Create(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11));
  try
    Assert.AreEqual(Byte(1), LReader.ReadByte);
    Assert.AreEqual(Word($0302), LReader.ReadWord);
    Assert.AreEqual(Integer($07060504), LReader.ReadInteger);
    Assert.AreEqual(4, LReader.Remaining);
    Assert.AreEqual(Cardinal($0B0A0908), LReader.ReadCardinal);
    Assert.AreEqual(11, LReader.Position);
  finally
    LReader.Free;
  end;
end;

procedure TTestVoxelEditorByteReader.DovrebbeRifiutareUnaLetturaOltreLaFine;
var
  LReader: TVoxelEditorByteReader;
begin
  LReader := TVoxelEditorByteReader.Create(TBytes.Create(1, 2, 3));
  try
    Assert.WillRaise(procedure begin LReader.ReadInteger; end, EVoxelEditorException);
    Assert.AreEqual(Word($0201), LReader.ReadWord);
    Assert.WillRaise(procedure begin LReader.ReadWord; end, EVoxelEditorException);
    Assert.AreEqual(Byte(3), LReader.ReadByte);
    Assert.WillRaise(procedure begin LReader.ReadByte; end, EVoxelEditorException);
    Assert.WillRaise(procedure begin LReader.ReadCardinal; end, EVoxelEditorException);
  finally
    LReader.Free;
  end;
end;

procedure TTestVoxelEditorByteReader.DovrebbeSaltareAUnaPosizione;
var
  LReader: TVoxelEditorByteReader;
begin
  LReader := TVoxelEditorByteReader.Create(TBytes.Create(1, 2, 3));
  try
    LReader.Seek(2);
    Assert.AreEqual(Byte(3), LReader.ReadByte);
    Assert.AreEqual(3, Integer(Length(LReader.Bytes)));
  finally
    LReader.Free;
  end;
end;

procedure TTestVoxelEditorByteReader.DovrebbeRifiutareUnaPosizioneNegativa;
var
  LReader: TVoxelEditorByteReader;
begin
  LReader := TVoxelEditorByteReader.Create(TBytes.Create(1, 2, 3));
  try
    LReader.Seek(-4);
    Assert.WillRaise(procedure begin LReader.ReadByte; end, EVoxelEditorException);
  finally
    LReader.Free;
  end;
end;

function Palette(AMaximum: Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 5 + 768);
  FillChar(Result[0], Length(Result), 0);
  for LIndex := 0 to 255 do
  begin
    Result[5 + LIndex * 3] := 10; // blue
    Result[5 + LIndex * 3 + 1] := 20; // green
    Result[5 + LIndex * 3 + 2] := 30; // red
  end;
  Result[5 + 3 * 3 + 1] := AMaximum;
end;

procedure TTestVoxelEditorByteReader.DovrebbeLeggereLaPalettaInFondoAlFile;
var
  LPalette: TVoxelEditorPalette;
  LBytes: TBytes;
begin
  LBytes := Palette(255);
  LPalette := TVoxelEditorSlabPalette.Read(LBytes);
  // r shl 16 + g shl 8 + b, the bytes of the file being blue, green and red
  Assert.AreEqual(Cardinal((30 shl 16) + (20 shl 8) + 10), LPalette[0]);
  Assert.AreEqual(Cardinal((30 shl 16) + (255 shl 8) + 10), LPalette[3]);
end;

procedure TTestVoxelEditorByteReader.DovrebbeStirareUnaPalettaDelVga;
var
  LPalette: TVoxelEditorPalette;
begin
  LPalette := TVoxelEditorSlabPalette.Read(Palette(63));
  // 255 / 63 = 4.05: at most 4
  Assert.AreEqual(Cardinal((120 shl 16) + (80 shl 8) + 40), LPalette[0]);
  Assert.AreEqual(Cardinal((120 shl 16) + (252 shl 8) + 40), LPalette[3]);
end;

procedure TTestVoxelEditorByteReader.DovrebbeNonStirareOltreQuattroVolte;
var
  LPalette: TVoxelEditorPalette;
begin
  LPalette := TVoxelEditorSlabPalette.Read(Palette(30));
  // the largest channel is 30: 255 / 30 = 8.5 is cut at 4 (and the values that go over 255 stay at 255)
  Assert.AreEqual(Cardinal((120 shl 16) + (80 shl 8) + 40), LPalette[0]);
  Assert.AreEqual(Cardinal((120 shl 16) + (120 shl 8) + 40), LPalette[3]);
end;

procedure TTestVoxelEditorByteReader.DovrebbeFareUnoDelNero;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 768);
  FillChar(LBytes[0], 768, 0);
  Assert.AreEqual(Cardinal(1), TVoxelEditorSlabPalette.Read(LBytes)[17]);
end;

procedure TTestVoxelEditorByteReader.DovrebbeRifiutareUnFileSenzaPaletta;
begin
  Assert.WillRaise(procedure begin TVoxelEditorSlabPalette.Read(TBytes.Create(1, 2, 3)); end, EVoxelEditorException);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the BMP file                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.BitmapWriter;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.BitmapWriter;

type
  [TestFixture]
  [Category('parity')]
  TTestParityBitmapWriter = class(TObject)
  strict private
    FStream: TMemoryStream;
    function ByteAt(AOffset: Integer): Byte;
    function CardinalAt(AOffset: Integer): Cardinal;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure LaTestataDovrebbeEssereDi54Byte;
    [Test]
    procedure DovrebbeScrivereLaFirmaBM;
    [Test]
    procedure LaDimensioneDelFileDovrebbeEssereTestataPiuPixel;
    [Test]
    procedure LaAltezzaDovrebbeEssereNegativaPerRigheDallAlto;
    [Test]
    procedure DovrebbeScrivereIPixelCosiCome;
    [Test]
    procedure UnaDimensioneNullaDovrebbeDareEccezione;
    [Test]
    procedure UnaMemoriaNilDovrebbeDareEccezione;
  end;

implementation

uses
  DelphiDoom.Parity.Types;

procedure TTestParityBitmapWriter.Setup;
begin
  FStream := TMemoryStream.Create;
end;

procedure TTestParityBitmapWriter.TearDown;
begin
  FStream.Free;
end;

function TTestParityBitmapWriter.ByteAt(AOffset: Integer): Byte;
begin
  Result := PByte(PByte(FStream.Memory) + AOffset)^;
end;

function TTestParityBitmapWriter.CardinalAt(AOffset: Integer): Cardinal;
begin
  Result := PCardinal(PByte(FStream.Memory) + AOffset)^;
end;

procedure TTestParityBitmapWriter.LaTestataDovrebbeEssereDi54Byte;
var
  LPixels: array[0..5] of Cardinal;
begin
  FillChar(LPixels, SizeOf(LPixels), 0);
  TParityBitmapWriter.Write(FStream, 3, 2, @LPixels[0]);
  Assert.AreEqual(54 + 24, Integer(FStream.Size));
  Assert.AreEqual(Cardinal(54), CardinalAt(10), 'offset of the pixels');
  Assert.AreEqual(Cardinal(40), CardinalAt(14), 'size of the info header');
end;

procedure TTestParityBitmapWriter.DovrebbeScrivereLaFirmaBM;
var
  LPixels: Cardinal;
begin
  LPixels := 0;
  TParityBitmapWriter.Write(FStream, 1, 1, @LPixels);
  Assert.AreEqual(Byte(Ord('B')), ByteAt(0));
  Assert.AreEqual(Byte(Ord('M')), ByteAt(1));
end;

procedure TTestParityBitmapWriter.LaDimensioneDelFileDovrebbeEssereTestataPiuPixel;
var
  LPixels: array[0..5] of Cardinal;
begin
  FillChar(LPixels, SizeOf(LPixels), 0);
  TParityBitmapWriter.Write(FStream, 3, 2, @LPixels[0]);
  Assert.AreEqual(Cardinal(54 + 24), CardinalAt(2), 'size of the file');
  Assert.AreEqual(Cardinal(24), CardinalAt(34), 'size of the image');
end;

procedure TTestParityBitmapWriter.LaAltezzaDovrebbeEssereNegativaPerRigheDallAlto;
var
  LPixels: array[0..5] of Cardinal;
begin
  FillChar(LPixels, SizeOf(LPixels), 0);
  TParityBitmapWriter.Write(FStream, 3, 2, @LPixels[0]);
  Assert.AreEqual(3, Integer(CardinalAt(18)), 'width');
  Assert.AreEqual(-2, Integer(CardinalAt(22)), 'height');
  Assert.AreEqual(32, Integer(PWord(PByte(FStream.Memory) + 28)^), 'bits per pixel');
end;

procedure TTestParityBitmapWriter.DovrebbeScrivereIPixelCosiCome;
var
  LPixels: array[0..1] of Cardinal;
begin
  LPixels[0] := $11223344;
  LPixels[1] := $AABBCCDD;
  TParityBitmapWriter.Write(FStream, 2, 1, @LPixels[0]);
  Assert.AreEqual(Cardinal($11223344), CardinalAt(54));
  Assert.AreEqual(Cardinal($AABBCCDD), CardinalAt(58));
end;

procedure TTestParityBitmapWriter.UnaDimensioneNullaDovrebbeDareEccezione;
var
  LPixels: Cardinal;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityBitmapWriter.Write(FStream, 0, 1, @LPixels);
    end, EParityException);
end;

procedure TTestParityBitmapWriter.UnaMemoriaNilDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityBitmapWriter.Write(FStream, 1, 1, nil);
    end, EParityException);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingFlatReader                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.FlatReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.FlatReader, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingFlatReader = class(TObject)
  private
    FReader: IImagingFlatReader;
    function CountingPalette: TImagingPixels;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestReadMatchesOldCodeInEveryCase;
    [Test]
    procedure TestReadMapsEachByteThroughThePalette;
    [Test]
    procedure TestReadTakesTheSizeFromTheLength;
    [Test]
    procedure TestReadOfAFlatWithAnotherLengthIsThe64x64;
    [Test]
    procedure TestReadTakesTheSizeOfFlatInfoWhenItHasOne;
    [Test]
    procedure TestReadOfAShortLumpGivesWholeRowsOf64;
    [Test]
    procedure TestReadLeavesZeroWhatTheLumpDoesNotCover;
    [Test]
    procedure TestReadWithAShortPaletteRaises;
    [Test]
    procedure TestReadWithBadFlatInfoIndexRaises;
  end;

implementation

function TTestImagingFlatReader.CountingPalette: TImagingPixels;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := $01000000 + Cardinal(LIndex) * 3;
end;

procedure TTestImagingFlatReader.Setup;
begin
  FReader := TImagingFlatReader.Create;
end;

procedure TTestImagingFlatReader.TestReadMatchesOldCodeInEveryCase;
var
  LCase: TSampleFlatCase;
  LImage: TImagingFlatImage;
  LPalette: TImagingPixels;
begin
  LPalette := TImagingSamples.Palette(99);
  for LCase in TImagingSamples.FlatCases do
  begin
    LImage := FReader.Read(LCase.Lump, LPalette, LCase.InfoSizeIndex);
    TImagingGolden.Check('flat.golden.txt', LCase.Name,
      IntToStr(LImage.Side) + ':' + TImagingSamples.Hex(TImagingSamples.Hash(LImage.Pixels)));
  end;
end;

procedure TTestImagingFlatReader.TestReadMapsEachByteThroughThePalette;
var
  LLump: TBytes;
  LImage: TImagingFlatImage;
  LIndex: Integer;
begin
  SetLength(LLump, 4096);
  for LIndex := 0 to 4095 do
    LLump[LIndex] := Byte(LIndex);
  LImage := FReader.Read(LLump, CountingPalette, 0);
  for LIndex := 0 to 4095 do
    if LImage.Pixels[LIndex] <> $01000000 + Cardinal(Byte(LIndex)) * 3 then
      Assert.Fail('dovrebbe passare dalla palette il byte ' + IntToStr(LIndex));
  Assert.Pass;
end;

procedure TTestImagingFlatReader.TestReadTakesTheSizeFromTheLength;
var
  LImage: TImagingFlatImage;
begin
  LImage := FReader.Read(TImagingSamples.RandomBytes(1, 16384), CountingPalette, 0);
  Assert.AreEqual(128, LImage.Side, 'dovrebbe vedere un flat 128x128');
  Assert.AreEqual<Integer>(16384, Length(LImage.Pixels), 'dovrebbe dare 128x128 pixel');
end;

procedure TTestImagingFlatReader.TestReadOfAFlatWithAnotherLengthIsThe64x64;
var
  LImage: TImagingFlatImage;
begin
  LImage := FReader.Read(TImagingSamples.RandomBytes(1, 8192), CountingPalette, 0);
  Assert.AreEqual(64, LImage.Side, 'dovrebbe vedere un flat 64x64 in un lump 64x128');
  Assert.AreEqual<Integer>(4096, Length(LImage.Pixels), 'dovrebbe dare 4096 pixel');
end;

procedure TTestImagingFlatReader.TestReadTakesTheSizeOfFlatInfoWhenItHasOne;
var
  LImage: TImagingFlatImage;
begin
  LImage := FReader.Read(TImagingSamples.RandomBytes(1, 65536), CountingPalette, 1);
  Assert.AreEqual(128, LImage.Side, 'dovrebbe usare la dimensione di FLATINFO');
end;

procedure TTestImagingFlatReader.TestReadOfAShortLumpGivesWholeRowsOf64;
var
  LImage: TImagingFlatImage;
  LPalette: TImagingPixels;
begin
  LPalette := CountingPalette;
  LImage := FReader.Read(TImagingSamples.RandomBytes(1, 130), LPalette, 0);
  Assert.AreNotEqual(Cardinal(0), LImage.Pixels[127], 'dovrebbe convertire le prime 2 righe da 64');
  Assert.AreEqual(Cardinal(0), LImage.Pixels[128], 'dovrebbe lasciare il resto di 2 byte');
end;

procedure TTestImagingFlatReader.TestReadLeavesZeroWhatTheLumpDoesNotCover;
var
  LImage: TImagingFlatImage;
begin
  LImage := FReader.Read(TImagingSamples.RandomBytes(1, 4096), CountingPalette, 1);
  Assert.AreEqual(128, LImage.Side, 'dovrebbe usare la dimensione di FLATINFO');
  Assert.AreNotEqual(Cardinal(0), LImage.Pixels[4095], 'dovrebbe convertire quello che il lump ha');
  Assert.AreEqual(Cardinal(0), LImage.Pixels[4096], 'dovrebbe dare zero oltre il lump');
end;

procedure TTestImagingFlatReader.TestReadWithAShortPaletteRaises;
var
  LPalette: TImagingPixels;
begin
  SetLength(LPalette, 100);
  Assert.WillRaise(
    procedure
    begin
      FReader.Read(TImagingSamples.RandomBytes(1, 4096), LPalette, 0);
    end, EImagingException, 'dovrebbe rifiutare una palette di meno di 256 colori');
end;

procedure TTestImagingFlatReader.TestReadWithBadFlatInfoIndexRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      FReader.Read(TImagingSamples.RandomBytes(1, 4096), CountingPalette, 7);
    end, EImagingException, 'dovrebbe rifiutare un indice di dimensione oltre 6');
end;

end.

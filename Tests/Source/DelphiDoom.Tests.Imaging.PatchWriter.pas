{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingPatchWriter (issue #167)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.PatchWriter;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.PatchWriter;

type
  /// <summary>
  ///   The patches are the bytes that FF_CreateDoomPatch of DD_FONT wrote (golden file made by the old code), and
  ///   what the patch reader of the library reads back is the picture
  /// </summary>
  [TestFixture]
  [Category('imaging')]
  TTestImagingPatchWriter = class(TObject)
  strict private
    FWriter: IImagingPatchWriter;
    function Digest(const ABytes: TBytes): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereGliStessiByteDelVecchio;
    [Test]
    procedure DovrebbeScrivereLIntestazioneDa8Byte;
    [Test]
    procedure DovrebbeUsareGliOffsetPredefinitiDelVecchio;
    [Test]
    procedure DovrebbeUsareGliOffsetChePassiamo;
    [Test]
    procedure DovrebbeScrivereLaFineDiOgniColonnaFFSeguitoDaUnoZero;
    [Test]
    procedure DovrebbeLasciareTrasparentiIPixelZero;
    [Test]
    procedure DovrebbeRendereUnPostInteroConLaPatchSolida;
    [Test]
    procedure DovrebbeFarTornareLaStessaImmagineAlLettoreDelleLibreria;
    [Test]
    procedure DovrebbeDividereLaColonnaInPiuPostSeCisonoBuchi;
    [Test]
    procedure DovrebbeScrivereUnaPatchSenzaColonneSeLaLarghezzaEZero;
    [Test]
    procedure DovrebbeAccettareLAltezzaMassimaDi255;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNegativaOTroppoGrande;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineConMenoPixelDelleDimensioni;
  end;

implementation

uses
  DelphiDoom.Imaging.Factory,
  DelphiDoom.Tests.Sound.Digest,
  DelphiDoom.Tests.Font.Golden,
  DelphiDoom.Tests.Font.Scenarios;

const
  GOLDEN_FILE = 'Imaging\patchwriter.golden.txt';

{ TTestImagingPatchWriter }

procedure TTestImagingPatchWriter.Setup;
begin
  FWriter := TImagingPatchWriter.Create;
end;

procedure TTestImagingPatchWriter.TearDown;
begin
  FWriter := nil;
end;

function TTestImagingPatchWriter.Digest(const ABytes: TBytes): string;
var
  LDigest: TSoundDigest;
begin
  LDigest := TSoundDigest.Start;
  LDigest.AddBuffer(@ABytes[0], Length(ABytes));
  Result := IntToHex(LDigest.Value, 16) + ':' + IntToStr(Length(ABytes));
end;

procedure TTestImagingPatchWriter.DovrebbeScrivereGliStessiByteDelVecchio;
var
  LLine: string;
  LWords: TArray<string>;
  LCase: TPatchCase;
  LBytes: TBytes;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'PATCH') do
  begin
    LWords := TFontGolden.Words(LLine);
    LCase := TFontScenarios.PatchCase(StrToInt(LWords[0]));
    if LCase.DefaultOffsets then
      LBytes := FWriter.Build(TBytes(LCase.Pixels), LCase.Width, LCase.Height, LCase.Solid)
    else
      LBytes := FWriter.Build(TBytes(LCase.Pixels), LCase.Width, LCase.Height, LCase.Solid, LCase.OffsetX,
        LCase.OffsetY);
    Assert.AreEqual(LWords[1], Digest(LBytes), 'patch ' + LWords[0]);
    Inc(LCount);
  end;
  Assert.AreEqual(TFontScenarios.PatchCaseCount, LCount);
end;

procedure TTestImagingPatchWriter.DovrebbeScrivereLIntestazioneDa8Byte;
var
  LPixels: TBytes;
  LPatch: TBytes;
  LHeader: TImagingPatchHeader;
begin
  SetLength(LPixels, 6);
  LPixels[0] := 1;
  LPatch := FWriter.Build(LPixels, 3, 2, False, 7, -2);
  Move(LPatch[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(8, SizeOf(TImagingPatchHeader));
  Assert.AreEqual(3, Integer(LHeader.Width));
  Assert.AreEqual(2, Integer(LHeader.Height));
  Assert.AreEqual(7, Integer(LHeader.LeftOffset));
  Assert.AreEqual(-2, Integer(LHeader.TopOffset));
end;

procedure TTestImagingPatchWriter.DovrebbeUsareGliOffsetPredefinitiDelVecchio;
var
  LPixels: TBytes;
  LPatch: TBytes;
  LHeader: TImagingPatchHeader;
begin
  SetLength(LPixels, 7 * 5);
  LPatch := FWriter.Build(LPixels, 7, 5, False);
  Move(LPatch[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(3, Integer(LHeader.LeftOffset), 'meta della larghezza');
  Assert.AreEqual(5, Integer(LHeader.TopOffset), 'altezza');
end;

procedure TTestImagingPatchWriter.DovrebbeUsareGliOffsetChePassiamo;
var
  LPixels: TBytes;
  LPatch: TBytes;
  LHeader: TImagingPatchHeader;
begin
  SetLength(LPixels, 4);
  LPatch := FWriter.Build(LPixels, 2, 2, True, 0, 3);
  Move(LPatch[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(0, Integer(LHeader.LeftOffset));
  Assert.AreEqual(3, Integer(LHeader.TopOffset));
end;

procedure TTestImagingPatchWriter.DovrebbeScrivereLaFineDiOgniColonnaFFSeguitoDaUnoZero;
var
  LPixels: TBytes;
  LPatch: TBytes;
  LOffset: Integer;
begin
  // a column with the pixels 5, 0: one post of one pixel, then $FF 0
  SetLength(LPixels, 2);
  LPixels[0] := 5;
  LPatch := FWriter.Build(LPixels, 1, 2, False);
  Move(LPatch[8], LOffset, SizeOf(LOffset));
  Assert.AreEqual(12, LOffset, 'dopo l''intestazione e la tabella di una colonna');
  Assert.AreEqual<Integer>(12 + 3 + 1 + 1 + 2, Length(LPatch));
  Assert.AreEqual(0, Integer(LPatch[12]), 'topdelta');
  Assert.AreEqual(1, Integer(LPatch[13]), 'lunghezza');
  Assert.AreEqual(0, Integer(LPatch[14]), 'riempimento');
  Assert.AreEqual(5, Integer(LPatch[15]), 'pixel');
  Assert.AreEqual(0, Integer(LPatch[16]), 'riempimento');
  Assert.AreEqual($FF, Integer(LPatch[17]));
  Assert.AreEqual(0, Integer(LPatch[18]));
end;

procedure TTestImagingPatchWriter.DovrebbeLasciareTrasparentiIPixelZero;
var
  LPixels: TBytes;
  LPatch: TBytes;
begin
  SetLength(LPixels, 4);
  LPatch := FWriter.Build(LPixels, 1, 4, False);
  // header 8 + table 4, then only the end of the column
  Assert.AreEqual<Integer>(8 + 4 + 2, Length(LPatch));
  Assert.AreEqual($FF, Integer(LPatch[12]));
end;

procedure TTestImagingPatchWriter.DovrebbeRendereUnPostInteroConLaPatchSolida;
var
  LPixels: TBytes;
  LPatch: TBytes;
begin
  SetLength(LPixels, 4);
  LPatch := FWriter.Build(LPixels, 1, 4, True);
  Assert.AreEqual(0, Integer(LPatch[12]), 'topdelta');
  Assert.AreEqual(4, Integer(LPatch[13]), 'lunghezza: tutta la colonna');
  Assert.AreEqual<Integer>(8 + 4 + 3 + 4 + 1 + 2, Length(LPatch));
end;

procedure TTestImagingPatchWriter.DovrebbeFarTornareLaStessaImmagineAlLettoreDelleLibreria;
var
  LIndex: Integer;
  LCase: TPatchCase;
  LPatch: TBytes;
  LImage: TImagingPatchImage;
  LPixel: Integer;
  LReader: IImagingPatchReader;
begin
  LReader := TImagingFactory.CreatePatchReader;
  for LIndex := 8 to TFontScenarios.PatchCaseCount - 1 do
  begin
    LCase := TFontScenarios.PatchCase(LIndex);
    LPatch := FWriter.Build(TBytes(LCase.Pixels), LCase.Width, LCase.Height, LCase.Solid, 1, 2);
    LImage := LReader.Read(LPatch);
    Assert.AreEqual(LCase.Width, LImage.Width);
    Assert.AreEqual(LCase.Height, LImage.Height);
    for LPixel := 0 to Length(LCase.Pixels) - 1 do
    begin
      Assert.AreEqual(Integer(LCase.Pixels[LPixel]), Integer(LImage.Pixels[LPixel]), Format('caso %d pixel %d', [LIndex, LPixel]));
      if LCase.Solid then
        Assert.AreEqual($FF, Integer(LImage.Opaque[LPixel]), 'solida: tutto opaco')
      else
        Assert.AreEqual(Ord(LCase.Pixels[LPixel] <> 0) * $FF, Integer(LImage.Opaque[LPixel]), 'opaco dove il pixel non e 0');
    end;
  end;
end;

procedure TTestImagingPatchWriter.DovrebbeDividereLaColonnaInPiuPostSeCisonoBuchi;
var
  LPixels: TBytes;
  LPatch: TBytes;
begin
  // 7, 0, 0, 9, 9: posts at row 0 (one pixel) and row 3 (two pixels)
  SetLength(LPixels, 5);
  LPixels[0] := 7;
  LPixels[3] := 9;
  LPixels[4] := 9;
  LPatch := FWriter.Build(LPixels, 1, 5, False);
  Assert.AreEqual(0, Integer(LPatch[12]));
  Assert.AreEqual(1, Integer(LPatch[13]));
  Assert.AreEqual(3, Integer(LPatch[12 + 3 + 1 + 1]), 'topdelta del secondo post');
  Assert.AreEqual(2, Integer(LPatch[12 + 3 + 1 + 1 + 1]), 'lunghezza del secondo post');
end;

procedure TTestImagingPatchWriter.DovrebbeScrivereUnaPatchSenzaColonneSeLaLarghezzaEZero;
var
  LPatch: TBytes;
begin
  LPatch := FWriter.Build(nil, 0, 0, False);
  Assert.AreEqual<Integer>(8, Length(LPatch));
end;

procedure TTestImagingPatchWriter.DovrebbeAccettareLAltezzaMassimaDi255;
var
  LPixels: TBytes;
  LPatch: TBytes;
begin
  SetLength(LPixels, 255);
  FillChar(LPixels[0], 255, 3);
  LPatch := FWriter.Build(LPixels, 1, 255, True);
  Assert.AreEqual(255, Integer(LPatch[13]), 'un post di 255 pixel');
end;

procedure TTestImagingPatchWriter.DovrebbeRifiutareUnaDimensioneNegativaOTroppoGrande;
begin
  Assert.WillRaise(
    procedure
    begin
      FWriter.Build(nil, -1, 1, False);
    end, EImagingException, 'larghezza negativa');
  Assert.WillRaise(
    procedure
    begin
      FWriter.Build(nil, 1, -1, False);
    end, EImagingException, 'altezza negativa');
  Assert.WillRaise(
    procedure
    var
      LPixels: TBytes;
    begin
      SetLength(LPixels, 256);
      FWriter.Build(LPixels, 1, 256, False);
    end, EImagingException, 'un post non puo essere piu lungo di 255');
  Assert.WillRaise(
    procedure
    begin
      FWriter.Build(nil, 32768, 0, False);
    end, EImagingException, 'una larghezza che non sta in uno SmallInt');
end;

procedure TTestImagingPatchWriter.DovrebbeRifiutareUnaImmagineConMenoPixelDelleDimensioni;
begin
  Assert.WillRaise(
    procedure
    var
      LPixels: TBytes;
    begin
      SetLength(LPixels, 5);
      FWriter.Build(LPixels, 3, 2, False);
    end, EImagingException);
end;

end.

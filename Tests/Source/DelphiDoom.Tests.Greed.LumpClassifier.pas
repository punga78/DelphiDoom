{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - what a lump is                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.LumpClassifier;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedLumpClassifier = class(TObject)
  private
    FClassifier: IGreedLumpClassifier;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRiconoscereLaPalette;
    [Test]
    procedure DovrebbeRiconoscereIMuri;
    [Test]
    procedure DovrebbeRiconoscereIFlat;
    [Test]
    procedure DovrebbeRiconoscereGliSprite;
    [Test]
    procedure DovrebbeRiconoscereUnaImmagineDallIntestazione;
    [Test]
    procedure DovrebbeNonDareUnTipoAiMarcatoriDeiGruppi;
    [Test]
    procedure DovrebbeNonDareUnTipoAUnLumpSenzaIntestazione;
    [Test]
    procedure DovrebbeNonDareUnTipoAUnLumpConLeDimensioniChiSbagliate;
    [Test]
    procedure DovrebbeNonRiconoscereLaPaletteComeUnaImmagine;
    [Test]
    procedure DovrebbeFunzionareSenzaIMarcatori;
    [Test]
    procedure DovrebbeDareIlDecoderDiOgniTipo;
    [Test]
    procedure DovrebbeNonDareUnDecoderPerPaletteEAltro;
    [Test]
    procedure DovrebbeVolereLArchivio;
  end;

implementation

uses
  System.Classes, DelphiDoom.Greed.Factory, DelphiDoom.Greed.LumpClassifier, DelphiDoom.Tests.Greed.Builders;

{ TTestGreedLumpClassifier }

procedure TTestGreedLumpClassifier.Setup;
begin
  FClassifier := TGreedFactory.CreateLumpClassifier(TGreedTestArchive.Open);
end;

procedure TTestGreedLumpClassifier.TearDown;
begin
  FClassifier := nil;
end;

procedure TTestGreedLumpClassifier.DovrebbeRiconoscereLaPalette;
begin
  Assert.AreEqual(Ord(glkPalette), Ord(FClassifier.Classify(TGreedTestArchive.LUMP_PALETTE)));
end;

procedure TTestGreedLumpClassifier.DovrebbeRiconoscereIMuri;
begin
  Assert.AreEqual(Ord(glkWall), Ord(FClassifier.Classify(TGreedTestArchive.LUMP_WALL1)));
  Assert.AreEqual(Ord(glkWall), Ord(FClassifier.Classify(TGreedTestArchive.LUMP_WALL2)));
end;

procedure TTestGreedLumpClassifier.DovrebbeRiconoscereIFlat;
begin
  Assert.AreEqual(Ord(glkFlat), Ord(FClassifier.Classify(TGreedTestArchive.LUMP_FLAT1)));
  Assert.AreEqual(Ord(glkFlat), Ord(FClassifier.Classify(TGreedTestArchive.LUMP_FLAT2)));
end;

procedure TTestGreedLumpClassifier.DovrebbeRiconoscereGliSprite;
begin
  Assert.AreEqual(Ord(glkSprite), Ord(FClassifier.Classify(TGreedTestArchive.LUMP_SPRITE1)));
end;

procedure TTestGreedLumpClassifier.DovrebbeRiconoscereUnaImmagineDallIntestazione;
begin
  Assert.AreEqual(Ord(glkPicture), Ord(FClassifier.Classify(15)));
end;

procedure TTestGreedLumpClassifier.DovrebbeNonDareUnTipoAiMarcatoriDeiGruppi;
var
  LLump: Integer;
begin
  for LLump in [TGreedTestArchive.LUMP_MAP, TGreedTestArchive.LUMP_START_FLATS, TGreedTestArchive.LUMP_END_FLATS,
    TGreedTestArchive.LUMP_START_WALLS, TGreedTestArchive.LUMP_END_WALLS, TGreedTestArchive.LUMP_START_SPRITES,
    TGreedTestArchive.LUMP_END_SPRITES] do
    Assert.AreEqual(Ord(glkOther), Ord(FClassifier.Classify(LLump)), IntToStr(LLump));
end;

procedure TTestGreedLumpClassifier.DovrebbeNonDareUnTipoAUnLumpSenzaIntestazione;
begin
  Assert.AreEqual(Ord(glkOther), Ord(FClassifier.Classify(TGreedTestArchive.LUMP_FONT)));
  Assert.AreEqual(Ord(glkOther), Ord(FClassifier.Classify(TGreedTestArchive.LUMP_UNNAMED)));
end;

procedure TTestGreedLumpClassifier.DovrebbeNonDareUnTipoAUnLumpConLeDimensioniChiSbagliate;
var
  LBlo: TGreedBlo;
  LClassifier: IGreedLumpClassifier;
  LNoPixels: TBytes;
  LNegative: TBytes;
begin
  LNoPixels := TGreedLumps.Picture(2, 2, 0, 0);
  SetLength(LNoPixels, Length(LNoPixels) + 1);
  LNegative := TGreedLumps.Picture(2, 2, 0, 0);
  LNegative[1] := $FF;
  LBlo := TGreedBlo.Create;
  try
    LClassifier := TGreedFactory.CreateLumpClassifier(
      LBlo.Add('long', LNoPixels).Add('negative', LNegative).Add('zero', TGreedLumps.Picture(0, 5, 0, 0)).Open);
  finally
    LBlo.Free;
  end;
  Assert.AreEqual(Ord(glkOther), Ord(LClassifier.Classify(0)));
  Assert.AreEqual(Ord(glkOther), Ord(LClassifier.Classify(1)));
  Assert.AreEqual(Ord(glkOther), Ord(LClassifier.Classify(2)));
end;

procedure TTestGreedLumpClassifier.DovrebbeNonRiconoscereLaPaletteComeUnaImmagine;
var
  LBlo: TGreedBlo;
  LClassifier: IGreedLumpClassifier;
  LPalette: TBytes;
begin
  // a palette whose first bytes look like the header of a picture of 768 - 8 pixels
  LPalette := TGreedLumps.Palette;
  LPalette[0] := 0;
  LPalette[1] := 0;
  LBlo := TGreedBlo.Create;
  try
    LClassifier := TGreedFactory.CreateLumpClassifier(LBlo.Add('palette', LPalette).Open);
  finally
    LBlo.Free;
  end;
  Assert.AreEqual(Ord(glkPalette), Ord(LClassifier.Classify(0)));
end;

procedure TTestGreedLumpClassifier.DovrebbeFunzionareSenzaIMarcatori;
var
  LBlo: TGreedBlo;
  LClassifier: IGreedLumpClassifier;
begin
  LBlo := TGreedBlo.Create;
  try
    LClassifier := TGreedFactory.CreateLumpClassifier(LBlo.Add('a', TGreedLumps.Picture(2, 2, 0, 0)).Add('b', TGreedLumps.Flat).Open);
  finally
    LBlo.Free;
  end;
  Assert.AreEqual(Ord(glkPicture), Ord(LClassifier.Classify(0)));
  // without the markers a flat is just a lump of 4096 bytes
  Assert.AreEqual(Ord(glkOther), Ord(LClassifier.Classify(1)));
end;

procedure TTestGreedLumpClassifier.DovrebbeDareIlDecoderDiOgniTipo;
var
  LKind: TGreedLumpKind;
begin
  for LKind in [glkPicture, glkFlat, glkWall, glkSprite] do
    Assert.IsNotNull(FClassifier.DecoderOf(LKind), IntToStr(Ord(LKind)));
  Assert.AreEqual(8, FClassifier.DecoderOf(glkWall).Decode(TGreedLumps.Wall(2)).Height);
  Assert.AreEqual(3, FClassifier.DecoderOf(glkSprite).Decode(TGreedLumps.Sprite).Width);
  Assert.AreEqual(64, FClassifier.DecoderOf(glkFlat).Decode(TGreedLumps.Flat).Width);
  Assert.AreEqual(3, FClassifier.DecoderOf(glkPicture).Decode(TGreedLumps.Picture(3, 2, 0, 0)).Width);
end;

procedure TTestGreedLumpClassifier.DovrebbeNonDareUnDecoderPerPaletteEAltro;
begin
  Assert.IsNull(FClassifier.DecoderOf(glkPalette));
  Assert.IsNull(FClassifier.DecoderOf(glkOther));
end;

procedure TTestGreedLumpClassifier.DovrebbeVolereLArchivio;
begin
  Assert.WillRaise(procedure begin TGreedLumpClassifier.Create(nil); end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedLumpClassifier);

end.

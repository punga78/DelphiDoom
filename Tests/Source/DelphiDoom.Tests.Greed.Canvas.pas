{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the 8 bit buffer of the HUD         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Canvas;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.Canvas, DelphiDoom.Tests.Greed.Builders;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedCanvas = class(TObject)
  strict private
    FCanvas: TGreedCanvas;
    function Picture(const APixels: array of Byte; AWidth, AOriginX, AOriginY: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNascereTuttaAZeroConLeMisureDelloSchermo;
    [Test]
    procedure DovrebbeRifiutareMisureNonValide;
    [Test]
    procedure DovrebbeScrivereELeggereUnPixel;
    [Test]
    procedure DovrebbeFinireSullaRigaDopoOltreIlBordoDestro;
    [Test]
    procedure DovrebbeIgnorareUnaRigaCheNonEsiste;
    [Test]
    procedure DovrebbeRiempireSoloDentroIlBuffer;
    [Test]
    procedure DovrebbeTradurreLoZeroDellImmaginePienaECambiareLImmagine;
    [Test]
    procedure DovrebbeCopiareLImmagineNonTradottaComeE;
    [Test]
    procedure DovrebbeSaltareLoZeroEUsareLOrigineNellImmagineMascherata;
    [Test]
    procedure DovrebbeRitagliareLImmagineMascherataAiBordi;
    [Test]
    procedure DovrebbeIlluminareLImmagineConLaTabellaETagliarlaInBasso;
    [Test]
    procedure DovrebbeSollevareSenzaTabellaDeiColori;
    [Test]
    procedure DovrebbeMescolareConLaTabellaDelleTrasparenze;
    [Test]
    procedure DovrebbeNonDisegnareTrasparenzeSenzaTabella;
    [Test]
    procedure DovrebbeComporreSulFotogrammaRaddoppiando;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaDiMisuraSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnImmagineTroppoCorta;
    [Test]
    procedure DovrebbeDareLeMisureDiUnImmagine;
  end;

implementation

{ TTestGreedCanvas }

procedure TTestGreedCanvas.Setup;
begin
  FCanvas := TGreedCanvas.Create(8, 4);
end;

procedure TTestGreedCanvas.TearDown;
begin
  FCanvas.Free;
end;

function TTestGreedCanvas.Picture(const APixels: array of Byte; AWidth, AOriginX, AOriginY: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, GREED_PICTURE_HEADER_BYTES + Length(APixels));
  TGreedLumps.PutWord(Result, 0, AWidth);
  TGreedLumps.PutWord(Result, 2, Length(APixels) div AWidth);
  TGreedLumps.PutWord(Result, 4, AOriginX);
  TGreedLumps.PutWord(Result, 6, AOriginY);
  for LIndex := 0 to High(APixels) do
    Result[GREED_PICTURE_HEADER_BYTES + LIndex] := APixels[LIndex];
end;

procedure TTestGreedCanvas.DovrebbeNascereTuttaAZeroConLeMisureDelloSchermo;
var
  LCanvas: TGreedCanvas;
  LIndex: Integer;
begin
  LCanvas := TGreedCanvas.Create;
  try
    Assert.AreEqual(320, LCanvas.Width);
    Assert.AreEqual(200, LCanvas.Height);
    Assert.AreEqual(64000, Integer(Length(LCanvas.Pixels)));
    for LIndex := 0 to High(LCanvas.Pixels) do
      if LCanvas.Pixels[LIndex] <> 0 then
        Assert.Fail('pixel ' + IntToStr(LIndex));
  finally
    LCanvas.Free;
  end;
end;

procedure TTestGreedCanvas.DovrebbeRifiutareMisureNonValide;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedCanvas.Create(0, 10).Free;
    end, EGreedException);
end;

procedure TTestGreedCanvas.DovrebbeScrivereELeggereUnPixel;
begin
  FCanvas.PutPixel(3, 2, 300);
  Assert.AreEqual(Byte(44), FCanvas.GetPixel(3, 2), 'the low byte of the value');
  Assert.AreEqual(Byte(44), FCanvas.Pixels[2 * 8 + 3]);
  FCanvas.Clear;
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(3, 2));
end;

procedure TTestGreedCanvas.DovrebbeFinireSullaRigaDopoOltreIlBordoDestro;
begin
  // as in the original: ylookup[1][9] is the second byte of the row 2
  FCanvas.PutPixel(9, 1, 7);
  Assert.AreEqual(Byte(7), FCanvas.GetPixel(1, 2));
  Assert.AreEqual(Byte(7), FCanvas.GetPixel(9, 1));
end;

procedure TTestGreedCanvas.DovrebbeIgnorareUnaRigaCheNonEsiste;
var
  LIndex: Integer;
begin
  FCanvas.PutPixel(2, -1, 7);
  FCanvas.PutPixel(2, 4, 7);
  FCanvas.PutPixel(40, 3, 7);
  FCanvas.PutLinear(-1, 7);
  FCanvas.PutLinear(32, 7);
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(2, -1));
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(2, 4));
  for LIndex := 0 to High(FCanvas.Pixels) do
    Assert.AreEqual(Byte(0), FCanvas.Pixels[LIndex]);
end;

procedure TTestGreedCanvas.DovrebbeRiempireSoloDentroIlBuffer;
begin
  FCanvas.FillRow(6, 3, 10, 5);
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(5, 3));
  Assert.AreEqual(Byte(5), FCanvas.GetPixel(6, 3));
  Assert.AreEqual(Byte(5), FCanvas.GetPixel(7, 3));
  FCanvas.FillRow(-3, 0, 5, 9);
  Assert.AreEqual(Byte(9), FCanvas.GetPixel(0, 0));
  Assert.AreEqual(Byte(9), FCanvas.GetPixel(1, 0));
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(2, 0));
  // past the end of a row the bytes go on in the next one
  FCanvas.FillRow(7, 1, 2, 4);
  Assert.AreEqual(Byte(4), FCanvas.GetPixel(0, 2));
end;

procedure TTestGreedCanvas.DovrebbeTradurreLoZeroDellImmaginePienaECambiareLImmagine;
var
  LPicture: TBytes;
begin
  LPicture := Picture([1, 0, 0, 4], 2, 1, 1);
  FCanvas.ApproxZero := 99;
  FCanvas.DrawPicSolid(2, 1, LPicture);
  // the origin is not used
  Assert.AreEqual(Byte(1), FCanvas.GetPixel(2, 1));
  Assert.AreEqual(Byte(99), FCanvas.GetPixel(3, 1));
  Assert.AreEqual(Byte(99), FCanvas.GetPixel(2, 2));
  Assert.AreEqual(Byte(4), FCanvas.GetPixel(3, 2));
  Assert.AreEqual(Byte(99), LPicture[GREED_PICTURE_HEADER_BYTES + 1], 'the picture itself is changed');
end;

procedure TTestGreedCanvas.DovrebbeCopiareLImmagineNonTradottaComeE;
var
  LPicture: TBytes;
begin
  LPicture := Picture([1, 0, 0, 4], 2, 0, 0);
  FCanvas.ApproxZero := 99;
  FCanvas.PutPixel(3, 1, 50);
  FCanvas.DrawPicSolidUntranslated(2, 1, LPicture);
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(3, 1));
  Assert.AreEqual(Byte(4), FCanvas.GetPixel(3, 2));
  Assert.AreEqual(Byte(0), LPicture[GREED_PICTURE_HEADER_BYTES + 1]);
end;

procedure TTestGreedCanvas.DovrebbeSaltareLoZeroEUsareLOrigineNellImmagineMascherata;
var
  LPicture: TBytes;
begin
  LPicture := Picture([1, 0, 3, 4], 2, 1, 1);
  FCanvas.PutPixel(3, 1, 50);
  FCanvas.DrawMaskedPic(3, 2, LPicture);
  Assert.AreEqual(Byte(1), FCanvas.GetPixel(2, 1));
  Assert.AreEqual(Byte(50), FCanvas.GetPixel(3, 1), 'the color 0 is not drawn');
  Assert.AreEqual(Byte(3), FCanvas.GetPixel(2, 2));
  Assert.AreEqual(Byte(4), FCanvas.GetPixel(3, 2));
  FCanvas.Clear;
  FCanvas.DrawMaskedPicToBuffer(3, 2, LPicture);
  Assert.AreEqual(Byte(4), FCanvas.GetPixel(3, 2));
end;

procedure TTestGreedCanvas.DovrebbeRitagliareLImmagineMascherataAiBordi;
var
  LPicture: TBytes;
begin
  LPicture := Picture([1, 2, 3, 4], 2, 0, 0);
  FCanvas.DrawMaskedPic(-1, -1, LPicture);
  Assert.AreEqual(Byte(4), FCanvas.GetPixel(0, 0));
  FCanvas.DrawMaskedPic(7, 3, LPicture);
  Assert.AreEqual(Byte(1), FCanvas.GetPixel(7, 3));
  // nothing went around the edge
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(7, 0));
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(0, 1));
end;

procedure TTestGreedCanvas.DovrebbeIlluminareLImmagineConLaTabellaETagliarlaInBasso;
var
  LPicture: TBytes;
  LColormap: TBytes;
  LIndex: Integer;
begin
  SetLength(LColormap, 256);
  for LIndex := 0 to 255 do
    LColormap[LIndex] := 255 - LIndex;
  LPicture := Picture([1, 0, 255, 4, 5, 6], 2, 1, 1);
  FCanvas.ApproxZero := 77;
  FCanvas.DrawMaskedPicToBuffer2(2, 1, LPicture, @LColormap[0], 3);
  Assert.AreEqual(Byte(254), FCanvas.GetPixel(2, 1), 'the origin is not used');
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(3, 1));
  Assert.AreEqual(Byte(77), FCanvas.GetPixel(2, 2), 'a color the table turns into 0 becomes the approx zero');
  Assert.AreEqual(Byte(251), FCanvas.GetPixel(3, 2));
  Assert.AreEqual(Byte(0), FCanvas.GetPixel(2, 3), 'cut at the height of the window');
end;

procedure TTestGreedCanvas.DovrebbeSollevareSenzaTabellaDeiColori;
begin
  Assert.WillRaise(
    procedure
    begin
      FCanvas.DrawMaskedPicToBuffer2(0, 0, Picture([1], 1, 0, 0), nil, 4);
    end, EArgumentNilException);
end;

procedure TTestGreedCanvas.DovrebbeMescolareConLaTabellaDelleTrasparenze;
var
  LTable: TBytes;
begin
  SetLength(LTable, GREED_TRANSPARENCY_BYTES);
  FillChar(LTable[0], Length(LTable), 0);
  // the color 3 over the color 50 gives 200
  LTable[(3 - 1) * 256 + 50] := 200;
  FCanvas.SetTransparency(LTable);
  FCanvas.PutPixel(1, 1, 50);
  FCanvas.PutPixel(2, 1, 60);
  FCanvas.DrawTransPicToBuffer(1, 1, Picture([3, 0], 2, 0, 0));
  Assert.AreEqual(Byte(200), FCanvas.GetPixel(1, 1));
  Assert.AreEqual(Byte(60), FCanvas.GetPixel(2, 1), 'the color 0 leaves what is below');
end;

procedure TTestGreedCanvas.DovrebbeNonDisegnareTrasparenzeSenzaTabella;
begin
  FCanvas.PutPixel(1, 1, 50);
  FCanvas.DrawTransPicToBuffer(1, 1, Picture([3], 1, 0, 0));
  Assert.AreEqual(Byte(50), FCanvas.GetPixel(1, 1));
end;

procedure TTestGreedCanvas.DovrebbeComporreSulFotogrammaRaddoppiando;
var
  LFrame: TGreedFrame;
  LIndex: Integer;
begin
  LFrame := TGreedFrame.Make(16, 8);
  for LIndex := 0 to High(LFrame.Pixels) do
    LFrame.Pixels[LIndex] := 9;
  FCanvas.PutPixel(1, 1, 5);
  FCanvas.ComposeOnto(LFrame);
  Assert.AreEqual(Byte(5), LFrame.Pixels[2 * 16 + 2]);
  Assert.AreEqual(Byte(5), LFrame.Pixels[2 * 16 + 3]);
  Assert.AreEqual(Byte(5), LFrame.Pixels[3 * 16 + 2]);
  Assert.AreEqual(Byte(5), LFrame.Pixels[3 * 16 + 3]);
  Assert.AreEqual(Byte(9), LFrame.Pixels[2 * 16 + 4], 'the 0 of the canvas lets the level show');
  Assert.AreEqual(Byte(9), LFrame.Pixels[0]);
end;

procedure TTestGreedCanvas.DovrebbeRifiutareUnFotogrammaDiMisuraSbagliata;
begin
  Assert.WillRaise(
    procedure
    var
      LFrame: TGreedFrame;
    begin
      LFrame := TGreedFrame.Make(12, 8);
      FCanvas.ComposeOnto(LFrame);
    end, EGreedException);
end;

procedure TTestGreedCanvas.DovrebbeRifiutareUnImmagineTroppoCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      FCanvas.DrawMaskedPic(0, 0, TBytes.Create(1, 0, 1));
    end, EGreedDataException);
  Assert.WillRaise(
    procedure
    begin
      // says 2 x 2 and has one pixel
      FCanvas.DrawPicSolid(0, 0, TBytes.Create(2, 0, 2, 0, 0, 0, 0, 0, 1));
    end, EGreedDataException);
end;

procedure TTestGreedCanvas.DovrebbeDareLeMisureDiUnImmagine;
begin
  Assert.AreEqual(2, TGreedCanvas.PictureWidth(Picture([1, 2, 3, 4, 5, 6], 2, 0, 0)));
  Assert.AreEqual(3, TGreedCanvas.PictureHeight(Picture([1, 2, 3, 4, 5, 6], 2, 0, 0)));
  Assert.AreEqual(0, TGreedCanvas.PictureWidth(nil));
  Assert.AreEqual(0, TGreedCanvas.PictureHeight(TBytes.Create(1, 2)));
end;

end.

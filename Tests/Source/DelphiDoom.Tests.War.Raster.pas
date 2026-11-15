{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the pixels of a drawing              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Raster;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Render.Blitter;

type
  /// <summary>
  ///   raster.golden.txt is the output of sdl_raster_ref.exe: the REAL software renderer of SDL3 (SDL3.dll of the remake)
  ///   on a 320 x 200 surface, drawing scenarios with a fixed seed (Tools\Verifica\197). The blitter must give the same
  ///   pixels: textures with the nearest scale, flips, color and alpha mod, clipping, fills and outlines
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarRaster = class(TObject)
  private
    FCanvas: TWarImageBlitter;
    FImage: TWarImage;
    function Opaque(AWidth, AHeight: Integer; ARed, AGreen, ABlue, AAlpha: Byte): TWarImage;
    function Pixel(AX, AY, AChannel: Integer): Byte;
    function Blit(AX, AY, AWidth, AHeight: Single; ASourceWidth, ASourceHeight: Integer; AAlpha: Byte): TWarBlit;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareGliStessiPixelDellaSDLVeraSuIScenariDelGoldenSenzaAlfaParziali;
    [Test]
    procedure DovrebbeCopiareUnTexelOpacoNellaPosizioneCortataAIntero;
    [Test]
    procedure DovrebbeIngrandireAlPixelPiuVicinoDalCentroDelPixel;
    [Test]
    procedure DovrebbeSpecchiareOrizzontalmenteEVerticalmente;
    [Test]
    procedure DovrebbeSaltareUnTexelTrasparente;
    [Test]
    procedure DovrebbeFondereConLAlfaDellaTexturePerLAlfaMod;
    [Test]
    procedure DovrebbeRitagliareCioCheEsceDallaTela;
    [Test]
    procedure DovrebbeRiempireUnRettangoloFondendoIlColore;
    [Test]
    procedure DovrebbeNonDisegnareUnRiempimentoVuoto;
    [Test]
    procedure DovrebbeDisegnareUnContornoDiUnPixel;
    [Test]
    procedure DovrebbeRifiutareUnaPartedellImmagineFuoriDallaSorgente;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.Tests.War.RealData, DelphiDoom.Tests.War.RasterScenario;

{ TTestWarRaster }

procedure TTestWarRaster.Setup;
var
  LBlack: TWarRgba;
begin
  FCanvas := TWarImageBlitter.Create(16, 12);
  LBlack.R := 0;
  LBlack.G := 0;
  LBlack.B := 0;
  LBlack.A := 255;
  FCanvas.Clear(LBlack);
end;

procedure TTestWarRaster.TearDown;
begin
  FreeAndNil(FCanvas);
end;

function TTestWarRaster.Opaque(AWidth, AHeight: Integer; ARed, AGreen, ABlue, AAlpha: Byte): TWarImage;
var
  LIndex: Integer;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Pixels, AWidth * AHeight * 4);
  for LIndex := 0 to AWidth * AHeight - 1 do
  begin
    Result.Pixels[LIndex * 4] := ARed;
    Result.Pixels[LIndex * 4 + 1] := AGreen;
    Result.Pixels[LIndex * 4 + 2] := ABlue;
    Result.Pixels[LIndex * 4 + 3] := AAlpha;
  end;
end;

function TTestWarRaster.Pixel(AX, AY, AChannel: Integer): Byte;
begin
  Result := FCanvas.Pixels[(AY * FCanvas.Width + AX) * 4 + AChannel];
end;

function TTestWarRaster.Blit(AX, AY, AWidth, AHeight: Single; ASourceWidth, ASourceHeight: Integer;
  AAlpha: Byte): TWarBlit;
begin
  Result.Source.X := 0;
  Result.Source.Y := 0;
  Result.Source.Width := ASourceWidth;
  Result.Source.Height := ASourceHeight;
  Result.Destination.X := AX;
  Result.Destination.Y := AY;
  Result.Destination.Width := AWidth;
  Result.Destination.Height := AHeight;
  Result.FlipHorizontal := False;
  Result.FlipVertical := False;
  Result.Color.R := 255;
  Result.Color.G := 255;
  Result.Color.B := 255;
  Result.Color.A := AAlpha;
end;

procedure TTestWarRaster.DovrebbeDareGliStessiPixelDellaSDLVeraSuIScenariDelGoldenSenzaAlfaParziali;
var
  LGolden: TStringList;
  LScenario: TRasterScenario;
  LCanvas: TWarImageBlitter;
  LLine: Integer;
  LMode: Integer;
  LParts: TArray<string>;
  LSeen: Integer;
  LDifferent: Integer;
  LLines: Boolean;
begin
  LGolden := TStringList.Create;
  LScenario := TRasterScenario.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('raster.golden.txt'));
    LMode := 0;
    LLines := False;
    LSeen := 0;
    LDifferent := 0;
    for LLine := 0 to LGolden.Count - 1 do
    begin
      if LGolden[LLine] = '' then
        Continue;
      LParts := LGolden[LLine].Split([' ']);
      if (LParts[0] = 'M') or (LParts[0] = 'L') then
      begin
        LMode := StrToInt(LParts[1]);
        LLines := LParts[0] = 'L';
        Continue;
      end;
      if LLines then
        LCanvas := LScenario.RunLines(StrToInt(LParts[1]), LMode)
      else
        LCanvas := LScenario.Run(StrToInt(LParts[1]), LMode);
      try
        Inc(LSeen);
        if LowerCase(IntToHex(TRasterScenario.Hash(LCanvas), 8)) <> LParts[2] then
          Inc(LDifferent);
      finally
        LCanvas.Free;
      end;
    end;
    Assert.IsTrue(LSeen >= 2400, 'Pochi scenari nel golden');
    Assert.AreEqual(0, LDifferent, 'Scenari con pixel diversi da quelli della SDL');
  finally
    LScenario.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarRaster.DovrebbeCopiareUnTexelOpacoNellaPosizioneCortataAIntero;
begin
  FImage := Opaque(1, 1, 10, 20, 30, 255);
  FCanvas.Draw(FImage, Blit(3.9, 2.9, 1, 1, 1, 1, 255));
  Assert.AreEqual<Integer>(10, Pixel(3, 2, 0));
  Assert.AreEqual<Integer>(20, Pixel(3, 2, 1));
  Assert.AreEqual<Integer>(30, Pixel(3, 2, 2));
  Assert.AreEqual<Integer>(0, Pixel(4, 3, 0));
end;

procedure TTestWarRaster.DovrebbeIngrandireAlPixelPiuVicinoDalCentroDelPixel;
var
  LPixels: TBytes;
begin
  // 2 x 1 pixels (red, green) to 4 x 1: two red then two green
  FImage.Width := 2;
  FImage.Height := 1;
  LPixels := [255, 0, 0, 255, 0, 255, 0, 255];
  FImage.Pixels := LPixels;
  FCanvas.Draw(FImage, Blit(0, 0, 4, 1, 2, 1, 255));
  Assert.AreEqual<Integer>(255, Pixel(0, 0, 0));
  Assert.AreEqual<Integer>(255, Pixel(1, 0, 0));
  Assert.AreEqual<Integer>(255, Pixel(2, 0, 1));
  Assert.AreEqual<Integer>(255, Pixel(3, 0, 1));
end;

procedure TTestWarRaster.DovrebbeSpecchiareOrizzontalmenteEVerticalmente;
var
  LPixels: TBytes;
  LBlit: TWarBlit;
begin
  FImage.Width := 2;
  FImage.Height := 2;
  LPixels := [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255];
  FImage.Pixels := LPixels;
  LBlit := Blit(0, 0, 2, 2, 2, 2, 255);
  LBlit.FlipHorizontal := True;
  FCanvas.Draw(FImage, LBlit);
  Assert.AreEqual<Integer>(255, Pixel(0, 0, 1), 'il verde va a sinistra');
  Assert.AreEqual<Integer>(255, Pixel(1, 0, 0), 'il rosso va a destra');
  LBlit.FlipHorizontal := False;
  LBlit.FlipVertical := True;
  LBlit.Destination.X := 4;
  FCanvas.Draw(FImage, LBlit);
  Assert.AreEqual<Integer>(255, Pixel(4, 0, 2), 'il blu va in alto');
  Assert.AreEqual<Integer>(255, Pixel(4, 1, 0), 'il rosso va in basso');
end;

procedure TTestWarRaster.DovrebbeSaltareUnTexelTrasparente;
begin
  FImage := Opaque(1, 1, 200, 200, 200, 0);
  FCanvas.Draw(FImage, Blit(1, 1, 1, 1, 1, 1, 255));
  Assert.AreEqual<Integer>(0, Pixel(1, 1, 0));
  Assert.AreEqual<Integer>(255, Pixel(1, 1, 3));
end;

procedure TTestWarRaster.DovrebbeFondereConLAlfaDellaTexturePerLAlfaMod;
begin
  // (255 * 128) / 255 + (0 * 127) / 255 = 128 (the generic blit of SDL, alpha mod 128)
  FImage := Opaque(1, 1, 255, 255, 255, 255);
  FCanvas.Draw(FImage, Blit(1, 1, 1, 1, 1, 1, 128));
  Assert.AreEqual<Integer>(128, Pixel(1, 1, 0));
  // the alpha of the canvas stays 255: 128 + (255 * 127) / 255
  Assert.AreEqual<Integer>(255, Pixel(1, 1, 3));
end;

procedure TTestWarRaster.DovrebbeRitagliareCioCheEsceDallaTela;
begin
  FImage := Opaque(4, 4, 50, 60, 70, 255);
  FCanvas.Draw(FImage, Blit(-2, -2, 4, 4, 4, 4, 255));
  Assert.AreEqual<Integer>(50, Pixel(0, 0, 0));
  Assert.AreEqual<Integer>(50, Pixel(1, 1, 0));
  Assert.AreEqual<Integer>(0, Pixel(2, 2, 0));
  FCanvas.Draw(FImage, Blit(14, 10, 4, 4, 4, 4, 255));
  Assert.AreEqual<Integer>(50, Pixel(15, 11, 0));
end;

procedure TTestWarRaster.DovrebbeRiempireUnRettangoloFondendoIlColore;
var
  LRect: TWarRectF;
  LColor: TWarRgba;
begin
  LRect.X := 2.5;
  LRect.Y := 3.5;
  LRect.Width := 3.9;
  LRect.Height := 2;
  LColor.R := 255;
  LColor.G := 255;
  LColor.B := 255;
  LColor.A := 128;
  FCanvas.FillRect(LRect, LColor);
  Assert.AreEqual<Integer>(128, Pixel(2, 3, 0));
  Assert.AreEqual<Integer>(128, Pixel(4, 4, 0));
  Assert.AreEqual<Integer>(0, Pixel(5, 3, 0), 'la larghezza 3,9 diventa 3');
  Assert.AreEqual<Integer>(0, Pixel(2, 5, 0));
end;

procedure TTestWarRaster.DovrebbeNonDisegnareUnRiempimentoVuoto;
var
  LRect: TWarRectF;
  LColor: TWarRgba;
begin
  LRect.X := 2;
  LRect.Y := 2;
  LRect.Width := 0.9;
  LRect.Height := 5;
  LColor.R := 255;
  LColor.G := 255;
  LColor.B := 255;
  LColor.A := 255;
  FCanvas.FillRect(LRect, LColor);
  Assert.AreEqual<Integer>(0, Pixel(2, 2, 0), 'la larghezza 0,9 diventa 0 e SDL non disegna nulla');
end;

procedure TTestWarRaster.DovrebbeDisegnareUnContornoDiUnPixel;
var
  LRect: TWarRectF;
  LColor: TWarRgba;
begin
  LRect.X := 1;
  LRect.Y := 1;
  LRect.Width := 5;
  LRect.Height := 4;
  LColor.R := 0;
  LColor.G := 200;
  LColor.B := 0;
  LColor.A := 255;
  FCanvas.StrokeRect(LRect, LColor);
  Assert.AreEqual<Integer>(200, Pixel(1, 1, 1), 'angolo');
  Assert.AreEqual<Integer>(200, Pixel(5, 4, 1), 'angolo opposto: x + w - 1, y + h - 1');
  Assert.AreEqual<Integer>(0, Pixel(3, 2, 1), 'l''interno resta com''e''');
  Assert.AreEqual<Integer>(0, Pixel(6, 4, 1));
end;

procedure TTestWarRaster.DovrebbeRifiutareUnaPartedellImmagineFuoriDallaSorgente;
begin
  FImage := Opaque(2, 2, 1, 1, 1, 255);
  Assert.WillRaise(
    procedure
    begin
      FCanvas.Draw(FImage, Blit(0, 0, 2, 2, 3, 3, 255));
    end, EWarException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarRaster);

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the transform, the blitter and the   }
{  sprite sheet                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Render;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.Types,
  DelphiDoom.War.Graphics.Types, DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform,
  DelphiDoom.War.Render.Blitter, DelphiDoom.War.Sprite.Sheet;

type
  [TestFixture]
  [Category('war')]
  TTestWarRenderTransform = class(TObject)
  private
    FBlits: TList<TWarBlit>;
    FTransform: TWarRenderTransform;
    function Rect(AX, AY, AWidth, AHeight: Single): TWarRectF;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireDallOrigineConScalaUnoETuttoOpaco;
    [Test]
    procedure DovrebbeSpostareLOrigineNelleUnitaDellaScala;
    [Test]
    procedure DovrebbeSalvareERipristinareLoStato;
    [Test]
    procedure DovrebbeSollevareEccezioneSeNonCeUnoStatoDaRipristinare;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaPilaEPiena;
    [Test]
    procedure DovrebbeFareUnBlitSenzaTrasformazione;
    [Test]
    procedure DovrebbeApplicareSpostamentoEScala;
    [Test]
    procedure DovrebbeSpecchiareConUnaScalaNegativa;
    [Test]
    procedure DovrebbeSpostareLOrigineDelRettangoloSeLaScalaDelloStatoENegativa;
    [Test]
    procedure DovrebbeDareLOpacitaDelloStatoComeByte;
    [Test]
    procedure DovrebbeDareIlColoreDellImmagine;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarImageBlitter = class(TObject)
  private
    FBlitter: TWarImageBlitter;
    FSource: TWarImage;
    FBlit: TWarBlit;
    function Pixel(AX, AY: Integer): TWarRgba;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCopiareUnaParteDellImmagine;
    [Test]
    procedure DovrebbeSpecchiareInOrizzontaleEInVerticale;
    [Test]
    procedure DovrebbeIngrandireConIlPixelPiuVicino;
    [Test]
    procedure DovrebbeMoltiplicarePerIlColore;
    [Test]
    procedure DovrebbeFondereConLAlfaDellaSorgenteEDellOpacita;
    [Test]
    procedure DovrebbeTagliareAlBordoDellaTela;
    [Test]
    procedure NonDovrebbeDisegnareUnRettangoloVuoto;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLaParteEFuoriDallaSorgente;
    [Test]
    procedure DovrebbeRiempireLaTela;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarSpriteSheet = class(TObject)
  private
    function MakeSprite(AFrames: Integer): TWarSprite;
  public
    [Test]
    procedure DovrebbeFareUnFotogrammaDaUnImmagine;
    [Test]
    procedure DovrebbeSollevareEccezioneSeIPixelDellImmagineSonoPochi;
    [Test]
    procedure DovrebbeFareUnFotogrammaDaUnCursore;
    [Test]
    procedure DovrebbePrendereTuttiIFotogrammiDiUnoSprite;
    [Test]
    procedure DovrebbePrendereSoloIFotogrammiChiestiNellOrdineChiesto;
    [Test]
    procedure DovrebbeAzzerareLOffsetDeiPixelEcopiarli;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnFotogrammaNonCe;
    [Test]
    procedure DovrebbeSollevareEccezioneSeSonoPiuDiCento;
    [Test]
    procedure DovrebbeSollevareEccezioneSeIPixelDiUnFotogrammaSonoPochi;
    [Test]
    procedure DovrebbeDisegnareLArea;
    [Test]
    procedure DovrebbeDisegnareUnaParte;
  end;

implementation

{ TTestWarRenderTransform }

function TTestWarRenderTransform.Rect(AX, AY, AWidth, AHeight: Single): TWarRectF;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Width := AWidth;
  Result.Height := AHeight;
end;

procedure TTestWarRenderTransform.Setup;
begin
  FBlits := TList<TWarBlit>.Create;
  FTransform := TWarRenderTransform.Create(FBlits);
end;

procedure TTestWarRenderTransform.TearDown;
begin
  FTransform.Free;
  FBlits.Free;
end;

procedure TTestWarRenderTransform.DovrebbePartireDallOrigineConScalaUnoETuttoOpaco;
begin
  Assert.AreEqual<Double>(0.0, Double(FTransform.CurrentState.OffsetX));
  Assert.AreEqual<Double>(1.0, Double(FTransform.CurrentState.ScaleY));
  Assert.AreEqual<Double>(1.0, Double(FTransform.CurrentState.Alpha));
  Assert.AreEqual<Integer>(0, FTransform.Depth);
end;

procedure TTestWarRenderTransform.DovrebbeSpostareLOrigineNelleUnitaDellaScala;
begin
  FTransform.Scale(2, 4);
  FTransform.Translate(10, 5);
  Assert.AreEqual<Double>(20.0, Double(FTransform.CurrentState.OffsetX));
  Assert.AreEqual<Double>(20.0, Double(FTransform.CurrentState.OffsetY));
  FTransform.GlobalAlpha(0.5);
  FTransform.GlobalAlpha(0.5);
  Assert.AreEqual<Double>(0.25, Double(FTransform.CurrentState.Alpha));
end;

procedure TTestWarRenderTransform.DovrebbeSalvareERipristinareLoStato;
begin
  FTransform.Translate(3, 3);
  FTransform.Save;
  FTransform.Translate(4, 4);
  Assert.AreEqual<Integer>(1, FTransform.Depth);
  Assert.AreEqual<Double>(7.0, Double(FTransform.CurrentState.OffsetX));
  FTransform.Restore;
  Assert.AreEqual<Double>(3.0, Double(FTransform.CurrentState.OffsetX));
end;

procedure TTestWarRenderTransform.DovrebbeSollevareEccezioneSeNonCeUnoStatoDaRipristinare;
begin
  Assert.WillRaise(
    procedure
    begin
      FTransform.Restore;
    end, EWarException);
end;

procedure TTestWarRenderTransform.DovrebbeSollevareEccezioneSeLaPilaEPiena;
var
  LIndex: Integer;
begin
  for LIndex := 1 to WAR_MAX_RENDER_STATE_STACK - 1 do
    FTransform.Save;
  Assert.WillRaise(
    procedure
    begin
      FTransform.Save;
    end, EWarException);
end;

procedure TTestWarRenderTransform.DovrebbeFareUnBlitSenzaTrasformazione;
begin
  FTransform.SubImage(Rect(8, 16, 24, 32), Rect(100, 50, 24, 32), 1, 1);
  Assert.AreEqual<Integer>(1, FBlits.Count);
  Assert.AreEqual<Double>(8.0, Double(FBlits[0].Source.X));
  Assert.AreEqual<Double>(100.0, Double(FBlits[0].Destination.X));
  Assert.AreEqual<Double>(32.0, Double(FBlits[0].Destination.Height));
  Assert.IsFalse(FBlits[0].FlipHorizontal);
  Assert.IsFalse(FBlits[0].FlipVertical);
  Assert.AreEqual<Integer>(255, FBlits[0].Color.A);
  Assert.AreEqual<Integer>(255, FBlits[0].Color.R);
end;

procedure TTestWarRenderTransform.DovrebbeApplicareSpostamentoEScala;
begin
  FTransform.Translate(10, 20);
  FTransform.Scale(2, 2);
  FTransform.SubImage(Rect(0, 0, 8, 8), Rect(5, 5, 8, 8), 1, 1);
  Assert.AreEqual<Double>(20.0, Double(FBlits[0].Destination.X));
  Assert.AreEqual<Double>(30.0, Double(FBlits[0].Destination.Y));
  Assert.AreEqual<Double>(16.0, Double(FBlits[0].Destination.Width));
end;

procedure TTestWarRenderTransform.DovrebbeSpecchiareConUnaScalaNegativa;
begin
  FTransform.SubImage(Rect(0, 0, 8, 8), Rect(0, 0, 8, 8), -2, 1);
  Assert.IsTrue(FBlits[0].FlipHorizontal);
  Assert.IsFalse(FBlits[0].FlipVertical);
  Assert.AreEqual<Double>(16.0, Double(FBlits[0].Destination.Width));
  FTransform.SubImage(Rect(0, 0, 8, 8), Rect(0, 0, 8, 8), 1, -1);
  Assert.IsTrue(FBlits[1].FlipVertical);
  FTransform.SubImage(Rect(0, 0, 8, 8), Rect(0, 0, 8, 8), -1, -1);
  Assert.IsTrue(FBlits[2].FlipHorizontal and FBlits[2].FlipVertical);
end;

procedure TTestWarRenderTransform.DovrebbeSpostareLOrigineDelRettangoloSeLaScalaDelloStatoENegativa;
begin
  FTransform.Scale(-1, -1);
  FTransform.SubImage(Rect(0, 0, 8, 6), Rect(10, 10, 8, 6), 1, 1);
  // the origin is at -10 and the rectangle goes left and up of it
  Assert.AreEqual<Double>(-18.0, Double(FBlits[0].Destination.X));
  Assert.AreEqual<Double>(-16.0, Double(FBlits[0].Destination.Y));
  Assert.AreEqual<Double>(8.0, Double(FBlits[0].Destination.Width));
  Assert.IsTrue(FBlits[0].FlipHorizontal);
end;

procedure TTestWarRenderTransform.DovrebbeDareLOpacitaDelloStatoComeByte;
begin
  FTransform.GlobalAlpha(0.5);
  FTransform.SubImage(Rect(0, 0, 1, 1), Rect(0, 0, 1, 1), 1, 1);
  Assert.AreEqual<Integer>(127, FBlits[0].Color.A);
end;

procedure TTestWarRenderTransform.DovrebbeDareIlColoreDellImmagine;
begin
  FTransform.SetColorMod(10, 20, 30);
  FTransform.SubImage(Rect(0, 0, 1, 1), Rect(0, 0, 1, 1), 1, 1);
  Assert.AreEqual<Integer>(20, FBlits[0].Color.G);
  Assert.AreEqual<Integer>(30, FBlits[0].Color.B);
end;

{ TTestWarImageBlitter }

function TTestWarImageBlitter.Pixel(AX, AY: Integer): TWarRgba;
begin
  Result.R := FBlitter.Pixels[(AY * FBlitter.Width + AX) * 4];
  Result.G := FBlitter.Pixels[(AY * FBlitter.Width + AX) * 4 + 1];
  Result.B := FBlitter.Pixels[(AY * FBlitter.Width + AX) * 4 + 2];
  Result.A := FBlitter.Pixels[(AY * FBlitter.Width + AX) * 4 + 3];
end;

procedure TTestWarImageBlitter.Setup;
var
  LIndex: Integer;
begin
  FBlitter := TWarImageBlitter.Create(8, 8);
  // a source of 2 x 2 pixels: red, green / blue, white, all opaque
  FSource.Width := 2;
  FSource.Height := 2;
  SetLength(FSource.Pixels, 16);
  for LIndex := 0 to 15 do
    FSource.Pixels[LIndex] := 0;
  FSource.Pixels[0] := 255; FSource.Pixels[3] := 255;
  FSource.Pixels[5] := 255; FSource.Pixels[7] := 255;
  FSource.Pixels[10] := 255; FSource.Pixels[11] := 255;
  FSource.Pixels[12] := 255; FSource.Pixels[13] := 255; FSource.Pixels[14] := 255; FSource.Pixels[15] := 255;
  FBlit := Default(TWarBlit);
  FBlit.Source.Width := 2;
  FBlit.Source.Height := 2;
  FBlit.Destination.X := 1;
  FBlit.Destination.Y := 1;
  FBlit.Destination.Width := 2;
  FBlit.Destination.Height := 2;
  FBlit.Color.R := 255;
  FBlit.Color.G := 255;
  FBlit.Color.B := 255;
  FBlit.Color.A := 255;
end;

procedure TTestWarImageBlitter.TearDown;
begin
  FBlitter.Free;
end;

procedure TTestWarImageBlitter.DovrebbeCopiareUnaParteDellImmagine;
begin
  FBlitter.Draw(FSource, FBlit);
  Assert.AreEqual<Integer>(255, Pixel(1, 1).R);
  Assert.AreEqual<Integer>(255, Pixel(2, 1).G);
  Assert.AreEqual<Integer>(255, Pixel(1, 2).B);
  Assert.AreEqual<Integer>(255, Pixel(2, 2).R);
  Assert.AreEqual<Integer>(0, Pixel(0, 0).A);
  Assert.AreEqual<Integer>(0, Pixel(3, 3).A);
end;

procedure TTestWarImageBlitter.DovrebbeSpecchiareInOrizzontaleEInVerticale;
begin
  FBlit.FlipHorizontal := True;
  FBlitter.Draw(FSource, FBlit);
  Assert.AreEqual<Integer>(255, Pixel(1, 1).G);
  Assert.AreEqual<Integer>(255, Pixel(2, 1).R);
  FBlitter.Clear(Default(TWarRgba));
  FBlit.FlipHorizontal := False;
  FBlit.FlipVertical := True;
  FBlitter.Draw(FSource, FBlit);
  Assert.AreEqual<Integer>(255, Pixel(1, 1).B);
  Assert.AreEqual<Integer>(255, Pixel(1, 2).R);
end;

procedure TTestWarImageBlitter.DovrebbeIngrandireConIlPixelPiuVicino;
begin
  FBlit.Destination.Width := 4;
  FBlit.Destination.Height := 4;
  FBlitter.Draw(FSource, FBlit);
  Assert.AreEqual<Integer>(255, Pixel(1, 1).R);
  Assert.AreEqual<Integer>(255, Pixel(2, 2).R);
  Assert.AreEqual<Integer>(255, Pixel(3, 1).G);
  Assert.AreEqual<Integer>(255, Pixel(1, 4).B);
  Assert.AreEqual<Integer>(255, Pixel(4, 4).B);
end;

procedure TTestWarImageBlitter.DovrebbeMoltiplicarePerIlColore;
begin
  FBlit.Color.R := 128;
  FBlit.Color.G := 0;
  FBlit.Color.B := 255;
  FBlitter.Draw(FSource, FBlit);
  // the white pixel becomes the color
  Assert.AreEqual<Integer>(128, Pixel(2, 2).R);
  Assert.AreEqual<Integer>(0, Pixel(2, 2).G);
  Assert.AreEqual<Integer>(255, Pixel(2, 2).B);
  // the green of the source is lost with a color that has no green
  Assert.AreEqual<Integer>(0, Pixel(2, 1).G);
end;

procedure TTestWarImageBlitter.DovrebbeFondereConLAlfaDellaSorgenteEDellOpacita;
var
  LBackground: TWarRgba;
begin
  LBackground.R := 0;
  LBackground.G := 0;
  LBackground.B := 200;
  LBackground.A := 255;
  FBlitter.Clear(LBackground);
  FBlit.Color.A := 128;
  FBlitter.Draw(FSource, FBlit);
  // the red pixel at half opacity over blue
  Assert.AreEqual<Integer>(128, Pixel(1, 1).R);
  Assert.AreEqual<Integer>(100, Pixel(1, 1).B);
  Assert.AreEqual<Integer>(255, Pixel(1, 1).A);
  // a source pixel with no alpha leaves what is there
  FSource.Pixels[3] := 0;
  FBlitter.Clear(LBackground);
  FBlit.Color.A := 255;
  FBlitter.Draw(FSource, FBlit);
  Assert.AreEqual<Integer>(200, Pixel(1, 1).B);
  Assert.AreEqual<Integer>(0, Pixel(1, 1).R);
end;

procedure TTestWarImageBlitter.DovrebbeTagliareAlBordoDellaTela;
begin
  FBlit.Destination.X := 7;
  FBlit.Destination.Y := -1;
  FBlitter.Draw(FSource, FBlit);
  // the pixel at the edge takes the lower left of the source (the rectangle starts above the canvas)
  Assert.AreEqual<Integer>(255, Pixel(7, 0).B);
  FBlit.Destination.X := 20;
  FBlitter.Draw(FSource, FBlit);
end;

procedure TTestWarImageBlitter.NonDovrebbeDisegnareUnRettangoloVuoto;
begin
  FBlit.Destination.Width := 0;
  FBlitter.Draw(FSource, FBlit);
  Assert.AreEqual<Integer>(0, Pixel(1, 1).A);
  FBlit.Destination.Width := 2;
  FBlit.Source.Height := 0;
  FBlitter.Draw(FSource, FBlit);
  Assert.AreEqual<Integer>(0, Pixel(1, 1).A);
end;

procedure TTestWarImageBlitter.DovrebbeSollevareEccezioneSeLaParteEFuoriDallaSorgente;
begin
  FBlit.Source.Width := 3;
  Assert.WillRaise(
    procedure
    begin
      FBlitter.Draw(FSource, FBlit);
    end, EWarException);
  FBlit.Source.Width := 2;
  SetLength(FSource.Pixels, 4);
  Assert.WillRaise(
    procedure
    begin
      FBlitter.Draw(FSource, FBlit);
    end, EWarException);
end;

procedure TTestWarImageBlitter.DovrebbeRiempireLaTela;
var
  LColor: TWarRgba;
begin
  LColor.R := 1;
  LColor.G := 2;
  LColor.B := 3;
  LColor.A := 4;
  FBlitter.Clear(LColor);
  Assert.AreEqual<Integer>(3, Pixel(7, 7).B);
  Assert.AreEqual<Integer>(4, Pixel(0, 0).A);
  Assert.AreEqual<Integer>(8, FBlitter.Height);
end;

{ TTestWarSpriteSheet }

function TTestWarSpriteSheet.MakeSprite(AFrames: Integer): TWarSprite;
var
  LIndex: Integer;
begin
  Result.FrameWidth := 4;
  Result.FrameHeight := 3;
  SetLength(Result.Frames, AFrames);
  for LIndex := 0 to AFrames - 1 do
  begin
    Result.Frames[LIndex].Dx := LIndex;
    Result.Frames[LIndex].Dy := 1;
    Result.Frames[LIndex].Width := 2;
    Result.Frames[LIndex].Height := 2;
    Result.Frames[LIndex].Offset := 100 + LIndex;
    SetLength(Result.Frames[LIndex].Pixels, 4 * 3 * 4);
    Result.Frames[LIndex].Pixels[0] := Byte(LIndex);
  end;
end;

procedure TTestWarSpriteSheet.DovrebbeFareUnFotogrammaDaUnImmagine;
var
  LImage: TWarImage;
  LSheet: TWarSpriteSheet;
begin
  LImage.Width := 3;
  LImage.Height := 2;
  SetLength(LImage.Pixels, 24);
  LImage.Pixels[5] := 9;
  LSheet := TWarSpriteSheet.FromImage(LImage);
  try
    Assert.AreEqual<Integer>(1, LSheet.FrameCount);
    Assert.AreEqual<Integer>(3, LSheet.FrameWidth);
    Assert.AreEqual<Integer>(2, LSheet.FrameHeight);
    Assert.AreEqual<Integer>(3, Integer(LSheet.GetFrame(0).Width));
    Assert.AreEqual<Integer>(9, Integer(LSheet.GetFrame(0).Pixels[5]));
    // the pixels are copied
    LImage.Pixels[5] := 1;
    Assert.AreEqual<Integer>(9, Integer(LSheet.GetFrame(0).Pixels[5]));
  finally
    LSheet.Free;
  end;
end;

procedure TTestWarSpriteSheet.DovrebbeSollevareEccezioneSeIPixelDellImmagineSonoPochi;
var
  LImage: TWarImage;
begin
  LImage.Width := 3;
  LImage.Height := 2;
  SetLength(LImage.Pixels, 10);
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteSheet.FromImage(LImage).Free;
    end, EWarException);
end;

procedure TTestWarSpriteSheet.DovrebbeFareUnFotogrammaDaUnCursore;
var
  LCursor: TWarCursor;
  LSheet: TWarSpriteSheet;
begin
  LCursor.HotX := 1;
  LCursor.HotY := 1;
  LCursor.Width := 2;
  LCursor.Height := 2;
  SetLength(LCursor.Pixels, 16);
  LSheet := TWarSpriteSheet.FromCursor(LCursor);
  try
    Assert.AreEqual<Integer>(2, LSheet.FrameWidth);
    Assert.AreEqual<Integer>(1, LSheet.FrameCount);
  finally
    LSheet.Free;
  end;
end;

procedure TTestWarSpriteSheet.DovrebbePrendereTuttiIFotogrammiDiUnoSprite;
var
  LSheet: TWarSpriteSheet;
begin
  LSheet := TWarSpriteSheet.FromSprite(MakeSprite(3), nil);
  try
    Assert.AreEqual<Integer>(3, LSheet.FrameCount);
    Assert.AreEqual<Integer>(4, LSheet.FrameWidth);
    Assert.AreEqual<Integer>(2, Integer(LSheet.GetFrame(2).Dx));
  finally
    LSheet.Free;
  end;
end;

procedure TTestWarSpriteSheet.DovrebbePrendereSoloIFotogrammiChiestiNellOrdineChiesto;
var
  LSheet: TWarSpriteSheet;
begin
  LSheet := TWarSpriteSheet.FromSprite(MakeSprite(5), [4, 0, 4]);
  try
    Assert.AreEqual<Integer>(3, LSheet.FrameCount);
    Assert.AreEqual<Integer>(4, Integer(LSheet.GetFrame(0).Dx));
    Assert.AreEqual<Integer>(0, Integer(LSheet.GetFrame(1).Dx));
    Assert.AreEqual<Integer>(4, Integer(LSheet.GetFrame(2).Pixels[0]));
  finally
    LSheet.Free;
  end;
end;

procedure TTestWarSpriteSheet.DovrebbeAzzerareLOffsetDeiPixelEcopiarli;
var
  LSprite: TWarSprite;
  LSheet: TWarSpriteSheet;
begin
  LSprite := MakeSprite(2);
  LSheet := TWarSpriteSheet.FromSprite(LSprite, nil);
  try
    Assert.AreEqual<Integer>(0, Integer(LSheet.GetFrame(1).Offset));
    LSprite.Frames[1].Pixels[0] := 77;
    Assert.AreEqual<Integer>(1, Integer(LSheet.GetFrame(1).Pixels[0]));
  finally
    LSheet.Free;
  end;
end;

procedure TTestWarSpriteSheet.DovrebbeSollevareEccezioneSeUnFotogrammaNonCe;
var
  LSheet: TWarSpriteSheet;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteSheet.FromSprite(MakeSprite(2), [2]).Free;
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteSheet.FromSprite(MakeSprite(2), [-1]).Free;
    end, EWarException);
  LSheet := TWarSpriteSheet.FromSprite(MakeSprite(2), nil);
  try
    Assert.WillRaise(
      procedure
      begin
        LSheet.GetFrame(2);
      end, EWarException);
    Assert.WillRaise(
      procedure
      begin
        LSheet.GetFrame(-1);
      end, EWarException);
  finally
    LSheet.Free;
  end;
end;

procedure TTestWarSpriteSheet.DovrebbeSollevareEccezioneSeSonoPiuDiCento;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteSheet.FromSprite(MakeSprite(101), nil).Free;
    end, EWarException);
end;

procedure TTestWarSpriteSheet.DovrebbeSollevareEccezioneSeIPixelDiUnFotogrammaSonoPochi;
var
  LSprite: TWarSprite;
begin
  LSprite := MakeSprite(2);
  SetLength(LSprite.Frames[1].Pixels, 5);
  Assert.WillRaise(
    procedure
    begin
      TWarSpriteSheet.FromSprite(LSprite, nil).Free;
    end, EWarException);
end;

procedure TTestWarSpriteSheet.DovrebbeDisegnareLArea;
var
  LBlits: TList<TWarBlit>;
  LTransform: TWarRenderTransform;
  LSheet: TWarSpriteSheet;
begin
  LBlits := TList<TWarBlit>.Create;
  LTransform := TWarRenderTransform.Create(LBlits);
  LSheet := TWarSpriteSheet.FromSprite(MakeSprite(1), nil);
  try
    LSheet.Render(LTransform, 5, 6, -1, 1);
    Assert.AreEqual<Integer>(1, LBlits.Count);
    Assert.AreEqual<Double>(4.0, Double(LBlits[0].Source.Width));
    Assert.AreEqual<Double>(3.0, Double(LBlits[0].Source.Height));
    Assert.AreEqual<Double>(5.0, Double(LBlits[0].Destination.X));
    Assert.IsTrue(LBlits[0].FlipHorizontal);
  finally
    LSheet.Free;
    LTransform.Free;
    LBlits.Free;
  end;
end;

procedure TTestWarSpriteSheet.DovrebbeDisegnareUnaParte;
var
  LBlits: TList<TWarBlit>;
  LTransform: TWarRenderTransform;
  LSheet: TWarSpriteSheet;
  LSource: TWarRectF;
  LDestination: TWarRectF;
begin
  LBlits := TList<TWarBlit>.Create;
  LTransform := TWarRenderTransform.Create(LBlits);
  LSheet := TWarSpriteSheet.FromSprite(MakeSprite(1), nil);
  try
    LSource.X := 1;
    LSource.Y := 1;
    LSource.Width := 2;
    LSource.Height := 2;
    LDestination.X := 10;
    LDestination.Y := 10;
    LDestination.Width := 2;
    LDestination.Height := 2;
    LSheet.RenderPart(LTransform, LSource, LDestination, 3, 3);
    Assert.AreEqual<Double>(6.0, Double(LBlits[0].Destination.Width));
    Assert.AreEqual<Double>(1.0, Double(LBlits[0].Source.X));
  finally
    LSheet.Free;
    LTransform.Free;
    LBlits.Free;
  end;
end;

end.

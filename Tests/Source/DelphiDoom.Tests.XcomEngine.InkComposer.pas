{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the ink layers of TXcomTrueColorComposer (the      }
{  text at the resolution of the display: coverage to alpha over the frame)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.InkComposer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Ink.Types, DelphiDoom.XcomSurface.FontDetail.Intf, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen,
  DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.XcomEngine.TrueColorComposer,
  DelphiDoom.XcomEngine.MemoryTrueColorVideoDevice;

type
  /// <summary>
  ///   A screen of 320 x 200 shown twice as large, filled with the index 10. The "widget" of a test is a surface
  ///   of 8 x 8 at (10, 20) with one pixel of text (index 200) at (3, 3)
  /// </summary>
  [TestFixture]
  [Category('XcomTrueColor')]
  TTestXcomTrueColorComposerInk = class
  strict private
    const
      BACK = 10;
      TEXT_INDEX = 200;
      INK_INDEX = 201;
      WIDGET_X = 10;
      WIDGET_Y = 20;
      WIDGET_SIZE = 8;
    var
      FOptions: TXcomOptions;
      FDevice: TXcomMemoryTrueColorVideoDevice;
      FDeviceRef: IXcomVideoDevice;
      FComposer: TXcomTrueColorComposer;
      FComposerRef: IXcomFrameComposer;
      FInk: IXcomInkLayers;
      FScreen: TXcomScreen;
      FPalette: TXcomColors;
      FWidget: TXcomSurface;
    procedure MakeScreen(ADisplayWidth, ADisplayHeight: Integer);
    function ColorOf(AIndex: Byte): Cardinal;
    function Mixed(AUnder, AColor: Byte; AAlpha: Integer): Cardinal;
    /// <summary>The pixel of the frame that is the sub pixel (ASubX, ASubY) of the pixel (AX, AY) of the widget</summary>
    function Frame(AX, AY: Integer; ASubX: Integer = 0; ASubY: Integer = 0): Cardinal;
    function NewInk: TXcomInkBuffer;
    /// <summary>BeginInk, the blit of the widget, EndInk</summary>
    procedure Leave(const AInk: TXcomInkBuffer; const AUnder: TBytes = nil);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaCoperturaDovrebbeMescolareIlColoreDelTestoConLoSfondo;
    [Test]
    procedure LaCoperturaPienaDovrebbeDareIlColoreDelTesto;
    [Test]
    procedure IlTestoDellImmagineDovrebbeSparireSottoLInchiostro;
    [Test]
    procedure IlContornoDovrebbeStareSottoIlCorpo;
    [Test]
    procedure IlColoreDovrebbeEssereQuelloDellaPalettaDelFlip;
    [Test]
    procedure UnPixelCopertoDopoDovrebbeRestareQuelloDellaBase;
    [Test]
    procedure SottoIlTestoDiUnPulsanteDovrebbeVedersiLaSuaFaccia;
    [Test]
    procedure LInchiostroAccantoAlTestoDovrebbeVedersi;
    [Test]
    procedure LInchiostroLontanoDalTestoNonDovrebbeVedersi;
    [Test]
    procedure UnWidgetCheEsceDalloSchermoDovrebbeEssereRitagliato;
    [Test]
    procedure UnWidgetTuttoFuoriNonDovrebbeLasciareInchiostro;
    [Test]
    procedure SuUnAltraSuperficieNonDovrebbeAccettareInchiostro;
    [Test]
    procedure PrimaDelPrimoFotogrammaNonDovrebbeAccettareInchiostro;
    [Test]
    procedure AScalaUnoNonDovrebbeAccettareInchiostro;
    [Test]
    procedure LInchiostroDovrebbeValerePerUnSoloFotogramma;
    [Test]
    procedure UnInchiostroDiMisuraSbagliataDovrebbeEssereIgnorato;
    [Test]
    procedure LoSchermoAIndiciNonDovrebbeCambiare;
    [Test]
    procedure ATreVolteOgniPixelDelGiocoDovrebbeAvereNoveValori;
  end;

implementation

procedure TTestXcomTrueColorComposerInk.Setup;
var
  LIndex: Integer;
begin
  FOptions := TXcomOptions.Create;
  FDevice := TXcomMemoryTrueColorVideoDevice.Create;
  FDeviceRef := FDevice;
  FComposer := TXcomTrueColorComposer.Create(FDevice);
  FComposerRef := FComposer;
  FInk := FComposer;
  for LIndex := 0 to 255 do
  begin
    FPalette[LIndex].Red := Byte(LIndex);
    FPalette[LIndex].Green := Byte(255 - LIndex);
    FPalette[LIndex].Blue := Byte((LIndex * 7) and $FF);
    FPalette[LIndex].Alpha := 255;
  end;
  FWidget := TXcomSurface.Create(WIDGET_SIZE, WIDGET_SIZE, WIDGET_X, WIDGET_Y);
  // the same palette as the screen: a blit between two palettes looks for the nearest colors
  FWidget.SetColors(FPalette);
  FWidget.SetPixel(3, 3, TEXT_INDEX);
end;

procedure TTestXcomTrueColorComposerInk.TearDown;
begin
  FWidget.Free;
  FScreen.Free;
  FScreen := nil;
  FInk := nil;
  FComposerRef := nil;
  FDeviceRef := nil;
  FOptions.Free;
end;

procedure TTestXcomTrueColorComposerInk.MakeScreen(ADisplayWidth, ADisplayHeight: Integer);
begin
  FOptions.DisplayWidth := ADisplayWidth;
  FOptions.DisplayHeight := ADisplayHeight;
  FOptions.BaseXResolution := 320;
  FOptions.BaseYResolution := 200;
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef, FComposerRef);
  FScreen.SetPalette(@FPalette[0], 0, 256);
  FScreen.GetSurface.Clear(BACK);
  // the composer takes ink only on the picture it has already composed a frame from
  FScreen.Flip;
end;

function TTestXcomTrueColorComposerInk.ColorOf(AIndex: Byte): Cardinal;
begin
  Result := $FF000000 or (Cardinal(FPalette[AIndex].Red) shl 16) or (Cardinal(FPalette[AIndex].Green) shl 8) or
    Cardinal(FPalette[AIndex].Blue);
end;

function TTestXcomTrueColorComposerInk.Mixed(AUnder, AColor: Byte; AAlpha: Integer): Cardinal;

  function Channel(AOver, ABelow: Integer): Cardinal;
  begin
    Result := Cardinal((AOver * AAlpha + ABelow * (255 - AAlpha) + 127) div 255);
  end;

begin
  Result := $FF000000 or (Channel(FPalette[AColor].Red, FPalette[AUnder].Red) shl 16) or
    (Channel(FPalette[AColor].Green, FPalette[AUnder].Green) shl 8) or
    Channel(FPalette[AColor].Blue, FPalette[AUnder].Blue);
end;

function TTestXcomTrueColorComposerInk.Frame(AX, AY, ASubX, ASubY: Integer): Cardinal;
var
  LScale: Integer;
begin
  LScale := FScreen.Width div 320;
  Result := FDevice.TrueColorPixels[((WIDGET_Y + AY) * LScale + ASubY) * FScreen.Width + (WIDGET_X + AX) * LScale +
    ASubX];
end;

function TTestXcomTrueColorComposerInk.NewInk: TXcomInkBuffer;
begin
  Result := TXcomInkBuffer.Make(WIDGET_SIZE, WIDGET_SIZE, FScreen.Width div 320);
end;

procedure TTestXcomTrueColorComposerInk.Leave(const AInk: TXcomInkBuffer; const AUnder: TBytes);
begin
  Assert.IsTrue(FInk.BeginInk(FScreen.GetSurface, WIDGET_X, WIDGET_Y, WIDGET_SIZE, WIDGET_SIZE));
  FWidget.Blit(FScreen.GetSurface);
  FInk.EndInk(FScreen.GetSurface, AInk, AUnder);
end;

procedure TTestXcomTrueColorComposerInk.LaCoperturaDovrebbeMescolareIlColoreDelTestoConLoSfondo;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 128, 0, 0));
  LInk.Put(7, 6, TXcomInkBuffer.Pack(INK_INDEX, 30, 0, 0));
  Leave(LInk);
  FScreen.Flip;
  Assert.AreEqual(Mixed(BACK, INK_INDEX, 128), Frame(3, 3, 0, 0));
  Assert.AreEqual(Mixed(BACK, INK_INDEX, 30), Frame(3, 3, 1, 0));
  // neither the color of the text nor the background: the mix
  Assert.AreNotEqual(ColorOf(INK_INDEX), Frame(3, 3, 0, 0));
  Assert.AreNotEqual(ColorOf(BACK), Frame(3, 3, 0, 0));
end;

procedure TTestXcomTrueColorComposerInk.LaCoperturaPienaDovrebbeDareIlColoreDelTesto;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  FScreen.Flip;
  Assert.AreEqual(ColorOf(INK_INDEX), Frame(3, 3, 0, 0));
end;

procedure TTestXcomTrueColorComposerInk.IlTestoDellImmagineDovrebbeSparireSottoLInchiostro;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  FScreen.Flip;
  // the pixel of the game had the text of the picture: its other three values show what was there before
  Assert.AreEqual(ColorOf(BACK), Frame(3, 3, 1, 0));
  Assert.AreEqual(ColorOf(BACK), Frame(3, 3, 0, 1));
  Assert.AreEqual(ColorOf(BACK), Frame(3, 3, 1, 1));
end;

procedure TTestXcomTrueColorComposerInk.IlContornoDovrebbeStareSottoIlCorpo;
var
  LInk: TXcomInkBuffer;
  LOutline: Cardinal;

  function Channel(AOver, ABelow: Cardinal): Cardinal;
  begin
    Result := (AOver * 128 + ABelow * 127 + 127) div 255;
  end;

begin
  MakeScreen(640, 400);
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 128, 204, 255));
  LInk.Put(7, 7, TXcomInkBuffer.Pack(INK_INDEX, 0, 204, 100));
  Leave(LInk);
  FScreen.Flip;
  // a full outline, then the body half over it
  LOutline := ColorOf(204);
  Assert.AreEqual($FF000000 or (Channel(FPalette[INK_INDEX].Red, (LOutline shr 16) and $FF) shl 16) or
    (Channel(FPalette[INK_INDEX].Green, (LOutline shr 8) and $FF) shl 8) or
    Channel(FPalette[INK_INDEX].Blue, LOutline and $FF), Frame(3, 3, 0, 0));
  Assert.AreEqual(Mixed(BACK, 204, 100), Frame(3, 3, 1, 1));
end;

procedure TTestXcomTrueColorComposerInk.IlColoreDovrebbeEssereQuelloDellaPalettaDelFlip;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  // the palette changes after the widget left its ink (a fade)
  FPalette[INK_INDEX].Red := 1;
  FPalette[INK_INDEX].Green := 2;
  FPalette[INK_INDEX].Blue := 3;
  FScreen.SetPalette(@FPalette[0], 0, 256);
  FScreen.Flip;
  Assert.AreEqual(Cardinal($FF010203), Frame(3, 3, 0, 0));
end;

procedure TTestXcomTrueColorComposerInk.UnPixelCopertoDopoDovrebbeRestareQuelloDellaBase;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  // a window is drawn over the widget
  FScreen.GetSurface.SetPixel(WIDGET_X + 3, WIDGET_Y + 3, 77);
  FScreen.Flip;
  Assert.AreEqual(ColorOf(77), Frame(3, 3, 0, 0));
  Assert.AreEqual(ColorOf(77), Frame(3, 3, 1, 1));
end;

procedure TTestXcomTrueColorComposerInk.SottoIlTestoDiUnPulsanteDovrebbeVedersiLaSuaFaccia;
var
  LInk: TXcomInkBuffer;
  LUnder: TBytes;
  LIndex: Integer;
begin
  MakeScreen(640, 400);
  // a button: a face of the index 150 with the text on it
  FWidget.Clear(150);
  FWidget.SetPixel(3, 3, TEXT_INDEX);
  SetLength(LUnder, WIDGET_SIZE * WIDGET_SIZE);
  for LIndex := 0 to High(LUnder) do
    LUnder[LIndex] := 150;
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 128, 0, 0));
  Leave(LInk, LUnder);
  FScreen.Flip;
  Assert.AreEqual(Mixed(150, INK_INDEX, 128), Frame(3, 3, 0, 0));
  Assert.AreEqual(ColorOf(150), Frame(3, 3, 1, 1));
  // the rest of the button is the picture of the game
  Assert.AreEqual(ColorOf(150), Frame(0, 0, 0, 0));
end;

procedure TTestXcomTrueColorComposerInk.LInchiostroAccantoAlTestoDovrebbeVedersi;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  // the edge of a character: ink on the pixel (5, 3) of the widget, that has no text of the picture
  LInk.Put(10, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  FScreen.Flip;
  Assert.AreEqual(ColorOf(INK_INDEX), Frame(5, 3, 0, 0));
  // its other values stay the frame
  Assert.AreEqual(ColorOf(BACK), Frame(5, 3, 1, 0));
end;

procedure TTestXcomTrueColorComposerInk.LInchiostroLontanoDalTestoNonDovrebbeVedersi;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  // three pixels of the game away from the only pixel of text: it could be something else of the same color
  LInk.Put(12, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  FScreen.Flip;
  Assert.AreEqual(ColorOf(BACK), Frame(6, 3, 0, 0));
end;

procedure TTestXcomTrueColorComposerInk.UnWidgetCheEsceDalloSchermoDovrebbeEssereRitagliato;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  FWidget.X := -2;
  FWidget.Y := -2;
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Assert.IsTrue(FInk.BeginInk(FScreen.GetSurface, -2, -2, WIDGET_SIZE, WIDGET_SIZE));
  FWidget.Blit(FScreen.GetSurface);
  FInk.EndInk(FScreen.GetSurface, LInk, nil);
  FScreen.Flip;
  // the pixel (3, 3) of the widget is the pixel (1, 1) of the screen
  Assert.AreEqual(ColorOf(INK_INDEX), FDevice.TrueColorPixels[2 * 640 + 2]);
  Assert.AreEqual(ColorOf(BACK), FDevice.TrueColorPixels[2 * 640 + 3]);
end;

procedure TTestXcomTrueColorComposerInk.UnWidgetTuttoFuoriNonDovrebbeLasciareInchiostro;
begin
  MakeScreen(640, 400);
  Assert.IsFalse(FInk.BeginInk(FScreen.GetSurface, 320, 0, WIDGET_SIZE, WIDGET_SIZE));
  Assert.IsFalse(FInk.BeginInk(FScreen.GetSurface, 0, -WIDGET_SIZE, WIDGET_SIZE, WIDGET_SIZE));
  Assert.IsFalse(FInk.BeginInk(FScreen.GetSurface, 0, 0, 0, WIDGET_SIZE));
end;

procedure TTestXcomTrueColorComposerInk.SuUnAltraSuperficieNonDovrebbeAccettareInchiostro;
var
  LOther: TXcomSurface;
begin
  MakeScreen(640, 400);
  // a surface as large as the screen that is not the screen (a button, a list, the picture of a globe)
  LOther := TXcomSurface.Create(320, 200);
  try
    Assert.IsFalse(FInk.BeginInk(LOther, WIDGET_X, WIDGET_Y, WIDGET_SIZE, WIDGET_SIZE));
    Assert.IsFalse(FInk.BeginInk(nil, WIDGET_X, WIDGET_Y, WIDGET_SIZE, WIDGET_SIZE));
  finally
    LOther.Free;
  end;
end;

procedure TTestXcomTrueColorComposerInk.PrimaDelPrimoFotogrammaNonDovrebbeAccettareInchiostro;
begin
  FOptions.DisplayWidth := 640;
  FOptions.DisplayHeight := 400;
  FOptions.BaseXResolution := 320;
  FOptions.BaseYResolution := 200;
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef, FComposerRef);
  Assert.IsFalse(FInk.BeginInk(FScreen.GetSurface, WIDGET_X, WIDGET_Y, WIDGET_SIZE, WIDGET_SIZE));
end;

procedure TTestXcomTrueColorComposerInk.AScalaUnoNonDovrebbeAccettareInchiostro;
begin
  MakeScreen(320, 200);
  Assert.IsFalse(FInk.BeginInk(FScreen.GetSurface, WIDGET_X, WIDGET_Y, WIDGET_SIZE, WIDGET_SIZE));
end;

procedure TTestXcomTrueColorComposerInk.LInchiostroDovrebbeValerePerUnSoloFotogramma;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  FScreen.Flip;
  FScreen.Flip;
  // the widget did not leave it again: the text of the picture
  Assert.AreEqual(ColorOf(TEXT_INDEX), Frame(3, 3, 0, 0));
end;

procedure TTestXcomTrueColorComposerInk.UnInchiostroDiMisuraSbagliataDovrebbeEssereIgnorato;
begin
  MakeScreen(640, 400);
  Leave(TXcomInkBuffer.Make(WIDGET_SIZE, WIDGET_SIZE, 3));
  Leave(TXcomInkBuffer.Make(WIDGET_SIZE - 1, WIDGET_SIZE, 2));
  Leave(Default(TXcomInkBuffer));
  Leave(NewInk, [1, 2, 3]);
  // an EndInk without its BeginInk
  FInk.EndInk(FScreen.GetSurface, NewInk, nil);
  FScreen.Flip;
  Assert.AreEqual(ColorOf(TEXT_INDEX), Frame(3, 3, 0, 0));
end;

procedure TTestXcomTrueColorComposerInk.LoSchermoAIndiciNonDovrebbeCambiare;
var
  LInk: TXcomInkBuffer;
  LDisplay: TBytes;
begin
  MakeScreen(640, 400);
  LInk := NewInk;
  LInk.Put(6, 6, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  FScreen.Flip;
  // the screenshot of indexes is the picture of the game, with its text
  LDisplay := FScreen.DisplayPixels;
  Assert.AreEqual(TEXT_INDEX, Integer(LDisplay[(WIDGET_Y + 3) * 2 * 640 + (WIDGET_X + 3) * 2]));
  Assert.AreEqual(TEXT_INDEX, Integer(FScreen.GetSurface.GetPixel(WIDGET_X + 3, WIDGET_Y + 3)));
end;

procedure TTestXcomTrueColorComposerInk.ATreVolteOgniPixelDelGiocoDovrebbeAvereNoveValori;
var
  LInk: TXcomInkBuffer;
begin
  MakeScreen(960, 600);
  LInk := NewInk;
  LInk.Put(3 * 3 + 2, 3 * 3 + 2, TXcomInkBuffer.Pack(INK_INDEX, 255, 0, 0));
  Leave(LInk);
  FScreen.Flip;
  Assert.AreEqual(ColorOf(INK_INDEX), Frame(3, 3, 2, 2));
  Assert.AreEqual(ColorOf(BACK), Frame(3, 3, 0, 0));
  Assert.AreEqual(ColorOf(BACK), Frame(3, 3, 1, 2));
end;

end.

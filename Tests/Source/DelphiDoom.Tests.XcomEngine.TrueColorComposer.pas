{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the composition of the frame in true color         }
{  (issue 183): the frame is the 8 bit picture of the screen after its palette  }
{  at any scale, and the detail layers of the widgets keep the order of blits   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.TrueColorComposer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.XcomEngine.TrueColorComposer,
  DelphiDoom.XcomEngine.MemoryTrueColorVideoDevice;

type
  [TestFixture]
  [Category('XcomTrueColor')]
  TTestXcomTrueColorComposer = class
  strict private
    FOptions: TXcomOptions;
    FDevice: TXcomMemoryTrueColorVideoDevice;
    FDeviceRef: IXcomVideoDevice;
    FComposer: TXcomTrueColorComposer;
    FComposerRef: IXcomFrameComposer;
    FScreen: TXcomScreen;
    FPalette: TXcomColors;
    procedure MakeScreen(ADisplayWidth, ADisplayHeight, ABaseWidth, ABaseHeight: Integer);
    procedure FillBase;
    function ColorOf(AIndex: Byte): Cardinal;
    procedure AssertFrameIsDisplayAfterPalette;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure AScalaUnoIlFotogrammaDovrebbeEssereLaBaseDopoLaPaletta;
    [Test]
    [TestCase('doppio', '640,400')]
    [TestCase('triplo', '960,600')]
    [TestCase('non intero', '500,333')]
    [TestCase('bande ai lati', '800,400')]
    [TestCase('bande sopra e sotto', '640,600')]
    procedure IlFotogrammaDovrebbeEssereLoZoomAIndiciDopoLaPaletta(ADisplayWidth, ADisplayHeight: Integer);
    [Test]
    procedure LaPalettaDovrebbeEssereQuellaDelMomentoDelFlip;
    [Test]
    procedure UnDispositivoCheRifiutaDovrebbeRicevereLImmagineAOttoBit;
    [Test]
    procedure SenzaCompositoreLoSchermoNonDovrebbeDareFotogrammiAColori;
    [Test]
    procedure SenzaCompositoreLoSchermoNonDovrebbeAvereStratiDiDettaglio;
    [Test]
    [TestCase('doppio', '640,400,2')]
    [TestCase('quadruplo', '1280,800,4')]
    [TestCase('non intero', '500,333,1')]
    [TestCase('con bande', '800,400,1')]
    [TestCase('scale diverse', '640,600,1')]
    procedure LaScalaDiDettaglioDovrebbeEssereInteraESenzaBande(ADisplayWidth, ADisplayHeight, AScale: Integer);
    [Test]
    procedure UnoStratoDovrebbeDareIPixelDiDettaglioDoveIlWidgetSiVede;
    [Test]
    procedure UnPixelCopertoDopoDovrebbeRestareQuelloDellaBase;
    [Test]
    procedure DoveIlDettaglioETrasparenteDovrebbeVedersiCioCheCEraPrima;
    [Test]
    procedure GliStratiDovrebberoValerePerUnSoloFotogramma;
    [Test]
    procedure UnoStratoDiMisuraSbagliataDovrebbeEssereIgnorato;
    [Test]
    procedure AScalaUnoGliStratiDovrebberoEssereIgnorati;
    [Test]
    procedure SenzaDispositivoDovrebbeSollevare;
  end;

implementation

procedure TTestXcomTrueColorComposer.Setup;
var
  LIndex: Integer;
begin
  FOptions := TXcomOptions.Create;
  FDevice := TXcomMemoryTrueColorVideoDevice.Create;
  FDeviceRef := FDevice;
  FComposer := TXcomTrueColorComposer.Create(FDevice);
  FComposerRef := FComposer;
  // every index has its own color, none of them gray
  for LIndex := 0 to 255 do
  begin
    FPalette[LIndex].Red := Byte(LIndex);
    FPalette[LIndex].Green := Byte(255 - LIndex);
    FPalette[LIndex].Blue := Byte((LIndex * 7) and $FF);
    FPalette[LIndex].Alpha := 255;
  end;
end;

procedure TTestXcomTrueColorComposer.TearDown;
begin
  FScreen.Free;
  FScreen := nil;
  FComposerRef := nil;
  FDeviceRef := nil;
  FOptions.Free;
end;

procedure TTestXcomTrueColorComposer.MakeScreen(ADisplayWidth, ADisplayHeight, ABaseWidth, ABaseHeight: Integer);
begin
  FOptions.DisplayWidth := ADisplayWidth;
  FOptions.DisplayHeight := ADisplayHeight;
  FOptions.BaseXResolution := ABaseWidth;
  FOptions.BaseYResolution := ABaseHeight;
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef, FComposerRef);
  FScreen.SetPalette(@FPalette[0], 0, 256);
end;

procedure TTestXcomTrueColorComposer.FillBase;
var
  LX: Integer;
  LY: Integer;
begin
  // no two neighbours alike: a pixel taken from the wrong place is seen
  for LY := 0 to FScreen.GetSurface.Height - 1 do
    for LX := 0 to FScreen.GetSurface.Width - 1 do
      FScreen.GetSurface.SetPixel(LX, LY, Byte((LX * 3 + LY * 5) mod 251 + 1));
end;

function TTestXcomTrueColorComposer.ColorOf(AIndex: Byte): Cardinal;
begin
  Result := $FF000000 or (Cardinal(FPalette[AIndex].Red) shl 16) or (Cardinal(FPalette[AIndex].Green) shl 8) or
    Cardinal(FPalette[AIndex].Blue);
end;

procedure TTestXcomTrueColorComposer.AssertFrameIsDisplayAfterPalette;
var
  LIndex: Integer;
  LDisplay: TBytes;
begin
  LDisplay := FScreen.DisplayPixels;
  Assert.AreEqual(FScreen.Width, FDevice.TrueColorWidth);
  Assert.AreEqual(FScreen.Height, FDevice.TrueColorHeight);
  Assert.AreEqual(Length(LDisplay), Length(FDevice.TrueColorPixels));
  for LIndex := 0 to High(LDisplay) do
    if FDevice.TrueColorPixels[LIndex] <> ColorOf(LDisplay[LIndex]) then
      Assert.Fail(Format('pixel %d: %x al posto di %x', [LIndex, FDevice.TrueColorPixels[LIndex],
        ColorOf(LDisplay[LIndex])]));
end;

procedure TTestXcomTrueColorComposer.AScalaUnoIlFotogrammaDovrebbeEssereLaBaseDopoLaPaletta;
var
  LIndex: Integer;
  LBase: TBytes;
begin
  MakeScreen(320, 200, 320, 200);
  FillBase;
  FScreen.Flip;
  Assert.AreEqual(1, FDevice.TrueColorPresented);
  LBase := FScreen.GetSurface.Pixels;
  Assert.AreEqual(320 * 200, Length(FDevice.TrueColorPixels));
  for LIndex := 0 to 320 * 200 - 1 do
    if FDevice.TrueColorPixels[LIndex] <> ColorOf(LBase[LIndex]) then
      Assert.Fail(Format('pixel %d', [LIndex]));
end;

procedure TTestXcomTrueColorComposer.IlFotogrammaDovrebbeEssereLoZoomAIndiciDopoLaPaletta(ADisplayWidth,
  ADisplayHeight: Integer);
begin
  MakeScreen(ADisplayWidth, ADisplayHeight, 320, 200);
  FillBase;
  FScreen.Flip;
  Assert.AreEqual(1, FDevice.TrueColorPresented);
  Assert.AreEqual(0, FDevice.Presented, 'niente immagine a 8 bit quando il fotogramma a colori e'' stato mostrato');
  AssertFrameIsDisplayAfterPalette;
end;

procedure TTestXcomTrueColorComposer.LaPalettaDovrebbeEssereQuellaDelMomentoDelFlip;
var
  LColor: TXcomColor;
begin
  MakeScreen(640, 400, 320, 200);
  FillBase;
  FScreen.Flip;
  // a fade: the same indexes, another color
  LColor.Red := 1;
  LColor.Green := 2;
  LColor.Blue := 3;
  LColor.Alpha := 255;
  FPalette[FScreen.GetSurface.GetPixel(0, 0)] := LColor;
  FScreen.SetPalette(@FPalette[0], 0, 256);
  FScreen.Flip;
  Assert.AreEqual(Cardinal($FF010203), FDevice.TrueColorPixels[0]);
  AssertFrameIsDisplayAfterPalette;
end;

procedure TTestXcomTrueColorComposer.UnDispositivoCheRifiutaDovrebbeRicevereLImmagineAOttoBit;
begin
  MakeScreen(640, 400, 320, 200);
  FillBase;
  FDevice.Refuses := True;
  FScreen.Flip;
  Assert.AreEqual(0, FDevice.TrueColorPresented);
  Assert.AreEqual(1, FDevice.Presented);
  Assert.AreEqual(640, FDevice.Width);
end;

procedure TTestXcomTrueColorComposer.SenzaCompositoreLoSchermoNonDovrebbeDareFotogrammiAColori;
begin
  FOptions.DisplayWidth := 640;
  FOptions.DisplayHeight := 400;
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef);
  FScreen.Flip;
  Assert.AreEqual(0, FDevice.TrueColorPresented);
  Assert.AreEqual(1, FDevice.Presented);
end;

procedure TTestXcomTrueColorComposer.SenzaCompositoreLoSchermoNonDovrebbeAvereStratiDiDettaglio;
begin
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef);
  Assert.IsTrue(FScreen.DetailLayers = nil);
end;

procedure TTestXcomTrueColorComposer.LaScalaDiDettaglioDovrebbeEssereInteraESenzaBande(ADisplayWidth,
  ADisplayHeight, AScale: Integer);
begin
  MakeScreen(ADisplayWidth, ADisplayHeight, 320, 200);
  Assert.AreEqual(AScale, FScreen.DetailLayers.DetailScale);
end;

procedure TTestXcomTrueColorComposer.UnoStratoDovrebbeDareIPixelDiDettaglioDoveIlWidgetSiVede;
var
  LWidget: TXcomSurface;
  LDetail: TXcomSurface;
begin
  MakeScreen(640, 400, 320, 200);
  FillBase;
  LWidget := TXcomSurface.Create(4, 4, 10, 20);
  LDetail := TXcomSurface.Create(8, 8);
  try
    LWidget.DrawRect(0, 0, 4, 4, 200);
    // the detail: a diagonal that the game picture cannot show
    LDetail.DrawRect(0, 0, 8, 8, 200);
    LDetail.SetPixel(0, 0, 201);
    LDetail.SetPixel(1, 1, 202);
    FScreen.DetailLayers.BeginLayer(FScreen.GetSurface, 10, 20, 4, 4);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.DetailLayers.EndLayer(FScreen.GetSurface, LDetail);
    FScreen.Flip;
    Assert.AreEqual(ColorOf(201), FDevice.TrueColorPixels[40 * 640 + 20]);
    Assert.AreEqual(ColorOf(200), FDevice.TrueColorPixels[40 * 640 + 21]);
    Assert.AreEqual(ColorOf(202), FDevice.TrueColorPixels[41 * 640 + 21]);
    // outside the rectangle the frame is the game picture
    Assert.AreEqual(ColorOf(FScreen.GetSurface.GetPixel(9, 20)), FDevice.TrueColorPixels[40 * 640 + 19]);
    Assert.AreEqual(ColorOf(FScreen.GetSurface.GetPixel(14, 20)), FDevice.TrueColorPixels[40 * 640 + 28]);
  finally
    LDetail.Free;
    LWidget.Free;
  end;
end;

procedure TTestXcomTrueColorComposer.UnPixelCopertoDopoDovrebbeRestareQuelloDellaBase;
var
  LWidget: TXcomSurface;
  LDetail: TXcomSurface;
begin
  MakeScreen(640, 400, 320, 200);
  LWidget := TXcomSurface.Create(4, 4, 10, 20);
  LDetail := TXcomSurface.Create(8, 8);
  try
    LWidget.DrawRect(0, 0, 4, 4, 200);
    LDetail.DrawRect(0, 0, 8, 8, 201);
    FScreen.DetailLayers.BeginLayer(FScreen.GetSurface, 10, 20, 4, 4);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.DetailLayers.EndLayer(FScreen.GetSurface, LDetail);
    // a button, a popup or the cursor drawn after the widget
    FScreen.GetSurface.SetPixel(11, 21, 77);
    FScreen.Flip;
    Assert.AreEqual(ColorOf(77), FDevice.TrueColorPixels[42 * 640 + 22]);
    Assert.AreEqual(ColorOf(77), FDevice.TrueColorPixels[43 * 640 + 23]);
    Assert.AreEqual(ColorOf(201), FDevice.TrueColorPixels[42 * 640 + 20]);
    Assert.AreEqual(ColorOf(201), FDevice.TrueColorPixels[42 * 640 + 24]);
  finally
    LDetail.Free;
    LWidget.Free;
  end;
end;

procedure TTestXcomTrueColorComposer.DoveIlDettaglioETrasparenteDovrebbeVedersiCioCheCEraPrima;
var
  LWidget: TXcomSurface;
  LDetail: TXcomSurface;
begin
  MakeScreen(640, 400, 320, 200);
  FScreen.GetSurface.DrawRect(0, 0, 320, 200, 50);
  LWidget := TXcomSurface.Create(4, 4, 10, 20);
  LDetail := TXcomSurface.Create(8, 8);
  try
    // the widget fills its pixel, the finer drawing leaves a corner of it empty (the rim of a disc)
    LWidget.DrawRect(0, 0, 4, 4, 200);
    LDetail.DrawRect(0, 0, 8, 8, 200);
    LDetail.SetPixel(0, 0, 0);
    FScreen.DetailLayers.BeginLayer(FScreen.GetSurface, 10, 20, 4, 4);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.DetailLayers.EndLayer(FScreen.GetSurface, LDetail);
    FScreen.Flip;
    Assert.AreEqual(ColorOf(50), FDevice.TrueColorPixels[40 * 640 + 20]);
    Assert.AreEqual(ColorOf(200), FDevice.TrueColorPixels[40 * 640 + 21]);
  finally
    LDetail.Free;
    LWidget.Free;
  end;
end;

procedure TTestXcomTrueColorComposer.GliStratiDovrebberoValerePerUnSoloFotogramma;
var
  LWidget: TXcomSurface;
  LDetail: TXcomSurface;
begin
  MakeScreen(640, 400, 320, 200);
  LWidget := TXcomSurface.Create(4, 4, 10, 20);
  LDetail := TXcomSurface.Create(8, 8);
  try
    LWidget.DrawRect(0, 0, 4, 4, 200);
    LDetail.DrawRect(0, 0, 8, 8, 201);
    FScreen.DetailLayers.BeginLayer(FScreen.GetSurface, 10, 20, 4, 4);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.DetailLayers.EndLayer(FScreen.GetSurface, LDetail);
    FScreen.Flip;
    Assert.AreEqual(ColorOf(201), FDevice.TrueColorPixels[40 * 640 + 20]);
    // the widget did not blit again: its detail is not kept
    FScreen.Flip;
    Assert.AreEqual(ColorOf(FScreen.GetSurface.GetPixel(10, 20)), FDevice.TrueColorPixels[40 * 640 + 20]);
    AssertFrameIsDisplayAfterPalette;
  finally
    LDetail.Free;
    LWidget.Free;
  end;
end;

procedure TTestXcomTrueColorComposer.UnoStratoDiMisuraSbagliataDovrebbeEssereIgnorato;
var
  LDetail: TXcomSurface;
  LOther: TXcomSurface;
begin
  MakeScreen(640, 400, 320, 200);
  FillBase;
  LDetail := TXcomSurface.Create(7, 8);
  LOther := TXcomSurface.Create(64, 64);
  try
    LDetail.DrawRect(0, 0, 7, 8, 201);
    // a detail that is not twice the rectangle
    FScreen.DetailLayers.BeginLayer(FScreen.GetSurface, 10, 20, 4, 4);
    FScreen.DetailLayers.EndLayer(FScreen.GetSurface, LDetail);
    // a rectangle that leaves the picture, a surface that is not the picture, an end without a begin
    FScreen.DetailLayers.BeginLayer(FScreen.GetSurface, 318, 20, 4, 4);
    FScreen.DetailLayers.EndLayer(FScreen.GetSurface, LDetail);
    FScreen.DetailLayers.BeginLayer(LOther, 0, 0, 4, 4);
    FScreen.DetailLayers.EndLayer(LOther, LDetail);
    FScreen.DetailLayers.EndLayer(FScreen.GetSurface, LDetail);
    FScreen.Flip;
    AssertFrameIsDisplayAfterPalette;
  finally
    LOther.Free;
    LDetail.Free;
  end;
end;

procedure TTestXcomTrueColorComposer.AScalaUnoGliStratiDovrebberoEssereIgnorati;
var
  LDetail: TXcomSurface;
begin
  MakeScreen(320, 200, 320, 200);
  FillBase;
  LDetail := TXcomSurface.Create(4, 4);
  try
    LDetail.DrawRect(0, 0, 4, 4, 201);
    FScreen.DetailLayers.BeginLayer(FScreen.GetSurface, 10, 20, 4, 4);
    FScreen.DetailLayers.EndLayer(FScreen.GetSurface, LDetail);
    FScreen.Flip;
    AssertFrameIsDisplayAfterPalette;
  finally
    LDetail.Free;
  end;
end;

procedure TTestXcomTrueColorComposer.SenzaDispositivoDovrebbeSollevare;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomTrueColorComposer.Create(nil);
    end, EArgumentNilException);
end;

end.

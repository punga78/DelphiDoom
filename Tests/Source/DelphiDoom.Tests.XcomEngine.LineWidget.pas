{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the surface of lines that is also drawn at the     }
{  resolution of the window (issue 183)                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.LineWidget;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Clock.Intf, DelphiDoom.Xcom.Types,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.XcomEngine.TrueColorComposer,
  DelphiDoom.XcomEngine.MemoryTrueColorVideoDevice, DelphiDoom.XcomEngine.LineWidget;

type
  /// <summary>A host that only has a screen (not owned)</summary>
  TScreenOnlyHost = class(TXcomStateHost)
  public
    TheScreen: TXcomScreen;
    function Screen: TXcomScreen; override;
    function Cursor: TXcomInteractiveSurface; override;
    function FpsCounter: TXcomInteractiveSurface; override;
    function Language: TXcomLanguage; override;
    function Resources: IXcomResources; override;
    function Options: TXcomOptions; override;
    function Clock: IClock; override;
    procedure PushState(AState: TXcomState); override;
    procedure PopState; override;
    procedure SetState(AState: TXcomState); override;
    procedure Quit; override;
    procedure AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage); override;
    function IsState(AState: TXcomState): Boolean; override;
  end;

  [TestFixture]
  [Category('XcomTrueColor')]
  TTestXcomLineWidget = class
  strict private
    FOptions: TXcomOptions;
    FDevice: TXcomMemoryTrueColorVideoDevice;
    FDeviceRef: IXcomVideoDevice;
    FComposer: IXcomFrameComposer;
    FScreen: TXcomScreen;
    FHost: TScreenOnlyHost;
    FPalette: TXcomColors;
    procedure MakeScreen(AScale: Integer; ATrueColor: Boolean);
    function ColorOf(AIndex: Byte): Cardinal;
    /// <summary>The pixels of the frame that are not the game picture enlarged</summary>
    function FinerPixels: Integer;
    function FrameCount(AColor: Byte): Integer;
    function NewWidget(AHost: TXcomStateHost): TXcomLineWidget;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LImmagineDelGiocoDovrebbeAvereLeLineeDiSempre;
    [Test]
    procedure SenzaCompositoreNonDovrebbeLasciareStrati;
    [Test]
    procedure UnaLineaOrizzontaleDovrebbeEssereQuellaDelGiocoIngrandita;
    [Test]
    [TestCase('doppio', '2')]
    [TestCase('quadruplo', '4')]
    procedure UnaLineaObliquaDovrebbeEsserePiuFineDentroIlSuoRettangolo(AScale: Integer);
    [Test]
    procedure DueSuperficiImpilateDovrebberoTenereEntrambeIlLoroDisegnoFine;
    [Test]
    procedure UnaSuperficieNascostaNonDovrebbeLasciareNulla;
    [Test]
    procedure ClearLinesDovrebbeDimenticareLeLinee;
    [Test]
    procedure SenzaHostDovrebbeEssereUnaSuperficieQualsiasi;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Gfx;

{ TScreenOnlyHost }

function TScreenOnlyHost.Screen: TXcomScreen;
begin
  Result := TheScreen;
end;

function TScreenOnlyHost.Cursor: TXcomInteractiveSurface;
begin
  Result := nil;
end;

function TScreenOnlyHost.FpsCounter: TXcomInteractiveSurface;
begin
  Result := nil;
end;

function TScreenOnlyHost.Language: TXcomLanguage;
begin
  Result := nil;
end;

function TScreenOnlyHost.Resources: IXcomResources;
begin
  Result := nil;
end;

function TScreenOnlyHost.Options: TXcomOptions;
begin
  Result := nil;
end;

function TScreenOnlyHost.Clock: IClock;
begin
  Result := nil;
end;

procedure TScreenOnlyHost.PushState(AState: TXcomState);
begin
end;

procedure TScreenOnlyHost.PopState;
begin
end;

procedure TScreenOnlyHost.SetState(AState: TXcomState);
begin
end;

procedure TScreenOnlyHost.Quit;
begin
end;

procedure TScreenOnlyHost.AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage);
begin
end;

function TScreenOnlyHost.IsState(AState: TXcomState): Boolean;
begin
  Result := False;
end;

{ TTestXcomLineWidget }

procedure TTestXcomLineWidget.Setup;
var
  LIndex: Integer;
begin
  FOptions := TXcomOptions.Create;
  FDevice := TXcomMemoryTrueColorVideoDevice.Create;
  FDeviceRef := FDevice;
  FHost := TScreenOnlyHost.Create;
  for LIndex := 0 to 255 do
  begin
    FPalette[LIndex].Red := Byte(LIndex);
    FPalette[LIndex].Green := Byte(255 - LIndex);
    FPalette[LIndex].Blue := Byte((LIndex * 7) and $FF);
    FPalette[LIndex].Alpha := 255;
  end;
end;

procedure TTestXcomLineWidget.TearDown;
begin
  FScreen.Free;
  FScreen := nil;
  FComposer := nil;
  FDeviceRef := nil;
  FHost.Free;
  FOptions.Free;
end;

procedure TTestXcomLineWidget.MakeScreen(AScale: Integer; ATrueColor: Boolean);
begin
  FOptions.DisplayWidth := 320 * AScale;
  FOptions.DisplayHeight := 200 * AScale;
  FOptions.BaseXResolution := 320;
  FOptions.BaseYResolution := 200;
  if ATrueColor then
    FComposer := TXcomTrueColorComposer.Create(FDevice);
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef, FComposer);
  FScreen.SetPalette(@FPalette[0], 0, 256);
  FScreen.GetSurface.DrawRect(0, 0, 320, 200, 9);
  FHost.TheScreen := FScreen;
end;

function TTestXcomLineWidget.ColorOf(AIndex: Byte): Cardinal;
begin
  Result := $FF000000 or (Cardinal(FPalette[AIndex].Red) shl 16) or (Cardinal(FPalette[AIndex].Green) shl 8) or
    Cardinal(FPalette[AIndex].Blue);
end;

function TTestXcomLineWidget.FinerPixels: Integer;
var
  LDisplay: TBytes;
  LIndex: Integer;
begin
  Result := 0;
  LDisplay := FScreen.DisplayPixels;
  for LIndex := 0 to High(LDisplay) do
    if FDevice.TrueColorPixels[LIndex] <> ColorOf(LDisplay[LIndex]) then
      Inc(Result);
end;

function TTestXcomLineWidget.FrameCount(AColor: Byte): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FDevice.TrueColorPixels) do
    if FDevice.TrueColorPixels[LIndex] = ColorOf(AColor) then
      Inc(Result);
end;

function TTestXcomLineWidget.NewWidget(AHost: TXcomStateHost): TXcomLineWidget;
begin
  // with the palette of the screen, as a state gives it to its surfaces (a blit maps the colors by palette)
  Result := TXcomLineWidget.Create(AHost, 320, 200, 0, 0);
  Result.SetPalette(@FPalette[0], 0, 256);
end;

procedure TTestXcomLineWidget.LImmagineDelGiocoDovrebbeAvereLeLineeDiSempre;
var
  LWidget: TXcomLineWidget;
  LPlain: TXcomSurface;
  LIndex: Integer;
begin
  MakeScreen(4, True);
  LWidget := NewWidget(FHost);
  LPlain := TXcomSurface.Create(320, 200);
  LPlain.SetColors(FPalette);
  try
    LWidget.Line(10, 20, 27, 61, 200);
    LWidget.Line(27, 61, 44, 30, 200);
    LWidget.Line(300, 5, 5, 190, 201);
    TXcomGfx.DrawLine(LPlain, 10, 20, 27, 61, 200);
    TXcomGfx.DrawLine(LPlain, 27, 61, 44, 30, 200);
    TXcomGfx.DrawLine(LPlain, 300, 5, 5, 190, 201);
    Assert.AreEqual(3, LWidget.LineCount);
    for LIndex := 0 to 320 * 200 - 1 do
      if LWidget.Pixels[LIndex] <> LPlain.Pixels[LIndex] then
        Assert.Fail(Format('pixel %d', [LIndex]));
  finally
    LPlain.Free;
    LWidget.Free;
  end;
end;

procedure TTestXcomLineWidget.SenzaCompositoreNonDovrebbeLasciareStrati;
var
  LWidget: TXcomLineWidget;
begin
  MakeScreen(4, False);
  LWidget := NewWidget(FHost);
  try
    LWidget.Line(10, 20, 27, 61, 200);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.Flip;
    Assert.AreEqual(0, FDevice.TrueColorPresented);
    Assert.AreEqual(200, Integer(FScreen.GetSurface.GetPixel(10, 20)));
  finally
    LWidget.Free;
  end;
end;

procedure TTestXcomLineWidget.UnaLineaOrizzontaleDovrebbeEssereQuellaDelGiocoIngrandita;
var
  LWidget: TXcomLineWidget;
begin
  MakeScreen(4, True);
  LWidget := NewWidget(FHost);
  try
    LWidget.Line(10, 20, 60, 20, 200);
    LWidget.Line(70, 30, 70, 90, 200);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.Flip;
    Assert.AreEqual(0, FinerPixels);
  finally
    LWidget.Free;
  end;
end;

procedure TTestXcomLineWidget.UnaLineaObliquaDovrebbeEsserePiuFineDentroIlSuoRettangolo(AScale: Integer);
var
  LWidget: TXcomLineWidget;
  LDisplay: TBytes;
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
begin
  MakeScreen(AScale, True);
  LWidget := NewWidget(FHost);
  try
    LWidget.Line(100, 50, 117, 91, 200);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.Flip;
    Assert.IsTrue(FinerPixels > 0, 'il disegno fine toglie i gradini');
    // the two ends are where the game picture has them
    Assert.AreEqual(ColorOf(200), FDevice.TrueColorPixels[(50 * AScale) * FScreen.Width + 100 * AScale]);
    Assert.AreEqual(ColorOf(200),
      FDevice.TrueColorPixels[(91 * AScale + AScale - 1) * FScreen.Width + 117 * AScale + AScale - 1]);
    // nothing changes outside the rectangle of the line
    LDisplay := FScreen.DisplayPixels;
    for LY := 0 to FScreen.Height - 1 do
      for LX := 0 to FScreen.Width - 1 do
      begin
        LIndex := LY * FScreen.Width + LX;
        if (FDevice.TrueColorPixels[LIndex] <> ColorOf(LDisplay[LIndex])) and ((LX < 100 * AScale)
          or (LX >= 118 * AScale) or (LY < 50 * AScale) or (LY >= 92 * AScale)) then
          Assert.Fail(Format('pixel %d,%d fuori dal rettangolo', [LX, LY]));
      end;
    // the line weighs about what the one of the game does
    Assert.IsTrue(Abs(FrameCount(200) - 42 * AScale * AScale) < 42 * AScale * AScale div 2,
      Format('pixel della linea: %d', [FrameCount(200)]));
  finally
    LWidget.Free;
  end;
end;

procedure TTestXcomLineWidget.DueSuperficiImpilateDovrebberoTenereEntrambeIlLoroDisegnoFine;
var
  LFirst: TXcomLineWidget;
  LSecond: TXcomLineWidget;
  LAlone: Integer;
begin
  MakeScreen(4, True);
  LFirst := NewWidget(FHost);
  LSecond := NewWidget(FHost);
  try
    LFirst.Line(100, 50, 117, 91, 200);
    LFirst.Blit(FScreen.GetSurface);
    FScreen.Flip;
    LAlone := FrameCount(200);
    // a second surface over the first one, with a line that shares its rectangle and does not touch it
    FScreen.GetSurface.DrawRect(0, 0, 320, 200, 9);
    LSecond.Line(104, 50, 121, 91, 201);
    LFirst.Blit(FScreen.GetSurface);
    LSecond.Blit(FScreen.GetSurface);
    FScreen.Flip;
    Assert.AreEqual(LAlone, FrameCount(200), 'la prima linea resta fine sotto la seconda superficie');
    Assert.AreEqual(LAlone, FrameCount(201));
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestXcomLineWidget.UnaSuperficieNascostaNonDovrebbeLasciareNulla;
var
  LWidget: TXcomLineWidget;
begin
  MakeScreen(4, True);
  LWidget := NewWidget(FHost);
  try
    LWidget.Line(100, 50, 117, 91, 200);
    LWidget.Visible := False;
    LWidget.Blit(FScreen.GetSurface);
    FScreen.Flip;
    Assert.AreEqual(0, FrameCount(200));
    Assert.AreEqual(0, FinerPixels);
  finally
    LWidget.Free;
  end;
end;

procedure TTestXcomLineWidget.ClearLinesDovrebbeDimenticareLeLinee;
var
  LWidget: TXcomLineWidget;
begin
  MakeScreen(4, True);
  LWidget := NewWidget(FHost);
  try
    LWidget.Line(100, 50, 117, 91, 200);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.Flip;
    LWidget.ClearLines;
    Assert.AreEqual(0, LWidget.LineCount);
    FScreen.GetSurface.DrawRect(0, 0, 320, 200, 9);
    LWidget.Line(10, 10, 20, 30, 201);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.Flip;
    Assert.AreEqual(0, FrameCount(200));
    Assert.IsTrue(FrameCount(201) > 0);
  finally
    LWidget.Free;
  end;
end;

procedure TTestXcomLineWidget.SenzaHostDovrebbeEssereUnaSuperficieQualsiasi;
var
  LWidget: TXcomLineWidget;
begin
  MakeScreen(4, True);
  LWidget := NewWidget(nil);
  try
    LWidget.Line(100, 50, 117, 91, 200);
    LWidget.Blit(FScreen.GetSurface);
    FScreen.Flip;
    Assert.AreEqual(0, FinerPixels);
  finally
    LWidget.Free;
  end;
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the finer drawing of the globe (issue 183): with   }
{  a screen that composes in true color at a whole scale the globe leaves a     }
{  detail layer, and the picture of the game stays the one of the 8 bit path    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomGeoscape.GlobeDetail;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.Xcom.Types,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.XcomEngine.TrueColorComposer,
  DelphiDoom.XcomEngine.MemoryTrueColorVideoDevice, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomGeoscape.Globe, DelphiDoom.Tests.XcomGeoscape.World,
  DelphiDoom.Tests.XcomGeoscape.Host;

type
  /// <summary>The host of the clock with a screen: what the globe asks to leave its detail</summary>
  TXcomScreenHost = class(TXcomClockHost)
  strict private
    FScreen: TXcomScreen;
  public
    function Screen: TXcomScreen; override;
    /// <summary>Not owned</summary>
    property TheScreen: TXcomScreen read FScreen write FScreen;
  end;

  [TestFixture]
  [Category('XcomGeoscape')]
  TTestXcomGlobeDetail = class
  strict private
    const
      GLOBE_WIDTH = 256;
      GLOBE_HEIGHT = 200;
    var
      FWorld: TXcomGeoWorld;
      FRules: TXcomRulesetRules;
      FSave: TXcomSavedGame;
      FHost: TXcomScreenHost;
      FOptions: TXcomOptions;
      FDevice: TXcomMemoryTrueColorVideoDevice;
      FDeviceRef: IXcomVideoDevice;
      FComposer: IXcomFrameComposer;
      FScreen: TXcomScreen;
      FGlobe: TXcomGlobe;
      FColors: TXcomColors;
    procedure NeedData;
    procedure Make(AScale: Integer; ATrueColor: Boolean);
    procedure Frame;
    function ColorOf(AIndex: Byte): Cardinal;
    function Scale: Integer;
    /// <summary>The pixels of the frame that are not the game picture enlarged; AOutside counts the ones off the globe</summary>
    function FinerPixels(out AOutside: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LImmagineDelGiocoNonDovrebbeCambiareConIlDettaglio;
    [Test]
    [TestCase('doppio', '2')]
    [TestCase('triplo', '3')]
    [TestCase('quadruplo', '4')]
    procedure IlDettaglioDovrebbeToccareSoloIPixelDelGlobo(AScale: Integer);
    [Test]
    procedure IlDettaglioDovrebbeEssereLaStessaImmaginePiuFine;
    [Test]
    procedure UnPixelCopertoDopoIlGloboDovrebbeRestareQuelloDelGioco;
    [Test]
    procedure UnGloboNascostoNonDovrebbeLasciareDettaglio;
    [Test]
    procedure AScalaUnoNonDovrebbeEsserciDettaglio;
    [Test]
    procedure IlDettaglioDovrebbeSeguireLoZoomELaRotazione;
  end;

implementation

uses
  DelphiDoom.Xcom.Palette, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.NewGame,
  DelphiDoom.XcomSave.DefaultSettings, DelphiDoom.XcomSave.Settings.Intf;

{ TXcomScreenHost }

function TXcomScreenHost.Screen: TXcomScreen;
begin
  Result := FScreen;
end;

{ TTestXcomGlobeDetail }

procedure TTestXcomGlobeDetail.Setup;
begin
  FWorld := TXcomGeoWorld.Create;
  FOptions := TXcomOptions.Create;
  FHost := TXcomScreenHost.Create;
  FDevice := TXcomMemoryTrueColorVideoDevice.Create;
  FDeviceRef := FDevice;
end;

procedure TTestXcomGlobeDetail.TearDown;
begin
  FGlobe.Free;
  FGlobe := nil;
  FScreen.Free;
  FScreen := nil;
  FComposer := nil;
  FDeviceRef := nil;
  FHost.Free;
  FSave.Free;
  FSave := nil;
  FRules.Free;
  FRules := nil;
  FOptions.Free;
  FWorld.Free;
end;

procedure TTestXcomGlobeDetail.NeedData;
begin
  if not FWorld.HasData then
    TTestSkip.Ignore('the data of the game is not on this machine');
end;

procedure TTestXcomGlobeDetail.Make(AScale: Integer; ATrueColor: Boolean);
var
  LPalette: TXcomPalette;
  LIndex: Integer;
  LSettings: IXcomSaveSettings;
  LRandom: IXcomRandom;
  LNewGame: TXcomNewGame;
begin
  LPalette := FWorld.GeoscapePalette;
  for LIndex := 0 to 255 do
    FColors[LIndex] := LPalette.Colors[LIndex];
  FOptions.DisplayWidth := 320 * AScale;
  FOptions.DisplayHeight := 200 * AScale;
  FOptions.BaseXResolution := 320;
  FOptions.BaseYResolution := 200;
  FComposer := nil;
  if ATrueColor then
    FComposer := TXcomTrueColorComposer.Create(FDevice);
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef, FComposer);
  FScreen.SetPalette(@FColors[0], 0, 256);
  FHost.TheScreen := FScreen;
  FRules := TXcomRulesetRules.Create(FWorld.Rules.Ruleset);
  // in variables: an object made inside the argument of a const interface parameter is not counted
  LSettings := TXcomDefaultSaveSettings.Create;
  LRandom := TXcomRandom.Create(1);
  LNewGame := TXcomNewGame.Create(FWorld.Rules.Ruleset, FRules, LSettings, LRandom);
  try
    FSave := LNewGame.NewSave;
  finally
    LNewGame.Free;
  end;
  FGlobe := TXcomGlobe.Create(FHost, FSave, FWorld.Rules.Ruleset, FWorld.Rules.GetSurfaceSet('TEXTURE.DAT'),
    FWorld.Rules.GetSurfaceSet('GlobeMarkers'), GLOBE_WIDTH div 2, GLOBE_HEIGHT div 2, GLOBE_WIDTH, GLOBE_HEIGHT,
    0, 0);
  FGlobe.SetPalette(@FColors[0], 0, 256);
  FGlobe.RadarLines := True;
end;

procedure TTestXcomGlobeDetail.Frame;
begin
  // a frame of the game: the screen is cleared, the globe blits, the screen flips
  FScreen.Clear;
  FGlobe.Blit(FScreen.GetSurface);
  FScreen.Flip;
end;

function TTestXcomGlobeDetail.ColorOf(AIndex: Byte): Cardinal;
begin
  Result := $FF000000 or (Cardinal(FColors[AIndex].Red) shl 16) or (Cardinal(FColors[AIndex].Green) shl 8) or
    Cardinal(FColors[AIndex].Blue);
end;

function TTestXcomGlobeDetail.Scale: Integer;
begin
  Result := FScreen.Width div 320;
end;

function TTestXcomGlobeDetail.FinerPixels(out AOutside: Integer): Integer;
var
  LDisplay: TBytes;
  LIndex: Integer;
begin
  Result := 0;
  AOutside := 0;
  LDisplay := FScreen.DisplayPixels;
  Assert.AreEqual(Length(LDisplay), Length(FDevice.TrueColorPixels));
  for LIndex := 0 to High(LDisplay) do
    if FDevice.TrueColorPixels[LIndex] <> ColorOf(LDisplay[LIndex]) then
    begin
      Inc(Result);
      if (LIndex mod FScreen.Width) >= GLOBE_WIDTH * Scale then
        Inc(AOutside);
    end;
end;

procedure TTestXcomGlobeDetail.LImmagineDelGiocoNonDovrebbeCambiareConIlDettaglio;
var
  LWithDetail: TBytes;
  LDisplayWithDetail: TBytes;
  LIndex: Integer;
begin
  NeedData;
  Make(2, True);
  Frame;
  LWithDetail := Copy(FScreen.GetSurface.Pixels);
  LDisplayWithDetail := Copy(FScreen.DisplayPixels);
  // the same globe on a screen of the 8 bit path
  FGlobe.Free;
  FGlobe := nil;
  FScreen.Free;
  FScreen := nil;
  FSave.Free;
  FSave := nil;
  FRules.Free;
  FRules := nil;
  Make(2, False);
  Frame;
  Assert.AreEqual(0, FDevice.TrueColorPresented - 1, 'il secondo schermo non compone a colori');
  Assert.AreEqual(Length(LWithDetail), Length(FScreen.GetSurface.Pixels));
  for LIndex := 0 to High(LWithDetail) do
    if LWithDetail[LIndex] <> FScreen.GetSurface.Pixels[LIndex] then
      Assert.Fail(Format('pixel %d dell''immagine del gioco', [LIndex]));
  for LIndex := 0 to High(LDisplayWithDetail) do
    if LDisplayWithDetail[LIndex] <> FScreen.DisplayPixels[LIndex] then
      Assert.Fail(Format('pixel %d dello schermo a indici', [LIndex]));
end;

procedure TTestXcomGlobeDetail.IlDettaglioDovrebbeToccareSoloIPixelDelGlobo(AScale: Integer);
var
  LFiner: Integer;
  LOutside: Integer;
begin
  NeedData;
  Make(AScale, True);
  Frame;
  LFiner := FinerPixels(LOutside);
  Assert.IsTrue(LFiner > 100, Format('pixel piu'' fini: %d', [LFiner]));
  Assert.AreEqual(0, LOutside, 'pixel cambiati fuori dal globo');
end;

procedure TTestXcomGlobeDetail.IlDettaglioDovrebbeEssereLaStessaImmaginePiuFine;
var
  LFiner: Integer;
  LOutside: Integer;
  LGlobePixels: Integer;
begin
  NeedData;
  Make(2, True);
  Frame;
  LFiner := FinerPixels(LOutside);
  // the finer globe is the same picture: only the rims of the polygons, the lines and the steps of the shadow
  // differ from the game picture enlarged
  LGlobePixels := GLOBE_WIDTH * 2 * GLOBE_HEIGHT * 2;
  Assert.IsTrue(LFiner * 10 < LGlobePixels, Format('%d pixel diversi su %d', [LFiner, LGlobePixels]));
end;

procedure TTestXcomGlobeDetail.UnPixelCopertoDopoIlGloboDovrebbeRestareQuelloDelGioco;
var
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
begin
  NeedData;
  Make(2, True);
  FScreen.Clear;
  FGlobe.Blit(FScreen.GetSurface);
  // a window over the middle of the globe, in a color the globe does not have there
  FScreen.GetSurface.DrawRect(100, 60, 60, 80, 255);
  FScreen.Flip;
  for LY := 120 to 279 do
    for LX := 200 to 319 do
    begin
      LIndex := LY * 640 + LX;
      if FDevice.TrueColorPixels[LIndex] <> ColorOf(255) then
        Assert.Fail(Format('il dettaglio del globo buca la finestra in %d,%d', [LX, LY]));
    end;
end;

procedure TTestXcomGlobeDetail.UnGloboNascostoNonDovrebbeLasciareDettaglio;
var
  LOutside: Integer;
begin
  NeedData;
  Make(2, True);
  Frame;
  FGlobe.Visible := False;
  Frame;
  Assert.AreEqual(0, FinerPixels(LOutside));
end;

procedure TTestXcomGlobeDetail.AScalaUnoNonDovrebbeEsserciDettaglio;
var
  LOutside: Integer;
begin
  NeedData;
  Make(1, True);
  Frame;
  Assert.AreEqual(1, FDevice.TrueColorPresented);
  Assert.AreEqual(0, FinerPixels(LOutside));
end;

procedure TTestXcomGlobeDetail.IlDettaglioDovrebbeSeguireLoZoomELaRotazione;
var
  LMoved: TXcomTrueColorPixels;
  LIndex: Integer;
begin
  NeedData;
  Make(2, True);
  // the detail is made at the first frame, then the view changes
  Frame;
  FGlobe.SetZoom(1);
  FGlobe.Center(FGlobe.CenterLongitude + 0.4, FGlobe.CenterLatitude - 0.2);
  Frame;
  LMoved := Copy(FDevice.TrueColorPixels);
  // a globe that is born with that view draws the same frame
  FGlobe.Free;
  FGlobe := nil;
  FScreen.Free;
  FScreen := nil;
  FSave.Free;
  FSave := nil;
  FRules.Free;
  FRules := nil;
  Make(2, True);
  FGlobe.SetZoom(1);
  FGlobe.Center(FGlobe.CenterLongitude + 0.4, FGlobe.CenterLatitude - 0.2);
  Frame;
  Assert.AreEqual(Length(LMoved), Length(FDevice.TrueColorPixels));
  for LIndex := 0 to High(LMoved) do
    if LMoved[LIndex] <> FDevice.TrueColorPixels[LIndex] then
      Assert.Fail(Format('pixel %d', [LIndex]));
end;

end.

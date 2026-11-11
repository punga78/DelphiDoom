{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomVideoDeviceSelector (the choice between the   }
{  GDI and the OpenGL display of Xcom32) and of what TXcomScreen does with a    }
{  display that scales the picture itself                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.VideoDeviceSelector;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen, DelphiDoom.Xcom.VideoDevice.Types,
  DelphiDoom.Xcom.VideoDeviceSelector;

type
  /// <summary>A display that writes what it is asked in a journal; its SetMode can fail as an OpenGL one does</summary>
  TFakeDisplay = class(TInterfacedObject, IXcomVideoDevice, IXcomWindowStyle, IXcomFilteredDisplay)
  strict private
    FName: string;
    FJournal: TStrings;
    FFailure: string;
    FScales: Boolean;
    FRefusesShader: Boolean;
    FFilter: TXcomDisplayFilter;
  public
    constructor Create(const AName: string; AJournal: TStrings; const AFailure: string = ''; AScales: Boolean = False;
      ARefusesShader: Boolean = False);
    destructor Destroy; override;
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
    procedure SetTitle(const ATitle: string);
    procedure SetWindowStyle(ABorderless, AResizable: Boolean);
    procedure SetDisplayFilter(const AFilter: TXcomDisplayFilter);
    function DisplayFilter: TXcomDisplayFilter;
    function PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors;
      ADisplayWidth, ADisplayHeight: Integer; const ABands: TXcomBlackBands): Boolean;
  end;

  TFakeLog = class(TInterfacedObject, IXcomLog)
  strict private
    FJournal: TStrings;
  public
    constructor Create(AJournal: TStrings);
    procedure Write(const ALevel, AMessage: string);
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomVideoDeviceSelector = class
  strict private
    FJournal: TStringList;
    FOpenGlFailure: string;
    FOpenGlRefusesShader: Boolean;
    FSelector: TXcomVideoDeviceSelector;
    FDevice: IXcomVideoDevice;
    function Journal: string;
    function Filter(AOpenGl: Boolean; const AShader: string = ''): TXcomDisplayFilter;
    procedure NewSelector(AWithOpenGl: Boolean = True);
    procedure SetMode(AWidth, AHeight: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeUsareIlDispositivoSempliceSeOpenGlNonERichiesto;
    [Test]
    procedure DovrebbeUsareOpenGlSeIlFiltroLoChiede;
    [Test]
    procedure DovrebbeRipiegareSulSempliceSeIlContestoNonSiCrea;
    [Test]
    procedure DovrebbeScrivereNelLogIlMotivoEsattoDelRipiego;
    [Test]
    procedure DovrebbeRilasciareIlVecchioDispositivoPrimaDiCreareIlNuovo;
    [Test]
    procedure DovrebbeTenereLoStessoDispositivoSeIlTipoNonCambia;
    [Test]
    procedure DovrebbeDareTitoloStileEFiltroAlDispositivoNuovo;
    [Test]
    procedure DovrebbeRiprovareOpenGlAlModoSuccessivo;
    [Test]
    procedure NonDovrebbeUsareOpenGlSenzaLaSuaFabbrica;
    [Test]
    procedure DovrebbePropagareLErroreDelDispositivoSemplice;
    [Test]
    procedure DovrebbeRifiutareLaFabbricaSempliceNil;
    [Test]
    procedure DovrebbePresentareNonScalatoSoloConOpenGl;
    [Test]
    procedure NonDovrebbePresentarePrimaDelModo;
    [Test]
    procedure LoSchermoDovrebbeSpegnereUseOpenGlDopoIlRipiego;
    [Test]
    procedure LoSchermoDovrebbeDimenticareLoShaderRifiutato;
    [Test]
    procedure LoSchermoDovrebbeDareLImmagineBaseAlDispositivoOpenGl;
    [Test]
    procedure LoSchermoDovrebbeDareLImmagineScalataSenzaOpenGl;
  end;

implementation

{ TFakeDisplay }

constructor TFakeDisplay.Create(const AName: string; AJournal: TStrings; const AFailure: string; AScales,
  ARefusesShader: Boolean);
begin
  inherited Create;
  FName := AName;
  FJournal := AJournal;
  FFailure := AFailure;
  FScales := AScales;
  FRefusesShader := ARefusesShader;
  FJournal.Add('create:' + FName);
end;

destructor TFakeDisplay.Destroy;
begin
  FJournal.Add('free:' + FName);
  inherited Destroy;
end;

procedure TFakeDisplay.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
  if FFailure <> '' then
  begin
    // what a display that fails half way could leave in the sizes
    AWidth := 1;
    AHeight := 1;
    raise EXcomVideoDeviceException.Create(FFailure);
  end;
  FJournal.Add(Format('mode:%s:%dx%d:%s', [FName, AWidth, AHeight, BoolToStr(AFullscreen, True)]));
end;

procedure TFakeDisplay.Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
begin
  FJournal.Add(Format('present:%s:%dx%d', [FName, AWidth, AHeight]));
end;

procedure TFakeDisplay.SetTitle(const ATitle: string);
begin
  FJournal.Add(Format('title:%s:%s', [FName, ATitle]));
end;

procedure TFakeDisplay.SetWindowStyle(ABorderless, AResizable: Boolean);
begin
  FJournal.Add(Format('style:%s:%s:%s', [FName, BoolToStr(ABorderless, True), BoolToStr(AResizable, True)]));
end;

procedure TFakeDisplay.SetDisplayFilter(const AFilter: TXcomDisplayFilter);
begin
  FFilter := AFilter;
  FJournal.Add(Format('filter:%s:%s', [FName, AFilter.Shader]));
end;

function TFakeDisplay.DisplayFilter: TXcomDisplayFilter;
begin
  Result := FFilter;
  Result.UseOpenGL := FScales;
  if FRefusesShader then
    Result.Shader := '';
end;

function TFakeDisplay.PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors;
  ADisplayWidth, ADisplayHeight: Integer; const ABands: TXcomBlackBands): Boolean;
begin
  Result := FScales;
  if Result then
    FJournal.Add(Format('unscaled:%s:%dx%d>%dx%d:%d,%d,%d,%d', [FName, AWidth, AHeight, ADisplayWidth,
      ADisplayHeight, ABands.Top, ABands.Bottom, ABands.Left, ABands.Right]));
end;

{ TFakeLog }

constructor TFakeLog.Create(AJournal: TStrings);
begin
  inherited Create;
  FJournal := AJournal;
end;

procedure TFakeLog.Write(const ALevel, AMessage: string);
begin
  FJournal.Add(Format('log:%s:%s', [ALevel, AMessage]));
end;

{ TTestXcomVideoDeviceSelector }

procedure TTestXcomVideoDeviceSelector.Setup;
begin
  FJournal := TStringList.Create;
  FOpenGlFailure := '';
  FOpenGlRefusesShader := False;
  NewSelector;
end;

procedure TTestXcomVideoDeviceSelector.TearDown;
begin
  FSelector := nil;
  FDevice := nil;
  FJournal.Free;
end;

procedure TTestXcomVideoDeviceSelector.NewSelector(AWithOpenGl: Boolean);
var
  LOpenGl: TXcomVideoDeviceFactory;
begin
  LOpenGl := nil;
  if AWithOpenGl then
    LOpenGl :=
      function: IXcomVideoDevice
      begin
        Result := TFakeDisplay.Create('gl', FJournal, FOpenGlFailure, True, FOpenGlRefusesShader);
      end;
  FSelector := TXcomVideoDeviceSelector.Create(
    function: IXcomVideoDevice
    begin
      Result := TFakeDisplay.Create('gdi', FJournal);
    end, LOpenGl, TFakeLog.Create(FJournal));
  // one interface reference for the whole life of the object
  FDevice := FSelector;
  FJournal.Clear;
end;

function TTestXcomVideoDeviceSelector.Journal: string;
begin
  Result := string.Join('|', FJournal.ToStringArray);
end;

function TTestXcomVideoDeviceSelector.Filter(AOpenGl: Boolean; const AShader: string): TXcomDisplayFilter;
begin
  Result := Default(TXcomDisplayFilter);
  Result.UseOpenGL := AOpenGl;
  Result.Shader := AShader;
end;

procedure TTestXcomVideoDeviceSelector.SetMode(AWidth, AHeight: Integer);
begin
  FSelector.SetMode(AWidth, AHeight, False);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeUsareIlDispositivoSempliceSeOpenGlNonERichiesto;
begin
  SetMode(640, 400);
  Assert.AreEqual('create:gdi|filter:gdi:|mode:gdi:640x400:False', Journal);
  Assert.IsFalse(FSelector.IsOpenGl);
  Assert.IsFalse(FSelector.DisplayFilter.UseOpenGL);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeUsareOpenGlSeIlFiltroLoChiede;
begin
  FSelector.SetDisplayFilter(Filter(True, 'Shaders/raw.opengl.shader'));
  SetMode(640, 400);
  Assert.AreEqual('create:gl|filter:gl:Shaders/raw.opengl.shader|mode:gl:640x400:False', Journal);
  Assert.IsTrue(FSelector.IsOpenGl);
  Assert.IsTrue(FSelector.DisplayFilter.UseOpenGL);
  Assert.AreEqual('Shaders/raw.opengl.shader', FSelector.DisplayFilter.Shader);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeRipiegareSulSempliceSeIlContestoNonSiCrea;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  FOpenGlFailure := 'wglCreateContext failed: test (5)';
  FSelector.SetDisplayFilter(Filter(True, 'Shaders/raw.opengl.shader'));
  LWidth := 640;
  LHeight := 400;
  FSelector.SetMode(LWidth, LHeight, True);
  Assert.IsFalse(FSelector.IsOpenGl);
  Assert.IsFalse(FSelector.DisplayFilter.UseOpenGL);
  Assert.AreEqual('', FSelector.DisplayFilter.Shader);
  // the plain display gets the sizes that were asked, not what the failed one left
  Assert.AreEqual('mode:gdi:640x400:True', FJournal[FJournal.Count - 1]);
  Assert.AreEqual(640, LWidth);
  Assert.AreEqual(400, LHeight);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeScrivereNelLogIlMotivoEsattoDelRipiego;
begin
  FOpenGlFailure := 'wglCreateContext failed: test (5)';
  FSelector.SetDisplayFilter(Filter(True));
  SetMode(640, 400);
  Assert.IsTrue(FJournal.IndexOf('log:WARN:OpenGL display not available, using GDI: wglCreateContext failed: test (5)')
    >= 0, Journal);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeRilasciareIlVecchioDispositivoPrimaDiCreareIlNuovo;
begin
  // the two displays draw in the same window: never two alive at once
  SetMode(640, 400);
  FJournal.Clear;
  FSelector.SetDisplayFilter(Filter(True));
  SetMode(640, 400);
  Assert.AreEqual('free:gdi|create:gl|filter:gl:|mode:gl:640x400:False', Journal);
  FJournal.Clear;
  FSelector.SetDisplayFilter(Filter(False));
  SetMode(640, 400);
  Assert.AreEqual('free:gl|create:gdi|filter:gdi:|mode:gdi:640x400:False', Journal);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeTenereLoStessoDispositivoSeIlTipoNonCambia;
begin
  SetMode(640, 400);
  FJournal.Clear;
  SetMode(800, 600);
  Assert.AreEqual('filter:gdi:|mode:gdi:800x600:False', Journal);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeDareTitoloStileEFiltroAlDispositivoNuovo;
begin
  FSelector.SetTitle('OpenXcom');
  FSelector.SetWindowStyle(True, False);
  FSelector.SetDisplayFilter(Filter(True, 'Shaders/crt.opengl.shader'));
  Assert.AreEqual('', Journal, 'no display before the first mode');
  SetMode(640, 400);
  Assert.AreEqual('create:gl|title:gl:OpenXcom|style:gl:True:False|filter:gl:Shaders/crt.opengl.shader|' +
    'mode:gl:640x400:False', Journal);
  FJournal.Clear;
  FSelector.SetTitle('Altro');
  Assert.AreEqual('title:gl:Altro', Journal);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeRiprovareOpenGlAlModoSuccessivo;
begin
  FOpenGlFailure := 'no';
  FSelector.SetDisplayFilter(Filter(True));
  SetMode(640, 400);
  Assert.IsFalse(FSelector.IsOpenGl);
  FOpenGlFailure := '';
  FJournal.Clear;
  SetMode(640, 400);
  Assert.IsTrue(FSelector.IsOpenGl);
  Assert.AreEqual('free:gdi|create:gl|filter:gl:|mode:gl:640x400:False', Journal);
end;

procedure TTestXcomVideoDeviceSelector.NonDovrebbeUsareOpenGlSenzaLaSuaFabbrica;
begin
  NewSelector(False);
  FSelector.SetDisplayFilter(Filter(True, 'Shaders/raw.opengl.shader'));
  SetMode(640, 400);
  Assert.AreEqual('create:gdi|filter:gdi:Shaders/raw.opengl.shader|mode:gdi:640x400:False', Journal);
  Assert.IsFalse(FSelector.DisplayFilter.UseOpenGL);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbePropagareLErroreDelDispositivoSemplice;
begin
  FSelector := TXcomVideoDeviceSelector.Create(
    function: IXcomVideoDevice
    begin
      Result := TFakeDisplay.Create('gdi', FJournal, 'no window');
    end, nil);
  FDevice := FSelector;
  Assert.WillRaiseWithMessage(
    procedure
    begin
      SetMode(640, 400);
    end, EXcomVideoDeviceException, 'no window');
end;

procedure TTestXcomVideoDeviceSelector.DovrebbeRifiutareLaFabbricaSempliceNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomVideoDeviceSelector.Create(nil, nil);
    end, EArgumentNilException);
end;

procedure TTestXcomVideoDeviceSelector.DovrebbePresentareNonScalatoSoloConOpenGl;
var
  LPixels: TBytes;
  LPalette: TXcomColors;
begin
  SetLength(LPixels, 320 * 200);
  FillChar(LPalette, SizeOf(LPalette), 0);
  SetMode(640, 400);
  Assert.IsFalse(FSelector.PresentUnscaled(LPixels, 320, 200, LPalette, 640, 400, Default(TXcomBlackBands)));
  FSelector.SetDisplayFilter(Filter(True));
  SetMode(640, 400);
  FJournal.Clear;
  Assert.IsTrue(FSelector.PresentUnscaled(LPixels, 320, 200, LPalette, 640, 400, Default(TXcomBlackBands)));
  Assert.AreEqual('unscaled:gl:320x200>640x400:0,0,0,0', Journal);
end;

procedure TTestXcomVideoDeviceSelector.NonDovrebbePresentarePrimaDelModo;
var
  LPixels: TBytes;
  LPalette: TXcomColors;
begin
  SetLength(LPixels, 4);
  FillChar(LPalette, SizeOf(LPalette), 0);
  FSelector.Present(LPixels, 2, 2, LPalette);
  Assert.IsFalse(FSelector.PresentUnscaled(LPixels, 2, 2, LPalette, 2, 2, Default(TXcomBlackBands)));
  Assert.AreEqual('', Journal);
end;

procedure TTestXcomVideoDeviceSelector.LoSchermoDovrebbeSpegnereUseOpenGlDopoIlRipiego;
var
  LOptions: TXcomOptions;
  LScreen: TXcomScreen;
begin
  // Screen::resetDisplay: "Options::useOpenGL = false" when the mode cannot be set with OpenGL
  FOpenGlFailure := 'ChoosePixelFormat found no OpenGL pixel format: test (2000)';
  LOptions := TXcomOptions.Create;
  try
    LOptions.UseOpenGL := True;
    LScreen := TXcomScreen.Create(LOptions, FDevice);
    try
      Assert.IsFalse(LOptions.UseOpenGL);
      Assert.IsFalse(FSelector.IsOpenGl);
      FJournal.Clear;
      LScreen.Flip;
      Assert.AreEqual('present:gdi:640x400', Journal);
    finally
      LScreen.Free;
    end;
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomVideoDeviceSelector.LoSchermoDovrebbeDimenticareLoShaderRifiutato;
var
  LOptions: TXcomOptions;
  LScreen: TXcomScreen;
begin
  // Screen::resetDisplay: "Options::useOpenGLShader = """ when set_shader fails; OpenGL stays
  FOpenGlRefusesShader := True;
  LOptions := TXcomOptions.Create;
  try
    LOptions.UseOpenGL := True;
    LOptions.UseOpenGLShader := 'Shaders/broken.opengl.shader';
    LScreen := TXcomScreen.Create(LOptions, FDevice);
    try
      Assert.IsTrue(LOptions.UseOpenGL);
      Assert.AreEqual('', LOptions.UseOpenGLShader);
    finally
      LScreen.Free;
    end;
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomVideoDeviceSelector.LoSchermoDovrebbeDareLImmagineBaseAlDispositivoOpenGl;
var
  LOptions: TXcomOptions;
  LScreen: TXcomScreen;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.UseOpenGL := True;
    LOptions.DisplayWidth := 800;
    LOptions.DisplayHeight := 400;
    LOptions.BaseXResolution := 320;
    LOptions.BaseYResolution := 200;
    LScreen := TXcomScreen.Create(LOptions, FDevice);
    try
      Assert.IsTrue(LOptions.UseOpenGL);
      Assert.AreEqual('Shaders/Raw.OpenGL.shader', LOptions.UseOpenGLShader);
      FJournal.Clear;
      LScreen.Flip;
      // the picture of the game, not scaled, and the bands that keep its proportions in the display
      Assert.AreEqual('unscaled:gl:320x200>800x400:0,0,80,80', Journal);
      // the scaled picture is made all the same (the screenshot key saves it)
      Assert.AreEqual(800 * 400, Length(LScreen.DisplayPixels));
    finally
      LScreen.Free;
    end;
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomVideoDeviceSelector.LoSchermoDovrebbeDareLImmagineScalataSenzaOpenGl;
var
  LOptions: TXcomOptions;
  LScreen: TXcomScreen;
begin
  LOptions := TXcomOptions.Create;
  try
    LScreen := TXcomScreen.Create(LOptions, FDevice);
    try
      Assert.AreEqual('create:gdi|style:gdi:False:False|filter:gdi:Shaders/Raw.OpenGL.shader|mode:gdi:640x400:False',
        Journal);
      FJournal.Clear;
      LScreen.Flip;
      Assert.AreEqual('present:gdi:640x400', Journal);
    finally
      LScreen.Free;
    end;
  finally
    LOptions.Free;
  end;
end;

end.

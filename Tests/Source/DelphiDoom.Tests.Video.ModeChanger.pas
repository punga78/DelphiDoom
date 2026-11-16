{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the change of the video mode        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.ModeChanger;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Video.ModeChanger.Intf,
  DelphiDoom.Video.ModeChanger,
  DelphiDoom.Video.Types;

type
  /// <summary>
  ///   A host that writes every call in a log: the sequence of the calls is what the old I_InitGraphics and
  ///   I_ChangeFullScreen did, in that order
  /// </summary>
  TFakeModeHost = class(TInterfacedObject, IVideoModeHost)
  strict private
    FWindowWidth: Integer;
    FWindowHeight: Integer;
  public
    Log: TStringList;
    ScreenWidth: Integer;
    ScreenHeight: Integer;
    // the sizes that FindWindowSize gives to the window
    FoundWidth: Integer;
    FoundHeight: Integer;
    // the resolutions that the desktop accepts (a size not in the list is refused)
    Accepted: TStringList;
    StallHackApplies: Boolean;
    constructor Create;
    destructor Destroy; override;
    function GetWindowWidth: Integer;
    function GetWindowHeight: Integer;
    procedure SetWindowSize(const AWidth, AHeight: Integer);
    function GetScreenWidth: Integer;
    function GetScreenHeight: Integer;
    procedure FindWindowSize(const AMode: Integer);
    procedure AdjustWindowMode;
    procedure RestoreWindowPosition(const AMode: Integer);
    procedure DisableAltTab;
    procedure EnableAltTab;
    function ChangeResolution(const AWidth, AHeight: Integer): Boolean;
    procedure RestoreResolution;
    function ApplyMemoryStallHack: Boolean;
    procedure ReinitializeScreens;
    procedure RefreshDpi;
    procedure Warn(const AMessage: string);
    procedure Print(const AMessage: string);
  end;

  [TestFixture]
  [Category('video')]
  TTestVideoModeChanger = class(TObject)
  strict private
    FHostObject: TFakeModeHost;
    FHost: IVideoModeHost;
    FChanger: IVideoModeChanger;
    function Calls: string;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeRifiutareUnHostNil;
    [Test]
    procedure DovrebbeAvviareLaFinestraSenzaCambiareLaRisoluzione;
    [Test]
    procedure DovrebbeAvviareLoSchermoIntero;
    [Test]
    procedure DovrebbeRipiegareSullaFinestraSeLoSchermoInteroFallisce;
    [Test]
    procedure DovrebbeRiportareLaModalitaDentroQuelleConosciute;
    [Test]
    procedure DovrebbeRifareGliSchermiSeLoStallHackRestringe;
    [Test]
    procedure DovrebbePassareAlloSchermoInteroEsclusivo;
    [Test]
    procedure DovrebbePassareAllaFinestraRipristinandoIlDesktop;
    [Test]
    procedure DovrebbeProvareUnaRisoluzioneStandardSeIlDesktopRifiuta;
    [Test]
    procedure DovrebbeAvvisareESeNonCambiaSeAncheLaStandardERifiutata;
    [Test]
    procedure DovrebbeRipristinareIlDesktopAllaFine;
    [Test]
    procedure DovrebbeLiberareAltTabAnchePrimaDiCambiareRisoluzione;
  end;

implementation

{ TFakeModeHost }

constructor TFakeModeHost.Create;
begin
  inherited Create;
  Log := TStringList.Create;
  Accepted := TStringList.Create;
  ScreenWidth := 640;
  ScreenHeight := 400;
  FoundWidth := 1024;
  FoundHeight := 768;
end;

destructor TFakeModeHost.Destroy;
begin
  Accepted.Free;
  Log.Free;
  inherited Destroy;
end;

function TFakeModeHost.GetWindowWidth: Integer;
begin
  Result := FWindowWidth;
end;

function TFakeModeHost.GetWindowHeight: Integer;
begin
  Result := FWindowHeight;
end;

procedure TFakeModeHost.SetWindowSize(const AWidth, AHeight: Integer);
begin
  FWindowWidth := AWidth;
  FWindowHeight := AHeight;
  Log.Add(Format('size %dx%d', [AWidth, AHeight]));
end;

function TFakeModeHost.GetScreenWidth: Integer;
begin
  Result := ScreenWidth;
end;

function TFakeModeHost.GetScreenHeight: Integer;
begin
  Result := ScreenHeight;
end;

procedure TFakeModeHost.FindWindowSize(const AMode: Integer);
begin
  FWindowWidth := FoundWidth;
  FWindowHeight := FoundHeight;
  Log.Add(Format('find %d', [AMode]));
end;

procedure TFakeModeHost.AdjustWindowMode;
begin
  Log.Add('adjust');
end;

procedure TFakeModeHost.RestoreWindowPosition(const AMode: Integer);
begin
  Log.Add(Format('place %d', [AMode]));
end;

procedure TFakeModeHost.DisableAltTab;
begin
  Log.Add('alttab off');
end;

procedure TFakeModeHost.EnableAltTab;
begin
  Log.Add('alttab on');
end;

function TFakeModeHost.ChangeResolution(const AWidth, AHeight: Integer): Boolean;
begin
  Result := Accepted.IndexOf(Format('%dx%d', [AWidth, AHeight])) >= 0;
  Log.Add(Format('change %dx%d %s', [AWidth, AHeight, BoolToStr(Result, True)]));
end;

procedure TFakeModeHost.RestoreResolution;
begin
  Log.Add('restore');
end;

function TFakeModeHost.ApplyMemoryStallHack: Boolean;
begin
  Result := StallHackApplies;
  Log.Add('stall ' + BoolToStr(Result, True));
end;

procedure TFakeModeHost.ReinitializeScreens;
begin
  Log.Add('reinit');
end;

procedure TFakeModeHost.RefreshDpi;
begin
  Log.Add('dpi');
end;

procedure TFakeModeHost.Warn(const AMessage: string);
begin
  Log.Add('warn ' + Trim(AMessage));
end;

procedure TFakeModeHost.Print(const AMessage: string);
begin
  Log.Add('print ' + Trim(AMessage));
end;

{ TTestVideoModeChanger }

procedure TTestVideoModeChanger.Setup;
begin
  FHostObject := TFakeModeHost.Create;
  FHost := FHostObject;
  FChanger := TVideoModeChanger.Create(FHost);
end;

function TTestVideoModeChanger.Calls: string;
begin
  Result := StringReplace(Trim(FHostObject.Log.Text), sLineBreak, '; ', [rfReplaceAll]);
end;

procedure TTestVideoModeChanger.DovrebbeRifiutareUnHostNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TVideoModeChanger.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestVideoModeChanger.DovrebbeAvviareLaFinestraSenzaCambiareLaRisoluzione;
var
  LFullScreen: Integer;
begin
  LFullScreen := FULLSCREEN_OFF;
  FChanger.Initialize(LFullScreen);
  Assert.AreEqual(FULLSCREEN_OFF, LFullScreen);
  Assert.AreEqual('find 2; adjust; place 2; stall False; dpi', Calls);
  Assert.IsFalse(FChanger.ResolutionChanged);
end;

procedure TTestVideoModeChanger.DovrebbeAvviareLoSchermoIntero;
var
  LFullScreen: Integer;
begin
  FHostObject.Accepted.Add('1024x768');
  LFullScreen := FULLSCREEN_EXCLUSIVE;
  FChanger.Initialize(LFullScreen);
  Assert.AreEqual(FULLSCREEN_EXCLUSIVE, LFullScreen);
  Assert.AreEqual('find 1; change 1024x768 True; place 1; alttab off; stall False; dpi', Calls);
  Assert.IsTrue(FChanger.ResolutionChanged);
end;

procedure TTestVideoModeChanger.DovrebbeRipiegareSullaFinestraSeLoSchermoInteroFallisce;
var
  LFullScreen: Integer;
begin
  LFullScreen := FULLSCREEN_EXCLUSIVE;
  FChanger.Initialize(LFullScreen);
  Assert.AreEqual(FULLSCREEN_SHARED, LFullScreen);
  Assert.AreEqual('find 1; change 1024x768 False; adjust; place 0; ' +
    'warn SetDisplayMode(): Failed to fullscreen 1024x768x32, trying window mode...; ' +
    'print Window Mode 640x400; stall False; dpi', Calls);
  Assert.IsFalse(FChanger.ResolutionChanged);
end;

procedure TTestVideoModeChanger.DovrebbeRiportareLaModalitaDentroQuelleConosciute;
var
  LFullScreen: Integer;
begin
  LFullScreen := FULLSCREEN_OFF + NUMFULLSCREEN_MODES * 2;
  FChanger.Initialize(LFullScreen);
  Assert.AreEqual(FULLSCREEN_OFF, LFullScreen);
end;

procedure TTestVideoModeChanger.DovrebbeRifareGliSchermiSeLoStallHackRestringe;
var
  LFullScreen: Integer;
begin
  FHostObject.StallHackApplies := True;
  LFullScreen := FULLSCREEN_OFF;
  FChanger.Initialize(LFullScreen);
  Assert.AreEqual('find 2; adjust; place 2; stall True; reinit; dpi', Calls);
end;

procedure TTestVideoModeChanger.DovrebbePassareAlloSchermoInteroEsclusivo;
var
  LFullScreen: Integer;
begin
  FHostObject.Accepted.Add('1024x768');
  LFullScreen := FULLSCREEN_OFF;
  FChanger.ChangeFullScreen(FULLSCREEN_EXCLUSIVE, LFullScreen);
  Assert.AreEqual(FULLSCREEN_EXCLUSIVE, LFullScreen);
  Assert.AreEqual('size 640x400; find 1; adjust; place 1; change 1024x768 True; place 1; dpi', Calls);
  Assert.IsTrue(FChanger.ResolutionChanged);
end;

procedure TTestVideoModeChanger.DovrebbePassareAllaFinestraRipristinandoIlDesktop;
var
  LFullScreen: Integer;
begin
  FHostObject.Accepted.Add('1024x768');
  LFullScreen := FULLSCREEN_OFF;
  FChanger.ChangeFullScreen(FULLSCREEN_EXCLUSIVE, LFullScreen);
  FHostObject.Log.Clear;
  FChanger.ChangeFullScreen(FULLSCREEN_OFF, LFullScreen);
  Assert.AreEqual(FULLSCREEN_OFF, LFullScreen);
  Assert.AreEqual('size 640x400; find 2; adjust; place 2; restore; dpi', Calls);
  Assert.IsFalse(FChanger.ResolutionChanged);
end;

// the old rule starts from the smallest standard resolution and so it ends on 400x300
procedure TTestVideoModeChanger.DovrebbeProvareUnaRisoluzioneStandardSeIlDesktopRifiuta;
var
  LFullScreen: Integer;
begin
  FHostObject.Accepted.Add('400x300');
  LFullScreen := FULLSCREEN_OFF;
  FChanger.ChangeFullScreen(FULLSCREEN_EXCLUSIVE, LFullScreen);
  Assert.AreEqual(FULLSCREEN_EXCLUSIVE, LFullScreen);
  Assert.AreEqual('size 640x400; find 1; adjust; place 1; change 1024x768 False; size 400x300; ' +
    'change 400x300 True; place 1; dpi', Calls);
end;

procedure TTestVideoModeChanger.DovrebbeAvvisareESeNonCambiaSeAncheLaStandardERifiutata;
var
  LFullScreen: Integer;
begin
  LFullScreen := FULLSCREEN_OFF;
  FChanger.ChangeFullScreen(FULLSCREEN_EXCLUSIVE, LFullScreen);
  Assert.AreEqual(FULLSCREEN_OFF, LFullScreen);
  Assert.AreEqual('size 640x400; find 1; adjust; place 1; change 1024x768 False; size 400x300; ' +
    'change 400x300 False; warn I_ChangeFullScreen(): Can not change to window mode', Calls);

  FHostObject.Log.Clear;
  LFullScreen := FULLSCREEN_EXCLUSIVE;
  FChanger.ChangeFullScreen(FULLSCREEN_SHARED, LFullScreen);
  FHostObject.Log.Clear;
  FChanger.ChangeFullScreen(FULLSCREEN_EXCLUSIVE, LFullScreen);
  Assert.AreEqual(FULLSCREEN_SHARED, LFullScreen);
  Assert.IsTrue(Pos('Can not change to fullscreen mode', Calls) > 0);
end;

procedure TTestVideoModeChanger.DovrebbeRipristinareIlDesktopAllaFine;
var
  LFullScreen: Integer;
begin
  FHostObject.Accepted.Add('1024x768');
  LFullScreen := FULLSCREEN_EXCLUSIVE;
  FChanger.Initialize(LFullScreen);
  FHostObject.Log.Clear;
  FChanger.Release;
  Assert.AreEqual('restore; alttab on', Calls);
  Assert.IsFalse(FChanger.ResolutionChanged);
end;

procedure TTestVideoModeChanger.DovrebbeLiberareAltTabAnchePrimaDiCambiareRisoluzione;
begin
  FChanger.Release;
  Assert.AreEqual('alttab on', Calls);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoModeChanger);

end.

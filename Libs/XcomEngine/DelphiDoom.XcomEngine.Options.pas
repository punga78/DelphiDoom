{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the options of OpenXcom                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Options;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Language;

type
  /// <summary>
  ///   The options of the game that the engine and the menus read (Options of OpenXcom), with the defaults of the
  ///   Windows build. They are instance fields, not globals: the game and the states receive the instance. Only the
  ///   options that the ported classes use are here; the other keys of options.cfg are ignored on load.
  ///   BaseXResolution and BaseYResolution are the size of the game picture
  /// </summary>
  TXcomOptions = class
  public
    DisplayWidth: Integer;
    DisplayHeight: Integer;
    Fullscreen: Boolean;
    BaseXResolution: Integer;
    BaseYResolution: Integer;
    BaseXGeoscape: Integer;
    BaseYGeoscape: Integer;
    BaseXBattlescape: Integer;
    BaseYBattlescape: Integer;
    GeoscapeScale: Integer;
    BattlescapeScale: Integer;
    NewDisplayWidth: Integer;
    NewDisplayHeight: Integer;
    KeepAspectRatio: Boolean;
    NonSquarePixelRatio: Boolean;
    AllowResize: Boolean;
    Borderless: Boolean;
    UseOpenGL: Boolean;
    UseScaleFilter: Boolean;
    UseHQXFilter: Boolean;
    UseXBRZFilter: Boolean;
    CursorInBlackBandsInFullscreen: Boolean;
    CursorInBlackBandsInWindow: Boolean;
    CursorInBlackBandsInBorderlessWindow: Boolean;
    Language: string;
    Wordwrap: TXcomTextWrapping;
    FpsCounter: Boolean;
    FPS: Integer;
    FPSInactive: Integer;
    MaxFrameSkip: Integer;
    Debug: Boolean;
    DebugUi: Boolean;
    Mute: Boolean;
    Reload: Boolean;
    PlayIntro: Boolean;
    SoundVolume: Integer;
    MusicVolume: Integer;
    UiVolume: Integer;
    KeyOk: Integer;
    KeyCancel: Integer;
    KeyScreenshot: Integer;
    MousewheelSpeed: Integer;
    ChangeValueByMouseWheel: Integer;
    KeyboardMode: TXcomKeyboardMode;
    /// <summary>The pending video options (newFullscreen...): the video screen changes these, OK swaps them with the current ones</summary>
    NewFullscreen: Boolean;
    NewBorderless: Boolean;
    NewAllowResize: Boolean;
    NewOpenGL: Boolean;
    NewScaleFilter: Boolean;
    NewHQXFilter: Boolean;
    NewXBRZFilter: Boolean;
    UseOpenGLShader: string;
    NewOpenGLShader: string;
    NewGeoscapeScale: Integer;
    NewBattlescapeScale: Integer;
    CaptureMouse: Boolean;
    RootWindowedMode: Boolean;
    NewRootWindowedMode: Boolean;
    WindowedModePositionX: Integer;
    WindowedModePositionY: Integer;
    NewWindowedModePositionX: Integer;
    NewWindowedModePositionY: Integer;
    constructor Create;
    /// <summary>Options::resetDefault for the options of this class</summary>
    procedure ResetDefaults;
    /// <summary>The pending video options start equal to the current ones (what Options::load leaves)</summary>
    procedure SyncPendingDisplay;
    /// <summary>Options::switchDisplay: swaps the current video options with the pending ones</summary>
    procedure SwitchDisplay;
    /// <summary>
    ///   Options::load: reads the "options" map of an options.cfg (the node of the file); a key that is missing
    ///   or has a bad value keeps what it has
    /// </summary>
    procedure Load(const ADocument: IYamlNode);
    /// <summary>The "options" part of options.cfg, as the keys that this class has</summary>
    function Save: string;
  end;

implementation

uses
  DelphiDoom.XcomEngine.YamlFields;

constructor TXcomOptions.Create;
begin
  inherited Create;
  ResetDefaults;
end;

procedure TXcomOptions.ResetDefaults;
begin
  DisplayWidth := 640;
  DisplayHeight := 400;
  Fullscreen := False;
  BaseXResolution := 320;
  BaseYResolution := 200;
  BaseXGeoscape := 320;
  BaseYGeoscape := 200;
  BaseXBattlescape := 320;
  BaseYBattlescape := 200;
  GeoscapeScale := 0;
  BattlescapeScale := 0;
  KeepAspectRatio := True;
  NonSquarePixelRatio := False;
  AllowResize := False;
  Borderless := False;
  UseOpenGL := False;
  UseScaleFilter := False;
  UseHQXFilter := False;
  UseXBRZFilter := False;
  CursorInBlackBandsInFullscreen := False;
  CursorInBlackBandsInWindow := True;
  CursorInBlackBandsInBorderlessWindow := False;
  Language := '';
  Wordwrap := twAuto;
  FpsCounter := False;
  FPS := 60;
  FPSInactive := 30;
  MaxFrameSkip := 0;
  Debug := False;
  DebugUi := False;
  Mute := False;
  Reload := False;
  PlayIntro := True;
  SoundVolume := 2 * (128 div 3);
  MusicVolume := 2 * (128 div 3);
  UiVolume := 128 div 3;
  KeyOk := XCOM_KEY_RETURN;
  KeyCancel := XCOM_KEY_ESCAPE;
  KeyScreenshot := XCOM_KEY_F12;
  MousewheelSpeed := 3;
  ChangeValueByMouseWheel := 0;
  KeyboardMode := kmOn;
  UseOpenGLShader := 'Shaders/Raw.OpenGL.shader';
  CaptureMouse := False;
  RootWindowedMode := False;
  WindowedModePositionX := 0;
  WindowedModePositionY := 0;
  SyncPendingDisplay;
end;

procedure TXcomOptions.SyncPendingDisplay;
begin
  NewDisplayWidth := DisplayWidth;
  NewDisplayHeight := DisplayHeight;
  NewFullscreen := Fullscreen;
  NewBorderless := Borderless;
  NewAllowResize := AllowResize;
  NewOpenGL := UseOpenGL;
  NewScaleFilter := UseScaleFilter;
  NewHQXFilter := UseHQXFilter;
  NewXBRZFilter := UseXBRZFilter;
  NewOpenGLShader := UseOpenGLShader;
  NewGeoscapeScale := GeoscapeScale;
  NewBattlescapeScale := BattlescapeScale;
  NewRootWindowedMode := RootWindowedMode;
  NewWindowedModePositionX := WindowedModePositionX;
  NewWindowedModePositionY := WindowedModePositionY;
end;

procedure TXcomOptions.SwitchDisplay;
  procedure SwapInt(var A, B: Integer);
  var
    LTemp: Integer;
  begin
    LTemp := A;
    A := B;
    B := LTemp;
  end;
  procedure SwapBool(var A, B: Boolean);
  var
    LTemp: Boolean;
  begin
    LTemp := A;
    A := B;
    B := LTemp;
  end;
  procedure SwapString(var A, B: string);
  var
    LTemp: string;
  begin
    LTemp := A;
    A := B;
    B := LTemp;
  end;
begin
  SwapInt(DisplayWidth, NewDisplayWidth);
  SwapInt(DisplayHeight, NewDisplayHeight);
  SwapBool(UseOpenGL, NewOpenGL);
  SwapBool(UseScaleFilter, NewScaleFilter);
  SwapInt(BattlescapeScale, NewBattlescapeScale);
  SwapInt(GeoscapeScale, NewGeoscapeScale);
  SwapBool(UseHQXFilter, NewHQXFilter);
  SwapString(UseOpenGLShader, NewOpenGLShader);
  SwapBool(UseXBRZFilter, NewXBRZFilter);
  SwapBool(RootWindowedMode, NewRootWindowedMode);
  SwapInt(WindowedModePositionX, NewWindowedModePositionX);
  SwapInt(WindowedModePositionY, NewWindowedModePositionY);
  SwapBool(Fullscreen, NewFullscreen);
  SwapBool(AllowResize, NewAllowResize);
  SwapBool(Borderless, NewBorderless);
end;

procedure TXcomOptions.Load(const ADocument: IYamlNode);
var
  LNode: IYamlNode;
begin
  LNode := TXcomYamlFields.Field(ADocument, 'options');
  if not Assigned(LNode) then
    Exit;
  DisplayWidth := TXcomYamlFields.ReadInteger(LNode, 'displayWidth', DisplayWidth);
  DisplayHeight := TXcomYamlFields.ReadInteger(LNode, 'displayHeight', DisplayHeight);
  Fullscreen := TXcomYamlFields.ReadBoolean(LNode, 'fullscreen', Fullscreen);
  GeoscapeScale := TXcomYamlFields.ReadInteger(LNode, 'geoscapeScale', GeoscapeScale);
  BattlescapeScale := TXcomYamlFields.ReadInteger(LNode, 'battlescapeScale', BattlescapeScale);
  KeepAspectRatio := TXcomYamlFields.ReadBoolean(LNode, 'keepAspectRatio', KeepAspectRatio);
  NonSquarePixelRatio := TXcomYamlFields.ReadBoolean(LNode, 'nonSquarePixelRatio', NonSquarePixelRatio);
  AllowResize := TXcomYamlFields.ReadBoolean(LNode, 'allowResize', AllowResize);
  Borderless := TXcomYamlFields.ReadBoolean(LNode, 'borderless', Borderless);
  UseOpenGL := TXcomYamlFields.ReadBoolean(LNode, 'useOpenGL', UseOpenGL);
  UseScaleFilter := TXcomYamlFields.ReadBoolean(LNode, 'useScaleFilter', UseScaleFilter);
  UseHQXFilter := TXcomYamlFields.ReadBoolean(LNode, 'useHQXFilter', UseHQXFilter);
  UseXBRZFilter := TXcomYamlFields.ReadBoolean(LNode, 'useXBRZFilter', UseXBRZFilter);
  CursorInBlackBandsInFullscreen := TXcomYamlFields.ReadBoolean(LNode, 'cursorInBlackBandsInFullscreen',
    CursorInBlackBandsInFullscreen);
  CursorInBlackBandsInWindow := TXcomYamlFields.ReadBoolean(LNode, 'cursorInBlackBandsInWindow',
    CursorInBlackBandsInWindow);
  CursorInBlackBandsInBorderlessWindow := TXcomYamlFields.ReadBoolean(LNode, 'cursorInBlackBandsInBorderlessWindow',
    CursorInBlackBandsInBorderlessWindow);
  Language := TXcomYamlFields.ReadString(LNode, 'language', Language);
  Wordwrap := TXcomTextWrapping(TXcomYamlFields.ReadInteger(LNode, 'wordwrap', Ord(Wordwrap)));
  FpsCounter := TXcomYamlFields.ReadBoolean(LNode, 'fpsCounter', FpsCounter);
  FPS := TXcomYamlFields.ReadInteger(LNode, 'FPS', FPS);
  FPSInactive := TXcomYamlFields.ReadInteger(LNode, 'FPSInactive', FPSInactive);
  MaxFrameSkip := TXcomYamlFields.ReadInteger(LNode, 'maxFrameSkip', MaxFrameSkip);
  Debug := TXcomYamlFields.ReadBoolean(LNode, 'debug', Debug);
  DebugUi := TXcomYamlFields.ReadBoolean(LNode, 'debugUi', DebugUi);
  PlayIntro := TXcomYamlFields.ReadBoolean(LNode, 'playIntro', PlayIntro);
  SoundVolume := TXcomYamlFields.ReadInteger(LNode, 'soundVolume', SoundVolume);
  MusicVolume := TXcomYamlFields.ReadInteger(LNode, 'musicVolume', MusicVolume);
  UiVolume := TXcomYamlFields.ReadInteger(LNode, 'uiVolume', UiVolume);
  KeyOk := TXcomYamlFields.ReadInteger(LNode, 'keyOk', KeyOk);
  KeyCancel := TXcomYamlFields.ReadInteger(LNode, 'keyCancel', KeyCancel);
  KeyScreenshot := TXcomYamlFields.ReadInteger(LNode, 'keyScreenshot', KeyScreenshot);
  MousewheelSpeed := TXcomYamlFields.ReadInteger(LNode, 'mousewheelSpeed', MousewheelSpeed);
  ChangeValueByMouseWheel := TXcomYamlFields.ReadInteger(LNode, 'changeValueByMouseWheel', ChangeValueByMouseWheel);
  CaptureMouse := TXcomYamlFields.ReadInteger(LNode, 'captureMouse', Ord(CaptureMouse)) <> 0;
  RootWindowedMode := TXcomYamlFields.ReadBoolean(LNode, 'rootWindowedMode', RootWindowedMode);
  WindowedModePositionX := TXcomYamlFields.ReadInteger(LNode, 'windowedModePosX', WindowedModePositionX);
  WindowedModePositionY := TXcomYamlFields.ReadInteger(LNode, 'windowedModePosY', WindowedModePositionY);
  UseOpenGLShader := TXcomYamlFields.ReadString(LNode, 'useOpenGLShader', UseOpenGLShader);
  SyncPendingDisplay;
end;

function TXcomOptions.Save: string;
  function Flag(AValue: Boolean): string;
  begin
    if AValue then
      Result := 'true'
    else
      Result := 'false';
  end;
begin
  Result := 'options:'#10 +
    '  displayWidth: ' + IntToStr(DisplayWidth) + #10 +
    '  displayHeight: ' + IntToStr(DisplayHeight) + #10 +
    '  fullscreen: ' + Flag(Fullscreen) + #10 +
    '  geoscapeScale: ' + IntToStr(GeoscapeScale) + #10 +
    '  battlescapeScale: ' + IntToStr(BattlescapeScale) + #10 +
    '  language: ' + Language + #10 +
    '  wordwrap: ' + IntToStr(Ord(Wordwrap)) + #10 +
    '  fpsCounter: ' + Flag(FpsCounter) + #10 +
    '  mousewheelSpeed: ' + IntToStr(MousewheelSpeed) + #10 +
    '  changeValueByMouseWheel: ' + IntToStr(ChangeValueByMouseWheel) + #10 +
    '  captureMouse: ' + IntToStr(Ord(CaptureMouse)) + #10 +
    '  rootWindowedMode: ' + Flag(RootWindowedMode) + #10 +
    '  windowedModePosX: ' + IntToStr(WindowedModePositionX) + #10 +
    '  windowedModePosY: ' + IntToStr(WindowedModePositionY) + #10 +
    '  useOpenGLShader: ' + UseOpenGLShader + #10;
end;

end.

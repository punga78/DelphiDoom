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
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.OptionInfo;

type
  /// <summary>One entry of Options::mods (a std::pair of the id of the mod and whether it is active)</summary>
  TXcomModSetting = record
    Id: string;
    Active: Boolean;
    class function Create(const AId: string; AActive: Boolean): TXcomModSetting; static;
  end;

  /// <summary>How a registered option is stored in the fields of TXcomOptions (the others live in dictionaries)</summary>
  TXcomOptionStorage = (osInteger, osBoolean, osString, osWordwrap, osKeyboardMode);

  TXcomOptionField = record
    Storage: TXcomOptionStorage;
    Address: Pointer;
  end;

  PXcomTextWrapping = ^TXcomTextWrapping;
  PXcomKeyboardMode = ^TXcomKeyboardMode;

  /// <summary>
  ///   The options of the game that the engine and the menus read (Options of OpenXcom), with the defaults of the
  ///   Windows build. They are instance fields, not globals: the game and the states receive the instance. Only the
  ///   options that the ported classes use are here; the other keys of options.cfg are ignored on load.
  ///   BaseXResolution and BaseYResolution are the size of the game picture
  /// </summary>
  TXcomOptions = class
  strict private
    FFields: TDictionary<string, TXcomOptionField>;
    FValues: TDictionary<string, Integer>;
    FTexts: TDictionary<string, string>;
    FUnknown: TDictionary<string, string>;
    procedure RegisterFields;
    procedure ResetRegisteredDefaults;
    class function YamlScalar(const AValue: string): string; static;
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
    /// <summary>MusicFormat, SoundFormat and VideoFormat of the audio options (0 is automatic / the animation)</summary>
    PreferredMusic: Integer;
    PreferredSound: Integer;
    PreferredVideo: Integer;
    CurrentSound: Integer;
    BackgroundMute: Boolean;
    RootWindowedMode: Boolean;
    NewRootWindowedMode: Boolean;
    WindowedModePositionX: Integer;
    WindowedModePositionY: Integer;
    NewWindowedModePositionX: Integer;
    NewWindowedModePositionY: Integer;
    /// <summary>The folders that the folders screen shows (Options::getUserFolder and the like), set by the program</summary>
    OriginalDataFolder: string;
    ModDataFolder: string;
    UserFolder: string;
    MasterUserFolder: string;
    ConfigFolder: string;
    /// <summary>Options::mods: the mods of options.cfg in order, each with its id and whether it is active</summary>
    Mods: TArray<TXcomModSetting>;
    /// <summary>The mod is in Options::mods and active (std::find of (id, true))</summary>
    function IsModActive(const AId: string): Boolean;
    constructor Create;
    destructor Destroy; override;
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
    /// <summary>
    ///   The "options" part of options.cfg: every registered option and the unknown keys that Load found, sorted by the
    ///   code of the characters as in the file of OpenXcom
    /// </summary>
    function Save: string;
    /// <summary>The value of a registered bool, int or key option by its id (0 if it is not registered)</summary>
    function GetValue(const AId: string): Integer;
    procedure SetValue(const AId: string; AValue: Integer);
    function GetBool(const AId: string): Boolean;
    procedure SetBool(const AId: string; AValue: Boolean);
    /// <summary>The value of a registered string option by its id</summary>
    function GetText(const AId: string): string;
    procedure SetText(const AId, AValue: string);
    /// <summary>The keys of options.cfg that are not registered (scalar values), kept to be written back</summary>
    property UnknownOptions: TDictionary<string, string> read FUnknown;
  end;

implementation

uses
  DelphiDoom.XcomEngine.YamlFields, DelphiDoom.XcomEngine.OptionTable;

constructor TXcomOptions.Create;
begin
  inherited Create;
  FFields := TDictionary<string, TXcomOptionField>.Create;
  FValues := TDictionary<string, Integer>.Create;
  FTexts := TDictionary<string, string>.Create;
  FUnknown := TDictionary<string, string>.Create;
  RegisterFields;
  ResetDefaults;
end;

destructor TXcomOptions.Destroy;
begin
  FUnknown.Free;
  FTexts.Free;
  FValues.Free;
  FFields.Free;
  inherited Destroy;
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
  PreferredMusic := 0;
  PreferredSound := 0;
  PreferredVideo := 0;
  CurrentSound := 0;
  BackgroundMute := False;
  RootWindowedMode := False;
  WindowedModePositionX := 0;
  WindowedModePositionY := 0;
  ResetRegisteredDefaults;
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

procedure TXcomOptions.RegisterFields;
  procedure AddField(const AId: string; AStorage: TXcomOptionStorage; AAddress: Pointer);
  var
    LField: TXcomOptionField;
  begin
    LField.Storage := AStorage;
    LField.Address := AAddress;
    FFields.Add(AId, LField);
  end;
begin
  AddField('displayWidth', osInteger, @DisplayWidth);
  AddField('displayHeight', osInteger, @DisplayHeight);
  AddField('fullscreen', osBoolean, @Fullscreen);
  AddField('geoscapeScale', osInteger, @GeoscapeScale);
  AddField('battlescapeScale', osInteger, @BattlescapeScale);
  AddField('keepAspectRatio', osBoolean, @KeepAspectRatio);
  AddField('nonSquarePixelRatio', osBoolean, @NonSquarePixelRatio);
  AddField('allowResize', osBoolean, @AllowResize);
  AddField('borderless', osBoolean, @Borderless);
  AddField('useOpenGL', osBoolean, @UseOpenGL);
  AddField('useScaleFilter', osBoolean, @UseScaleFilter);
  AddField('useHQXFilter', osBoolean, @UseHQXFilter);
  AddField('useXBRZFilter', osBoolean, @UseXBRZFilter);
  AddField('cursorInBlackBandsInFullscreen', osBoolean, @CursorInBlackBandsInFullscreen);
  AddField('cursorInBlackBandsInWindow', osBoolean, @CursorInBlackBandsInWindow);
  AddField('cursorInBlackBandsInBorderlessWindow', osBoolean, @CursorInBlackBandsInBorderlessWindow);
  AddField('language', osString, @Language);
  AddField('wordwrap', osWordwrap, @Wordwrap);
  AddField('fpsCounter', osBoolean, @FpsCounter);
  AddField('FPS', osInteger, @FPS);
  AddField('FPSInactive', osInteger, @FPSInactive);
  AddField('maxFrameSkip', osInteger, @MaxFrameSkip);
  AddField('debug', osBoolean, @Debug);
  AddField('debugUi', osBoolean, @DebugUi);
  AddField('playIntro', osBoolean, @PlayIntro);
  AddField('soundVolume', osInteger, @SoundVolume);
  AddField('musicVolume', osInteger, @MusicVolume);
  AddField('uiVolume', osInteger, @UiVolume);
  AddField('keyOk', osInteger, @KeyOk);
  AddField('keyCancel', osInteger, @KeyCancel);
  AddField('keyScreenshot', osInteger, @KeyScreenshot);
  AddField('mousewheelSpeed', osInteger, @MousewheelSpeed);
  AddField('changeValueByMouseWheel', osInteger, @ChangeValueByMouseWheel);
  AddField('keyboardMode', osKeyboardMode, @KeyboardMode);
  AddField('captureMouse', osBoolean, @CaptureMouse);
  AddField('rootWindowedMode', osBoolean, @RootWindowedMode);
  AddField('windowedModePositionX', osInteger, @WindowedModePositionX);
  AddField('windowedModePositionY', osInteger, @WindowedModePositionY);
  AddField('useOpenGLShader', osString, @UseOpenGLShader);
  AddField('preferredMusic', osInteger, @PreferredMusic);
  AddField('preferredSound', osInteger, @PreferredSound);
  AddField('preferredVideo', osInteger, @PreferredVideo);
  AddField('backgroundMute', osBoolean, @BackgroundMute);
end;

function TXcomOptions.GetValue(const AId: string): Integer;
var
  LField: TXcomOptionField;
begin
  if FFields.TryGetValue(AId, LField) then
  begin
    case LField.Storage of
      osInteger:
        Result := PInteger(LField.Address)^;
      osBoolean:
        Result := Ord(PBoolean(LField.Address)^);
      osWordwrap:
        Result := Ord(PXcomTextWrapping(LField.Address)^);
      osKeyboardMode:
        Result := Ord(PXcomKeyboardMode(LField.Address)^);
    else
      Result := 0;
    end;
  end
  else if not FValues.TryGetValue(AId, Result) then
    Result := 0;
end;

procedure TXcomOptions.SetValue(const AId: string; AValue: Integer);
var
  LField: TXcomOptionField;
begin
  if FFields.TryGetValue(AId, LField) then
  begin
    case LField.Storage of
      osInteger:
        PInteger(LField.Address)^ := AValue;
      osBoolean:
        PBoolean(LField.Address)^ := AValue <> 0;
      osWordwrap:
        PXcomTextWrapping(LField.Address)^ := TXcomTextWrapping(AValue);
      osKeyboardMode:
        PXcomKeyboardMode(LField.Address)^ := TXcomKeyboardMode(AValue);
    end;
  end
  else
    FValues.AddOrSetValue(AId, AValue);
end;

function TXcomOptions.GetBool(const AId: string): Boolean;
begin
  Result := GetValue(AId) <> 0;
end;

procedure TXcomOptions.SetBool(const AId: string; AValue: Boolean);
begin
  SetValue(AId, Ord(AValue));
end;

function TXcomOptions.GetText(const AId: string): string;
var
  LField: TXcomOptionField;
begin
  if FFields.TryGetValue(AId, LField) then
  begin
    if LField.Storage = osString then
      Result := PString(LField.Address)^
    else
      Result := '';
  end
  else if not FTexts.TryGetValue(AId, Result) then
    Result := '';
end;

procedure TXcomOptions.SetText(const AId, AValue: string);
var
  LField: TXcomOptionField;
begin
  if FFields.TryGetValue(AId, LField) then
  begin
    if LField.Storage = osString then
      PString(LField.Address)^ := AValue;
  end
  else
    FTexts.AddOrSetValue(AId, AValue);
end;

procedure TXcomOptions.ResetRegisteredDefaults;
var
  LInfo: TXcomOptionInfo;
begin
  for LInfo in TXcomOptionTable.All do
    if LInfo.Kind = okString then
      SetText(LInfo.Id, LInfo.DefaultText)
    else
      SetValue(LInfo.Id, LInfo.DefaultValue);
end;

class function TXcomModSetting.Create(const AId: string; AActive: Boolean): TXcomModSetting;
begin
  Result.Id := AId;
  Result.Active := AActive;
end;

function TXcomOptions.IsModActive(const AId: string): Boolean;
var
  LMod: TXcomModSetting;
begin
  for LMod in Mods do
    if LMod.Active and (LMod.Id = AId) then
      Exit(True);
  Result := False;
end;

procedure TXcomOptions.Load(const ADocument: IYamlNode);
var
  LNode: IYamlNode;
  LValue: IYamlNode;
  LInfo: TXcomOptionInfo;
  LInteger: Integer;
  LBoolean: Boolean;
  LPair: TYamlPair;
  LKey: string;
  LModsNode: IYamlNode;
  LModItem: IYamlNode;
begin
  LModsNode := TXcomYamlFields.Field(ADocument, 'mods');
  if Assigned(LModsNode) and LModsNode.IsSequence then
  begin
    // Options::load: "mods" is a list of one-pair maps (id: active)
    Mods := nil;
    for LModItem in LModsNode.Items do
      if LModItem.IsMap then
        for LPair in LModItem.Pairs do
        begin
          if not LPair.Value.TryAsBoolean(LBoolean) then
            LBoolean := False;
          SetLength(Mods, Length(Mods) + 1);
          Mods[High(Mods)].Id := LPair.Key.ScalarString;
          Mods[High(Mods)].Active := LBoolean;
          Break;
        end;
  end;
  LNode := TXcomYamlFields.Field(ADocument, 'options');
  if not Assigned(LNode) then
    Exit;
  for LInfo in TXcomOptionTable.All do
  begin
    LValue := TXcomYamlFields.Field(LNode, LInfo.Id);
    // a key that is missing or has a bad value keeps what it has
    if not Assigned(LValue) then
      Continue;
    case LInfo.Kind of
      okBool:
        if LValue.TryAsBoolean(LBoolean) then
          SetBool(LInfo.Id, LBoolean);
      okInt, okKey:
        if LValue.TryAsInteger(LInteger) then
          SetValue(LInfo.Id, LInteger);
      okString:
        if LValue.IsScalar then
          SetText(LInfo.Id, LValue.ScalarString);
    end;
  end;
  // the keys that this class does not know are kept to be written back
  for LPair in LNode.Pairs do
    if LPair.Key.IsScalar and LPair.Value.IsScalar then
    begin
      LKey := LPair.Key.ScalarString;
      if not TXcomOptionTable.TryFind(LKey, LInfo) then
        FUnknown.AddOrSetValue(LKey, LPair.Value.ScalarString);
    end;
  SyncPendingDisplay;
end;

class function TXcomOptions.YamlScalar(const AValue: string): string;
var
  LIndex: Integer;
  LChar: Char;
  LPlain: Boolean;
begin
  LPlain := AValue <> '';
  for LIndex := 1 to Length(AValue) do
  begin
    LChar := AValue[LIndex];
    if (LChar < ' ') or (LChar = '"') or (LChar = '#') or (LChar = ':') or (LChar = '\') or (LChar = '''') or
      (LChar = '{') or (LChar = '[') or (LChar = ',') then
      LPlain := False;
  end;
  if LPlain and ((AValue[1] = ' ') or (AValue[Length(AValue)] = ' ') or (AValue[1] = '-') or (AValue[1] = '&') or
    (AValue[1] = '*') or (AValue[1] = '!') or (AValue[1] = '|') or (AValue[1] = '>') or (AValue[1] = '%') or
    (AValue[1] = '@') or (AValue[1] = '`')) then
    LPlain := False;
  if LPlain then
    Exit(AValue);
  Result := '"' + StringReplace(StringReplace(AValue, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]) + '"';
end;

function TXcomOptions.Save: string;
var
  LLines: TDictionary<string, string>;
  LInfo: TXcomOptionInfo;
  LKeys: TArray<string>;
  LKey: string;
  LPair: TPair<string, string>;
  LBuilder: TStringBuilder;
begin
  LLines := TDictionary<string, string>.Create;
  try
    for LInfo in TXcomOptionTable.All do
      case LInfo.Kind of
        okBool:
          if GetBool(LInfo.Id) then
            LLines.AddOrSetValue(LInfo.Id, 'true')
          else
            LLines.AddOrSetValue(LInfo.Id, 'false');
        okInt, okKey:
          LLines.AddOrSetValue(LInfo.Id, IntToStr(GetValue(LInfo.Id)));
        okString:
          LLines.AddOrSetValue(LInfo.Id, YamlScalar(GetText(LInfo.Id)));
      end;
    for LPair in FUnknown do
      LLines.AddOrSetValue(LPair.Key, YamlScalar(LPair.Value));
    LKeys := LLines.Keys.ToArray;
    // the order of the keys of the real file (the map of yaml-cpp is sorted by the code of the characters)
    TArray.Sort<string>(LKeys, TStringComparer.Ordinal);
    LBuilder := TStringBuilder.Create;
    try
      LBuilder.Append('options:'#10);
      for LKey in LKeys do
        LBuilder.Append('  ').Append(LKey).Append(': ').Append(LLines[LKey]).Append(#10);
      Result := LBuilder.ToString;
    finally
      LBuilder.Free;
    end;
  finally
    LLines.Free;
  end;
end;

end.
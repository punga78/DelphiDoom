{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - items driven by a cvar                            }
{                                                                              }
{  Item_EnableShowViaCvar, Item_YesNo_HandleKey, Item_Multi_CountSettings,     }
{  _FindCvarByValue, _Setting and _HandleKey of ui_shared.c (Quake III Arena,  }
{  id Software, GPL v2 or later). Based on the Quake III Arena GPL Source      }
{  Code (id Software).                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.CvarItems;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display.State;

type
  /// <summary>The yes/no and multi items, and the cvar tests that enable, disable, show or hide an item</summary>
  TGuiCvarItems = class
  strict private
    FState: TGuiDisplayState;
    procedure SetCvar(const AName, AValue: AnsiString);
    function CvarValue(const AName: AnsiString): Single;
  public
    constructor Create(const AState: TGuiDisplayState);
    /// <summary>
    ///   Item_EnableShowViaCvar: whether the cvar test lets the item be enabled (<c>AFlag</c> = CVAR_ENABLE) or
    ///   shown (CVAR_SHOW). An item without <c>enableCvar</c> and <c>cvarTest</c> always passes.
    /// </summary>
    function EnableShowViaCvar(const AItem: TGuiItem; const AFlag: Integer): Boolean;
    /// <summary>Item_YesNo_HandleKey: a click or enter toggles the cvar</summary>
    function YesNoHandleKey(const AItem: TGuiItem; const AKey: Integer): Boolean;
    /// <summary>Item_Multi_CountSettings</summary>
    function MultiCountSettings(const AItem: TGuiItem): Integer;
    /// <summary>Item_Multi_FindCvarByValue: the setting the cvar has now, 0 if none matches</summary>
    function MultiFindCvarByValue(const AItem: TGuiItem): Integer;
    /// <summary>Item_Multi_Setting: the name of the current setting, empty if none</summary>
    function MultiSetting(const AItem: TGuiItem): AnsiString;
    /// <summary>Item_Multi_HandleKey: a click or enter moves to the next setting</summary>
    function MultiHandleKey(const AItem: TGuiItem; const AKey: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.Gui.Keys, DelphiDoom.Gui.ScriptCursor, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Display.FloatMask;

constructor TGuiCvarItems.Create(const AState: TGuiDisplayState);
begin
  inherited Create;
  FState := AState;
end;

procedure TGuiCvarItems.SetCvar(const AName, AValue: AnsiString);
begin
  if Assigned(FState.Script) then
    FState.Script.SetCvar(AName, AValue);
end;

function TGuiCvarItems.CvarValue(const AName: AnsiString): Single;
begin
  if Assigned(FState.Script) then
    Result := FState.Script.GetCvarValue(AName)
  else
    Result := 0;
end;

function TGuiCvarItems.EnableShowViaCvar(const AItem: TGuiItem; const AFlag: Integer): Boolean;
var
  LBuffer, LValue: AnsiString;
  LCursor: TGuiScriptCursor;
  LFlagSet: Boolean;
begin
  if (not Assigned(AItem)) or (AItem.EnableCvar = '') or (AItem.CvarTest = '') then
    Exit(True);
  LFlagSet := (AItem.CvarFlags and AFlag) <> 0;
  LBuffer := FState.Input.GetCvarString(AItem.CvarTest);
  LCursor := TGuiScriptCursor.Create(Copy(AItem.EnableCvar, 1, GUI_SCRIPT_BUFFER_SIZE - 1), FState.Menus.Strings);
  try
    while True do
    begin
      // expect value then ; or NULL, NULL ends list
      LValue := '';
      if not LCursor.ParseString(LValue) then
        Exit(not LFlagSet);
      if LValue = ';' then
        Continue;
      // enable it if any of the values are true, disable it if any of the values are true
      if TIdStrings.Icmp(LBuffer, LValue) = 0 then
        Exit(LFlagSet);
    end;
  finally
    LCursor.Free;
  end;
end;

function TGuiCvarItems.YesNoHandleKey(const AItem: TGuiItem; const AKey: Integer): Boolean;
begin
  Result := False;
  if TGuiDisplayState.RectContains(AItem.Window.Rect, FState.CursorX, FState.CursorY) and
    ((AItem.Window.Flags and WINDOW_HASFOCUS) <> 0) and (AItem.Cvar <> '') then
  begin
    if (AKey = K_MOUSE1) or (AKey = K_ENTER) or (AKey = K_MOUSE2) or (AKey = K_MOUSE3) then
    begin
      // va( "%i", !value )
      if CvarValue(AItem.Cvar) = 0 then
        SetCvar(AItem.Cvar, '1')
      else
        SetCvar(AItem.Cvar, '0');
      Result := True;
    end;
  end;
end;

function TGuiCvarItems.MultiCountSettings(const AItem: TGuiItem): Integer;
begin
  if AItem.DataKind <> gdkMulti then
    Result := 0
  else
    Result := AItem.Multi.Count;
end;

function TGuiCvarItems.MultiFindCvarByValue(const AItem: TGuiItem): Integer;
var
  LBuffer: AnsiString;
  LValue: Single;
  LIndex: Integer;
begin
  Result := 0;
  if AItem.DataKind <> gdkMulti then
    Exit;
  LValue := 0;
  if AItem.Multi.StrDef then
    LBuffer := FState.Input.GetCvarString(AItem.Cvar)
  else
    LValue := CvarValue(AItem.Cvar);
  for LIndex := 0 to AItem.Multi.Count - 1 do
  begin
    if AItem.Multi.StrDef then
    begin
      if TIdStrings.Icmp(LBuffer, AItem.Multi.CvarStr[LIndex]) = 0 then
        Exit(LIndex);
    end
    else if AItem.Multi.CvarValue[LIndex] = LValue then
      Exit(LIndex);
  end;
end;

function TGuiCvarItems.MultiSetting(const AItem: TGuiItem): AnsiString;
var
  LBuffer: AnsiString;
  LValue: Single;
  LIndex: Integer;
begin
  Result := '';
  if AItem.DataKind <> gdkMulti then
    Exit;
  LValue := 0;
  if AItem.Multi.StrDef then
    LBuffer := FState.Input.GetCvarString(AItem.Cvar)
  else
    LValue := CvarValue(AItem.Cvar);
  for LIndex := 0 to AItem.Multi.Count - 1 do
  begin
    if AItem.Multi.StrDef then
    begin
      if TIdStrings.Icmp(LBuffer, AItem.Multi.CvarStr[LIndex]) = 0 then
        Exit(AItem.Multi.CvarList[LIndex]);
    end
    else if AItem.Multi.CvarValue[LIndex] = LValue then
      Exit(AItem.Multi.CvarList[LIndex]);
  end;
end;

function TGuiCvarItems.MultiHandleKey(const AItem: TGuiItem; const AKey: Integer): Boolean;
var
  LCurrent, LMax: Integer;
  LValue: Single;
  LMask: IInterface;
begin
  Result := False;
  if AItem.DataKind <> gdkMulti then
    Exit;
  LMask := TGuiFloatMask.Enter;
  if TGuiDisplayState.RectContains(AItem.Window.Rect, FState.CursorX, FState.CursorY) and
    ((AItem.Window.Flags and WINDOW_HASFOCUS) <> 0) and (AItem.Cvar <> '') then
  begin
    if (AKey = K_MOUSE1) or (AKey = K_ENTER) or (AKey = K_MOUSE2) or (AKey = K_MOUSE3) then
    begin
      LCurrent := MultiFindCvarByValue(AItem) + 1;
      LMax := MultiCountSettings(AItem);
      if (LCurrent < 0) or (LCurrent >= LMax) then
        LCurrent := 0;
      if AItem.Multi.StrDef then
        SetCvar(AItem.Cvar, AItem.Multi.CvarStr[LCurrent])
      else
      begin
        LValue := AItem.Multi.CvarValue[LCurrent];
        if Single(TGuiDisplayState.FloatToInt(LValue)) = LValue then
          SetCvar(AItem.Cvar, AnsiString(IntToStr(TGuiDisplayState.FloatToInt(LValue))))
        else
          SetCvar(AItem.Cvar, AnsiString(Format('%.6f', [Double(LValue)], TFormatSettings.Invariant)));
      end;
      Result := True;
    end;
  end;
end;

end.

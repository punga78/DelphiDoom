{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - running the action scripts of a menu as text      }
{                                                                              }
{  Port of Item_RunScript, the table commandList and the Script_* handlers of  }
{  ui_shared.c, with Menu_ShowItemByName, Menu_FadeItemByName,                 }
{  Menu_TransitionItemByName, Menu_OrbitItemByName and Menu_ClearFocus         }
{  (Quake III Arena, id Software, GPL v2 or later). Based on the Quake III     }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{  Overflow and range checks are off: the integer absolute value of a         }
{  transition wraps for the smallest integer, as in the original.              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.ScriptRunner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Assets,
  DelphiDoom.Gui.StringPool, DelphiDoom.Gui.ScriptCursor;

type
  /// <summary>
  ///   Runs a script of a menu or an item ("setcolor backcolor 1 0 0 1 ; hide group ; uiScript Name") without
  ///   the game. The commands that change the menu itself (show, hide, fadein, fadeout, setcolor, setitemcolor,
  ///   setbackground, setteamcolor, setfocus, transition, orbit) change the model; the others go to the
  ///   IGuiScriptHost and IGuiMediaHost that the caller gives (open, close, conditionalopen, setcvar, exec, play,
  ///   playlooped, setplayermodel, setplayerhead, and every command the table does not know). Nothing is drawn.
  /// </summary>
  TGuiScriptRunner = class
  strict private
    FAssets: TGuiAssets;
    FRegistry: IGuiAssetRegistry;
    FHost: IGuiScriptHost;
    FMedia: IGuiMediaHost;
    FStrings: TGuiStringPool;
    procedure RunBuiltin(const AItem: TGuiItem; const ACommand: AnsiString; const ACursor: TGuiScriptCursor;
      var AHandled: Boolean);
    procedure RunHostCommand(const AItem: TGuiItem; const ACommand: AnsiString; const ACursor: TGuiScriptCursor);
    procedure ShowItemByName(const AMenu: TGuiMenu; const AName: AnsiString; const AShow: Boolean);
    procedure FadeItemByName(const AMenu: TGuiMenu; const AName: AnsiString; const AFadeOut: Boolean);
    procedure SetColorCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
    procedure SetItemColorCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
    procedure TransitionCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
    procedure OrbitCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
    procedure SetFocusCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
    procedure ConditionalOpenCommand(const ACursor: TGuiScriptCursor);
    procedure PlayCommand(const ACursor: TGuiScriptCursor; const ALooped: Boolean);
    procedure ExecCommand(const ACursor: TGuiScriptCursor);
    procedure SetCvarCommand(const ACursor: TGuiScriptCursor; const AFixedName: AnsiString);
    class function TruncatedAbs(const AValue: Single): Integer; static;
    class function Divide(const ANumerator, ADenominator: Single): Single; static;
  public
    /// <summary>
    ///   The assets give the focus sound; the registry the handle of a background and of a sound; the pool is the
    ///   menu set's (the words of a script go through it). The host and the media host may be nil: their commands
    ///   then do nothing.
    /// </summary>
    constructor Create(const AAssets: TGuiAssets; const ARegistry: IGuiAssetRegistry;
      const AStrings: TGuiStringPool; const AHost: IGuiScriptHost; const AMedia: IGuiMediaHost);
    /// <summary>
    ///   Item_RunScript: the script is cut to 1023 characters. A command that parses less than its arguments
    ///   leaves the rest to be read as commands. An item without a parent menu runs the commands that need
    ///   one as no-ops (the original dereferences a null pointer).
    /// </summary>
    procedure Run(const AItem: TGuiItem; const AScript: AnsiString);
    /// <summary>Menu_ClearFocus: takes the focus off every item, running their leaveFocus scripts; the item that had it, or nil</summary>
    function ClearFocus(const AMenu: TGuiMenu): TGuiItem;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

const
  // the names of commandList, in the order of the table
  BUILTIN_COMMANDS: array[0..20] of AnsiString = (
    'fadein', 'fadeout', 'show', 'hide', 'setcolor', 'open', 'conditionalopen', 'close', 'setasset',
    'setbackground', 'setitemcolor', 'setteamcolor', 'setfocus', 'setplayermodel', 'setplayerhead',
    'transition', 'setcvar', 'exec', 'play', 'playlooped', 'orbit');

constructor TGuiScriptRunner.Create(const AAssets: TGuiAssets; const ARegistry: IGuiAssetRegistry;
  const AStrings: TGuiStringPool; const AHost: IGuiScriptHost; const AMedia: IGuiMediaHost);
begin
  inherited Create;
  FAssets := AAssets;
  FRegistry := ARegistry;
  FStrings := AStrings;
  FHost := AHost;
  FMedia := AMedia;
end;

class function TGuiScriptRunner.TruncatedAbs(const AValue: Single): Integer;
begin
  // abs() of the original takes an int: the float is truncated first (an out of range value is the x86
  // "integer indefinite", the smallest integer, whose absolute value is itself)
  if (AValue <> AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Exit(Low(Integer));
  Result := Trunc(AValue);
  if Result < 0 then
    Result := -Result;
end;

class function TGuiScriptRunner.Divide(const ANumerator, ADenominator: Single): Single;
begin
  // IEEE division: no exception for zero (the original divides by whatever the script says)
  if ADenominator = 0 then
  begin
    if (ANumerator = 0) or (ANumerator <> ANumerator) then
      Exit(Single.NaN);
    // the sign of a zero is its sign bit
    if (ANumerator > 0) = (PInteger(@ADenominator)^ >= 0) then
      Exit(Single.PositiveInfinity);
    Exit(Single.NegativeInfinity);
  end;
  Result := Single(Double(ANumerator) / Double(ADenominator));
end;

function TGuiScriptRunner.ClearFocus(const AMenu: TGuiMenu): TGuiItem;
var
  LIndex: Integer;
  LItem: TGuiItem;
begin
  Result := nil;
  if not Assigned(AMenu) then
    Exit;
  for LIndex := 0 to AMenu.Items.Count - 1 do
  begin
    LItem := AMenu.Items[LIndex];
    if (LItem.Window.Flags and WINDOW_HASFOCUS) <> 0 then
      Result := LItem;
    LItem.Window.Flags := LItem.Window.Flags and not WINDOW_HASFOCUS;
    if LItem.LeaveFocus <> '' then
      Run(LItem, LItem.LeaveFocus);
  end;
end;

procedure TGuiScriptRunner.Run(const AItem: TGuiItem; const AScript: AnsiString);
var
  LCursor: TGuiScriptCursor;
  LCommand: AnsiString;
  LHandled: Boolean;
begin
  if (not Assigned(AItem)) or (AScript = '') then
    Exit;
  LCursor := TGuiScriptCursor.Create(Copy(AScript, 1, GUI_SCRIPT_BUFFER_SIZE - 1), FStrings);
  try
    while True do
    begin
      // expect command then arguments, ; ends command, the end of the text ends the script
      LCommand := '';
      if not LCursor.ParseString(LCommand) then
        Exit;
      if LCommand = ';' then
        Continue;
      LHandled := False;
      RunBuiltin(AItem, LCommand, LCursor, LHandled);
      // not in our auto list, pass to the host
      if not LHandled then
        RunHostCommand(AItem, LCommand, LCursor);
    end;
  finally
    LCursor.Free;
  end;
end;

procedure TGuiScriptRunner.RunHostCommand(const AItem: TGuiItem; const ACommand: AnsiString;
  const ACursor: TGuiScriptCursor);
var
  LArguments: TArray<AnsiString>;
  LState: TGuiScriptCursorState;
  LWord: AnsiString;
begin
  // the host reads its own arguments (DC->runScript(&p)); here they run up to the next ";"
  SetLength(LArguments, 0);
  while True do
  begin
    LState := ACursor.SaveState;
    LWord := ACursor.ParseExt;
    if (LWord = '') or (LWord = ';') then
    begin
      ACursor.RestoreState(LState);
      Break;
    end;
    SetLength(LArguments, Length(LArguments) + 1);
    LArguments[High(LArguments)] := LWord;
  end;
  if Assigned(FHost) then
    FHost.RunCommand(AItem, ACommand, LArguments);
end;

procedure TGuiScriptRunner.ShowItemByName(const AMenu: TGuiMenu; const AName: AnsiString; const AShow: Boolean);
var
  LIndex: Integer;
  LItem: TGuiItem;
begin
  if not Assigned(AMenu) then
    Exit;
  for LIndex := 0 to AMenu.ItemsMatchingGroup(AName) - 1 do
  begin
    LItem := AMenu.GetMatchingItemByNumber(LIndex, AName);
    if not Assigned(LItem) then
      Continue;
    if AShow then
      LItem.Window.Flags := LItem.Window.Flags or WINDOW_VISIBLE
    else
    begin
      LItem.Window.Flags := LItem.Window.Flags and not WINDOW_VISIBLE;
      // stop cinematics playing in the window
      if LItem.Window.Cinematic >= 0 then
      begin
        if Assigned(FMedia) then
          FMedia.StopCinematic(LItem.Window.Cinematic);
        LItem.Window.Cinematic := -1;
      end;
    end;
  end;
end;

procedure TGuiScriptRunner.FadeItemByName(const AMenu: TGuiMenu; const AName: AnsiString; const AFadeOut: Boolean);
var
  LIndex: Integer;
  LItem: TGuiItem;
begin
  if not Assigned(AMenu) then
    Exit;
  for LIndex := 0 to AMenu.ItemsMatchingGroup(AName) - 1 do
  begin
    LItem := AMenu.GetMatchingItemByNumber(LIndex, AName);
    if not Assigned(LItem) then
      Continue;
    if AFadeOut then
    begin
      LItem.Window.Flags := LItem.Window.Flags or (WINDOW_FADINGOUT or WINDOW_VISIBLE);
      LItem.Window.Flags := LItem.Window.Flags and not WINDOW_FADINGIN;
    end
    else
    begin
      LItem.Window.Flags := LItem.Window.Flags or (WINDOW_VISIBLE or WINDOW_FADINGIN);
      LItem.Window.Flags := LItem.Window.Flags and not WINDOW_FADINGOUT;
    end;
  end;
end;

procedure TGuiScriptRunner.SetColorCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
var
  LName: AnsiString;
  LIndex: Integer;
  LValue: Single;
  LColor: Integer;
begin
  LName := '';
  if not ACursor.ParseString(LName) then
    Exit;
  // expecting type of color to set and 4 args for the color
  LColor := -1;
  if TIdStrings.Icmp(LName, 'backcolor') = 0 then
  begin
    LColor := 0;
    AItem.Window.Flags := AItem.Window.Flags or WINDOW_BACKCOLORSET;
  end
  else if TIdStrings.Icmp(LName, 'forecolor') = 0 then
  begin
    LColor := 1;
    AItem.Window.Flags := AItem.Window.Flags or WINDOW_FORECOLORSET;
  end
  else if TIdStrings.Icmp(LName, 'bordercolor') = 0 then
    LColor := 2;
  if LColor < 0 then
    Exit;
  LValue := 0;
  for LIndex := 0 to 3 do
  begin
    if not ACursor.ParseFloat(LValue) then
      Exit;
    case LColor of
      0: AItem.Window.BackColor[LIndex] := LValue;
      1: AItem.Window.ForeColor[LIndex] := LValue;
    else
      AItem.Window.BorderColor[LIndex] := LValue;
    end;
  end;
end;

procedure TGuiScriptRunner.SetItemColorCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
var
  LItemName: AnsiString;
  LName: AnsiString;
  LColor: TGuiColor;
  LCount: Integer;
  LIndex: Integer;
  LTarget: TGuiItem;
begin
  LItemName := '';
  LName := '';
  if not (ACursor.ParseString(LItemName) and ACursor.ParseString(LName)) then
    Exit;
  if not Assigned(AItem.Parent) then
    Exit;
  LCount := AItem.Parent.ItemsMatchingGroup(LItemName);
  LColor := Default(TGuiColor);
  if not ACursor.ParseColor(LColor) then
    Exit;
  for LIndex := 0 to LCount - 1 do
  begin
    LTarget := AItem.Parent.GetMatchingItemByNumber(LIndex, LItemName);
    if not Assigned(LTarget) then
      Continue;
    if TIdStrings.Icmp(LName, 'backcolor') = 0 then
      LTarget.Window.BackColor := LColor
    else if TIdStrings.Icmp(LName, 'forecolor') = 0 then
    begin
      LTarget.Window.ForeColor := LColor;
      LTarget.Window.Flags := LTarget.Window.Flags or WINDOW_FORECOLORSET;
    end
    else if TIdStrings.Icmp(LName, 'bordercolor') = 0 then
      LTarget.Window.BorderColor := LColor;
  end;
end;

procedure TGuiScriptRunner.TransitionCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
var
  LName: AnsiString;
  LFrom: TGuiRect;
  LTo: TGuiRect;
  LTime: Integer;
  LAmount: Single;
  LIndex: Integer;
  LTarget: TGuiItem;
begin
  LName := '';
  if not ACursor.ParseString(LName) then
    Exit;
  LFrom := Default(TGuiRect);
  LTo := Default(TGuiRect);
  LTime := 0;
  LAmount := 0;
  if not (ACursor.ParseRect(LFrom) and ACursor.ParseRect(LTo) and ACursor.ParseInt(LTime) and
    ACursor.ParseFloat(LAmount)) then
    Exit;
  if not Assigned(AItem.Parent) then
    Exit;
  for LIndex := 0 to AItem.Parent.ItemsMatchingGroup(LName) - 1 do
  begin
    LTarget := AItem.Parent.GetMatchingItemByNumber(LIndex, LName);
    if not Assigned(LTarget) then
      Continue;
    LTarget.Window.Flags := LTarget.Window.Flags or (WINDOW_INTRANSITION or WINDOW_VISIBLE);
    LTarget.Window.OffsetTime := LTime;
    LTarget.Window.RectClient := LFrom;
    LTarget.Window.RectEffects := LTo;
    LTarget.Window.RectEffects2.X := Divide(TruncatedAbs(LTo.X - LFrom.X), LAmount);
    LTarget.Window.RectEffects2.Y := Divide(TruncatedAbs(LTo.Y - LFrom.Y), LAmount);
    LTarget.Window.RectEffects2.W := Divide(TruncatedAbs(LTo.W - LFrom.W), LAmount);
    LTarget.Window.RectEffects2.H := Divide(TruncatedAbs(LTo.H - LFrom.H), LAmount);
    LTarget.UpdatePosition;
  end;
end;

procedure TGuiScriptRunner.OrbitCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
var
  LName: AnsiString;
  LX: Single;
  LY: Single;
  LCenterX: Single;
  LCenterY: Single;
  LTime: Integer;
  LIndex: Integer;
  LTarget: TGuiItem;
begin
  LName := '';
  if not ACursor.ParseString(LName) then
    Exit;
  LX := 0;
  LY := 0;
  LCenterX := 0;
  LCenterY := 0;
  LTime := 0;
  if not (ACursor.ParseFloat(LX) and ACursor.ParseFloat(LY) and ACursor.ParseFloat(LCenterX) and
    ACursor.ParseFloat(LCenterY) and ACursor.ParseInt(LTime)) then
    Exit;
  if not Assigned(AItem.Parent) then
    Exit;
  for LIndex := 0 to AItem.Parent.ItemsMatchingGroup(LName) - 1 do
  begin
    LTarget := AItem.Parent.GetMatchingItemByNumber(LIndex, LName);
    if not Assigned(LTarget) then
      Continue;
    LTarget.Window.Flags := LTarget.Window.Flags or (WINDOW_ORBITING or WINDOW_VISIBLE);
    LTarget.Window.OffsetTime := LTime;
    LTarget.Window.RectEffects.X := LCenterX;
    LTarget.Window.RectEffects.Y := LCenterY;
    LTarget.Window.RectClient.X := LX;
    LTarget.Window.RectClient.Y := LY;
    LTarget.UpdatePosition;
  end;
end;

procedure TGuiScriptRunner.SetFocusCommand(const AItem: TGuiItem; const ACursor: TGuiScriptCursor);
var
  LName: AnsiString;
  LFocusItem: TGuiItem;
begin
  LName := '';
  if not ACursor.ParseString(LName) then
    Exit;
  if not Assigned(AItem.Parent) then
    Exit;
  LFocusItem := AItem.Parent.FindItemByName(LName);
  if Assigned(LFocusItem) and ((LFocusItem.Window.Flags and WINDOW_DECORATION) = 0) and
    ((LFocusItem.Window.Flags and WINDOW_HASFOCUS) = 0) then
  begin
    ClearFocus(AItem.Parent);
    LFocusItem.Window.Flags := LFocusItem.Window.Flags or WINDOW_HASFOCUS;
    if LFocusItem.OnFocus <> '' then
      Run(LFocusItem, LFocusItem.OnFocus);
    if (FAssets.ItemFocusSound <> 0) and Assigned(FMedia) then
      FMedia.StartLocalSound(FAssets.ItemFocusSound, GUI_CHAN_LOCAL_SOUND);
  end;
end;

procedure TGuiScriptRunner.ConditionalOpenCommand(const ACursor: TGuiScriptCursor);
var
  LCvar: AnsiString;
  LName1: AnsiString;
  LName2: AnsiString;
begin
  LCvar := '';
  LName1 := '';
  LName2 := '';
  if not (ACursor.ParseString(LCvar) and ACursor.ParseString(LName1) and ACursor.ParseString(LName2)) then
    Exit;
  if not Assigned(FHost) then
    Exit;
  if FHost.GetCvarValue(LCvar) = 0 then
    FHost.OpenMenu(LName2)
  else
    FHost.OpenMenu(LName1);
end;

procedure TGuiScriptRunner.PlayCommand(const ACursor: TGuiScriptCursor; const ALooped: Boolean);
var
  LValue: AnsiString;
begin
  LValue := '';
  if not ACursor.ParseString(LValue) then
    Exit;
  if not Assigned(FMedia) then
    Exit;
  if ALooped then
  begin
    FMedia.StopBackgroundTrack;
    FMedia.StartBackgroundTrack(LValue, LValue);
  end
  else
    FMedia.StartLocalSound(FRegistry.RegisterSound(LValue, False), GUI_CHAN_LOCAL_SOUND);
end;

procedure TGuiScriptRunner.ExecCommand(const ACursor: TGuiScriptCursor);
var
  LValue: AnsiString;
begin
  LValue := '';
  if ACursor.ParseString(LValue) and Assigned(FHost) then
    FHost.ExecuteText(GUI_EXEC_APPEND, LValue + ' ; ');
end;

procedure TGuiScriptRunner.SetCvarCommand(const ACursor: TGuiScriptCursor; const AFixedName: AnsiString);
var
  LName: AnsiString;
  LValue: AnsiString;
begin
  LName := '';
  LValue := '';
  if AFixedName <> '' then
  begin
    // setplayermodel and setplayerhead
    if ACursor.ParseString(LValue) and Assigned(FHost) then
      FHost.SetCvar(AFixedName, LValue);
    Exit;
  end;
  if ACursor.ParseString(LName) and ACursor.ParseString(LValue) and Assigned(FHost) then
    FHost.SetCvar(LName, LValue);
end;

procedure TGuiScriptRunner.RunBuiltin(const AItem: TGuiItem; const ACommand: AnsiString;
  const ACursor: TGuiScriptCursor; var AHandled: Boolean);
var
  LIndex: Integer;
  LName: AnsiString;
  LTeamColor: TGuiColor;
  LBackground: Integer;
begin
  AHandled := True;
  LName := '';
  for LIndex := 0 to High(BUILTIN_COMMANDS) do
    if TIdStrings.Icmp(ACommand, BUILTIN_COMMANDS[LIndex]) = 0 then
      Break;
  case LIndex of
    0, 1, 2, 3:
      if ACursor.ParseString(LName) then
      begin
        if LIndex = 2 then
          ShowItemByName(AItem.Parent, LName, True)
        else if LIndex = 3 then
          ShowItemByName(AItem.Parent, LName, False)
        else
          FadeItemByName(AItem.Parent, LName, LIndex = 1);
      end;
    4:
      SetColorCommand(AItem, ACursor);
    5:
      if ACursor.ParseString(LName) and Assigned(FHost) then
        FHost.OpenMenu(LName);
    6:
      ConditionalOpenCommand(ACursor);
    7:
      if ACursor.ParseString(LName) and Assigned(FHost) then
        FHost.CloseMenu(LName);
    8:
      // setasset reads its argument and does nothing with it
      ACursor.ParseString(LName);
    9:
      if ACursor.ParseString(LName) then
      begin
        LBackground := FRegistry.RegisterShader(LName);
        AItem.Window.Background := LBackground;
      end;
    10:
      SetItemColorCommand(AItem, ACursor);
    11:
      if Assigned(FHost) and FHost.GetTeamColor(LTeamColor) then
        AItem.Window.BackColor := LTeamColor;
    12:
      SetFocusCommand(AItem, ACursor);
    13:
      SetCvarCommand(ACursor, 'team_model');
    14:
      SetCvarCommand(ACursor, 'team_headmodel');
    15:
      TransitionCommand(AItem, ACursor);
    16:
      SetCvarCommand(ACursor, '');
    17:
      ExecCommand(ACursor);
    18:
      PlayCommand(ACursor, False);
    19:
      PlayCommand(ACursor, True);
    20:
      OrbitCommand(AItem, ACursor);
  else
    AHandled := False;
  end;
end;

end.

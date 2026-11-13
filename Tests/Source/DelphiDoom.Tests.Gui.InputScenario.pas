{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the input scenarios                  }
{                                                                              }
{  Runs Tests\Data\Gui\scenarios\input.txt as the input commands of            }
{  Tools\Verifica\125 (uiparse.c) run them on the real ui_shared.c, and        }
{  writes the same lines: the calls the display context received ("host ..."), }
{  the answers ("result ...") and the state of the menus ("istate ...").       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.InputScenario;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf,
  DelphiDoom.Gui.Menu, DelphiDoom.Gui.MenuSet, DelphiDoom.Gui.FontRegistry, DelphiDoom.Gui.MenuFileReader,
  DelphiDoom.Gui.ScriptRunner, DelphiDoom.Gui.Display.Intf, DelphiDoom.Gui.Display;

type
  /// <summary>
  ///   The display context of the C driver: cvars from a table (a name that is not there answers as the older
  ///   scenarios expect: 0 for "zero", 1 for the rest), feeders with a count, an overstrike flag, and a transcript
  ///   line for every call that reaches the host. <c>open</c> and <c>close</c> go to the display, as the real
  ///   Script_Open and Script_Close reach Menus_OpenByName and Menus_CloseByName.
  /// </summary>
  TGuiInputFakeHost = class(TInterfacedObject, IGuiScriptHost, IGuiMediaHost, IGuiInputHost)
  strict private
    FLines: TStrings;
    FDisplay: TGuiDisplay;
    FCvarNames: TList<string>;
    FCvarValues: TList<AnsiString>;
    FFeeders: array[0..7] of Integer;
    FCursorX: Integer;
    FCursorY: Integer;
    FRealTime: Integer;
    FOverstrike: Boolean;
    function FindCvar(const AName: AnsiString): Integer;
  public
    constructor Create(const ALines: TStrings);
    destructor Destroy; override;
    procedure SetCvarEntry(const AName, AValue: AnsiString);
    procedure SetFeeder(const AId, ACount: Integer);
    procedure SetCursor(const AX, AY: Integer);
    procedure SetRealTime(const ATime: Integer);
    property Display: TGuiDisplay read FDisplay write FDisplay;
    property Overstrike: Boolean read FOverstrike;
    // IGuiScriptHost
    procedure RunCommand(const AItem: TObject; const ACommand: AnsiString; const AArguments: TArray<AnsiString>);
    procedure OpenMenu(const AName: AnsiString);
    procedure CloseMenu(const AName: AnsiString);
    function GetCvarValue(const AName: AnsiString): Single;
    procedure SetCvar(const AName, AValue: AnsiString);
    procedure ExecuteText(const AWhen: Integer; const AText: AnsiString);
    function GetTeamColor(out AColor: TGuiColor): Boolean;
    // IGuiMediaHost
    procedure StartLocalSound(const ASound, AChannel: Integer);
    procedure StartBackgroundTrack(const AIntro, ALoop: AnsiString);
    procedure StopBackgroundTrack;
    procedure StopCinematic(const AHandle: Integer);
    // IGuiInputHost
    function CursorX: Integer;
    function CursorY: Integer;
    function RealTime: Integer;
    function FeederCount(const AFeeder: Single): Integer;
    procedure FeederSelection(const AFeeder: Single; const AIndex: Integer);
    function GetCvarString(const AName: AnsiString): AnsiString;
    function GetOverstrikeMode: Boolean;
    procedure SetOverstrikeMode(const AOverstrike: Boolean);
    function OwnerDrawHandleKey(const AOwnerDraw, AFlags: Integer; var ASpecial: Single; const AKey: Integer): Boolean;
    procedure Pause(const APause: Boolean);
    procedure Print(const AMessage: AnsiString);
  end;

  /// <summary>
  ///   The menus of Tests\Data\Gui\files\ui\input.menu on a display, for the tests that call the classes one by
  ///   one: the host (cursor, time, cvars, feeders) and the transcript of what it was asked.
  /// </summary>
  TGuiDisplayRig = class
  strict private
    FTranscript: TStringList;
    FHost: TGuiInputFakeHost;
    FHostIntf: IInterface;
    FFonts: TGuiFontRegistry;
    FMenus: TGuiMenuSet;
    FReader: TGuiMenuFileReader;
    FRunner: TGuiScriptRunner;
    FDisplay: TGuiDisplay;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The menu with that name (nil if there is none)</summary>
    function Menu(const AName: AnsiString): TGuiMenu;
    /// <summary>The item with that name in that menu</summary>
    function Item(const AMenu, AItem: AnsiString): TGuiItem;
    property Menus: TGuiMenuSet read FMenus;
    property Runner: TGuiScriptRunner read FRunner;
    property Host: TGuiInputFakeHost read FHost;
    property Display: TGuiDisplay read FDisplay;
    property Transcript: TStringList read FTranscript;
  end;

  /// <summary>Runs an input scenario file and collects the transcript</summary>
  TGuiInputScenarioRunner = class
  public
    /// <summary>The root folder holds ui/ and fonts/</summary>
    class procedure Run(const ARoot, AScenarioFile: string; const ATranscript: TStrings); static;
  end;

implementation

uses
  System.Math, DelphiDoom.Gui.Factory, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Tests.Gui.Fakes;

{ TGuiInputFakeHost }

constructor TGuiInputFakeHost.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
  FCvarNames := TList<string>.Create;
  FCvarValues := TList<AnsiString>.Create;
end;

destructor TGuiInputFakeHost.Destroy;
begin
  FCvarValues.Free;
  FCvarNames.Free;
  inherited Destroy;
end;

function TGuiInputFakeHost.FindCvar(const AName: AnsiString): Integer;
begin
  Result := FCvarNames.IndexOf(string(AName));
end;

procedure TGuiInputFakeHost.SetCvarEntry(const AName, AValue: AnsiString);
var
  LIndex: Integer;
begin
  LIndex := FindCvar(AName);
  if LIndex < 0 then
  begin
    FCvarNames.Add(string(AName));
    FCvarValues.Add(AValue);
  end
  else
    FCvarValues[LIndex] := AValue;
end;

procedure TGuiInputFakeHost.SetFeeder(const AId, ACount: Integer);
begin
  if (AId >= 0) and (AId <= High(FFeeders)) then
    FFeeders[AId] := ACount;
end;

procedure TGuiInputFakeHost.SetCursor(const AX, AY: Integer);
begin
  FCursorX := AX;
  FCursorY := AY;
end;

procedure TGuiInputFakeHost.SetRealTime(const ATime: Integer);
begin
  FRealTime := ATime;
end;

procedure TGuiInputFakeHost.RunCommand(const AItem: TObject; const ACommand: AnsiString;
  const AArguments: TArray<AnsiString>);
var
  LLine: string;
  LArgument: AnsiString;
begin
  LLine := 'host command';
  for LArgument in AArguments do
    LLine := LLine + ' "' + string(LArgument) + '"';
  FLines.Add(LLine);
end;

procedure TGuiInputFakeHost.OpenMenu(const AName: AnsiString);
begin
  FDisplay.Stack.OpenByName(AName);
end;

procedure TGuiInputFakeHost.CloseMenu(const AName: AnsiString);
begin
  FDisplay.Stack.CloseByName(AName);
end;

function TGuiInputFakeHost.GetCvarValue(const AName: AnsiString): Single;
var
  LIndex: Integer;
  LValue: Double;
begin
  LIndex := FindCvar(AName);
  if LIndex >= 0 then
  begin
    // atof
    if not TryStrToFloat(string(FCvarValues[LIndex]), LValue, TFormatSettings.Invariant) then
      LValue := 0;
    Exit(LValue);
  end;
  if AName = 'zero' then
    Result := 0
  else
    Result := 1;
end;

procedure TGuiInputFakeHost.SetCvar(const AName, AValue: AnsiString);
var
  LIndex: Integer;
begin
  FLines.Add('host setcvar "' + string(AName) + '" "' + string(AValue) + '"');
  LIndex := FindCvar(AName);
  if LIndex >= 0 then
    FCvarValues[LIndex] := AValue;
end;

procedure TGuiInputFakeHost.ExecuteText(const AWhen: Integer; const AText: AnsiString);
var
  LPart: string;
begin
  // the text may hold new lines (the screenshot command): the driver prints them as they are, one line each
  for LPart in ('host exec ' + IntToStr(AWhen) + ' "' + string(AText) + '"').Split([#10]) do
    FLines.Add(LPart);
end;

function TGuiInputFakeHost.GetTeamColor(out AColor: TGuiColor): Boolean;
begin
  AColor[0] := 0.25;
  AColor[1] := 0.5;
  AColor[2] := 0.75;
  AColor[3] := 1.0;
  Result := True;
end;

procedure TGuiInputFakeHost.StartLocalSound(const ASound, AChannel: Integer);
begin
  FLines.Add(Format('host sound %d %d', [ASound, AChannel]));
end;

procedure TGuiInputFakeHost.StartBackgroundTrack(const AIntro, ALoop: AnsiString);
begin
  FLines.Add('host background "' + string(AIntro) + '" "' + string(ALoop) + '"');
end;

procedure TGuiInputFakeHost.StopBackgroundTrack;
begin
  FLines.Add('host stopbackground');
end;

procedure TGuiInputFakeHost.StopCinematic(const AHandle: Integer);
begin
  FLines.Add('host stopcinematic ' + IntToStr(AHandle));
end;

function TGuiInputFakeHost.CursorX: Integer;
begin
  Result := FCursorX;
end;

function TGuiInputFakeHost.CursorY: Integer;
begin
  Result := FCursorY;
end;

function TGuiInputFakeHost.RealTime: Integer;
begin
  Result := FRealTime;
end;

function TGuiInputFakeHost.FeederCount(const AFeeder: Single): Integer;
var
  LId: Integer;
begin
  LId := Trunc(AFeeder);
  if (LId >= 0) and (LId <= High(FFeeders)) then
    Result := FFeeders[LId]
  else
    Result := 0;
end;

procedure TGuiInputFakeHost.FeederSelection(const AFeeder: Single; const AIndex: Integer);
begin
  FLines.Add(Format('host feeder %d %d', [Trunc(AFeeder), AIndex]));
end;

function TGuiInputFakeHost.GetCvarString(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  LIndex := FindCvar(AName);
  if LIndex >= 0 then
    Result := Copy(FCvarValues[LIndex], 1, 1023)
  else
    Result := '';
end;

function TGuiInputFakeHost.GetOverstrikeMode: Boolean;
begin
  Result := FOverstrike;
end;

procedure TGuiInputFakeHost.SetOverstrikeMode(const AOverstrike: Boolean);
begin
  FOverstrike := AOverstrike;
  FLines.Add('host overstrike ' + IntToStr(Ord(AOverstrike)));
end;

function TGuiInputFakeHost.OwnerDrawHandleKey(const AOwnerDraw, AFlags: Integer; var ASpecial: Single;
  const AKey: Integer): Boolean;
begin
  FLines.Add(Format('host ownerdraw %d %d %d', [AOwnerDraw, AFlags, AKey]));
  Result := AKey = 13;
end;

procedure TGuiInputFakeHost.Pause(const APause: Boolean);
begin
  FLines.Add('host pause ' + IntToStr(Ord(APause)));
end;

procedure TGuiInputFakeHost.Print(const AMessage: AnsiString);
begin
  // the C driver writes the message as a log line, without its new lines
  FLines.Add('log dc ' + TrimRight(string(AMessage)));
end;

{ TGuiDisplayRig }

constructor TGuiDisplayRig.Create;
var
  LFileSystem: IIdLibFileSystem;
  LLog: IGuiLog;
  LAssets: IGuiAssetRegistry;
begin
  inherited Create;
  FTranscript := TStringList.Create;
  LFileSystem := TGuiFakeFileSystem.Create(GuiDataFolder + 'files\');
  LLog := TGuiFakeLog.Create(FTranscript);
  LAssets := TGuiFakeAssets.Create(FTranscript);
  FHost := TGuiInputFakeHost.Create(FTranscript);
  FHostIntf := FHost;
  FFonts := TGuiFactory.CreateFontRegistry(LFileSystem, LAssets, LLog);
  FMenus := TGuiFactory.CreateMenuSet(LAssets, FFonts);
  FReader := TGuiFactory.CreateMenuFileReader(TGuiFactory.CreateSourceLoader(LFileSystem, LLog), FMenus, LLog);
  FRunner := TGuiFactory.CreateScriptRunner(FMenus, FHost, FHost);
  FDisplay := TGuiFactory.CreateDisplay(FMenus, FRunner, FHost, FHost, FHost);
  FHost.Display := FDisplay;
  FMenus.Assets.FadeClamp := 1.0;
  FMenus.Assets.FadeCycle := 1;
  FMenus.Assets.FadeAmount := 0.1;
  FReader.ParseMenu('ui/assets.menu');
  FReader.ParseMenu('ui/input.menu');
  FHost.SetFeeder(1, 10);
  FHost.SetFeeder(2, 8);
  FHost.SetFeeder(3, 6);
end;

destructor TGuiDisplayRig.Destroy;
begin
  FHost.Display := nil;
  FDisplay.Free;
  FRunner.Free;
  FReader.Free;
  FMenus.Free;
  FFonts.Free;
  FTranscript.Free;
  inherited Destroy;
end;

function TGuiDisplayRig.Menu(const AName: AnsiString): TGuiMenu;
begin
  Result := FMenus.FindByName(AName);
end;

function TGuiDisplayRig.Item(const AMenu, AItem: AnsiString): TGuiItem;
begin
  Result := Menu(AMenu).FindItemByName(AItem);
end;

{ TGuiInputScenarioRunner }

class procedure TGuiInputScenarioRunner.Run(const ARoot, AScenarioFile: string; const ATranscript: TStrings);
var
  LScenario: TStringList;
  LFileSystem: IIdLibFileSystem;
  LLog: IGuiLog;
  LAssets: IGuiAssetRegistry;
  LHost: TGuiInputFakeHost;
  LHostIntf: IInterface;
  LFonts: TGuiFontRegistry;
  LMenus: TGuiMenuSet;
  LFileReader: TGuiMenuFileReader;
  LRunner: TGuiScriptRunner;
  LDisplay: TGuiDisplay;
  LLine: string;
  LTokens: TArray<string>;

  function Bits(const AValue: Single): string;
  var
    LValue: Single;
  begin
    LValue := AValue;
    Result := LowerCase(IntToHex(PCardinal(@LValue)^, 8));
  end;

  function Number(const AText: string): Single;
  var
    LValue: Double;
  begin
    LValue := StrToFloat(AText, TFormatSettings.Invariant);
    Result := LValue;
  end;

  function MenuName(const AMenu: TGuiMenu): string;
  begin
    if Assigned(AMenu) then
      Result := string(AMenu.Window.Name)
    else
      Result := '-';
  end;

  function ItemName(const AItem: TGuiItem): string;
  begin
    if Assigned(AItem) then
      Result := string(AItem.Window.Name)
    else
      Result := '-';
  end;

  function FindMenu(const AName: string): TGuiMenu;
  begin
    if AName = '-' then
      Result := nil
    else
      Result := LMenus.FindByName(AnsiString(AName));
  end;

  function FindItem(const AMenuName, AItemName: string): TGuiItem;
  var
    LMenu: TGuiMenu;
  begin
    LMenu := LMenus.FindByName(AnsiString(AMenuName));
    if Assigned(LMenu) then
      Result := LMenu.FindItemByName(AnsiString(AItemName))
    else
      Result := nil;
  end;

  procedure DumpInput;
  var
    LIndex, LItemIndex, LStart, LCursor, LPaint: Integer;
    LMenu: TGuiMenu;
    LItem: TGuiItem;
    LText: string;
  begin
    LText := 'istate stack ' + IntToStr(LDisplay.State.OpenMenuCount);
    for LIndex := 0 to LDisplay.State.OpenMenuCount - 1 do
      LText := LText + ' ' + MenuName(LDisplay.State.MenuStack[LIndex]);
    ATranscript.Add(LText + ' capture ' + ItemName(LDisplay.State.ItemCapture) + ' editing ' +
      IntToStr(Ord(LDisplay.State.EditingField)) + ' edit ' + ItemName(LDisplay.State.EditItem) + ' overstrike ' +
      IntToStr(Ord(LHost.Overstrike)) + ' debug ' + IntToStr(Ord(LDisplay.State.DebugMode)));
    for LIndex := 0 to LMenus.Count - 1 do
    begin
      LMenu := LMenus[LIndex];
      ATranscript.Add(Format(' menu %s flags=%d cursorItem=%d rect=%s,%s', [MenuName(LMenu), LMenu.Window.Flags,
        LMenu.CursorItem, Bits(LMenu.Window.Rect.X), Bits(LMenu.Window.Rect.Y)]));
      for LItemIndex := 0 to LMenu.Items.Count - 1 do
      begin
        LItem := LMenu.Items[LItemIndex];
        LStart := 0;
        LCursor := 0;
        LPaint := 0;
        if LItem.ItemType = ITEM_TYPE_LISTBOX then
        begin
          LStart := LItem.ListBox.StartPos;
          LCursor := LItem.ListBox.CursorPos;
        end
        else if (LItem.DataKind = gdkEditField) and ((LItem.ItemType = ITEM_TYPE_EDITFIELD) or
          (LItem.ItemType = ITEM_TYPE_NUMERICFIELD)) then
          LPaint := LItem.EditField.PaintOffset;
        // an item that is as the menu file left it (only visible) is not listed
        if (LItem.Window.Flags = WINDOW_VISIBLE) and (LItem.CursorPos = 0) and (LStart = 0) and (LCursor = 0) and
          (LPaint = 0) then
          Continue;
        LText := Format('  item %s flags=%d cursorPos=%d special=%s', [ItemName(LItem), LItem.Window.Flags,
          LItem.CursorPos, Bits(LItem.Special)]);
        if LItem.ItemType = ITEM_TYPE_LISTBOX then
          LText := LText + Format(' start=%d cursor=%d', [LStart, LCursor])
        else if (LItem.ItemType = ITEM_TYPE_EDITFIELD) or (LItem.ItemType = ITEM_TYPE_NUMERICFIELD) then
          LText := LText + Format(' paintOffset=%d', [LPaint]);
        ATranscript.Add(LText);
      end;
    end;
  end;

  procedure Answer(const AText: string);
  begin
    ATranscript.Add('result ' + AText);
  end;

  procedure Command;
  var
    LName: string;
    LMenu: TGuiMenu;
    LItem: TGuiItem;
    LFocus: Integer;
    LHasName: Boolean;
    LNamed: string;
  begin
    LName := LTokens[0];
    if LName = 'istate' then
      DumpInput
    else if LName = 'cursor' then
      LHost.SetCursor(StrToInt(LTokens[1]), StrToInt(LTokens[2]))
    else if LName = 'time' then
      LHost.SetRealTime(StrToInt(LTokens[1]))
    else if LName = 'feeder' then
      LHost.SetFeeder(StrToInt(LTokens[1]), StrToInt(LTokens[2]))
    else if LName = 'cvar' then
    begin
      // "cvar name value": the value is the rest of the line
      LNamed := Copy(LLine, 6 + Length(LTokens[1]) + 1, MaxInt);
      LHost.SetCvarEntry(AnsiString(LTokens[1]), AnsiString(LNamed));
    end
    else if LName = 'textrect' then
    begin
      LItem := FindItem(LTokens[1], LTokens[2]);
      if Assigned(LItem) then
      begin
        LItem.TextRect.X := Number(LTokens[3]);
        LItem.TextRect.Y := Number(LTokens[4]);
        LItem.TextRect.W := Number(LTokens[5]);
        LItem.TextRect.H := Number(LTokens[6]);
      end;
    end
    else if LName = 'cinematic' then
    begin
      LItem := FindItem(LTokens[1], LTokens[2]);
      if Assigned(LItem) then
        LItem.Window.Cinematic := StrToInt(LTokens[3]);
    end
    else if LName = 'activate' then
    begin
      LMenu := LMenus.FindByName(AnsiString(LTokens[1]));
      if Assigned(LMenu) then
        LDisplay.Stack.Activate(LMenu);
      DumpInput;
    end
    else if LName = 'open' then
    begin
      LDisplay.Stack.OpenByName(AnsiString(LTokens[1]));
      DumpInput;
    end
    else if LName = 'show' then
    begin
      LDisplay.Stack.ShowByName(AnsiString(LTokens[1]));
      DumpInput;
    end
    else if LName = 'closemenu' then
    begin
      LDisplay.Stack.CloseByName(AnsiString(LTokens[1]));
      DumpInput;
    end
    else if LName = 'closeall' then
    begin
      LDisplay.Stack.CloseAll;
      DumpInput;
    end
    else if LName = 'key' then
    begin
      LDisplay.MenuKeys.DisplayHandleKey(StrToInt(LTokens[1]), StrToInt(LTokens[2]) <> 0, LHost.CursorX, LHost.CursorY);
      DumpInput;
    end
    else if LName = 'menukey' then
    begin
      LDisplay.MenuKeys.HandleKey(FindMenu(LTokens[1]), StrToInt(LTokens[2]), StrToInt(LTokens[3]) <> 0);
      DumpInput;
    end
    else if LName = 'move' then
    begin
      LDisplay.Pointer.MouseMove(nil, StrToInt(LTokens[1]), StrToInt(LTokens[2]));
      DumpInput;
    end
    else if LName = 'drag' then
    begin
      LDisplay.Pointer.MouseMove(FindMenu(LTokens[1]), StrToInt(LTokens[2]), StrToInt(LTokens[3]));
      DumpInput;
    end
    else if LName = 'capture' then
    begin
      LDisplay.ItemKeys.RunCapture;
      DumpInput;
    end
    else if LName = 'focus' then
    begin
      LItem := FindItem(LTokens[1], LTokens[2]);
      if Assigned(LItem) then
        LFocus := Ord(LDisplay.Pointer.SetFocus(LItem, LHost.CursorX, LHost.CursorY))
      else
        LFocus := -1;
      Answer(IntToStr(LFocus));
      DumpInput;
    end
    else if (LName = 'next') or (LName = 'prev') then
    begin
      LMenu := LMenus.FindByName(AnsiString(LTokens[1]));
      LItem := nil;
      if Assigned(LMenu) then
        if LName = 'next' then
          LItem := LDisplay.Pointer.SetNextCursorItem(LMenu)
        else
          LItem := LDisplay.Pointer.SetPrevCursorItem(LMenu);
      Answer(ItemName(LItem));
      DumpInput;
    end
    else if LName = 'visible' then
      Answer(IntToStr(LDisplay.Stack.VisibleMenuCount))
    else if LName = 'fullscreen' then
      Answer(IntToStr(Ord(LDisplay.Stack.AnyFullScreenVisible)))
    else if LName = 'focused' then
      Answer(MenuName(LDisplay.Stack.GetFocused))
    else if LName = 'cursortype' then
      Answer(IntToStr(LDisplay.Pointer.CursorType(StrToInt(LTokens[1]), StrToInt(LTokens[2]))))
    else if LName = 'captureitem' then
      Answer(MenuName(LDisplay.Pointer.CaptureItem(StrToInt(LTokens[1]), StrToInt(LTokens[2]))))
    else if LName = 'hit' then
    begin
      LMenu := LMenus.FindByName(AnsiString(LTokens[1]));
      LItem := nil;
      if Assigned(LMenu) then
        LItem := LDisplay.Pointer.HitTest(LMenu, Number(LTokens[2]), Number(LTokens[3]));
      Answer(ItemName(LItem));
    end
    else if LName = 'scrollfeeder' then
    begin
      LDisplay.ItemKeys.ScrollFeeder(LMenus.FindByName(AnsiString(LTokens[1])), StrToInt(LTokens[2]),
        StrToInt(LTokens[3]) <> 0);
      DumpInput;
    end
    else if LName = 'feedersel' then
    begin
      LHasName := StrToInt(LTokens[4]) <> 0;
      if LHasName then
        LNamed := LTokens[5]
      else
        LNamed := '';
      LDisplay.Stack.SetFeederSelection(FindMenu(LTokens[1]), StrToInt(LTokens[2]), StrToInt(LTokens[3]),
        AnsiString(LNamed), LHasName);
      DumpInput;
    end
    else if LName = 'mouseenter' then
    begin
      LDisplay.Pointer.MouseEnter(FindItem(LTokens[1], LTokens[2]), Number(LTokens[3]), Number(LTokens[4]));
      DumpInput;
    end
    else if LName = 'mouseleave' then
    begin
      LDisplay.Pointer.MouseLeave(FindItem(LTokens[1], LTokens[2]));
      DumpInput;
    end
    else
      ATranscript.Add('unknown scenario line');
  end;

begin
  LScenario := TStringList.Create;
  try
    LScenario.LoadFromFile(AScenarioFile);
    LFileSystem := TGuiFakeFileSystem.Create(ARoot);
    LLog := TGuiFakeLog.Create(ATranscript);
    LAssets := TGuiFakeAssets.Create(ATranscript);
    LHost := TGuiInputFakeHost.Create(ATranscript);
    LHostIntf := LHost;
    LFonts := TGuiFactory.CreateFontRegistry(LFileSystem, LAssets, LLog);
    LMenus := TGuiFactory.CreateMenuSet(LAssets, LFonts);
    LFileReader := TGuiFactory.CreateMenuFileReader(TGuiFactory.CreateSourceLoader(LFileSystem, LLog), LMenus, LLog);
    LRunner := TGuiFactory.CreateScriptRunner(LMenus, LHost, LHost);
    LDisplay := TGuiFactory.CreateDisplay(LMenus, LRunner, LHost, LHost, LHost);
    LHost.Display := LDisplay;
    try
      LMenus.Assets.FadeClamp := 1.0;
      LMenus.Assets.FadeCycle := 1;
      LMenus.Assets.FadeAmount := 0.1;
      for LLine in LScenario do
      begin
        if (LLine = '') or (LLine[1] = '#') then
          Continue;
        ATranscript.Add('> ' + LLine);
        if Copy(LLine, 1, 5) = 'menu ' then
          LFileReader.ParseMenu(AnsiString(Copy(LLine, 6, MaxInt)))
        else
        begin
          LTokens := LLine.Split([' ']);
          Command;
        end;
      end;
    finally
      LHost.Display := nil;
      LDisplay.Free;
      LRunner.Free;
      LFileReader.Free;
      LMenus.Free;
      LFonts.Free;
    end;
  finally
    LScenario.Free;
  end;
end;

end.

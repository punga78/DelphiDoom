{******************************************************************************}
{                                                                              }
{  DelphiDoom: the whole game of OpenXcom for the tests of the strategic       }
{  screens (the composition of the program, a memory display, a manual clock)  }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.World;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Game, DelphiDoom.XcomEngine.ManualClock,
  DelphiDoom.XcomEngine.QueueEventSource, DelphiDoom.XcomEngine.MemoryVideoDevice, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomGeoscape.Globe;

type
  /// <summary>
  ///   The game as the program composes it (TXcomGameComposition, with the navigator and the simulation of the
  ///   program) on the data of X-COM: Terror from the Deep that the repository does not have
  ///   (Reference\_dati\xcom_tftd, found by climbing from the executable). The display is in memory, the clock is
  ///   manual and the events are the ones the test gives, in the pixels of the 640 x 400 window. The folder of the
  ///   player is a new temporary one, deleted with the world
  /// </summary>
  TXcomTourWorld = class
  strict private
    FRoot: string;
    FUserFolder: string;
    FClock: TXcomManualClock;
    FClockRef: IXcomClock;
    FEvents: TXcomQueueEventSource;
    FEventsRef: IXcomEventSource;
    FDevice: TXcomMemoryVideoDevice;
    FDeviceRef: IXcomVideoDevice;
    FGame: TXcomGame;
    class function FindUp(const ARelative: string): string; static;
    function LoadSave(const AFolder, AName: string): Boolean;
    function TopWidgets: TArray<TXcomWidget>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The data is there: without it the game is nil and a test has nothing to check</summary>
    function HasData: Boolean;
    /// <summary>Lets the time pass one millisecond at a time, with a turn of the game for each</summary>
    procedure Wait(AMilliseconds: Integer);
    /// <summary>A left click, then the time for the screen that opens to show its surfaces</summary>
    procedure Click(AX, AY: Integer);
    /// <summary>A key (a printable one also types its character), then the time for the screen to change</summary>
    procedure Key(AKey: Integer);
    /// <summary>Types the lower case letters and digits of the text</summary>
    procedure TypeText(const AText: string);
    /// <summary>From the start of the program to the geoscape of a new game with its first base, named "ab"</summary>
    procedure StartNewGame;
    /// <summary>
    ///   From the start of the program to the geoscape of a saved game of Tests\Data\XcomSave\variants (its header
    ///   is adapted to the catalog of the saved games, as the scripts of Tools\Verifica\176 do). False: no file
    /// </summary>
    function LoadVariant(const AName: string): Boolean;
    /// <summary>
    ///   The same for a saved game of Tests\Data\XcomSave\missions (Tools\Verifica\176\Make-XcomMissionSave.ps1: a
    ///   craft with soldiers over its target, a UFO over the base). False: no file
    /// </summary>
    function LoadMission(const AName: string): Boolean;
    /// <summary>The class of the state on top ('' when there is none)</summary>
    function Top: string;
    function Save: TXcomSavedGame;
    function FirstBase: TXcomBase;
    /// <summary>The zoom of the globe of the geoscape, which must be the state on top</summary>
    function GlobeZoom: Integer;
    /// <summary>The globe of the geoscape, which must be the state on top</summary>
    function Globe: TXcomGlobe;
    /// <summary>The point of the window where the globe of the geoscape draws the target</summary>
    procedure TargetPoint(ATarget: TXcomTarget; out AX, AY: Integer);
    /// <summary>A copy of the picture on the display (640 x 400 palette indexes)</summary>
    function Picture: TBytes;
    /// <summary>A button of the mouse goes down on a point and stays there (a held arrow repeats with the time)</summary>
    procedure Press(AX, AY: Integer; AButton: Integer = 1);
    /// <summary>The button comes up, then the time for the screen to change</summary>
    procedure Release(AX, AY: Integer; AButton: Integer = 1);
    /// <summary>A click of the right button</summary>
    procedure RightClick(AX, AY: Integer);
    /// <summary>
    ///   What the screen on top shows, for the message of a failed test: class, place in the window and text of each
    ///   visible button and text, and the rows of each list
    /// </summary>
    function Describe: string;
    /// <summary>True: the screen on top has a visible button with this text</summary>
    function HasButton(const AText: string): Boolean;
    /// <summary>Clicks the middle of the visible button of the screen on top with this text; fails without it</summary>
    procedure ClickButton(const AText: string);
    /// <summary>
    ///   True: a visible text, button or text field of the screen on top contains this text (the characters that change the
    ///   color of a text do not count)
    /// </summary>
    function Shows(const AText: string): Boolean;
    /// <summary>
    ///   The row of a list of the screen on top whose first cell is this text (-1: none); the list is scrolled to
    ///   show it and AY is the middle of the row in the window
    /// </summary>
    function FindRow(const AText: string; out AY: Integer): Integer;
    /// <summary>Clicks the row whose first cell is this text, at this column of the window; fails without it</summary>
    procedure ClickRow(const AText: string; AX: Integer; AButton: Integer = 1);
    /// <summary>
    ///   The middle of an arrow of the rows of the first list with arrows of the screen on top, in the window
    ///   (ARight: the second arrow)
    /// </summary>
    function RowArrowX(ARight: Boolean): Integer;
    /// <summary>
    ///   Opens the combo box of the screen on top and clicks the option with this text (its list is scrolled to
    ///   show it); fails without it
    /// </summary>
    procedure ChooseCombo(const AOption: string);
    /// <summary>The options of the combo box of the screen on top</summary>
    function ComboOptions: TArray<string>;
    /// <summary>
    ///   The cell of the row whose first cell is this text, without the characters that change its color; fails
    ///   without it
    /// </summary>
    function RowCell(const AText: string; AColumn: Integer): string;
    property Game: TXcomGame read FGame;
    property UserFolder: string read FUserFolder;
  end;

const
  /// <summary>The column of the buttons of the basescape and their rows, in the pixels of the window</summary>
  TOUR_BASE_BUTTON_X = 510;
  TOUR_NEW_BASE_Y = 128;
  TOUR_BASE_INFO_Y = 154;
  TOUR_SOLDIERS_Y = 180;
  TOUR_CRAFTS_Y = 206;
  TOUR_FACILITIES_Y = 232;
  TOUR_RESEARCH_Y = 258;
  TOUR_MANUFACTURE_Y = 284;
  TOUR_TRANSFER_Y = 310;
  TOUR_PURCHASE_Y = 336;
  TOUR_SELL_Y = 362;
  /// <summary>The column of the buttons of the geoscape and their rows</summary>
  TOUR_GEO_BUTTON_X = 575;
  TOUR_INTERCEPT_Y = 10;
  TOUR_BASES_Y = 34;
  TOUR_GRAPHS_Y = 58;
  TOUR_OPTIONS_Y = 106;
  TOUR_FUNDING_Y = 130;

implementation

uses
  System.IOUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomUi.TextEdit,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.GeoscapeState,
  DelphiDoom.Xcom.GameComposition;

class function TXcomTourWorld.FindUp(const ARelative: string): string;
var
  LFolder: string;
  LParent: string;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  while LFolder <> '' do
  begin
    if TDirectory.Exists(TPath.Combine(LFolder, ARelative)) then
      Exit(TPath.Combine(LFolder, ARelative));
    LParent := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
    if LParent = LFolder then
      Break;
    LFolder := LParent;
  end;
  Result := '';
end;

constructor TXcomTourWorld.Create;
var
  LSettings: TXcomGameSettings;
begin
  inherited Create;
  FRoot := FindUp('Reference\_dati\xcom_tftd');
  if (FRoot = '') or not TDirectory.Exists(TPath.Combine(FRoot, 'openxcom\standard\xcom2')) or
    not TDirectory.Exists(TPath.Combine(FRoot, 'TFTD\GEODATA')) then
  begin
    FRoot := '';
    Exit;
  end;
  FUserFolder := TPath.Combine(TPath.GetTempPath, 'DelphiDoomXcomTour_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FUserFolder);
  FClock := TXcomManualClock.Create;
  FClockRef := FClock;
  FEvents := TXcomQueueEventSource.Create;
  FEventsRef := FEvents;
  FDevice := TXcomMemoryVideoDevice.Create;
  FDeviceRef := FDevice;
  LSettings := Default(TXcomGameSettings);
  LSettings.DataFolder := TPath.Combine(FRoot, 'openxcom');
  LSettings.GameFolder := TPath.Combine(FRoot, 'TFTD');
  LSettings.UserFolder := FUserFolder;
  LSettings.ModId := 'xcom2';
  LSettings.VersionText := 'test';
  LSettings.LoadMode := lmImmediate;
  // the same game at every run: funds, soldiers and alien missions
  LSettings.Seed := 176;
  FGame := TXcomGameComposition.CreateGame(LSettings, FDeviceRef, FClockRef, FEvents);
  // the tour starts from the main menu: no introduction (playIntro is on by default)
  FGame.Options.PlayIntro := False;
end;

destructor TXcomTourWorld.Destroy;
begin
  FGame.Free;
  if (FUserFolder <> '') and TDirectory.Exists(FUserFolder) then
    TDirectory.Delete(FUserFolder, True);
  inherited Destroy;
end;

function TXcomTourWorld.HasData: Boolean;
begin
  Result := Assigned(FGame);
end;

procedure TXcomTourWorld.Wait(AMilliseconds: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to AMilliseconds do
  begin
    FClock.Advance(1);
    FGame.RunFrame;
  end;
end;

procedure TXcomTourWorld.Click(AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := AX;
  LEvent.Y := AY;
  FEvents.Enqueue(LEvent);
  Wait(20);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := XCOM_BUTTON_LEFT;
  FEvents.Enqueue(LEvent);
  Wait(40);
  LEvent.Kind := ekMouseUp;
  FEvents.Enqueue(LEvent);
  // the window of a screen shows its surfaces when it has opened
  Wait(500);
end;

procedure TXcomTourWorld.Key(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  if (AKey >= 32) and (AKey <= 126) then
    LEvent.Character := Cardinal(AKey);
  FEvents.Enqueue(LEvent);
  Wait(20);
  LEvent.Kind := ekKeyUp;
  FEvents.Enqueue(LEvent);
  Wait(480);
end;

procedure TXcomTourWorld.TypeText(const AText: string);
var
  LChar: Char;
begin
  for LChar in AText do
    Key(Ord(LChar));
end;

procedure TXcomTourWorld.StartNewGame;
begin
  // the start screen, then the main menu
  Wait(5000);
  // New Game, OK of the difficulty, the site of the base on the globe, its name
  Click(220, 200);
  Click(238, 344);
  Wait(1000);
  Click(250, 200);
  TypeText('ab');
  Key(XCOM_KEY_RETURN);
  Wait(500);
end;

function TXcomTourWorld.LoadVariant(const AName: string): Boolean;
begin
  Result := LoadSave('Tests\Data\XcomSave\variants', AName);
end;

function TXcomTourWorld.LoadMission(const AName: string): Boolean;
begin
  Result := LoadSave('Tests\Data\XcomSave\missions', AName);
end;

function TXcomTourWorld.LoadSave(const AFolder, AName: string): Boolean;
var
  LFolder: string;
  LText: string;
begin
  LFolder := FindUp(AFolder);
  Result := (LFolder <> '') and TFile.Exists(TPath.Combine(LFolder, AName + '.sav'));
  if not Result then
    Exit;
  LText := TFile.ReadAllText(TPath.Combine(LFolder, AName + '.sav'), TEncoding.UTF8);
  LText := LText.Replace('name: ""', 'name: "Variant"').Replace('  - "xcom2 ver: 1.0"', '  - xcom2').Replace(#13#10, #10);
  TDirectory.CreateDirectory(TPath.Combine(FUserFolder, 'xcom2'));
  // no byte order mark: the catalog reads the header as YAML
  TFile.WriteAllBytes(TPath.Combine(FUserFolder, 'xcom2\' + AName + '.sav'), TEncoding.UTF8.GetBytes(LText));
  // the start screen, the main menu, Load Game, the only saved game of the list
  Wait(5000);
  Click(220, 256);
  Click(60, 93);
  Wait(2500);
end;

function TXcomTourWorld.Top: string;
begin
  if FGame.TopState = nil then
    Result := ''
  else
    Result := FGame.TopState.ClassName;
end;

function TXcomTourWorld.Save: TXcomSavedGame;
begin
  Result := TXcomStrategy.SavedGame(FGame);
end;

function TXcomTourWorld.GlobeZoom: Integer;
begin
  Result := Globe.Zoom;
end;

function TXcomTourWorld.Globe: TXcomGlobe;
begin
  Result := (FGame.TopState as TXcomGeoscapeState).Globe;
end;

procedure TXcomTourWorld.TargetPoint(ATarget: TXcomTarget; out AX, AY: Integer);
var
  LX, LY: SmallInt;
begin
  Globe.PolarToCart(ATarget.Longitude, ATarget.Latitude, LX, LY);
  AX := 2 * LX;
  AY := 2 * LY;
end;

function TXcomTourWorld.Picture: TBytes;
begin
  Result := Copy(FDevice.Pixels);
end;

procedure TXcomTourWorld.Press(AX, AY, AButton: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := AX;
  LEvent.Y := AY;
  FEvents.Enqueue(LEvent);
  Wait(20);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := AButton;
  FEvents.Enqueue(LEvent);
  Wait(40);
end;

procedure TXcomTourWorld.Release(AX, AY, AButton: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseUp);
  LEvent.X := AX;
  LEvent.Y := AY;
  LEvent.Button := AButton;
  FEvents.Enqueue(LEvent);
  Wait(500);
end;

procedure TXcomTourWorld.RightClick(AX, AY: Integer);
begin
  Press(AX, AY, XCOM_BUTTON_RIGHT);
  Release(AX, AY, XCOM_BUTTON_RIGHT);
end;

// The list does not say how many cells a row has: a column past the last one is an empty text
function CellText(AList: TXcomTextList; ARow, AColumn: Integer): string;
begin
  try
    Result := AList.GetCellText(ARow, AColumn);
  except
    on EArgumentOutOfRangeException do
      Result := '';
  end;
end;

// A text without the characters that change its color or its font
function Plain(const AText: string): string;
var
  LChar: Char;
begin
  Result := '';
  for LChar in AText do
    if LChar >= ' ' then
      Result := Result + LChar;
end;

function TXcomTourWorld.TopWidgets: TArray<TXcomWidget>;
var
  LWidgets: TArray<TXcomWidget>;
begin
  LWidgets := nil;
  if FGame.TopState <> nil then
    FGame.TopState.VisitSurfaces(
      procedure(AWidget: TXcomWidget)
      begin
        LWidgets := LWidgets + [AWidget];
      end);
  Result := LWidgets;
end;

function TXcomTourWorld.Describe: string;
var
  LBuilder: TStringBuilder;
  LWidget: TXcomWidget;
  LList: TXcomTextList;
  LRow, LColumn: Integer;
begin
  if FGame.TopState = nil then
    Exit('(nessuno stato)');
  LBuilder := TStringBuilder.Create;
  try
    LBuilder.AppendLine(FGame.TopState.ClassName);
    for LWidget in TopWidgets do
    begin
      if not LWidget.Visible then
        Continue;
      if LWidget is TXcomTextButton then
        LBuilder.AppendFormat('  button (%d,%d) "%s"', [2 * LWidget.X + LWidget.Width, 2 * LWidget.Y + LWidget.Height,
          TXcomTextButton(LWidget).GetText]).AppendLine
      else if LWidget is TXcomText then
        LBuilder.AppendFormat('  text (%d,%d) "%s"', [2 * LWidget.X, 2 * LWidget.Y, TXcomText(LWidget).GetText]).AppendLine
      else if LWidget is TXcomTextList then
      begin
        LList := TXcomTextList(LWidget);
        LBuilder.AppendFormat('  list (%d,%d) %d x %d, arrows %d..%d, scroll %d', [2 * LList.X, 2 * LList.Y,
          2 * LList.Width, 2 * LList.Height, 2 * LList.GetArrowsLeftEdge, 2 * LList.GetArrowsRightEdge,
          LList.GetScroll]).AppendLine;
        for LRow := 0 to LList.GetTexts - 1 do
        begin
          LBuilder.AppendFormat('    %d y=%d:', [LRow, 2 * LList.GetRowY(LRow)]);
          for LColumn := 0 to 5 do
            if CellText(LList, LRow, LColumn) <> '' then
              LBuilder.Append(' [' + CellText(LList, LRow, LColumn) + ']');
          LBuilder.AppendLine;
        end;
      end
      else if LWidget is TXcomComboBox then
      begin
        LBuilder.AppendFormat('  combo (%d,%d):', [2 * LWidget.X, 2 * LWidget.Y]);
        for LRow := 0 to TXcomComboBox(LWidget).List.GetTexts - 1 do
          LBuilder.Append(' [' + TXcomComboBox(LWidget).List.GetCellText(LRow, 0) + ']');
        LBuilder.AppendLine;
      end
      else
        LBuilder.AppendFormat('  %s (%d,%d) %d x %d', [LWidget.ClassName, 2 * LWidget.X, 2 * LWidget.Y, 2 * LWidget.Width,
          2 * LWidget.Height]).AppendLine;
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TXcomTourWorld.HasButton(const AText: string): Boolean;
var
  LWidget: TXcomWidget;
begin
  Result := False;
  if FGame.TopState = nil then
    Exit;
  for LWidget in TopWidgets do
    if LWidget.Visible and (LWidget is TXcomTextButton) and SameText(TXcomTextButton(LWidget).GetText, AText) then
      Exit(True);
end;

procedure TXcomTourWorld.ClickButton(const AText: string);
var
  LWidget: TXcomWidget;
begin
  if FGame.TopState <> nil then
    for LWidget in TopWidgets do
      if LWidget.Visible and (LWidget is TXcomTextButton) and SameText(TXcomTextButton(LWidget).GetText, AText) then
      begin
        Click(2 * LWidget.X + LWidget.Width, 2 * LWidget.Y + LWidget.Height);
        Exit;
      end;
  Assert.Fail(Format('il pulsante "%s" non c''e'': %s', [AText, Describe]));
end;

function TXcomTourWorld.Shows(const AText: string): Boolean;
var
  LWidget: TXcomWidget;
begin
  Result := False;
  if FGame.TopState = nil then
    Exit;
  for LWidget in TopWidgets do
  begin
    if not LWidget.Visible then
      Continue;
    if (LWidget is TXcomTextButton) and Plain(TXcomTextButton(LWidget).GetText).Contains(AText) then
      Exit(True);
    if (LWidget is TXcomText) and Plain(TXcomText(LWidget).GetText).Contains(AText) then
      Exit(True);
    if (LWidget is TXcomTextEdit) and TXcomTextEdit(LWidget).GetText.Contains(AText) then
      Exit(True);
  end;
end;

function TXcomTourWorld.FindRow(const AText: string; out AY: Integer): Integer;
var
  LWidget: TXcomWidget;
  LList: TXcomTextList;
  LRow: Integer;
begin
  AY := 0;
  Result := -1;
  if FGame.TopState = nil then
    Exit;
  for LWidget in TopWidgets do
  begin
    if not (LWidget.Visible and (LWidget is TXcomTextList)) then
      Continue;
    LList := TXcomTextList(LWidget);
    for LRow := 0 to LList.GetTexts - 1 do
      if SameText(Plain(LList.GetCellText(LRow, 0)), AText) then
      begin
        if (LRow < LList.GetScroll) or (LRow >= LList.GetScroll + LList.GetVisibleRows) then
        begin
          LList.ScrollTo(LRow);
          Wait(40);
        end;
        // the list gives the place of a row as if it were not scrolled
        AY := 2 * (LList.GetRowY(LRow) - LList.GetRowY(LList.GetScroll) + LList.GetRowY(0)) + LList.GetTextHeight(LRow);
        Exit(LRow);
      end;
  end;
end;

procedure TXcomTourWorld.ClickRow(const AText: string; AX, AButton: Integer);
var
  LY: Integer;
begin
  if FindRow(AText, LY) < 0 then
    Assert.Fail(Format('la riga "%s" non c''e'': %s', [AText, Describe]));
  if AButton = XCOM_BUTTON_LEFT then
    Click(AX, LY)
  else
  begin
    Press(AX, LY, AButton);
    Release(AX, LY, AButton);
  end;
end;

function TXcomTourWorld.RowArrowX(ARight: Boolean): Integer;
var
  LWidget: TXcomWidget;
begin
  for LWidget in TopWidgets do
    if LWidget.Visible and (LWidget is TXcomTextList) and (TXcomTextList(LWidget).GetArrowsRightEdge > 0) then
    begin
      // two arrows of 11 pixels, the second 12 pixels after the first
      Result := 2 * TXcomTextList(LWidget).GetArrowsLeftEdge + 10;
      if ARight then
        Inc(Result, 24);
      Exit;
    end;
  Assert.Fail('nessuna lista con le frecce: ' + Describe);
  Result := 0;
end;

procedure TXcomTourWorld.ChooseCombo(const AOption: string);
var
  LWidget: TXcomWidget;
  LList: TXcomTextList;
  LRow: Integer;
begin
  for LWidget in TopWidgets do
    if LWidget.Visible and (LWidget is TXcomComboBox) then
    begin
      Click(2 * LWidget.X + LWidget.Width, 2 * LWidget.Y + LWidget.Height);
      LList := TXcomComboBox(LWidget).List;
      for LRow := 0 to LList.GetTexts - 1 do
        if SameText(LList.GetCellText(LRow, 0), AOption) then
        begin
          if (LRow < LList.GetScroll) or (LRow >= LList.GetScroll + LList.GetVisibleRows) then
          begin
            LList.ScrollTo(LRow);
            Wait(40);
          end;
          Click(2 * LList.X + 20, 2 * (LList.GetRowY(LRow) - LList.GetRowY(LList.GetScroll) + LList.GetRowY(0)) +
            LList.GetTextHeight(LRow));
          Exit;
        end;
    end;
  Assert.Fail(Format('l''opzione "%s" non c''e'': %s', [AOption, Describe]));
end;

function TXcomTourWorld.ComboOptions: TArray<string>;
var
  LWidget: TXcomWidget;
  LRow: Integer;
begin
  Result := nil;
  for LWidget in TopWidgets do
    if LWidget.Visible and (LWidget is TXcomComboBox) then
      for LRow := 0 to TXcomComboBox(LWidget).List.GetTexts - 1 do
        Result := Result + [TXcomComboBox(LWidget).List.GetCellText(LRow, 0)];
end;

function TXcomTourWorld.RowCell(const AText: string; AColumn: Integer): string;
var
  LWidget: TXcomWidget;
  LList: TXcomTextList;
  LRow: Integer;
begin
  if FGame.TopState <> nil then
    for LWidget in TopWidgets do
      if LWidget.Visible and (LWidget is TXcomTextList) then
      begin
        LList := TXcomTextList(LWidget);
        for LRow := 0 to LList.GetTexts - 1 do
          if SameText(Plain(LList.GetCellText(LRow, 0)), AText) then
            Exit(Plain(CellText(LList, LRow, AColumn)));
      end;
  Assert.Fail(Format('la riga "%s" non c''e'': %s', [AText, Describe]));
  Result := '';
end;

function TXcomTourWorld.FirstBase: TXcomBase;
begin
  Result := Save.Bases.First;
end;

end.

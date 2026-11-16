{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom editor - the presenter of the main window                 }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EndoomEditor.Presenter;

interface

uses
  System.SysUtils, System.Types,
  DelphiDoom.Endoom.Types,
  DelphiDoom.Endoom.Intf,
  DelphiDoom.Endoom.TextArt.Types,
  DelphiDoom.Endoom.TextArt.Intf,
  DelphiDoom.Tools.Intf,
  DelphiDoom.EndoomEditor.Types,
  DelphiDoom.EndoomEditor.Intf;

type
  /// <summary>
  ///   What the main window of ENDEDIT (main.pas, 157 handlers) decided, without the window: the tool and the
  ///   colors in use, what the mouse does with them, the cursor and the keys of the text tool, the zoom, the undo,
  ///   the files (open, save, recent files, backup, the question on closing), the clipboard (a picture becomes
  ///   text art, a text is pasted) and the export. The window tells it what happens and draws what it says
  ///   (IEndoomEditorView). Mouse positions are pixels of the stretched picture (640+80*zoom wide, 400+50*zoom tall)
  /// </summary>
  TEndoomEditorPresenter = class
  strict private
    FView: IEndoomEditorView;
    FDialogs: IEndoomEditorDialogs;
    FClipboard: IEndoomEditorClipboard;
    FExporter: IEndoomEditorImageExporter;
    FFileSystem: IToolFileSystem;
    FBackup: IToolFileBackup;
    FSettings: ISettingsStore;
    FRecentFiles: IRecentFiles;
    FUndo: IToolUndoHistory;
    FScreen: IEndoomScreen;
    FImage: IEndoomScreenImage;
    FFont: TBytes;
    FTextArt: IEndoomTextArtConverter;
    FMethods: TEndoomTextArtMethodProvider;
    FPixels: TArray<Cardinal>;
    FFileName: string;
    FChanged: Boolean;
    FZoom: Integer;
    FShowGrid: Boolean;
    FMethod: TEndoomTextArtKind;
    FTool: TEndoomEditorTool;
    FForeground: Integer;
    FBackground: Integer;
    FSpecial1: Integer;
    FSpecial2: Integer;
    FBlinkHidden: Boolean;
    FCursorInverted: Boolean;
    FCursorX: Integer;
    FCursorY: Integer;
    FMouseDown: Boolean;
    FRecalculateDown: Boolean;
    FTrace: Boolean;
    FClearOnMove: Boolean;
    FDownX: Integer;
    FDownY: Integer;
    FBack: TBytes;
    FSelection: TEndoomRect;
    FHasSelection: Boolean;
    FBlock: TEndoomBlock;
    FHasBlock: Boolean;
    function CellX(APixelX: Integer): Integer;
    function CellY(APixelY: Integer): Integer;
    procedure ApplyToolBehaviour;
    procedure PaintAt(AX, AY: Integer);
    procedure PaintTo(AX, AY: Integer);
    procedure SaveUndo;
    procedure Redraw;
    procedure UpdateState;
    procedure UpdateTitle;
    procedure UpdateRecentFiles;
    procedure UpdateChoices;
    procedure PrepareDocument;
    function LoadFromFile(const AFileName: string): Boolean;
    function WriteToFile(const AFileName: string): Boolean;
    procedure SetFileName(const AFileName: string);
    function BuildExportPixels: TArray<Cardinal>;
    procedure ChangeZoom(AZoom: Integer);
    procedure MoveCursor(AX, AY: Integer);
    procedure ClearCells(const ARect: TEndoomRect);
  public
    /// <param name="AFont">The picture of DOSFONT that the screen is drawn with</param>
    constructor Create(const AView: IEndoomEditorView; const ADialogs: IEndoomEditorDialogs;
      const AClipboard: IEndoomEditorClipboard; const AExporter: IEndoomEditorImageExporter;
      const AFileSystem: IToolFileSystem; const ABackup: IToolFileBackup; const ASettings: ISettingsStore;
      const ARecentFiles: IRecentFiles; const AUndo: IToolUndoHistory; const AScreen: IEndoomScreen;
      const AImage: IEndoomScreenImage; const AFontSource: IEndoomFontSource;
      const ATextArt: IEndoomTextArtConverter; const AMethods: TEndoomTextArtMethodProvider);

    /// <summary>
    ///   The window is ready: the settings come back (zoom, grid, method, recent files), the file of the command
    ///   line is opened, or an empty screen is made
    /// </summary>
    procedure Start(const ACommandLineFile: string);
    /// <summary>The window closes: the settings are saved</summary>
    procedure Shutdown;

    // tools and colors
    procedure SelectTool(ATool: TEndoomEditorTool);
    procedure SelectForeground(AColor: Integer);
    procedure SelectBackground(AColor: Integer);
    procedure SelectSpecialCharacter1(ACode: Integer);
    procedure SelectSpecialCharacter2(ACode: Integer);
    procedure SelectTextArtMethod(AKind: TEndoomTextArtKind);

    // the mouse (pixels of the stretched picture)
    procedure MouseDown(AX, AY: Integer);
    procedure MouseMove(AX, AY: Integer);
    procedure MouseUp(AX, AY: Integer);

    // the keyboard (the text tool)
    procedure KeyPress(AKey: Char);
    procedure KeyDown(AKey: TEndoomEditorKey);

    // the timers
    procedure BlinkTick;
    procedure CursorTick;

    // view
    procedure ZoomIn;
    procedure ZoomOut;
    procedure ToggleGrid;
    /// <summary>Asks the view to show the state of the commands again (the clipboard may have changed)</summary>
    procedure RefreshState;

    // the document
    procedure NewDocument;
    procedure OpenFile;
    procedure OpenRecent(AIndex: Integer);
    procedure Save;
    procedure SaveAs;
    procedure ExportImage;
    /// <summary>False if the user cancels the question about the changes that are not saved</summary>
    function TryClose: Boolean;
    /// <summary>The Exit command: closes the window if the changes are saved or given up</summary>
    procedure RequestClose;
    procedure About;

    // edit
    procedure Undo;
    procedure Redo;
    procedure CopyImage;
    /// <summary>
    ///   The picture goes to the clipboard and every background becomes black: what the Cut command of ENDEDIT did
    /// </summary>
    procedure CutImage;
    procedure Paste;

    // selection
    procedure SelectAll;
    procedure ClearSelection;
    procedure CopySelection;
    procedure CutSelection;
    procedure DeleteSelection;
    procedure FillSelection;
    /// <summary>The copied block goes with its top left corner to the selection, or to the cursor</summary>
    procedure PasteSelection;

    property Screen: IEndoomScreen read FScreen;
    property FileName: string read FFileName;
    property Modified: Boolean read FChanged;
    property Zoom: Integer read FZoom;
    property ShowGrid: Boolean read FShowGrid;
    property Tool: TEndoomEditorTool read FTool;
    property Foreground: Integer read FForeground;
    property Background: Integer read FBackground;
    property SpecialCharacter1: Integer read FSpecial1;
    property SpecialCharacter2: Integer read FSpecial2;
    property TextArtMethod: TEndoomTextArtKind read FMethod;
    property CursorX: Integer read FCursorX;
    property CursorY: Integer read FCursorY;
    property Selection: TEndoomRect read FSelection;
    property HasSelection: Boolean read FHasSelection;
    /// <summary>The characters that blink are hidden at this moment (the blink of the old tool)</summary>
    property BlinkHidden: Boolean read FBlinkHidden;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Endoom.Drawing, DelphiDoom.Endoom.TextPaste, DelphiDoom.Tools.PathText, DelphiDoom.Tools.Types;

{ TEndoomEditorPresenter }

constructor TEndoomEditorPresenter.Create(const AView: IEndoomEditorView; const ADialogs: IEndoomEditorDialogs;
  const AClipboard: IEndoomEditorClipboard; const AExporter: IEndoomEditorImageExporter;
  const AFileSystem: IToolFileSystem; const ABackup: IToolFileBackup; const ASettings: ISettingsStore;
  const ARecentFiles: IRecentFiles; const AUndo: IToolUndoHistory; const AScreen: IEndoomScreen;
  const AImage: IEndoomScreenImage; const AFontSource: IEndoomFontSource;
  const ATextArt: IEndoomTextArtConverter; const AMethods: TEndoomTextArtMethodProvider);
begin
  inherited Create;
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  if not Assigned(ADialogs) then
    raise EArgumentNilException.Create('ADialogs');
  if not Assigned(AClipboard) then
    raise EArgumentNilException.Create('AClipboard');
  if not Assigned(AExporter) then
    raise EArgumentNilException.Create('AExporter');
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  if not Assigned(ABackup) then
    raise EArgumentNilException.Create('ABackup');
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  if not Assigned(ARecentFiles) then
    raise EArgumentNilException.Create('ARecentFiles');
  if not Assigned(AUndo) then
    raise EArgumentNilException.Create('AUndo');
  if not Assigned(AScreen) then
    raise EArgumentNilException.Create('AScreen');
  if not Assigned(AImage) then
    raise EArgumentNilException.Create('AImage');
  if not Assigned(AFontSource) then
    raise EArgumentNilException.Create('AFontSource');
  if not Assigned(ATextArt) then
    raise EArgumentNilException.Create('ATextArt');
  if not Assigned(AMethods) then
    raise EArgumentNilException.Create('AMethods');
  FView := AView;
  FDialogs := ADialogs;
  FClipboard := AClipboard;
  FExporter := AExporter;
  FFileSystem := AFileSystem;
  FBackup := ABackup;
  FSettings := ASettings;
  FRecentFiles := ARecentFiles;
  FUndo := AUndo;
  FScreen := AScreen;
  FImage := AImage;
  FFont := AFontSource.GetFont;
  FTextArt := ATextArt;
  FMethods := AMethods;
  FTool := eetFreeDraw;
  FForeground := 7;
  FBackground := 0;
  FSpecial1 := ENDOOM_EDITOR_FIRST_SPECIAL_CODE;
  FSpecial2 := ENDOOM_EDITOR_FIRST_SPECIAL_CODE;
  FMethod := eakBackgroundOnly;
  ApplyToolBehaviour;
end;

// ---------------------------------------------------------------------------------------------------------------
// cells and tools
// ---------------------------------------------------------------------------------------------------------------

function TEndoomEditorPresenter.CellX(APixelX: Integer): Integer;
begin
  Result := EnsureRange(APixelX div ((ENDOOM_EDITOR_EXPORT_WIDTH + ENDOOM_COLUMNS * FZoom) div ENDOOM_COLUMNS),
    0, ENDOOM_COLUMNS - 1);
end;

function TEndoomEditorPresenter.CellY(APixelY: Integer): Integer;
begin
  Result := EnsureRange(APixelY div ((ENDOOM_EDITOR_EXPORT_HEIGHT + ENDOOM_ROWS * 2 * FZoom) div ENDOOM_ROWS),
    0, ENDOOM_ROWS - 1);
end;

procedure TEndoomEditorPresenter.ApplyToolBehaviour;
begin
  // the flags of the buttons of ENDEDIT: does the start of the drag follow the mouse, is every cell between two mouse
  // positions painted, is the screen put back to what it was at the start before each painting
  case FTool of
    eetFloodFill:
      begin
        FRecalculateDown := True;
        FTrace := False;
        FClearOnMove := True;
      end;
    eetRectangle, eetFilledRectangle, eetEllipse, eetFilledEllipse, eetFrameSingle, eetFrameDoubleHorizontal,
    eetFrameDoubleVertical, eetFrameDouble, eetFrameBlock:
      begin
        FRecalculateDown := False;
        FTrace := False;
        FClearOnMove := True;
      end;
    eetLine:
      begin
        FRecalculateDown := False;
        FTrace := True;
        FClearOnMove := True;
      end;
    eetText, eetSelect:
      begin
        FRecalculateDown := False;
        FTrace := False;
        FClearOnMove := False;
      end;
  else
    begin
      FRecalculateDown := True;
      FTrace := True;
      FClearOnMove := False;
    end;
  end;
end;

procedure TEndoomEditorPresenter.PaintAt(AX, AY: Integer);
begin
  case FTool of
    eetFreeDraw, eetLine:
      FScreen.SetBackground(AX, AY, FBackground);
    eetFloodFill:
      TEndoomDrawing.FloodFill(FScreen, AX, AY, FBackground);
    eetEraseText:
      FScreen.SetCharacter(AX, AY, 0);
    eetRectangle:
      TEndoomDrawing.Rectangle(FScreen, FDownX, FDownY, AX, AY, FBackground);
    eetFilledRectangle:
      TEndoomDrawing.FillRectangle(FScreen, FDownX, FDownY, AX, AY, FBackground);
    eetText:
      MoveCursor(AX, AY);
    eetEllipse:
      TEndoomDrawing.EllipseOutline(FScreen, FDownX, FDownY, AX, AY, FBackground);
    eetFilledEllipse:
      TEndoomDrawing.EllipseFilled(FScreen, FDownX, FDownY, AX, AY, FBackground);
    eetSpecialCharacterWithBackground:
      begin
        FScreen.SetBackground(AX, AY, FBackground);
        FScreen.SetForeground(AX, AY, FForeground);
        FScreen.SetCharacter(AX, AY, Byte(FSpecial1));
      end;
    eetSpecialCharacter:
      begin
        FScreen.SetForeground(AX, AY, FForeground);
        FScreen.SetCharacter(AX, AY, Byte(FSpecial2));
      end;
    eetTextColor:
      FScreen.SetForeground(AX, AY, FForeground);
    eetFrameSingle, eetFrameDoubleHorizontal, eetFrameDoubleVertical, eetFrameDouble, eetFrameBlock:
      TEndoomDrawing.CharacterFrame(FScreen, FDownX, FDownY, AX, AY,
        TEndoomFrameStyle(Ord(FTool) - Ord(eetFrameSingle)), FForeground);
    eetBlinkOn:
      FScreen.SetBlink(AX, AY, True);
    eetBlinkOff:
      FScreen.SetBlink(AX, AY, False);
  end;
end;

procedure TEndoomEditorPresenter.PaintTo(AX, AY: Integer);
var
  LCell: TPoint;
begin
  if not FMouseDown then
    Exit;
  if FClearOnMove then
    FScreen.LoadFromBytes(FBack);
  if FTrace then
  begin
    for LCell in TEndoomDrawing.TraceCells(FDownX, FDownY, AX, AY) do
      PaintAt(LCell.X, LCell.Y);
  end
  else
    PaintAt(AX, AY);
  if FTool <> eetText then
    FChanged := True;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.SaveUndo;
begin
  FUndo.Save(FScreen.ToBytes);
end;

procedure TEndoomEditorPresenter.MoveCursor(AX, AY: Integer);
begin
  FCursorX := EnsureRange(AX, 0, ENDOOM_COLUMNS - 1);
  FCursorY := EnsureRange(AY, 0, ENDOOM_ROWS - 1);
end;

procedure TEndoomEditorPresenter.ClearCells(const ARect: TEndoomRect);
var
  LX: Integer;
  LY: Integer;
  LRect: TEndoomRect;
begin
  LRect := TEndoomRect.Between(Max(0, ARect.Left), Max(0, ARect.Top), Min(ENDOOM_COLUMNS - 1, ARect.Right),
    Min(ENDOOM_ROWS - 1, ARect.Bottom));
  for LY := LRect.Top to LRect.Bottom do
    for LX := LRect.Left to LRect.Right do
      FScreen.SetCell(LX, LY, Default(TEndoomCell));
end;

// ---------------------------------------------------------------------------------------------------------------
// what the window shows
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.Redraw;
var
  LOverlay: TEndoomEditorOverlay;
begin
  // the flag of the old tool, blink = true hides the characters that blink, is the opposite of ABlinkVisible
  FImage.Render(FScreen, FFont, not FBlinkHidden, FPixels);
  LOverlay.Zoom := FZoom;
  LOverlay.ShowGrid := FShowGrid;
  LOverlay.CursorVisible := FTool = eetText;
  LOverlay.CursorInverted := FCursorInverted;
  LOverlay.CursorX := FCursorX;
  LOverlay.CursorY := FCursorY;
  LOverlay.SelectionVisible := FHasSelection;
  LOverlay.Selection := FSelection;
  FView.ShowPicture(FPixels, LOverlay);
end;

procedure TEndoomEditorPresenter.UpdateState;
var
  LState: TEndoomEditorState;
begin
  LState.CanUndo := FUndo.CanUndo;
  LState.CanRedo := FUndo.CanRedo;
  LState.CanPaste := FClipboard.HasImage or FClipboard.HasText;
  LState.CanZoomIn := FZoom < ENDOOM_EDITOR_MAX_ZOOM;
  LState.CanZoomOut := FZoom > ENDOOM_EDITOR_MIN_ZOOM;
  LState.HasSelection := FHasSelection;
  LState.HasBlock := FHasBlock;
  FView.ShowState(LState);
end;

procedure TEndoomEditorPresenter.UpdateTitle;
begin
  if FFileName <> '' then
    FView.ShowTitle(ENDOOM_EDITOR_TITLE + ' - ' + TToolPathText.Shorten(FFileName, TOOLS_SHORT_NAME_LIMIT))
  else
    FView.ShowTitle(ENDOOM_EDITOR_TITLE);
end;

procedure TEndoomEditorPresenter.UpdateRecentFiles;
var
  LCaptions: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LCaptions, FRecentFiles.Count);
  for LIndex := 0 to FRecentFiles.Count - 1 do
    LCaptions[LIndex] := FRecentFiles.MenuCaption(LIndex);
  FView.ShowRecentFiles(LCaptions);
end;

procedure TEndoomEditorPresenter.UpdateChoices;
begin
  FView.ShowChoices(FTool, FForeground, FBackground, FSpecial1, FSpecial2);
end;

procedure TEndoomEditorPresenter.RefreshState;
begin
  UpdateState;
end;

// ---------------------------------------------------------------------------------------------------------------
// start and end
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.Start(const ACommandLineFile: string);
var
  LStarted: Boolean;
begin
  FSettings.Load;
  FRecentFiles.LoadFrom(FSettings, ENDOOM_EDITOR_SECTION_HISTORY);
  FShowGrid := FSettings.ReadBoolean(ENDOOM_EDITOR_SECTION_OPTIONS, ENDOOM_EDITOR_SETTING_GRID, False);
  FZoom := EnsureRange(FSettings.ReadInteger(ENDOOM_EDITOR_SECTION_OPTIONS, ENDOOM_EDITOR_SETTING_ZOOM, 0),
    ENDOOM_EDITOR_MIN_ZOOM, ENDOOM_EDITOR_MAX_ZOOM);
  FMethod := TEndoomTextArtKind(EnsureRange(FSettings.ReadInteger(ENDOOM_EDITOR_SECTION_OPTIONS,
    ENDOOM_EDITOR_SETTING_METHOD, 0), Ord(Low(TEndoomTextArtKind)), Ord(High(TEndoomTextArtKind))));
  LStarted := (ACommandLineFile <> '') and LoadFromFile(ACommandLineFile);
  if not LStarted then
    NewDocument;
  UpdateRecentFiles;
  UpdateChoices;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.Shutdown;
begin
  FRecentFiles.SaveTo(FSettings, ENDOOM_EDITOR_SECTION_HISTORY);
  FSettings.WriteBoolean(ENDOOM_EDITOR_SECTION_OPTIONS, ENDOOM_EDITOR_SETTING_GRID, FShowGrid);
  FSettings.WriteInteger(ENDOOM_EDITOR_SECTION_OPTIONS, ENDOOM_EDITOR_SETTING_ZOOM, FZoom);
  FSettings.WriteInteger(ENDOOM_EDITOR_SECTION_OPTIONS, ENDOOM_EDITOR_SETTING_METHOD, Ord(FMethod));
  FSettings.Save;
end;

// ---------------------------------------------------------------------------------------------------------------
// tools and colors
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.SelectTool(ATool: TEndoomEditorTool);
begin
  FTool := ATool;
  FMouseDown := False;
  ApplyToolBehaviour;
  UpdateChoices;
  Redraw;
end;

procedure TEndoomEditorPresenter.SelectForeground(AColor: Integer);
begin
  FForeground := EnsureRange(AColor, 0, ENDOOM_COLOR_COUNT - 1);
  UpdateChoices;
end;

procedure TEndoomEditorPresenter.SelectBackground(AColor: Integer);
begin
  FBackground := EnsureRange(AColor, 0, ENDOOM_BACKGROUND_COLOR_COUNT - 1);
  UpdateChoices;
end;

procedure TEndoomEditorPresenter.SelectSpecialCharacter1(ACode: Integer);
begin
  FSpecial1 := EnsureRange(ACode, 0, 255);
  UpdateChoices;
end;

procedure TEndoomEditorPresenter.SelectSpecialCharacter2(ACode: Integer);
begin
  FSpecial2 := EnsureRange(ACode, 0, 255);
  UpdateChoices;
end;

procedure TEndoomEditorPresenter.SelectTextArtMethod(AKind: TEndoomTextArtKind);
begin
  FMethod := AKind;
end;

// ---------------------------------------------------------------------------------------------------------------
// the mouse
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.MouseDown(AX, AY: Integer);
var
  LX: Integer;
  LY: Integer;
begin
  LX := CellX(AX);
  LY := CellY(AY);
  FDownX := LX;
  FDownY := LY;
  if FTool = eetSelect then
  begin
    FMouseDown := True;
    FSelection := TEndoomRect.Between(LX, LY, LX, LY);
    FHasSelection := True;
    Redraw;
    UpdateState;
    Exit;
  end;
  if FTool <> eetText then
    SaveUndo;
  FBack := FScreen.ToBytes;
  FMouseDown := True;
  PaintTo(LX, LY);
end;

procedure TEndoomEditorPresenter.MouseMove(AX, AY: Integer);
var
  LX: Integer;
  LY: Integer;
begin
  LX := CellX(AX);
  LY := CellY(AY);
  FView.ShowStatus(Format(SEndoomEditorStatus, [LX, LY, IntToHex(ENDOOM_COLORS[FScreen.GetBackground(LX, LY)], 6),
    IntToHex(ENDOOM_COLORS[FScreen.GetForeground(LX, LY)], 6), IntToHex(FScreen.GetCharacter(LX, LY), 2)]));
  if not FMouseDown then
    Exit;
  if FTool = eetSelect then
  begin
    FSelection := TEndoomRect.Between(FDownX, FDownY, LX, LY);
    Redraw;
    Exit;
  end;
  PaintTo(LX, LY);
  if FRecalculateDown then
  begin
    FDownX := LX;
    FDownY := LY;
  end;
end;

procedure TEndoomEditorPresenter.MouseUp(AX, AY: Integer);
var
  LX: Integer;
  LY: Integer;
begin
  if not FMouseDown then
    Exit;
  LX := CellX(AX);
  LY := CellY(AY);
  if FTool = eetSelect then
  begin
    FSelection := TEndoomRect.Between(FDownX, FDownY, LX, LY);
    FMouseDown := False;
    Redraw;
    UpdateState;
    Exit;
  end;
  PaintTo(LX, LY);
  FMouseDown := False;
end;

// ---------------------------------------------------------------------------------------------------------------
// the keyboard
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.KeyPress(AKey: Char);
var
  LCode: Byte;
begin
  if FTool <> eetText then
    Exit;
  if (Ord(AKey) >= 32) and (Ord(AKey) <= 128) then
  begin
    LCode := TEndoomTextPaste.CodeOf(AKey);
    if (FScreen.GetCharacter(FCursorX, FCursorY) <> LCode) or (FScreen.GetForeground(FCursorX, FCursorY) <> FForeground) then
    begin
      SaveUndo;
      FChanged := True;
      FScreen.SetForeground(FCursorX, FCursorY, FForeground);
      FScreen.SetCharacter(FCursorX, FCursorY, LCode);
    end;
    if FCursorX < ENDOOM_COLUMNS - 1 then
      Inc(FCursorX)
    else if FCursorY < ENDOOM_ROWS - 1 then
    begin
      FCursorX := 0;
      Inc(FCursorY);
    end;
  end
  else if AKey = #8 then
  begin
    if FCursorX > 0 then
      Dec(FCursorX)
    else if FCursorY > 0 then
    begin
      FCursorX := ENDOOM_COLUMNS - 1;
      Dec(FCursorY);
    end;
    if FScreen.GetCharacter(FCursorX, FCursorY) <> Ord(' ') then
    begin
      SaveUndo;
      FChanged := True;
      FScreen.SetCharacter(FCursorX, FCursorY, Ord(' '));
    end;
  end
  else if AKey = #13 then
  begin
    if FCursorY < ENDOOM_ROWS - 1 then
    begin
      FCursorX := 0;
      Inc(FCursorY);
    end;
  end
  else
    Exit;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.KeyDown(AKey: TEndoomEditorKey);
begin
  if FTool <> eetText then
    Exit;
  case AKey of
    eekDelete:
      if FScreen.GetCharacter(FCursorX, FCursorY) <> Ord(' ') then
      begin
        SaveUndo;
        FChanged := True;
        FScreen.SetCharacter(FCursorX, FCursorY, Ord(' '));
      end;
    eekEnd:
      FCursorX := ENDOOM_COLUMNS - 1;
    eekHome:
      FCursorX := 0;
    eekLeft:
      MoveCursor(FCursorX - 1, FCursorY);
    eekRight:
      MoveCursor(FCursorX + 1, FCursorY);
    eekUp:
      MoveCursor(FCursorX, FCursorY - 1);
    eekDown:
      MoveCursor(FCursorX, FCursorY + 1);
    eekPageUp:
      MoveCursor(FCursorX, FCursorY - ENDOOM_EDITOR_PAGE_ROWS);
    eekPageDown:
      MoveCursor(FCursorX, FCursorY + ENDOOM_EDITOR_PAGE_ROWS);
  end;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.BlinkTick;
begin
  FBlinkHidden := not FBlinkHidden;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.CursorTick;
begin
  if FTool <> eetText then
    Exit;
  FCursorInverted := not FCursorInverted;
  Redraw;
end;

// ---------------------------------------------------------------------------------------------------------------
// view
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.ChangeZoom(AZoom: Integer);
begin
  AZoom := EnsureRange(AZoom, ENDOOM_EDITOR_MIN_ZOOM, ENDOOM_EDITOR_MAX_ZOOM);
  if AZoom = FZoom then
    Exit;
  FZoom := AZoom;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.ZoomIn;
begin
  ChangeZoom(FZoom + 1);
end;

procedure TEndoomEditorPresenter.ZoomOut;
begin
  ChangeZoom(FZoom - 1);
end;

procedure TEndoomEditorPresenter.ToggleGrid;
begin
  FShowGrid := not FShowGrid;
  Redraw;
end;

// ---------------------------------------------------------------------------------------------------------------
// the document
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.PrepareDocument;
begin
  FCursorX := 0;
  FCursorY := 0;
  FCursorInverted := False;
  FUndo.Clear;
  FBlinkHidden := False;
  FChanged := False;
  FMouseDown := False;
  FHasSelection := False;
end;

procedure TEndoomEditorPresenter.SetFileName(const AFileName: string);
begin
  FFileName := AFileName;
  UpdateTitle;
end;

procedure TEndoomEditorPresenter.NewDocument;
begin
  if not TryClose then
    Exit;
  FScreen.Clear;
  PrepareDocument;
  SetFileName('');
  Redraw;
  UpdateState;
end;

function TEndoomEditorPresenter.LoadFromFile(const AFileName: string): Boolean;
var
  LBytes: TBytes;
begin
  Result := False;
  if not FFileSystem.FileExists(AFileName) then
  begin
    FDialogs.ShowMessage(Format(SEndoomEditorFileNotFound, [TToolPathText.Shorten(AFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  if (not FFileSystem.TryReadAllBytes(AFileName, LBytes)) or (Length(LBytes) < ENDOOM_LUMP_SIZE) then
  begin
    FDialogs.ShowMessage(Format(SEndoomEditorCannotRead, [TToolPathText.Shorten(AFileName, TOOLS_SHORT_NAME_LIMIT),
      ENDOOM_LUMP_SIZE]));
    Exit;
  end;
  FScreen.LoadFromBytes(LBytes);
  PrepareDocument;
  SetFileName(AFileName);
  FRecentFiles.Add(AFileName);
  UpdateRecentFiles;
  Redraw;
  UpdateState;
  Result := True;
end;

function TEndoomEditorPresenter.WriteToFile(const AFileName: string): Boolean;
begin
  FBackup.Backup(AFileName);
  Result := FFileSystem.TryWriteAllBytes(AFileName, FScreen.ToBytes);
  if not Result then
  begin
    FDialogs.ShowMessage(Format(SEndoomEditorCannotWrite, [TToolPathText.Shorten(AFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  SetFileName(AFileName);
  FRecentFiles.Add(AFileName);
  UpdateRecentFiles;
  FChanged := False;
end;

procedure TEndoomEditorPresenter.OpenFile;
var
  LFileName: string;
begin
  if not TryClose then
    Exit;
  if FDialogs.PickFileToOpen(LFileName) then
    LoadFromFile(LFileName);
end;

procedure TEndoomEditorPresenter.OpenRecent(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FRecentFiles.Count) then
    Exit;
  if TryClose then
    LoadFromFile(FRecentFiles[AIndex]);
end;

procedure TEndoomEditorPresenter.Save;
begin
  if FFileName = '' then
    SaveAs
  else
    WriteToFile(FFileName);
end;

procedure TEndoomEditorPresenter.SaveAs;
var
  LFileName: string;
begin
  if FDialogs.PickFileToSave(FFileName, LFileName) then
    WriteToFile(LFileName);
end;

function TEndoomEditorPresenter.TryClose: Boolean;
begin
  Result := True;
  if not FChanged then
    Exit;
  case FDialogs.AskSaveChanges of
    ecCancel:
      Result := False;
    ecYes:
      begin
        Save;
        Result := not FChanged;
      end;
  end;
end;

procedure TEndoomEditorPresenter.RequestClose;
begin
  if TryClose then
    FView.CloseWindow;
end;

procedure TEndoomEditorPresenter.About;
begin
  FDialogs.ShowAbout;
end;

function TEndoomEditorPresenter.BuildExportPixels: TArray<Cardinal>;
var
  LRow: Integer;
begin
  FImage.Render(FScreen, FFont, not FBlinkHidden, FPixels);
  // the old tool stretched the picture to 640x400: every row twice
  SetLength(Result, ENDOOM_EDITOR_EXPORT_WIDTH * ENDOOM_EDITOR_EXPORT_HEIGHT);
  for LRow := 0 to ENDOOM_EDITOR_EXPORT_HEIGHT - 1 do
    Move(FPixels[(LRow div 2) * ENDOOM_WIDTH], Result[LRow * ENDOOM_EDITOR_EXPORT_WIDTH],
      ENDOOM_EDITOR_EXPORT_WIDTH * SizeOf(Cardinal));
end;

procedure TEndoomEditorPresenter.ExportImage;
var
  LFileName: string;
begin
  if not FDialogs.PickImageToExport(LFileName) then
    Exit;
  FBackup.Backup(LFileName);
  if not FExporter.Export(LFileName, BuildExportPixels, ENDOOM_EDITOR_EXPORT_WIDTH, ENDOOM_EDITOR_EXPORT_HEIGHT) then
    FDialogs.ShowMessage(Format(SEndoomEditorCannotExport, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
end;

// ---------------------------------------------------------------------------------------------------------------
// edit
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.Undo;
begin
  if not FUndo.CanUndo then
    Exit;
  FScreen.LoadFromBytes(FUndo.Undo(FScreen.ToBytes));
  FChanged := True;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.Redo;
begin
  if not FUndo.CanRedo then
    Exit;
  FScreen.LoadFromBytes(FUndo.Redo(FScreen.ToBytes));
  FChanged := True;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.CopyImage;
begin
  FClipboard.SetImage(BuildExportPixels, ENDOOM_EDITOR_EXPORT_WIDTH, ENDOOM_EDITOR_EXPORT_HEIGHT);
  UpdateState;
end;

procedure TEndoomEditorPresenter.CutImage;
begin
  FClipboard.SetImage(BuildExportPixels, ENDOOM_EDITOR_EXPORT_WIDTH, ENDOOM_EDITOR_EXPORT_HEIGHT);
  SaveUndo;
  FChanged := True;
  FScreen.FillBackground(TEndoomRect.Between(0, 0, ENDOOM_COLUMNS - 1, ENDOOM_ROWS - 1), 0);
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.Paste;
var
  LPixels: TArray<Cardinal>;
  LWidth: Integer;
  LHeight: Integer;
  LCursor: TPoint;
  LStartX: Integer;
  LStartY: Integer;
begin
  if FClipboard.HasImage then
  begin
    if FClipboard.TryGetImage(LPixels, LWidth, LHeight) and FDialogs.PickTextArtMethod(FMethod) then
    begin
      SaveUndo;
      FChanged := True;
      FTextArt.Convert(FScreen, LPixels, LWidth, LHeight, FMethods(FMethod));
    end;
  end
  else if FClipboard.HasText then
  begin
    LStartX := 0;
    LStartY := 0;
    if FTool = eetText then
    begin
      LStartX := FCursorX;
      LStartY := FCursorY;
    end;
    SaveUndo;
    FChanged := True;
    LCursor := TEndoomTextPaste.Apply(FScreen, FClipboard.GetText, LStartX, LStartY, FForeground);
    MoveCursor(LCursor.X, LCursor.Y);
  end
  else
    Exit;
  Redraw;
  UpdateState;
end;

// ---------------------------------------------------------------------------------------------------------------
// selection
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPresenter.SelectAll;
begin
  FSelection := TEndoomRect.Between(0, 0, ENDOOM_COLUMNS - 1, ENDOOM_ROWS - 1);
  FHasSelection := True;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.ClearSelection;
begin
  FHasSelection := False;
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.CopySelection;
begin
  if not FHasSelection then
    Exit;
  FBlock := FScreen.CopyBlock(FSelection);
  FHasBlock := True;
  UpdateState;
end;

procedure TEndoomEditorPresenter.CutSelection;
begin
  if not FHasSelection then
    Exit;
  CopySelection;
  DeleteSelection;
end;

procedure TEndoomEditorPresenter.DeleteSelection;
begin
  if not FHasSelection then
    Exit;
  SaveUndo;
  FChanged := True;
  ClearCells(FSelection);
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.FillSelection;
begin
  if not FHasSelection then
    Exit;
  SaveUndo;
  FChanged := True;
  FScreen.FillBackground(FSelection, FBackground);
  Redraw;
  UpdateState;
end;

procedure TEndoomEditorPresenter.PasteSelection;
var
  LX: Integer;
  LY: Integer;
begin
  if not FHasBlock then
    Exit;
  if FHasSelection then
  begin
    LX := FSelection.Left;
    LY := FSelection.Top;
  end
  else
  begin
    LX := FCursorX;
    LY := FCursorY;
  end;
  SaveUndo;
  FChanged := True;
  FScreen.PasteBlock(FBlock, LX, LY);
  Redraw;
  UpdateState;
end;

end.

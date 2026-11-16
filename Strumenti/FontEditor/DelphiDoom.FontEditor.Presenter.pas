{******************************************************************************}
{                                                                              }
{  DelphiDoom: font editor - the presenter of the main window                   }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.FontEditor.Presenter;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Tools.Intf,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf,
  DelphiDoom.FontEditor.Types,
  DelphiDoom.FontEditor.Intf;

type
  /// <summary>
  ///   What the main window of DD_FONT (main.pas, 80 handlers) decided, without the window: the settings of the
  ///   font and the changes that the user makes to them (name, size, styles, colors, size of the cell), with undo,
  ///   the project files (open, save, recent files, backup, the question on closing), the zoom and the grid, the
  ///   page of what a WAD is made of (a text, the characters, the digits; pitch, noise, palette), the preview, the
  ///   export of the picture and the making of the WAD. The window tells it what happens and draws what it says
  ///   (IFontEditorView). The picture of the grid and of the preview are drawn by the library, so that the
  ///   window only shows them
  /// </summary>
  TFontEditorPresenter = class
  strict private
    FView: IFontEditorView;
    FDialogs: IFontEditorDialogs;
    FCatalog: IFontCatalog;
    FInstaller: IFontInstaller;
    FExporter: IFontEditorImageExporter;
    FFileSystem: IToolFileSystem;
    FBackup: IToolFileBackup;
    FStore: ISettingsStore;
    FRecentFiles: IRecentFiles;
    FUndo: IToolUndoHistory;
    FGridComposer: IFontGridComposer;
    FTextComposer: IFontTextComposer;
    FWadGenerator: IFontWadGenerator;
    FFont: TFontSettings;
    FFileName: string;
    FChanged: Boolean;
    FShowGrid: Boolean;
    FZoom: Integer;
    FKind: TFontSequenceKind;
    FText: string;
    FCharacterPrefix: string;
    FDigitPrefix: string;
    FFixedPitch: Boolean;
    FPerlinNoise: Boolean;
    FPalette: TFontEditorPalette;
    FExternalPalette: string;
    FFontNames: TArray<string>;
    FInstalledFonts: TList<string>;
    function CanGenerate: Boolean;
    function PreviewText: string;
    function BuildPalette: TFontPaletteSelection;
    function BuildRequest: TFontGenerationRequest;
    procedure ApplyFont(const ANewFont: TFontSettings);
    procedure RestoreFont(const ABytes: TBytes);
    procedure RefreshGrid;
    procedure RefreshPreview;
    procedure RefreshDisplay;
    procedure RefreshState;
    procedure RefreshTitle;
    procedure RefreshRecentFiles;
    procedure RefreshAll;
    procedure ReadStoredFont;
    procedure WriteStoredFont;
    function LoadFromFile(const AFileName: string): Boolean;
    function WriteToFile(const AFileName: string): Boolean;
    procedure SetFileName(const AFileName: string);
    procedure ReadFontNames;
    function PaletteFromName(const AName: string): TFontEditorPalette;
    function PaletteName(APalette: TFontEditorPalette): string;
  public
    constructor Create(const AView: IFontEditorView; const ADialogs: IFontEditorDialogs;
      const ACatalog: IFontCatalog; const AInstaller: IFontInstaller; const AExporter: IFontEditorImageExporter;
      const AFileSystem: IToolFileSystem; const ABackup: IToolFileBackup; const AStore: ISettingsStore;
      const ARecentFiles: IRecentFiles; const AUndo: IToolUndoHistory; const AGridComposer: IFontGridComposer;
      const ATextComposer: IFontTextComposer; const AWadGenerator: IFontWadGenerator);
    destructor Destroy; override;

    /// <summary>
    ///   The window is ready: the settings come back (the font, the cell, the page of the WAD, the zoom, the grid,
    ///   the recent files), the project of the command line is opened, or a new one is made
    /// </summary>
    procedure Start(const ACommandLineFile: string);
    /// <summary>The window closes: the settings are saved and the fonts that were opened are given back</summary>
    procedure Shutdown;

    // the font (each change can be undone, and makes the project "changed")
    /// <summary>A font of the list; a name that is not in the list is not taken</summary>
    procedure SelectFontName(const AName: string);
    procedure SetBold(AEnabled: Boolean);
    procedure SetItalic(AEnabled: Boolean);
    procedure SetUnderline(AEnabled: Boolean);
    procedure SetStrikeOut(AEnabled: Boolean);
    /// <summary>One step up in the size of the font: by 1, then by 4 above 19 (the steps of the buttons of DD_FONT)</summary>
    procedure MakeBigger;
    procedure MakeSmaller;
    procedure ChooseFrontColor;
    procedure ChooseBackColor;
    /// <summary>The size of a cell; the sliders of DD_FONT went from 5 to 32 and so does this</summary>
    procedure SetDrawWidth(AWidth: Integer);
    procedure SetDrawHeight(AHeight: Integer);

    // view
    procedure ZoomIn;
    procedure ZoomOut;
    procedure ToggleGrid;

    // what the WAD is made of (not part of the project)
    procedure SetKind(AKind: TFontSequenceKind);
    procedure SetText(const AText: string);
    procedure SetCharacterPrefix(const APrefix: string);
    procedure SetDigitPrefix(const APrefix: string);
    procedure SetFixedPitch(AEnabled: Boolean);
    procedure SetPerlinNoise(AEnabled: Boolean);
    procedure SelectPalette(APalette: TFontEditorPalette);
    procedure SetExternalPalette(const AFileName: string);
    procedure ChooseExternalPalette;

    // the project
    procedure NewDocument;
    procedure OpenFile;
    /// <summary>A project that is known by its name (the command line, a file that was dropped): it is opened if the changes are saved or given up</summary>
    procedure OpenProject(const AFileName: string);
    procedure OpenRecent(AIndex: Integer);
    procedure Save;
    procedure SaveAs;
    /// <summary>The picture of the grid to a file of the user</summary>
    procedure ExportImage;
    /// <summary>The WAD of the page of the window, to a file of the user</summary>
    procedure GenerateWad;
    /// <summary>A font file that the user chooses becomes one of the fonts of the list</summary>
    procedure InstallFont;
    /// <summary>False if the user cancels the question about the changes that are not saved</summary>
    function TryClose: Boolean;
    /// <summary>The Exit command: closes the window if the changes are saved or given up</summary>
    procedure RequestClose;
    procedure About;

    // edit
    procedure Undo;
    procedure Redo;

    property Font: TFontSettings read FFont;
    property FileName: string read FFileName;
    property Modified: Boolean read FChanged;
    property Zoom: Integer read FZoom;
    property ShowGridLines: Boolean read FShowGrid;
    property Kind: TFontSequenceKind read FKind;
    property Text: string read FText;
    property CharacterPrefix: string read FCharacterPrefix;
    property DigitPrefix: string read FDigitPrefix;
    property FixedPitch: Boolean read FFixedPitch;
    property PerlinNoise: Boolean read FPerlinNoise;
    property Palette: TFontEditorPalette read FPalette;
    property ExternalPalette: string read FExternalPalette;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tools.PathText, DelphiDoom.Tools.Types,
  DelphiDoom.Palette.GamePalettes,
  DelphiDoom.Font.SettingsFormat, DelphiDoom.Font.LumpNames;

{ TFontEditorPresenter }

constructor TFontEditorPresenter.Create(const AView: IFontEditorView; const ADialogs: IFontEditorDialogs;
  const ACatalog: IFontCatalog; const AInstaller: IFontInstaller; const AExporter: IFontEditorImageExporter;
  const AFileSystem: IToolFileSystem; const ABackup: IToolFileBackup; const AStore: ISettingsStore;
  const ARecentFiles: IRecentFiles; const AUndo: IToolUndoHistory; const AGridComposer: IFontGridComposer;
  const ATextComposer: IFontTextComposer; const AWadGenerator: IFontWadGenerator);
begin
  inherited Create;
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  if not Assigned(ADialogs) then
    raise EArgumentNilException.Create('ADialogs');
  if not Assigned(ACatalog) then
    raise EArgumentNilException.Create('ACatalog');
  if not Assigned(AInstaller) then
    raise EArgumentNilException.Create('AInstaller');
  if not Assigned(AExporter) then
    raise EArgumentNilException.Create('AExporter');
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  if not Assigned(ABackup) then
    raise EArgumentNilException.Create('ABackup');
  if not Assigned(AStore) then
    raise EArgumentNilException.Create('AStore');
  if not Assigned(ARecentFiles) then
    raise EArgumentNilException.Create('ARecentFiles');
  if not Assigned(AUndo) then
    raise EArgumentNilException.Create('AUndo');
  if not Assigned(AGridComposer) then
    raise EArgumentNilException.Create('AGridComposer');
  if not Assigned(ATextComposer) then
    raise EArgumentNilException.Create('ATextComposer');
  if not Assigned(AWadGenerator) then
    raise EArgumentNilException.Create('AWadGenerator');
  FView := AView;
  FDialogs := ADialogs;
  FCatalog := ACatalog;
  FInstaller := AInstaller;
  FExporter := AExporter;
  FFileSystem := AFileSystem;
  FBackup := ABackup;
  FStore := AStore;
  FRecentFiles := ARecentFiles;
  FUndo := AUndo;
  FGridComposer := AGridComposer;
  FTextComposer := ATextComposer;
  FWadGenerator := AWadGenerator;
  FInstalledFonts := TList<string>.Create;
  FFont := TFontSettings.Initial;
  FText := FONT_DEFAULT_TEXT;
  FCharacterPrefix := FONT_DEFAULT_CHARACTER_PREFIX;
  FDigitPrefix := FONT_DEFAULT_DIGIT_PREFIX;
  FPalette := epDoom;
end;

destructor TFontEditorPresenter.Destroy;
begin
  FInstalledFonts.Free;
  inherited Destroy;
end;

// ---------------------------------------------------------------------------------------------------------------
// settings
// ---------------------------------------------------------------------------------------------------------------

function TFontEditorPresenter.PaletteFromName(const AName: string): TFontEditorPalette;
var
  LGame: TGamePalette;
begin
  if AName = '' then
    Exit(epDoom);
  if TGamePalettes.TryFromName(AName, LGame) then
    Result := TFontEditorPalette(Ord(LGame))
  else
    Result := epOther;
end;

function TFontEditorPresenter.PaletteName(APalette: TFontEditorPalette): string;
begin
  if APalette = epOther then
    Result := FONT_EDITOR_PALETTE_OTHER_NAME
  else
    Result := TGamePalettes.Name(TGamePalette(Ord(APalette)));
end;

procedure TFontEditorPresenter.ReadStoredFont;
begin
  FFont := TFontSettings.Initial;
  FFont.FontSize := FStore.ReadInteger(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_FONT_SIZE, FFont.FontSize);
  FFont.FontName := FStore.ReadString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_FONT_NAME, FFont.FontName);
  if FFont.FontName = '' then
    FFont.FontName := FONT_DEFAULT_NAME;
  FFont := FFont.WithStyle(FONT_STYLE_BOLD, FStore.ReadBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_BOLD, False));
  FFont := FFont.WithStyle(FONT_STYLE_ITALIC, FStore.ReadBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_ITALIC, False));
  FFont := FFont.WithStyle(FONT_STYLE_UNDERLINE,
    FStore.ReadBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_UNDERLINE, False));
  FFont := FFont.WithStyle(FONT_STYLE_STRIKEOUT,
    FStore.ReadBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_STRIKEOUT, False));
  FFont.FrontColor := FStore.ReadInteger(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_FRONT_COLOR, FFont.FrontColor);
  FFont.BackColor := FStore.ReadInteger(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_BACK_COLOR, FFont.BackColor);
  FFont.DrawWidth := EnsureRange(FStore.ReadInteger(FONT_EDITOR_SECTION_OPTIONS, FONT_EDITOR_SETTING_DRAW_WIDTH,
    FFont.DrawWidth), FONT_EDITOR_MIN_CELL, FONT_EDITOR_MAX_CELL);
  FFont.DrawHeight := EnsureRange(FStore.ReadInteger(FONT_EDITOR_SECTION_OPTIONS, FONT_EDITOR_SETTING_DRAW_HEIGHT,
    FFont.DrawHeight), FONT_EDITOR_MIN_CELL, FONT_EDITOR_MAX_CELL);
end;

procedure TFontEditorPresenter.WriteStoredFont;
begin
  FStore.WriteInteger(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_FONT_SIZE, FFont.FontSize);
  FStore.WriteString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_FONT_NAME, FFont.FontName);
  FStore.WriteBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_BOLD, FFont.IsBold);
  FStore.WriteBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_ITALIC, FFont.IsItalic);
  FStore.WriteBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_UNDERLINE, FFont.IsUnderline);
  FStore.WriteBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_STRIKEOUT, FFont.IsStrikeOut);
  FStore.WriteInteger(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_FRONT_COLOR, FFont.FrontColor);
  FStore.WriteInteger(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_BACK_COLOR, FFont.BackColor);
  FStore.WriteInteger(FONT_EDITOR_SECTION_OPTIONS, FONT_EDITOR_SETTING_DRAW_WIDTH, FFont.DrawWidth);
  FStore.WriteInteger(FONT_EDITOR_SECTION_OPTIONS, FONT_EDITOR_SETTING_DRAW_HEIGHT, FFont.DrawHeight);
end;

procedure TFontEditorPresenter.Start(const ACommandLineFile: string);
var
  LStarted: Boolean;
begin
  FStore.Load;
  FRecentFiles.LoadFrom(FStore, FONT_EDITOR_SECTION_HISTORY);
  FShowGrid := FStore.ReadBoolean(FONT_EDITOR_SECTION_OPTIONS, FONT_EDITOR_SETTING_GRID, False);
  FZoom := EnsureRange(FStore.ReadInteger(FONT_EDITOR_SECTION_OPTIONS, FONT_EDITOR_SETTING_ZOOM, 0),
    FONT_EDITOR_MIN_ZOOM, FONT_EDITOR_MAX_ZOOM);
  FFixedPitch := FStore.ReadBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_FIXED_PITCH, False);
  FPerlinNoise := FStore.ReadBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_PERLIN_NOISE, False);
  FPalette := PaletteFromName(FStore.ReadString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_PALETTE, ''));
  FExternalPalette := FStore.ReadString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_EXTERNAL_PALETTE, '');
  FText := FStore.ReadString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_TEXT, FONT_DEFAULT_TEXT);
  FCharacterPrefix := FStore.ReadString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_CHARACTER_PREFIX,
    FONT_DEFAULT_CHARACTER_PREFIX);
  FDigitPrefix := FStore.ReadString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_DIGIT_PREFIX,
    FONT_DEFAULT_DIGIT_PREFIX);
  ReadStoredFont;
  ReadFontNames;
  // the original loaded the project of the command line and then reset it (a defect): here it stays
  LStarted := (ACommandLineFile <> '') and LoadFromFile(ACommandLineFile);
  if not LStarted then
  begin
    FUndo.Clear;
    SetFileName('');
    FChanged := False;
  end;
  RefreshRecentFiles;
  RefreshAll;
end;

procedure TFontEditorPresenter.Shutdown;
begin
  FRecentFiles.SaveTo(FStore, FONT_EDITOR_SECTION_HISTORY);
  FStore.WriteBoolean(FONT_EDITOR_SECTION_OPTIONS, FONT_EDITOR_SETTING_GRID, FShowGrid);
  FStore.WriteInteger(FONT_EDITOR_SECTION_OPTIONS, FONT_EDITOR_SETTING_ZOOM, FZoom);
  FStore.WriteBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_FIXED_PITCH, FFixedPitch);
  FStore.WriteBoolean(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_PERLIN_NOISE, FPerlinNoise);
  FStore.WriteString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_PALETTE, PaletteName(FPalette));
  FStore.WriteString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_EXTERNAL_PALETTE, FExternalPalette);
  FStore.WriteString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_TEXT, FText);
  FStore.WriteString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_CHARACTER_PREFIX, FCharacterPrefix);
  FStore.WriteString(FONT_EDITOR_SECTION_FONT, FONT_EDITOR_SETTING_DIGIT_PREFIX, FDigitPrefix);
  WriteStoredFont;
  FStore.Save;
  FInstaller.UninstallAll;
  FInstalledFonts.Clear;
end;

// ---------------------------------------------------------------------------------------------------------------
// what the window shows
// ---------------------------------------------------------------------------------------------------------------

function TFontEditorPresenter.CanGenerate: Boolean;
begin
  Result := (FKind <> fskText) or (TFontLumpNames.RemoveSpaces(FText) <> '');
end;

function TFontEditorPresenter.PreviewText: string;
begin
  case FKind of
    fskCharacters:
      Result := FONT_CHARACTER_PREVIEW;
    fskDigits:
      Result := FONT_DIGIT_PREVIEW;
  else
    Result := FText;
  end;
end;

procedure TFontEditorPresenter.RefreshGrid;
begin
  FView.ShowGrid(FGridComposer.Compose(FFont), FShowGrid, FZoom, FFont.GridWidth, FFont.GridHeight);
end;

procedure TFontEditorPresenter.RefreshPreview;
begin
  FView.ShowPreview(FTextComposer.Compose(FFont, PreviewText, FFixedPitch, FONT_MAX_PATCH_WIDTH));
end;

procedure TFontEditorPresenter.RefreshDisplay;
var
  LDisplay: TFontEditorDisplay;
begin
  LDisplay.FontName := FFont.FontName;
  LDisplay.FontSize := FFont.FontSize;
  LDisplay.Bold := FFont.IsBold;
  LDisplay.Italic := FFont.IsItalic;
  LDisplay.Underline := FFont.IsUnderline;
  LDisplay.StrikeOut := FFont.IsStrikeOut;
  LDisplay.DrawWidth := FFont.DrawWidth;
  LDisplay.DrawHeight := FFont.DrawHeight;
  LDisplay.FrontColor := FFont.FrontColor;
  LDisplay.BackColor := FFont.BackColor;
  LDisplay.ShowGrid := FShowGrid;
  LDisplay.Zoom := FZoom;
  LDisplay.Info := Format(SFontEditorInfo, [FFont.GridWidth * FFont.DrawWidth, FFont.GridHeight * FFont.DrawHeight,
    FFont.DrawWidth, FFont.DrawHeight]);
  LDisplay.Kind := FKind;
  LDisplay.Text := FText;
  LDisplay.CharacterPrefix := FCharacterPrefix;
  LDisplay.DigitPrefix := FDigitPrefix;
  LDisplay.FixedPitch := FFixedPitch;
  LDisplay.PerlinNoise := FPerlinNoise;
  LDisplay.Palette := FPalette;
  LDisplay.ExternalPalette := FExternalPalette;
  FView.ShowDisplay(LDisplay);
end;

procedure TFontEditorPresenter.RefreshState;
var
  LState: TFontEditorState;
begin
  LState.CanUndo := FUndo.CanUndo;
  LState.CanRedo := FUndo.CanRedo;
  LState.CanZoomIn := FZoom < FONT_EDITOR_MAX_ZOOM;
  LState.CanZoomOut := FZoom > FONT_EDITOR_MIN_ZOOM;
  LState.CanGenerate := CanGenerate;
  LState.ExternalPaletteVisible := FPalette = epOther;
  FView.ShowState(LState);
end;

procedure TFontEditorPresenter.RefreshTitle;
begin
  if FFileName = '' then
    FView.ShowTitle(FONT_EDITOR_TITLE)
  else
    FView.ShowTitle(FONT_EDITOR_TITLE + ' - ' + TToolPathText.Shorten(FFileName, TOOLS_SHORT_NAME_LIMIT));
end;

procedure TFontEditorPresenter.RefreshRecentFiles;
var
  LCaptions: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LCaptions, FRecentFiles.Count);
  for LIndex := 0 to FRecentFiles.Count - 1 do
    LCaptions[LIndex] := FRecentFiles.MenuCaption(LIndex);
  FView.ShowRecentFiles(LCaptions);
end;

procedure TFontEditorPresenter.RefreshAll;
begin
  RefreshDisplay;
  RefreshGrid;
  RefreshPreview;
  RefreshState;
  RefreshTitle;
end;

procedure TFontEditorPresenter.ReadFontNames;
begin
  FFontNames := FCatalog.FontNames;
  FView.ShowFontNames(FFontNames);
end;

// ---------------------------------------------------------------------------------------------------------------
// the font
// ---------------------------------------------------------------------------------------------------------------

procedure TFontEditorPresenter.ApplyFont(const ANewFont: TFontSettings);
begin
  if ANewFont.Equals(FFont) then
    Exit;
  FUndo.Save(TFontSettingsFormat.Save(FFont));
  FFont := ANewFont;
  FChanged := True;
  RefreshAll;
end;

procedure TFontEditorPresenter.RestoreFont(const ABytes: TBytes);
begin
  FFont := TFontSettingsFormat.Load(ABytes, FFont);
  FChanged := True;
  RefreshAll;
end;

procedure TFontEditorPresenter.SelectFontName(const AName: string);
var
  LNew: TFontSettings;
  LName: string;
  LKnown: Boolean;
begin
  LKnown := False;
  for LName in FFontNames do
    if LName = AName then
      LKnown := True;
  if (not LKnown) or (AName = FFont.FontName) then
    Exit;
  LNew := FFont;
  LNew.FontName := AName;
  ApplyFont(LNew);
end;

procedure TFontEditorPresenter.SetBold(AEnabled: Boolean);
begin
  ApplyFont(FFont.WithStyle(FONT_STYLE_BOLD, AEnabled));
end;

procedure TFontEditorPresenter.SetItalic(AEnabled: Boolean);
begin
  ApplyFont(FFont.WithStyle(FONT_STYLE_ITALIC, AEnabled));
end;

procedure TFontEditorPresenter.SetUnderline(AEnabled: Boolean);
begin
  ApplyFont(FFont.WithStyle(FONT_STYLE_UNDERLINE, AEnabled));
end;

procedure TFontEditorPresenter.SetStrikeOut(AEnabled: Boolean);
begin
  ApplyFont(FFont.WithStyle(FONT_STYLE_STRIKEOUT, AEnabled));
end;

procedure TFontEditorPresenter.MakeBigger;
var
  LNew: TFontSettings;
begin
  if FFont.FontSize >= FONT_MAX_SIZE then
    Exit;
  LNew := FFont;
  if LNew.FontSize > 19 then
  begin
    LNew.FontSize := LNew.FontSize + 4;
    if LNew.FontSize > FONT_MAX_SIZE then
      LNew.FontSize := FONT_MAX_SIZE;
  end
  else
    LNew.FontSize := LNew.FontSize + 1;
  if LNew.FontSize < FONT_MIN_SIZE then
    LNew.FontSize := FONT_MIN_SIZE;
  ApplyFont(LNew);
end;

procedure TFontEditorPresenter.MakeSmaller;
var
  LNew: TFontSettings;
begin
  if FFont.FontSize <= FONT_MIN_SIZE then
    Exit;
  LNew := FFont;
  if LNew.FontSize < 21 then
    LNew.FontSize := LNew.FontSize - 1
  else if LNew.FontSize < 24 then
    LNew.FontSize := 20
  else
    LNew.FontSize := LNew.FontSize - 4;
  if LNew.FontSize > FONT_MAX_SIZE then
    LNew.FontSize := FONT_MAX_SIZE;
  ApplyFont(LNew);
end;

procedure TFontEditorPresenter.ChooseFrontColor;
var
  LColor: Integer;
  LNew: TFontSettings;
begin
  LColor := FFont.FrontColor;
  if FDialogs.PickColor(LColor) then
  begin
    LNew := FFont;
    LNew.FrontColor := LColor;
    ApplyFont(LNew);
  end;
end;

procedure TFontEditorPresenter.ChooseBackColor;
var
  LColor: Integer;
  LNew: TFontSettings;
begin
  LColor := FFont.BackColor;
  if FDialogs.PickColor(LColor) then
  begin
    LNew := FFont;
    LNew.BackColor := LColor;
    ApplyFont(LNew);
  end;
end;

procedure TFontEditorPresenter.SetDrawWidth(AWidth: Integer);
var
  LNew: TFontSettings;
begin
  LNew := FFont;
  LNew.DrawWidth := EnsureRange(AWidth, FONT_EDITOR_MIN_CELL, FONT_EDITOR_MAX_CELL);
  ApplyFont(LNew);
end;

procedure TFontEditorPresenter.SetDrawHeight(AHeight: Integer);
var
  LNew: TFontSettings;
begin
  LNew := FFont;
  LNew.DrawHeight := EnsureRange(AHeight, FONT_EDITOR_MIN_CELL, FONT_EDITOR_MAX_CELL);
  ApplyFont(LNew);
end;

// ---------------------------------------------------------------------------------------------------------------
// view and the page of the WAD
// ---------------------------------------------------------------------------------------------------------------

procedure TFontEditorPresenter.ZoomIn;
begin
  if FZoom >= FONT_EDITOR_MAX_ZOOM then
    Exit;
  Inc(FZoom);
  RefreshDisplay;
  RefreshGrid;
  RefreshState;
end;

procedure TFontEditorPresenter.ZoomOut;
begin
  if FZoom <= FONT_EDITOR_MIN_ZOOM then
    Exit;
  Dec(FZoom);
  RefreshDisplay;
  RefreshGrid;
  RefreshState;
end;

procedure TFontEditorPresenter.ToggleGrid;
begin
  FShowGrid := not FShowGrid;
  RefreshDisplay;
  RefreshGrid;
end;

procedure TFontEditorPresenter.SetKind(AKind: TFontSequenceKind);
begin
  FKind := AKind;
  RefreshDisplay;
  RefreshPreview;
  RefreshState;
end;

procedure TFontEditorPresenter.SetText(const AText: string);
begin
  FText := AText;
  RefreshPreview;
  RefreshState;
end;

procedure TFontEditorPresenter.SetCharacterPrefix(const APrefix: string);
begin
  FCharacterPrefix := APrefix;
end;

procedure TFontEditorPresenter.SetDigitPrefix(const APrefix: string);
begin
  FDigitPrefix := APrefix;
end;

procedure TFontEditorPresenter.SetFixedPitch(AEnabled: Boolean);
begin
  FFixedPitch := AEnabled;
  RefreshPreview;
end;

procedure TFontEditorPresenter.SetPerlinNoise(AEnabled: Boolean);
begin
  FPerlinNoise := AEnabled;
end;

procedure TFontEditorPresenter.SelectPalette(APalette: TFontEditorPalette);
begin
  FPalette := APalette;
  RefreshDisplay;
  RefreshState;
end;

procedure TFontEditorPresenter.SetExternalPalette(const AFileName: string);
begin
  FExternalPalette := AFileName;
  RefreshDisplay;
end;

procedure TFontEditorPresenter.ChooseExternalPalette;
var
  LFileName: string;
begin
  if FDialogs.PickPaletteFile(LFileName) then
    SetExternalPalette(LFileName);
end;

// ---------------------------------------------------------------------------------------------------------------
// the project
// ---------------------------------------------------------------------------------------------------------------

procedure TFontEditorPresenter.SetFileName(const AFileName: string);
begin
  FFileName := AFileName;
  RefreshTitle;
end;

function TFontEditorPresenter.LoadFromFile(const AFileName: string): Boolean;
var
  LBytes: TBytes;
begin
  Result := False;
  if not FFileSystem.FileExists(AFileName) then
  begin
    FDialogs.ShowMessage(Format(SFontEditorFileNotFound, [TToolPathText.Shorten(AFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  if not FFileSystem.TryReadAllBytes(AFileName, LBytes) then
  begin
    FDialogs.ShowMessage(Format(SFontEditorCannotRead, [TToolPathText.Shorten(AFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  FUndo.Clear;
  FFont := TFontSettingsFormat.Load(LBytes, FFont);
  FChanged := False;
  SetFileName(AFileName);
  FRecentFiles.Add(AFileName);
  RefreshRecentFiles;
  RefreshAll;
  Result := True;
end;

function TFontEditorPresenter.WriteToFile(const AFileName: string): Boolean;
begin
  FBackup.Backup(AFileName);
  Result := FFileSystem.TryWriteAllBytes(AFileName, TFontSettingsFormat.Save(FFont));
  if not Result then
  begin
    FDialogs.ShowMessage(Format(SFontEditorCannotWrite, [TToolPathText.Shorten(AFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  SetFileName(AFileName);
  FRecentFiles.Add(AFileName);
  RefreshRecentFiles;
  FChanged := False;
end;

procedure TFontEditorPresenter.NewDocument;
begin
  if not TryClose then
    Exit;
  FUndo.Clear;
  SetFileName('');
  FFont := TFontSettings.Initial;
  FChanged := False;
  RefreshAll;
end;

procedure TFontEditorPresenter.OpenFile;
var
  LFileName: string;
begin
  if not TryClose then
    Exit;
  if FDialogs.PickProjectToOpen(LFileName) then
    LoadFromFile(LFileName);
end;

procedure TFontEditorPresenter.OpenProject(const AFileName: string);
begin
  if TryClose then
    LoadFromFile(AFileName);
end;

procedure TFontEditorPresenter.OpenRecent(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FRecentFiles.Count) then
    Exit;
  if TryClose then
    LoadFromFile(FRecentFiles[AIndex]);
end;

procedure TFontEditorPresenter.Save;
begin
  if FFileName = '' then
    SaveAs
  else
    WriteToFile(FFileName);
end;

procedure TFontEditorPresenter.SaveAs;
var
  LFileName: string;
begin
  if FDialogs.PickProjectToSave(ChangeFileExt(FFileName, FONT_EDITOR_PROJECT_EXTENSION), LFileName) then
    WriteToFile(LFileName);
end;

procedure TFontEditorPresenter.ExportImage;
var
  LFileName: string;
begin
  if not FDialogs.PickImageToExport(LFileName) then
    Exit;
  FBackup.Backup(LFileName);
  if not FExporter.Export(LFileName, FGridComposer.Compose(FFont)) then
    FDialogs.ShowMessage(Format(SFontEditorCannotExport, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
end;

function TFontEditorPresenter.BuildPalette: TFontPaletteSelection;
var
  LBytes: TBytes;
  LRgb: TBytes;
begin
  if FPalette <> epOther then
    Exit(TFontPaletteSelection.Create(TGamePalettes.ToColors(TGamePalettes.Colors(TGamePalette(Ord(FPalette)))),
      TGamePalettes.FirstUsableIndex(TGamePalette(Ord(FPalette))),
      TGamePalettes.LastUsableIndex(TGamePalette(Ord(FPalette)))));
  // a file that is missing or that is not a palette gives the gray ramp, as it did
  LRgb := TGamePalettes.GrayscaleColors;
  if (Trim(FExternalPalette) <> '') and FFileSystem.FileExists(FExternalPalette)
    and FFileSystem.TryReadAllBytes(FExternalPalette, LBytes) then
    LRgb := TGamePalettes.ParseExternal(LBytes);
  Result := TFontPaletteSelection.Create(TGamePalettes.ToColors(LRgb), TGamePalettes.FirstUsableIndexOfOther,
    TGamePalettes.LastUsableIndexOfOther);
end;

function TFontEditorPresenter.BuildRequest: TFontGenerationRequest;
begin
  case FKind of
    fskCharacters:
      Result := TFontGenerationRequest.ForCharacters(FCharacterPrefix, FFixedPitch, FPerlinNoise);
    fskDigits:
      Result := TFontGenerationRequest.ForDigits(FDigitPrefix, FFixedPitch, FPerlinNoise);
  else
    Result := TFontGenerationRequest.ForText(FText, FFixedPitch, FPerlinNoise);
  end;
end;

procedure TFontEditorPresenter.GenerateWad;
var
  LFileName: string;
  LBytes: TBytes;
begin
  if not CanGenerate then
    Exit;
  if not FDialogs.PickWadToSave(LFileName) then
    Exit;
  try
    LBytes := FWadGenerator.Generate(FFont, BuildPalette, BuildRequest);
  except
    on E: EFontException do
    begin
      FDialogs.ShowMessage(E.Message);
      Exit;
    end;
  end;
  FBackup.Backup(LFileName);
  if not FFileSystem.TryWriteAllBytes(LFileName, LBytes) then
    FDialogs.ShowMessage(Format(SFontEditorCannotWrite, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
end;

procedure TFontEditorPresenter.InstallFont;
var
  LFileName: string;
begin
  if not FDialogs.PickFontFile(LFileName) then
    Exit;
  if FInstalledFonts.IndexOf(LFileName) >= 0 then
  begin
    FDialogs.ShowMessage(Format(SFontEditorFontAlreadyLoaded, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  if not FInstaller.Install(LFileName) then
  begin
    FDialogs.ShowMessage(Format(SFontEditorCannotInstall, [TToolPathText.Shorten(LFileName, TOOLS_SHORT_NAME_LIMIT)]));
    Exit;
  end;
  FInstalledFonts.Add(LFileName);
  ReadFontNames;
end;

function TFontEditorPresenter.TryClose: Boolean;
begin
  Result := True;
  if not FChanged then
    Exit;
  case FDialogs.AskSaveChanges of
    fcCancel:
      Result := False;
    fcYes:
      begin
        Save;
        Result := not FChanged;
      end;
  end;
end;

procedure TFontEditorPresenter.RequestClose;
begin
  if TryClose then
    FView.CloseWindow;
end;

procedure TFontEditorPresenter.About;
begin
  FDialogs.ShowAbout;
end;

// ---------------------------------------------------------------------------------------------------------------
// edit
// ---------------------------------------------------------------------------------------------------------------

procedure TFontEditorPresenter.Undo;
begin
  if FUndo.CanUndo then
    RestoreFont(FUndo.Undo(TFontSettingsFormat.Save(FFont)));
end;

procedure TFontEditorPresenter.Redo;
begin
  if FUndo.CanRedo then
    RestoreFont(FUndo.Redo(TFontSettingsFormat.Save(FFont)));
end;

end.

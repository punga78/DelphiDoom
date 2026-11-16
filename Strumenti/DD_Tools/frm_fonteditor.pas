{******************************************************************************}
{                                                                              }
{  DD_Tools: the window of the font editor                                      }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit frm_fonteditor;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  Vcl.Controls, Vcl.Forms, Vcl.Menus, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.Graphics,
  DelphiDoom.Font.Types,
  DelphiDoom.FontEditor.Types,
  DelphiDoom.FontEditor.Intf,
  DelphiDoom.FontEditor.Presenter,
  DelphiDoom.Tools.Composition;

type
  /// <summary>
  ///   The window of the font editor (DD_FONT): the font and the size of the cell on top, the grid of the
  ///   characters in the middle, what a WAD is made of on the right. It draws, takes the clicks and tells the
  ///   presenter; the presenter decides. It has no .dfm: the controls are made here. The window is hidden when it
  ///   is closed and shown again by the menu of the tools; the main window closes it for good
  /// </summary>
  TFontEditorForm = class(TForm, IFontEditorView)
  strict private
    const
      MAX_RECENT_ITEMS = 10;
      PREVIEW_HEIGHT = 40;
  strict private
    FPresenter: TFontEditorPresenter;
    FUpdating: Boolean;
    FDisplay: TFontEditorDisplay;
    FGridSource: TBitmap;
    FGridColumns: Integer;
    FGridRows: Integer;
    FGridLines: Boolean;
    FGridZoom: Integer;
    FPreviewSource: TBitmap;
    FMenu: TMainMenu;
    FFileMenu: TMenuItem;
    FRecentSeparator: TMenuItem;
    FRecentItems: array[0..MAX_RECENT_ITEMS - 1] of TMenuItem;
    FUndoItem: TMenuItem;
    FRedoItem: TMenuItem;
    FZoomInItem: TMenuItem;
    FZoomOutItem: TMenuItem;
    FGenerateItem: TMenuItem;
    FTopPanel: TPanel;
    FFontCombo: TComboBox;
    FBoldButton: TSpeedButton;
    FItalicButton: TSpeedButton;
    FUnderlineButton: TSpeedButton;
    FStrikeOutButton: TSpeedButton;
    FSmallerButton: TSpeedButton;
    FBiggerButton: TSpeedButton;
    FSizeLabel: TLabel;
    FFrontPanel: TPanel;
    FBackPanel: TPanel;
    FWidthTrack: TTrackBar;
    FHeightTrack: TTrackBar;
    FWidthLabel: TLabel;
    FHeightLabel: TLabel;
    FRightPanel: TPanel;
    FPages: TPageControl;
    FTextSheet: TTabSheet;
    FCharactersSheet: TTabSheet;
    FDigitsSheet: TTabSheet;
    FTextEdit: TEdit;
    FCharacterEdit: TEdit;
    FDigitEdit: TEdit;
    FFixedPitchBox: TCheckBox;
    FPerlinBox: TCheckBox;
    FPaletteGroup: TRadioGroup;
    FExternalEdit: TEdit;
    FExternalButton: TButton;
    FPreviewPaint: TPaintBox;
    FGenerateButton: TButton;
    FGridScroll: TScrollBox;
    FGridPaint: TPaintBox;
    FInfoLabel: TLabel;
    function AddItem(const AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent;
      AShortCut: TShortCut = 0): TMenuItem;
    function AddButton(const ACaption: string; ALeft: Integer; AHandler: TNotifyEvent;
      AToggle: Boolean): TSpeedButton;
    function AddLabel(const AParent: TWinControl; const ACaption: string; ALeft, ATop: Integer): TLabel;
    function AddColorPanel(ALeft: Integer; AHandler: TNotifyEvent): TPanel;
    procedure BuildMenus;
    procedure BuildTopPanel;
    procedure BuildRightPanel;
    procedure BuildGrid;
    function GridScale: Double;
    procedure NewClick(ASender: TObject);
    procedure OpenClick(ASender: TObject);
    procedure RecentClick(ASender: TObject);
    procedure SaveClick(ASender: TObject);
    procedure SaveAsClick(ASender: TObject);
    procedure ExportClick(ASender: TObject);
    procedure GenerateClick(ASender: TObject);
    procedure InstallFontClick(ASender: TObject);
    procedure CloseClick(ASender: TObject);
    procedure UndoClick(ASender: TObject);
    procedure RedoClick(ASender: TObject);
    procedure ZoomInClick(ASender: TObject);
    procedure ZoomOutClick(ASender: TObject);
    procedure GridClick(ASender: TObject);
    procedure AboutClick(ASender: TObject);
    procedure FontComboChange(ASender: TObject);
    procedure BoldClick(ASender: TObject);
    procedure ItalicClick(ASender: TObject);
    procedure UnderlineClick(ASender: TObject);
    procedure StrikeOutClick(ASender: TObject);
    procedure SmallerClick(ASender: TObject);
    procedure BiggerClick(ASender: TObject);
    procedure FrontColorClick(ASender: TObject);
    procedure BackColorClick(ASender: TObject);
    procedure WidthChange(ASender: TObject);
    procedure HeightChange(ASender: TObject);
    procedure PageChange(ASender: TObject);
    procedure TextChange(ASender: TObject);
    procedure CharacterPrefixChange(ASender: TObject);
    procedure DigitPrefixChange(ASender: TObject);
    procedure FixedPitchClick(ASender: TObject);
    procedure PerlinClick(ASender: TObject);
    procedure PaletteClick(ASender: TObject);
    procedure ExternalChange(ASender: TObject);
    procedure ExternalPaletteClick(ASender: TObject);
    procedure GridPaintPaint(ASender: TObject);
    procedure PreviewPaintPaint(ASender: TObject);
    procedure FormCloseQueried(ASender: TObject; var ACanClose: Boolean);
    procedure FormClosed(ASender: TObject; var AAction: TCloseAction);
    procedure FormWheel(ASender: TObject; AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint;
      var AHandled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>The composition root makes the presenter for this window; the window owns it from here on</summary>
    procedure Configure(const AServices: TToolsServices);
    /// <summary>The window is shown: the project of the command line is opened, or a new one is made</summary>
    procedure Start(const AProjectFile: string);
    /// <summary>A project is opened in a window that is already running</summary>
    procedure OpenProject(const AProjectFile: string);
    /// <summary>The program ends: the settings are saved and the fonts that were opened are given back</summary>
    procedure Finish;
    /// <summary>False if the user cancels the question about the changes that are not saved</summary>
    function CanFinish: Boolean;

    // IFontEditorView
    procedure ShowGrid(const AImage: TFontImage; AShowGrid: Boolean; AZoom, AColumns, ARows: Integer);
    procedure ShowPreview(const AImage: TFontImage);
    procedure ShowTitle(const ATitle: string);
    procedure ShowDisplay(const ADisplay: TFontEditorDisplay);
    procedure ShowState(const AState: TFontEditorState);
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    procedure ShowFontNames(const ANames: TArray<string>);
    procedure CloseWindow;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Tools.Win.Bitmaps;

const
  /// <summary>VK_ADD and VK_SUBTRACT of Windows, the keys + and - of the numeric pad (Winapi.Windows is not used here: it has a TBitmap too)</summary>
  KEY_ADD = $6B;
  KEY_SUBTRACT = $6D;

{ TFontEditorForm }

constructor TFontEditorForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := FONT_EDITOR_TITLE;
  Position := poScreenCenter;
  ClientWidth := 1100;
  ClientHeight := 640;
  OnCloseQuery := FormCloseQueried;
  OnClose := FormClosed;
  OnMouseWheel := FormWheel;
  FGridSource := TBitmap.Create;
  FGridSource.PixelFormat := pf32bit;
  FPreviewSource := TBitmap.Create;
  FPreviewSource.PixelFormat := pf32bit;
  BuildGrid;
  BuildRightPanel;
  BuildTopPanel;
  BuildMenus;
end;

destructor TFontEditorForm.Destroy;
begin
  // the presenter holds interfaces to this window: it goes first
  FreeAndNil(FPresenter);
  FreeAndNil(FGridSource);
  FreeAndNil(FPreviewSource);
  inherited Destroy;
end;

function TFontEditorForm.AddItem(const AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent;
  AShortCut: TShortCut): TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := ACaption;
  Result.OnClick := AHandler;
  Result.ShortCut := AShortCut;
  AParent.Add(Result);
end;

function TFontEditorForm.AddButton(const ACaption: string; ALeft: Integer; AHandler: TNotifyEvent;
  AToggle: Boolean): TSpeedButton;
begin
  Result := TSpeedButton.Create(Self);
  Result.Parent := FTopPanel;
  Result.SetBounds(ALeft, 8, 28, 24);
  Result.Caption := ACaption;
  Result.OnClick := AHandler;
  if AToggle then
  begin
    Result.AllowAllUp := True;
    Result.GroupIndex := ALeft;
  end;
end;

function TFontEditorForm.AddLabel(const AParent: TWinControl; const ACaption: string; ALeft,
  ATop: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, 100, 16);
  Result.Caption := ACaption;
  Result.AutoSize := True;
end;

function TFontEditorForm.AddColorPanel(ALeft: Integer; AHandler: TNotifyEvent): TPanel;
begin
  Result := TPanel.Create(Self);
  Result.Parent := FTopPanel;
  Result.SetBounds(ALeft, 8, 28, 24);
  Result.BevelKind := bkFlat;
  Result.ParentBackground := False;
  Result.Cursor := crHandPoint;
  Result.OnClick := AHandler;
end;

procedure TFontEditorForm.BuildGrid;
begin
  FInfoLabel := TLabel.Create(Self);
  FInfoLabel.Parent := Self;
  FInfoLabel.Align := alBottom;
  FInfoLabel.AlignWithMargins := True;
  FGridScroll := TScrollBox.Create(Self);
  FGridScroll.Parent := Self;
  FGridScroll.Align := alClient;
  FGridPaint := TPaintBox.Create(Self);
  FGridPaint.Parent := FGridScroll;
  FGridPaint.SetBounds(0, 0, 256, 256);
  FGridPaint.OnPaint := GridPaintPaint;
end;

procedure TFontEditorForm.BuildTopPanel;
begin
  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 80;
  FTopPanel.BevelOuter := bvNone;
  FFontCombo := TComboBox.Create(Self);
  FFontCombo.Parent := FTopPanel;
  FFontCombo.SetBounds(8, 9, 200, 24);
  FFontCombo.Style := csDropDownList;
  FFontCombo.DropDownCount := 24;
  FFontCombo.OnChange := FontComboChange;
  FBoldButton := AddButton('B', 216, BoldClick, True);
  FBoldButton.Font.Style := [fsBold];
  FItalicButton := AddButton('I', 248, ItalicClick, True);
  FItalicButton.Font.Style := [fsItalic];
  FUnderlineButton := AddButton('U', 280, UnderlineClick, True);
  FUnderlineButton.Font.Style := [fsUnderline];
  FStrikeOutButton := AddButton('S', 312, StrikeOutClick, True);
  FStrikeOutButton.Font.Style := [fsStrikeOut];
  FSmallerButton := AddButton('A-', 352, SmallerClick, False);
  FBiggerButton := AddButton('A+', 384, BiggerClick, False);
  FSizeLabel := AddLabel(FTopPanel, '8', 418, 13);
  AddLabel(FTopPanel, 'Text', 452, 13);
  FFrontPanel := AddColorPanel(486, FrontColorClick);
  AddLabel(FTopPanel, 'Back', 524, 13);
  FBackPanel := AddColorPanel(558, BackColorClick);
  FWidthLabel := AddLabel(FTopPanel, 'Rect Width: 16', 8, 46);
  FWidthTrack := TTrackBar.Create(Self);
  FWidthTrack.Parent := FTopPanel;
  FWidthTrack.SetBounds(110, 40, 180, 30);
  FWidthTrack.Min := FONT_EDITOR_MIN_CELL;
  FWidthTrack.Max := FONT_EDITOR_MAX_CELL;
  FWidthTrack.OnChange := WidthChange;
  FHeightLabel := AddLabel(FTopPanel, 'Rect Height: 16', 310, 46);
  FHeightTrack := TTrackBar.Create(Self);
  FHeightTrack.Parent := FTopPanel;
  FHeightTrack.SetBounds(420, 40, 180, 30);
  FHeightTrack.Min := FONT_EDITOR_MIN_CELL;
  FHeightTrack.Max := FONT_EDITOR_MAX_CELL;
  FHeightTrack.OnChange := HeightChange;
end;

procedure TFontEditorForm.BuildRightPanel;
const
  PALETTE_CAPTIONS: array[TFontEditorPalette] of string = ('Doom', 'Heretic', 'Hexen', 'Strife', 'Radix',
    'GLSpeed', 'Other');
var
  LPalette: TFontEditorPalette;
begin
  FRightPanel := TPanel.Create(Self);
  FRightPanel.Parent := Self;
  FRightPanel.Align := alRight;
  FRightPanel.Width := 360;
  FRightPanel.BevelOuter := bvNone;
  FPages := TPageControl.Create(Self);
  FPages.Parent := FRightPanel;
  FPages.SetBounds(8, 8, 344, 110);
  FPages.OnChange := PageChange;
  FTextSheet := TTabSheet.Create(FPages);
  FTextSheet.PageControl := FPages;
  FTextSheet.Caption := 'Text';
  FCharactersSheet := TTabSheet.Create(FPages);
  FCharactersSheet.PageControl := FPages;
  FCharactersSheet.Caption := 'Characters';
  FDigitsSheet := TTabSheet.Create(FPages);
  FDigitsSheet.PageControl := FPages;
  FDigitsSheet.Caption := 'Digits';
  AddLabel(FTextSheet, 'The text, and the name of its lump', 8, 8);
  FTextEdit := TEdit.Create(Self);
  FTextEdit.Parent := FTextSheet;
  FTextEdit.SetBounds(8, 32, 320, 24);
  FTextEdit.OnChange := TextChange;
  AddLabel(FCharactersSheet, 'Start of the names of the lumps', 8, 8);
  FCharacterEdit := TEdit.Create(Self);
  FCharacterEdit.Parent := FCharactersSheet;
  FCharacterEdit.SetBounds(8, 32, 320, 24);
  FCharacterEdit.OnChange := CharacterPrefixChange;
  AddLabel(FDigitsSheet, 'Start of the names of the lumps', 8, 8);
  FDigitEdit := TEdit.Create(Self);
  FDigitEdit.Parent := FDigitsSheet;
  FDigitEdit.SetBounds(8, 32, 320, 24);
  FDigitEdit.OnChange := DigitPrefixChange;
  FFixedPitchBox := TCheckBox.Create(Self);
  FFixedPitchBox.Parent := FRightPanel;
  FFixedPitchBox.SetBounds(8, 128, 160, 20);
  FFixedPitchBox.Caption := 'Fixed pitch';
  FFixedPitchBox.OnClick := FixedPitchClick;
  FPerlinBox := TCheckBox.Create(Self);
  FPerlinBox.Parent := FRightPanel;
  FPerlinBox.SetBounds(180, 128, 160, 20);
  FPerlinBox.Caption := 'Perlin noise';
  FPerlinBox.OnClick := PerlinClick;
  FPaletteGroup := TRadioGroup.Create(Self);
  FPaletteGroup.Parent := FRightPanel;
  FPaletteGroup.SetBounds(8, 156, 344, 76);
  FPaletteGroup.Caption := 'Palette';
  FPaletteGroup.Columns := 4;
  for LPalette := Low(TFontEditorPalette) to High(TFontEditorPalette) do
    FPaletteGroup.Items.Add(PALETTE_CAPTIONS[LPalette]);
  FPaletteGroup.OnClick := PaletteClick;
  FExternalEdit := TEdit.Create(Self);
  FExternalEdit.Parent := FRightPanel;
  FExternalEdit.SetBounds(8, 240, 296, 24);
  FExternalEdit.OnChange := ExternalChange;
  FExternalButton := TButton.Create(Self);
  FExternalButton.Parent := FRightPanel;
  FExternalButton.SetBounds(312, 240, 40, 24);
  FExternalButton.Caption := '...';
  FExternalButton.OnClick := ExternalPaletteClick;
  FPreviewPaint := TPaintBox.Create(Self);
  FPreviewPaint.Parent := FRightPanel;
  FPreviewPaint.SetBounds(8, 276, FONT_MAX_PATCH_WIDTH, PREVIEW_HEIGHT);
  FPreviewPaint.OnPaint := PreviewPaintPaint;
  FGenerateButton := TButton.Create(Self);
  FGenerateButton.Parent := FRightPanel;
  FGenerateButton.SetBounds(8, 330, 344, 32);
  FGenerateButton.Caption := 'Generate WAD...';
  FGenerateButton.OnClick := GenerateClick;
end;

procedure TFontEditorForm.BuildMenus;
var
  LEdit: TMenuItem;
  LView: TMenuItem;
  LHelp: TMenuItem;
  LIndex: Integer;
  LItem: TMenuItem;
begin
  FMenu := TMainMenu.Create(Self);
  FFileMenu := TMenuItem.Create(Self);
  FFileMenu.Caption := '&File';
  FMenu.Items.Add(FFileMenu);
  AddItem(FFileMenu, '&New', NewClick, ShortCut(Ord('N'), [ssCtrl]));
  AddItem(FFileMenu, '&Open...', OpenClick, ShortCut(Ord('O'), [ssCtrl]));
  AddItem(FFileMenu, '&Save', SaveClick, ShortCut(Ord('S'), [ssCtrl]));
  AddItem(FFileMenu, 'Save &as...', SaveAsClick);
  AddItem(FFileMenu, '&Export image...', ExportClick);
  FGenerateItem := AddItem(FFileMenu, '&Generate WAD...', GenerateClick, ShortCut(Ord('G'), [ssCtrl]));
  AddItem(FFileMenu, 'Open external &font...', InstallFontClick);
  FRecentSeparator := AddItem(FFileMenu, '-', nil);
  for LIndex := 0 to MAX_RECENT_ITEMS - 1 do
  begin
    FRecentItems[LIndex] := AddItem(FFileMenu, '', RecentClick);
    FRecentItems[LIndex].Tag := LIndex;
    FRecentItems[LIndex].Visible := False;
  end;
  AddItem(FFileMenu, '-', nil);
  AddItem(FFileMenu, '&Close', CloseClick);

  LEdit := TMenuItem.Create(Self);
  LEdit.Caption := '&Edit';
  FMenu.Items.Add(LEdit);
  FUndoItem := AddItem(LEdit, '&Undo', UndoClick, ShortCut(Ord('Z'), [ssCtrl]));
  FRedoItem := AddItem(LEdit, '&Redo', RedoClick, ShortCut(Ord('Y'), [ssCtrl]));

  LView := TMenuItem.Create(Self);
  LView.Caption := '&View';
  FMenu.Items.Add(LView);
  FZoomInItem := AddItem(LView, 'Zoom &in', ZoomInClick, ShortCut(KEY_ADD, [ssCtrl]));
  FZoomOutItem := AddItem(LView, 'Zoom &out', ZoomOutClick, ShortCut(KEY_SUBTRACT, [ssCtrl]));
  LItem := AddItem(LView, '&Grid', GridClick, ShortCut(Ord('D'), [ssCtrl]));
  LItem.AutoCheck := False;

  LHelp := TMenuItem.Create(Self);
  LHelp.Caption := '&Help';
  FMenu.Items.Add(LHelp);
  AddItem(LHelp, '&About...', AboutClick);
  Menu := FMenu;
end;

procedure TFontEditorForm.Configure(const AServices: TToolsServices);
begin
  FPresenter := AServices.CreateFontEditor(Self);
end;

procedure TFontEditorForm.Start(const AProjectFile: string);
begin
  FPresenter.Start(AProjectFile);
end;

procedure TFontEditorForm.OpenProject(const AProjectFile: string);
begin
  FPresenter.OpenProject(AProjectFile);
end;

procedure TFontEditorForm.Finish;
begin
  if Assigned(FPresenter) then
    FPresenter.Shutdown;
end;

function TFontEditorForm.CanFinish: Boolean;
begin
  Result := (not Assigned(FPresenter)) or FPresenter.TryClose;
end;

// ---------------------------------------------------------------------------------------------------------------
// what the presenter shows
// ---------------------------------------------------------------------------------------------------------------

function TFontEditorForm.GridScale: Double;
begin
  Result := 1 + 3 * FGridZoom / FONT_EDITOR_MAX_ZOOM;
end;

procedure TFontEditorForm.ShowGrid(const AImage: TFontImage; AShowGrid: Boolean; AZoom, AColumns, ARows: Integer);
var
  LBitmap: TBitmap;
begin
  FGridLines := AShowGrid;
  FGridZoom := AZoom;
  FGridColumns := AColumns;
  FGridRows := ARows;
  if (AImage.Width > 0) and (AImage.Height > 0) then
  begin
    LBitmap := TToolsBitmapPixels.ToBitmap(AImage.Pixels, AImage.Width, AImage.Height);
    try
      FGridSource.Assign(LBitmap);
    finally
      LBitmap.Free;
    end;
  end
  else
    FGridSource.SetSize(0, 0);
  FGridPaint.SetBounds(0, 0, Round(FGridSource.Width * GridScale), Round(FGridSource.Height * GridScale));
  FGridPaint.Invalidate;
end;

procedure TFontEditorForm.ShowPreview(const AImage: TFontImage);
var
  LBitmap: TBitmap;
begin
  if (AImage.Width > 0) and (AImage.Height > 0) then
  begin
    LBitmap := TToolsBitmapPixels.ToBitmap(AImage.Pixels, AImage.Width, AImage.Height);
    try
      FPreviewSource.Assign(LBitmap);
    finally
      LBitmap.Free;
    end;
  end
  else
    FPreviewSource.SetSize(0, 0);
  FPreviewPaint.Height := Max(PREVIEW_HEIGHT, AImage.Height);
  FPreviewPaint.Invalidate;
end;

procedure TFontEditorForm.ShowTitle(const ATitle: string);
begin
  Caption := ATitle;
end;

procedure TFontEditorForm.ShowDisplay(const ADisplay: TFontEditorDisplay);
begin
  FDisplay := ADisplay;
  FUpdating := True;
  try
    FFontCombo.ItemIndex := FFontCombo.Items.IndexOf(ADisplay.FontName);
    FBoldButton.Down := ADisplay.Bold;
    FItalicButton.Down := ADisplay.Italic;
    FUnderlineButton.Down := ADisplay.Underline;
    FStrikeOutButton.Down := ADisplay.StrikeOut;
    FSizeLabel.Caption := IntToStr(ADisplay.FontSize);
    FFrontPanel.Color := TColor(ADisplay.FrontColor);
    FBackPanel.Color := TColor(ADisplay.BackColor);
    FWidthTrack.Position := ADisplay.DrawWidth;
    FHeightTrack.Position := ADisplay.DrawHeight;
    FWidthLabel.Caption := Format('Rect Width: %d', [ADisplay.DrawWidth]);
    FHeightLabel.Caption := Format('Rect Height: %d', [ADisplay.DrawHeight]);
    FInfoLabel.Caption := ADisplay.Info;
    FPages.ActivePageIndex := Ord(ADisplay.Kind);
    if FTextEdit.Text <> ADisplay.Text then
      FTextEdit.Text := ADisplay.Text;
    if FCharacterEdit.Text <> ADisplay.CharacterPrefix then
      FCharacterEdit.Text := ADisplay.CharacterPrefix;
    if FDigitEdit.Text <> ADisplay.DigitPrefix then
      FDigitEdit.Text := ADisplay.DigitPrefix;
    FFixedPitchBox.Checked := ADisplay.FixedPitch;
    FPerlinBox.Checked := ADisplay.PerlinNoise;
    FPaletteGroup.ItemIndex := Ord(ADisplay.Palette);
    if FExternalEdit.Text <> ADisplay.ExternalPalette then
      FExternalEdit.Text := ADisplay.ExternalPalette;
  finally
    FUpdating := False;
  end;
  FPreviewPaint.Invalidate;
end;

procedure TFontEditorForm.ShowState(const AState: TFontEditorState);
begin
  FUndoItem.Enabled := AState.CanUndo;
  FRedoItem.Enabled := AState.CanRedo;
  FZoomInItem.Enabled := AState.CanZoomIn;
  FZoomOutItem.Enabled := AState.CanZoomOut;
  FGenerateItem.Enabled := AState.CanGenerate;
  FGenerateButton.Enabled := AState.CanGenerate;
  FExternalEdit.Visible := AState.ExternalPaletteVisible;
  FExternalButton.Visible := AState.ExternalPaletteVisible;
end;

procedure TFontEditorForm.ShowRecentFiles(const ACaptions: TArray<string>);
var
  LIndex: Integer;
begin
  FRecentSeparator.Visible := Length(ACaptions) > 0;
  for LIndex := 0 to MAX_RECENT_ITEMS - 1 do
    if LIndex < Length(ACaptions) then
    begin
      FRecentItems[LIndex].Caption := ACaptions[LIndex];
      FRecentItems[LIndex].Visible := True;
    end
    else
      FRecentItems[LIndex].Visible := False;
end;

procedure TFontEditorForm.ShowFontNames(const ANames: TArray<string>);
var
  LName: string;
begin
  FUpdating := True;
  try
    FFontCombo.Items.BeginUpdate;
    try
      FFontCombo.Items.Clear;
      for LName in ANames do
        FFontCombo.Items.Add(LName);
    finally
      FFontCombo.Items.EndUpdate;
    end;
    FFontCombo.ItemIndex := FFontCombo.Items.IndexOf(FDisplay.FontName);
  finally
    FUpdating := False;
  end;
end;

procedure TFontEditorForm.CloseWindow;
begin
  Hide;
end;

procedure TFontEditorForm.GridPaintPaint(ASender: TObject);
var
  LColumn: Integer;
  LRow: Integer;
  LStep: Double;
begin
  if FGridSource.Width = 0 then
    Exit;
  FGridPaint.Canvas.StretchDraw(Rect(0, 0, FGridPaint.Width, FGridPaint.Height), FGridSource);
  if FGridLines and (FGridColumns > 0) and (FGridRows > 0) then
  begin
    FGridPaint.Canvas.Pen.Style := psSolid;
    FGridPaint.Canvas.Pen.Color := TColor($80A0A0);
    LStep := FGridPaint.Width / FGridColumns;
    for LColumn := 1 to FGridColumns - 1 do
    begin
      FGridPaint.Canvas.MoveTo(Round(LColumn * LStep) - 1, 0);
      FGridPaint.Canvas.LineTo(Round(LColumn * LStep) - 1, FGridPaint.Height);
    end;
    LStep := FGridPaint.Height / FGridRows;
    for LRow := 1 to FGridRows - 1 do
    begin
      FGridPaint.Canvas.MoveTo(0, Round(LRow * LStep) - 1);
      FGridPaint.Canvas.LineTo(FGridPaint.Width, Round(LRow * LStep) - 1);
    end;
  end;
end;

procedure TFontEditorForm.PreviewPaintPaint(ASender: TObject);
begin
  FPreviewPaint.Canvas.Brush.Color := TColor(FDisplay.BackColor);
  FPreviewPaint.Canvas.FillRect(Rect(0, 0, FPreviewPaint.Width, FPreviewPaint.Height));
  if FPreviewSource.Width > 0 then
    FPreviewPaint.Canvas.Draw(0, 0, FPreviewSource);
end;

// ---------------------------------------------------------------------------------------------------------------
// what the user does
// ---------------------------------------------------------------------------------------------------------------

procedure TFontEditorForm.NewClick(ASender: TObject);
begin
  FPresenter.NewDocument;
end;

procedure TFontEditorForm.OpenClick(ASender: TObject);
begin
  FPresenter.OpenFile;
end;

procedure TFontEditorForm.RecentClick(ASender: TObject);
begin
  FPresenter.OpenRecent((ASender as TMenuItem).Tag);
end;

procedure TFontEditorForm.SaveClick(ASender: TObject);
begin
  FPresenter.Save;
end;

procedure TFontEditorForm.SaveAsClick(ASender: TObject);
begin
  FPresenter.SaveAs;
end;

procedure TFontEditorForm.ExportClick(ASender: TObject);
begin
  FPresenter.ExportImage;
end;

procedure TFontEditorForm.GenerateClick(ASender: TObject);
begin
  FPresenter.GenerateWad;
end;

procedure TFontEditorForm.InstallFontClick(ASender: TObject);
begin
  FPresenter.InstallFont;
end;

procedure TFontEditorForm.CloseClick(ASender: TObject);
begin
  Close;
end;

procedure TFontEditorForm.UndoClick(ASender: TObject);
begin
  FPresenter.Undo;
end;

procedure TFontEditorForm.RedoClick(ASender: TObject);
begin
  FPresenter.Redo;
end;

procedure TFontEditorForm.ZoomInClick(ASender: TObject);
begin
  FPresenter.ZoomIn;
end;

procedure TFontEditorForm.ZoomOutClick(ASender: TObject);
begin
  FPresenter.ZoomOut;
end;

procedure TFontEditorForm.GridClick(ASender: TObject);
begin
  FPresenter.ToggleGrid;
  (ASender as TMenuItem).Checked := FPresenter.ShowGridLines;
end;

procedure TFontEditorForm.AboutClick(ASender: TObject);
begin
  FPresenter.About;
end;

procedure TFontEditorForm.FontComboChange(ASender: TObject);
begin
  if (not FUpdating) and (FFontCombo.ItemIndex >= 0) then
    FPresenter.SelectFontName(FFontCombo.Items[FFontCombo.ItemIndex]);
end;

procedure TFontEditorForm.BoldClick(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetBold(FBoldButton.Down);
end;

procedure TFontEditorForm.ItalicClick(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetItalic(FItalicButton.Down);
end;

procedure TFontEditorForm.UnderlineClick(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetUnderline(FUnderlineButton.Down);
end;

procedure TFontEditorForm.StrikeOutClick(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetStrikeOut(FStrikeOutButton.Down);
end;

procedure TFontEditorForm.SmallerClick(ASender: TObject);
begin
  FPresenter.MakeSmaller;
end;

procedure TFontEditorForm.BiggerClick(ASender: TObject);
begin
  FPresenter.MakeBigger;
end;

procedure TFontEditorForm.FrontColorClick(ASender: TObject);
begin
  FPresenter.ChooseFrontColor;
end;

procedure TFontEditorForm.BackColorClick(ASender: TObject);
begin
  FPresenter.ChooseBackColor;
end;

procedure TFontEditorForm.WidthChange(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetDrawWidth(FWidthTrack.Position);
end;

procedure TFontEditorForm.HeightChange(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetDrawHeight(FHeightTrack.Position);
end;

procedure TFontEditorForm.PageChange(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetKind(TFontSequenceKind(FPages.ActivePageIndex));
end;

procedure TFontEditorForm.TextChange(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetText(FTextEdit.Text);
end;

procedure TFontEditorForm.CharacterPrefixChange(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetCharacterPrefix(FCharacterEdit.Text);
end;

procedure TFontEditorForm.DigitPrefixChange(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetDigitPrefix(FDigitEdit.Text);
end;

procedure TFontEditorForm.FixedPitchClick(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetFixedPitch(FFixedPitchBox.Checked);
end;

procedure TFontEditorForm.PerlinClick(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetPerlinNoise(FPerlinBox.Checked);
end;

procedure TFontEditorForm.PaletteClick(ASender: TObject);
begin
  if (not FUpdating) and (FPaletteGroup.ItemIndex >= 0) then
    FPresenter.SelectPalette(TFontEditorPalette(FPaletteGroup.ItemIndex));
end;

procedure TFontEditorForm.ExternalChange(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SetExternalPalette(FExternalEdit.Text);
end;

procedure TFontEditorForm.ExternalPaletteClick(ASender: TObject);
begin
  FPresenter.ChooseExternalPalette;
end;

procedure TFontEditorForm.FormCloseQueried(ASender: TObject; var ACanClose: Boolean);
begin
  // the window is hidden and not closed: a project with changes is asked about when the program ends
  ACanClose := True;
end;

procedure TFontEditorForm.FormClosed(ASender: TObject; var AAction: TCloseAction);
begin
  AAction := caHide;
end;

procedure TFontEditorForm.FormWheel(ASender: TObject; AShift: TShiftState; AWheelDelta: Integer;
  AMousePos: TPoint; var AHandled: Boolean);
begin
  if (not Assigned(FPresenter)) or (not (ssCtrl in AShift)) then
    Exit;
  if AWheelDelta > 0 then
    FPresenter.ZoomIn
  else
    FPresenter.ZoomOut;
  AHandled := True;
end;

end.

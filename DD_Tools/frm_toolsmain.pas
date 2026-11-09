{******************************************************************************}
{                                                                              }
{  DD_Tools: the main window of the tools                                       }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit frm_toolsmain;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  Vcl.Controls, Vcl.Forms, Vcl.Menus, Vcl.ComCtrls, Vcl.ExtCtrls,
  DelphiDoom.EndoomEditor.Types,
  DelphiDoom.EndoomEditor.Intf,
  DelphiDoom.EndoomEditor.Presenter,
  DelphiDoom.Tools.Composition,
  DelphiDoom.Tools.Vcl.EndoomPanel,
  frm_fonteditor;

type
  /// <summary>
  ///   The window of DD_Tools: a menu, a page for each tool (today the endoom editor, ENDEDIT) and a status bar. It
  ///   draws, takes the mouse, the keys and the menus and tells the presenter; the presenter decides. It has no .dfm:
  ///   the controls are made here, so that the file stays short. The wheel of the mouse zooms with Ctrl held
  /// </summary>
  TToolsMainForm = class(TForm, IEndoomEditorView)
  strict private
    const
      MAX_RECENT_ITEMS = 10;
  strict private
    FServices: TToolsServices;
    FPresenter: TEndoomEditorPresenter;
    FPages: TPageControl;
    FEndoomSheet: TTabSheet;
    FPanel: TEndoomEditorPanel;
    FFontForm: TFontEditorForm;
    FStatusBar: TStatusBar;
    FMenu: TMainMenu;
    FFileMenu: TMenuItem;
    FRecentSeparator: TMenuItem;
    FRecentItems: array[0..MAX_RECENT_ITEMS - 1] of TMenuItem;
    FUndoItem: TMenuItem;
    FRedoItem: TMenuItem;
    FPasteItem: TMenuItem;
    FSelectionItems: TArray<TMenuItem>;
    FPasteSelectionItem: TMenuItem;
    FZoomInItem: TMenuItem;
    FZoomOutItem: TMenuItem;
    FBlinkTimer: TTimer;
    FCursorTimer: TTimer;
    FClosing: Boolean;
    function AddItem(const AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent;
      AShortCut: TShortCut = 0): TMenuItem;
    procedure BuildMenus;
    procedure BuildControls;
    procedure NewClick(ASender: TObject);
    procedure OpenClick(ASender: TObject);
    procedure RecentClick(ASender: TObject);
    procedure SaveClick(ASender: TObject);
    procedure SaveAsClick(ASender: TObject);
    procedure ExportClick(ASender: TObject);
    procedure ExitClick(ASender: TObject);
    procedure UndoClick(ASender: TObject);
    procedure RedoClick(ASender: TObject);
    procedure CutClick(ASender: TObject);
    procedure CopyClick(ASender: TObject);
    procedure PasteClick(ASender: TObject);
    procedure SelectAllClick(ASender: TObject);
    procedure DeselectClick(ASender: TObject);
    procedure CopySelectionClick(ASender: TObject);
    procedure CutSelectionClick(ASender: TObject);
    procedure PasteSelectionClick(ASender: TObject);
    procedure DeleteSelectionClick(ASender: TObject);
    procedure FillSelectionClick(ASender: TObject);
    procedure ZoomInClick(ASender: TObject);
    procedure ZoomOutClick(ASender: TObject);
    procedure GridClick(ASender: TObject);
    procedure AboutClick(ASender: TObject);
    procedure FontEditorClick(ASender: TObject);
    procedure BlinkTimerTick(ASender: TObject);
    procedure CursorTimerTick(ASender: TObject);
    procedure FormKeyPressed(ASender: TObject; var AKey: Char);
    procedure FormKeyPressedDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
    procedure FormCloseQueried(ASender: TObject; var ACanClose: Boolean);
    procedure FormClosed(ASender: TObject; var AAction: TCloseAction);
    procedure FormWheel(ASender: TObject; AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint;
      var AHandled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>The composition root gives the window what it needs; the window owns the services from here on</summary>
    procedure Configure(const AServices: TToolsServices);
    /// <summary>The window is shown: the file of the command line is opened (or an empty screen is made)</summary>
    procedure Start(const ACommandLineFile: string);
    /// <summary>The font editor is shown in its own window (made the first time); a project can be opened in it</summary>
    procedure ShowFontEditor(const AProjectFile: string);

    // IEndoomEditorView
    procedure ShowPicture(const APixels: TArray<Cardinal>; const AOverlay: TEndoomEditorOverlay);
    procedure ShowTitle(const ATitle: string);
    procedure ShowStatus(const AText: string);
    procedure ShowState(const AState: TEndoomEditorState);
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    procedure ShowChoices(ATool: TEndoomEditorTool; AForeground, ABackground, ASpecial1, ASpecial2: Integer);
    procedure CloseWindow;
  end;

var
  ToolsMainForm: TToolsMainForm;

implementation

uses
  Winapi.Windows,
  Vcl.Dialogs;

{ TToolsMainForm }

constructor TToolsMainForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := ENDOOM_EDITOR_TITLE;
  Position := poScreenCenter;
  ClientWidth := 1180;
  ClientHeight := 620;
  KeyPreview := True;
  OnKeyPress := FormKeyPressed;
  OnKeyDown := FormKeyPressedDown;
  OnCloseQuery := FormCloseQueried;
  OnClose := FormClosed;
  OnMouseWheel := FormWheel;
  BuildControls;
  BuildMenus;
end;

destructor TToolsMainForm.Destroy;
begin
  // the presenters hold interfaces to the windows: they go first
  FreeAndNil(FFontForm);
  FreeAndNil(FPresenter);
  FreeAndNil(FServices);
  inherited Destroy;
end;

function TToolsMainForm.AddItem(const AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent;
  AShortCut: TShortCut): TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := ACaption;
  Result.OnClick := AHandler;
  Result.ShortCut := AShortCut;
  AParent.Add(Result);
end;

procedure TToolsMainForm.BuildControls;
begin
  FStatusBar := TStatusBar.Create(Self);
  FStatusBar.Parent := Self;
  FStatusBar.SimplePanel := True;
  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alClient;
  FEndoomSheet := TTabSheet.Create(FPages);
  FEndoomSheet.PageControl := FPages;
  FEndoomSheet.Caption := 'Endoom';
  FPanel := TEndoomEditorPanel.Create(Self);
  FPanel.Parent := FEndoomSheet;
  FBlinkTimer := TTimer.Create(Self);
  FBlinkTimer.Interval := 500;
  FBlinkTimer.OnTimer := BlinkTimerTick;
  FCursorTimer := TTimer.Create(Self);
  FCursorTimer.Interval := 300;
  FCursorTimer.OnTimer := CursorTimerTick;
end;

procedure TToolsMainForm.BuildMenus;
var
  LEdit: TMenuItem;
  LView: TMenuItem;
  LTools: TMenuItem;
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
  FRecentSeparator := AddItem(FFileMenu, '-', nil);
  for LIndex := 0 to MAX_RECENT_ITEMS - 1 do
  begin
    FRecentItems[LIndex] := AddItem(FFileMenu, '', RecentClick);
    FRecentItems[LIndex].Tag := LIndex;
    FRecentItems[LIndex].Visible := False;
  end;
  AddItem(FFileMenu, '-', nil);
  AddItem(FFileMenu, 'E&xit', ExitClick);

  LEdit := TMenuItem.Create(Self);
  LEdit.Caption := '&Edit';
  FMenu.Items.Add(LEdit);
  FUndoItem := AddItem(LEdit, '&Undo', UndoClick, ShortCut(Ord('Z'), [ssCtrl]));
  FRedoItem := AddItem(LEdit, '&Redo', RedoClick, ShortCut(Ord('Y'), [ssCtrl]));
  AddItem(LEdit, '-', nil);
  AddItem(LEdit, 'Cu&t picture', CutClick, ShortCut(Ord('X'), [ssCtrl]));
  AddItem(LEdit, '&Copy picture', CopyClick, ShortCut(Ord('C'), [ssCtrl]));
  FPasteItem := AddItem(LEdit, '&Paste picture or text', PasteClick, ShortCut(Ord('V'), [ssCtrl]));
  AddItem(LEdit, '-', nil);
  AddItem(LEdit, 'Select &all', SelectAllClick, ShortCut(Ord('A'), [ssCtrl]));
  SetLength(FSelectionItems, 5);
  FSelectionItems[0] := AddItem(LEdit, 'Dese&lect', DeselectClick);
  FSelectionItems[1] := AddItem(LEdit, 'Copy cells', CopySelectionClick, ShortCut(Ord('C'), [ssCtrl, ssShift]));
  FSelectionItems[2] := AddItem(LEdit, 'Cut cells', CutSelectionClick, ShortCut(Ord('X'), [ssCtrl, ssShift]));
  FSelectionItems[3] := AddItem(LEdit, 'Clear cells', DeleteSelectionClick);
  FSelectionItems[4] := AddItem(LEdit, 'Fill cells with the background', FillSelectionClick);
  FPasteSelectionItem := AddItem(LEdit, 'Paste cells', PasteSelectionClick, ShortCut(Ord('V'), [ssCtrl, ssShift]));

  LView := TMenuItem.Create(Self);
  LView.Caption := '&View';
  FMenu.Items.Add(LView);
  FZoomInItem := AddItem(LView, 'Zoom &in', ZoomInClick, ShortCut(VK_ADD, [ssCtrl]));
  FZoomOutItem := AddItem(LView, 'Zoom &out', ZoomOutClick, ShortCut(VK_SUBTRACT, [ssCtrl]));
  LItem := AddItem(LView, '&Grid', GridClick, ShortCut(Ord('G'), [ssCtrl]));
  LItem.AutoCheck := False;

  LTools := TMenuItem.Create(Self);
  LTools.Caption := '&Tools';
  FMenu.Items.Add(LTools);
  AddItem(LTools, '&Font creator...', FontEditorClick);

  LHelp := TMenuItem.Create(Self);
  LHelp.Caption := '&Help';
  FMenu.Items.Add(LHelp);
  AddItem(LHelp, '&About...', AboutClick);
  Menu := FMenu;
end;

procedure TToolsMainForm.Configure(const AServices: TToolsServices);
var
  LFont: TBytes;
begin
  FServices := AServices;
  FPresenter := FServices.CreateEndoomEditor(Self, LFont);
  FPanel.Attach(FPresenter, LFont);
end;

procedure TToolsMainForm.Start(const ACommandLineFile: string);
begin
  FPresenter.Start(ACommandLineFile);
end;

procedure TToolsMainForm.ShowFontEditor(const AProjectFile: string);
begin
  if not Assigned(FFontForm) then
  begin
    FFontForm := TFontEditorForm.Create(Self);
    FFontForm.Configure(FServices);
    FFontForm.Start(AProjectFile);
  end
  else if AProjectFile <> '' then
    FFontForm.OpenProject(AProjectFile);
  FFontForm.Show;
  FFontForm.BringToFront;
end;

// ---------------------------------------------------------------------------------------------------------------
// what the presenter shows
// ---------------------------------------------------------------------------------------------------------------

procedure TToolsMainForm.ShowPicture(const APixels: TArray<Cardinal>; const AOverlay: TEndoomEditorOverlay);
begin
  FPanel.ShowPicture(APixels, AOverlay);
end;

procedure TToolsMainForm.ShowTitle(const ATitle: string);
begin
  Caption := ATitle;
end;

procedure TToolsMainForm.ShowStatus(const AText: string);
begin
  FStatusBar.SimpleText := AText;
end;

procedure TToolsMainForm.ShowState(const AState: TEndoomEditorState);
var
  LItem: TMenuItem;
begin
  FUndoItem.Enabled := AState.CanUndo;
  FRedoItem.Enabled := AState.CanRedo;
  FPasteItem.Enabled := AState.CanPaste;
  FZoomInItem.Enabled := AState.CanZoomIn;
  FZoomOutItem.Enabled := AState.CanZoomOut;
  for LItem in FSelectionItems do
    LItem.Enabled := AState.HasSelection;
  FPasteSelectionItem.Enabled := AState.HasBlock;
end;

procedure TToolsMainForm.ShowRecentFiles(const ACaptions: TArray<string>);
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

procedure TToolsMainForm.ShowChoices(ATool: TEndoomEditorTool; AForeground, ABackground, ASpecial1,
  ASpecial2: Integer);
begin
  FPanel.ShowChoices(ATool, AForeground, ABackground, ASpecial1, ASpecial2);
end;

procedure TToolsMainForm.CloseWindow;
begin
  FClosing := True;
  Close;
end;

// ---------------------------------------------------------------------------------------------------------------
// what the user does
// ---------------------------------------------------------------------------------------------------------------

procedure TToolsMainForm.NewClick(ASender: TObject);
begin
  FPresenter.NewDocument;
end;

procedure TToolsMainForm.OpenClick(ASender: TObject);
begin
  FPresenter.OpenFile;
end;

procedure TToolsMainForm.RecentClick(ASender: TObject);
begin
  FPresenter.OpenRecent((ASender as TMenuItem).Tag);
end;

procedure TToolsMainForm.SaveClick(ASender: TObject);
begin
  FPresenter.Save;
end;

procedure TToolsMainForm.SaveAsClick(ASender: TObject);
begin
  FPresenter.SaveAs;
end;

procedure TToolsMainForm.ExportClick(ASender: TObject);
begin
  FPresenter.ExportImage;
end;

procedure TToolsMainForm.ExitClick(ASender: TObject);
begin
  FPresenter.RequestClose;
end;

procedure TToolsMainForm.UndoClick(ASender: TObject);
begin
  FPresenter.Undo;
end;

procedure TToolsMainForm.RedoClick(ASender: TObject);
begin
  FPresenter.Redo;
end;

procedure TToolsMainForm.CutClick(ASender: TObject);
begin
  FPresenter.CutImage;
end;

procedure TToolsMainForm.CopyClick(ASender: TObject);
begin
  FPresenter.CopyImage;
end;

procedure TToolsMainForm.PasteClick(ASender: TObject);
begin
  FPresenter.Paste;
end;

procedure TToolsMainForm.SelectAllClick(ASender: TObject);
begin
  FPresenter.SelectAll;
end;

procedure TToolsMainForm.DeselectClick(ASender: TObject);
begin
  FPresenter.ClearSelection;
end;

procedure TToolsMainForm.CopySelectionClick(ASender: TObject);
begin
  FPresenter.CopySelection;
end;

procedure TToolsMainForm.CutSelectionClick(ASender: TObject);
begin
  FPresenter.CutSelection;
end;

procedure TToolsMainForm.PasteSelectionClick(ASender: TObject);
begin
  FPresenter.PasteSelection;
end;

procedure TToolsMainForm.DeleteSelectionClick(ASender: TObject);
begin
  FPresenter.DeleteSelection;
end;

procedure TToolsMainForm.FillSelectionClick(ASender: TObject);
begin
  FPresenter.FillSelection;
end;

procedure TToolsMainForm.ZoomInClick(ASender: TObject);
begin
  FPresenter.ZoomIn;
end;

procedure TToolsMainForm.ZoomOutClick(ASender: TObject);
begin
  FPresenter.ZoomOut;
end;

procedure TToolsMainForm.GridClick(ASender: TObject);
begin
  FPresenter.ToggleGrid;
  (ASender as TMenuItem).Checked := FPresenter.ShowGrid;
end;

procedure TToolsMainForm.AboutClick(ASender: TObject);
begin
  FPresenter.About;
end;

procedure TToolsMainForm.FontEditorClick(ASender: TObject);
begin
  ShowFontEditor('');
end;

procedure TToolsMainForm.BlinkTimerTick(ASender: TObject);
begin
  if Assigned(FPresenter) then
    FPresenter.BlinkTick;
end;

procedure TToolsMainForm.CursorTimerTick(ASender: TObject);
begin
  if Assigned(FPresenter) then
    FPresenter.CursorTick;
end;

procedure TToolsMainForm.FormKeyPressed(ASender: TObject; var AKey: Char);
begin
  if Assigned(FPresenter) and (FPresenter.Tool = eetText) then
  begin
    FPresenter.KeyPress(AKey);
    AKey := #0;
  end;
end;

procedure TToolsMainForm.FormKeyPressedDown(ASender: TObject; var AKey: Word; AShift: TShiftState);
var
  LKey: TEndoomEditorKey;
begin
  if (not Assigned(FPresenter)) or (FPresenter.Tool <> eetText) or (AShift <> []) then
    Exit;
  case AKey of
    VK_LEFT:
      LKey := eekLeft;
    VK_RIGHT:
      LKey := eekRight;
    VK_UP:
      LKey := eekUp;
    VK_DOWN:
      LKey := eekDown;
    VK_HOME:
      LKey := eekHome;
    VK_END:
      LKey := eekEnd;
    VK_PRIOR:
      LKey := eekPageUp;
    VK_NEXT:
      LKey := eekPageDown;
    VK_DELETE:
      LKey := eekDelete;
  else
    Exit;
  end;
  FPresenter.KeyDown(LKey);
  AKey := 0;
end;

procedure TToolsMainForm.FormCloseQueried(ASender: TObject; var ACanClose: Boolean);
begin
  ACanClose := FClosing or (not Assigned(FPresenter)) or FPresenter.TryClose;
  if ACanClose and Assigned(FFontForm) and (not FClosing) then
    ACanClose := FFontForm.CanFinish;
end;

procedure TToolsMainForm.FormClosed(ASender: TObject; var AAction: TCloseAction);
begin
  if Assigned(FPresenter) then
    FPresenter.Shutdown;
  if Assigned(FFontForm) then
    FFontForm.Finish;
end;

procedure TToolsMainForm.FormWheel(ASender: TObject; AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint;
  var AHandled: Boolean);
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

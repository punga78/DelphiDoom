{******************************************************************************}
{                                                                              }
{  DD_Tools: the window of the voxel editor                                     }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit frm_voxeleditor;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  Vcl.Controls, Vcl.Forms, Vcl.Menus, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons, Vcl.Graphics,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Intf,
  DelphiDoom.VoxelEditor.Presenter,
  DelphiDoom.Tools.Composition;

type
  /// <summary>
  ///   The window of the voxel editor (DD_VOXEL): the plane that is edited in the middle (a slice of the cube, or one
  ///   of its six views) drawn cell by cell, the tools and the two colors on top, the palette on the right. It draws,
  ///   takes the mouse and the menus and tells the presenter; the presenter decides. It has no .dfm: the controls are
  ///   made here. The window is hidden when it is closed and shown again by the menu of the tools; the main window
  ///   closes it for good. The OpenGL view of the 3D voxel, the export of sprites, the LDraw import and the macros of
  ///   the old program are not in this window
  /// </summary>
  TVoxelEditorForm = class(TForm, IVoxelEditorView)
  strict private
    const
      MAX_RECENT_ITEMS = 10;
      SWATCH = 12;
      SWATCH_COLUMNS = 16;
  strict private
    FPresenter: TVoxelEditorPresenter;
    FUpdating: Boolean;
    FImage: TVoxelEditorImage;
    FSize: Integer;
    FZoom: Integer;
    FPalette: TVoxelEditorPalette;
    FMenu: TMainMenu;
    FFileMenu: TMenuItem;
    FRecentSeparator: TMenuItem;
    FRecentItems: array[0..MAX_RECENT_ITEMS - 1] of TMenuItem;
    FUndoItem: TMenuItem;
    FRedoItem: TMenuItem;
    FToolbar: TPanel;
    FToolButtons: array[TVoxelEditorTool] of TSpeedButton;
    FColor1Panel: TPanel;
    FColor2Panel: TPanel;
    FPlaneCombo: TComboBox;
    FRightPanel: TPanel;
    FPalettePaint: TPaintBox;
    FScroll: TScrollBox;
    FPlanePaint: TPaintBox;
    FStatus: TStatusBar;
    function AddItem(const AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent;
      AShortCut: TShortCut = 0; ATag: Integer = 0): TMenuItem;
    function AddSubMenu(const AParent: TMenuItem; const ACaption: string): TMenuItem;
    function AddToolButton(ATool: TVoxelEditorTool; const ACaption: string; ALeft: Integer): TSpeedButton;
    procedure BuildMenus;
    procedure BuildToolbar;
    procedure BuildCenter;
    procedure BuildRight;
    procedure NewClick(ASender: TObject);
    procedure OpenClick(ASender: TObject);
    procedure RecentClick(ASender: TObject);
    procedure SaveClick(ASender: TObject);
    procedure SaveAsClick(ASender: TObject);
    procedure ImportKvxClick(ASender: TObject);
    procedure ImportVoxClick(ASender: TObject);
    procedure ImportDdmeshClick(ASender: TObject);
    procedure ExportVoxClick(ASender: TObject);
    procedure ExportMeshClick(ASender: TObject);
    procedure ExportPlaneClick(ASender: TObject);
    procedure ExportViewClick(ASender: TObject);
    procedure ConvertClick(ASender: TObject);
    procedure CloseClick(ASender: TObject);
    procedure UndoClick(ASender: TObject);
    procedure RedoClick(ASender: TObject);
    procedure CutClick(ASender: TObject);
    procedure CopyClick(ASender: TObject);
    procedure PasteClick(ASender: TObject);
    procedure ClearClick(ASender: TObject);
    procedure CopyViewClick(ASender: TObject);
    procedure PasteViewClick(ASender: TObject);
    procedure FlipHorizontalClick(ASender: TObject);
    procedure FlipVerticalClick(ASender: TObject);
    procedure RotateLeftClick(ASender: TObject);
    procedure RotateRightClick(ASender: TObject);
    procedure ImportImageClick(ASender: TObject);
    procedure RemoveNonVisibleClick(ASender: TObject);
    procedure RotateClick(ASender: TObject);
    procedure RotateHqClick(ASender: TObject);
    procedure CropClick(ASender: TObject);
    procedure ShrinkClick(ASender: TObject);
    procedure HeightmapClick(ASender: TObject);
    procedure TerrainClick(ASender: TObject);
    procedure CountColorsClick(ASender: TObject);
    procedure GrayScaleClick(ASender: TObject);
    procedure ConvertPaletteClick(ASender: TObject);
    procedure GamePaletteClick(ASender: TObject);
    procedure ViewClick(ASender: TObject);
    procedure SliceClick(ASender: TObject);
    procedure LevelUpClick(ASender: TObject);
    procedure LevelDownClick(ASender: TObject);
    procedure ZoomInClick(ASender: TObject);
    procedure ZoomOutClick(ASender: TObject);
    procedure AboutClick(ASender: TObject);
    procedure ToolClick(ASender: TObject);
    procedure Color1Click(ASender: TObject);
    procedure Color2Click(ASender: TObject);
    procedure PlaneComboChange(ASender: TObject);
    procedure PlanePaintPaint(ASender: TObject);
    procedure PlanePaintMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure PlanePaintMouseMove(ASender: TObject; AShift: TShiftState; AX, AY: Integer);
    procedure PlanePaintMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure PalettePaintPaint(ASender: TObject);
    procedure PalettePaintMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure FormCloseQueried(ASender: TObject; var ACanClose: Boolean);
    procedure FormClosed(ASender: TObject; var AAction: TCloseAction);
    procedure FormWheel(ASender: TObject; AShift: TShiftState; AWheelDelta: Integer; AMousePos: TPoint;
      var AHandled: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>The composition root makes the presenter for this window; the window owns it from here on</summary>
    procedure Configure(const AServices: TToolsServices);
    /// <summary>The window is shown: the voxel of the command line is opened, or a new one is made</summary>
    procedure Start(const AVoxelFile: string);
    /// <summary>A voxel is opened in a window that is already running</summary>
    procedure OpenVoxel(const AVoxelFile: string);
    /// <summary>The program ends: the settings are saved</summary>
    procedure Finish;
    /// <summary>False if the user cancels the question about the changes that are not saved</summary>
    function CanFinish: Boolean;

    // IVoxelEditorView
    procedure ShowPlane(const AImage: TVoxelEditorImage; ASize, AZoom: Integer);
    procedure ShowTitle(const ATitle: string);
    procedure ShowState(const AState: TVoxelEditorState);
    procedure ShowPalette(const APalette: TVoxelEditorPalette);
    procedure ShowRecentFiles(const ACaptions: TArray<string>);
    procedure ShowPlanes(const ANames: TArray<string>; ASelected: Integer);
    procedure ShowProgress(const AText: string; APercent: Integer);
    procedure CloseWindow;
  end;

implementation

uses
  System.Math;

const
  TOOL_CAPTIONS: array[TVoxelEditorTool] of string = ('Draw', 'Fill', 'Pick', 'Erase', 'Raise');
  // the virtual keys of Windows (Winapi.Windows is not used here: it has a TBitmap and an RGB of its own)
  VK_PRIOR = $21;
  VK_NEXT = $22;
  VK_DELETE = $2E;
  VK_ADD = $6B;
  VK_SUBTRACT = $6D;

function RGB(ARed, AGreen, ABlue: Integer): TColor;
begin
  Result := TColor(ARed or (AGreen shl 8) or (ABlue shl 16));
end;

{ TVoxelEditorForm }

constructor TVoxelEditorForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := VOXEL_EDITOR_TITLE;
  Position := poScreenCenter;
  ClientWidth := 1000;
  ClientHeight := 720;
  KeyPreview := False;
  OnCloseQuery := FormCloseQueried;
  OnClose := FormClosed;
  OnMouseWheel := FormWheel;
  FZoom := 4;
  BuildCenter;
  BuildRight;
  BuildToolbar;
  BuildMenus;
end;

destructor TVoxelEditorForm.Destroy;
begin
  // the presenter holds interfaces to this window: it goes first
  FreeAndNil(FPresenter);
  inherited Destroy;
end;

function TVoxelEditorForm.AddItem(const AParent: TMenuItem; const ACaption: string; AHandler: TNotifyEvent;
  AShortCut: TShortCut; ATag: Integer): TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := ACaption;
  Result.OnClick := AHandler;
  Result.ShortCut := AShortCut;
  Result.Tag := ATag;
  AParent.Add(Result);
end;

function TVoxelEditorForm.AddSubMenu(const AParent: TMenuItem; const ACaption: string): TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := ACaption;
  AParent.Add(Result);
end;

function TVoxelEditorForm.AddToolButton(ATool: TVoxelEditorTool; const ACaption: string; ALeft: Integer): TSpeedButton;
begin
  Result := TSpeedButton.Create(Self);
  Result.Parent := FToolbar;
  Result.SetBounds(ALeft, 8, 52, 28);
  Result.Caption := ACaption;
  Result.GroupIndex := 1;
  Result.Tag := Ord(ATool);
  Result.OnClick := ToolClick;
end;

procedure TVoxelEditorForm.BuildCenter;
begin
  FStatus := TStatusBar.Create(Self);
  FStatus.Parent := Self;
  FStatus.SimplePanel := True;
  FScroll := TScrollBox.Create(Self);
  FScroll.Parent := Self;
  FScroll.Align := alClient;
  FPlanePaint := TPaintBox.Create(Self);
  FPlanePaint.Parent := FScroll;
  FPlanePaint.SetBounds(0, 0, 256, 256);
  FPlanePaint.OnPaint := PlanePaintPaint;
  FPlanePaint.OnMouseDown := PlanePaintMouseDown;
  FPlanePaint.OnMouseMove := PlanePaintMouseMove;
  FPlanePaint.OnMouseUp := PlanePaintMouseUp;
end;

procedure TVoxelEditorForm.BuildRight;
begin
  FRightPanel := TPanel.Create(Self);
  FRightPanel.Parent := Self;
  FRightPanel.Align := alRight;
  FRightPanel.Width := SWATCH * SWATCH_COLUMNS + 16;
  FRightPanel.BevelOuter := bvNone;
  FPalettePaint := TPaintBox.Create(Self);
  FPalettePaint.Parent := FRightPanel;
  FPalettePaint.SetBounds(8, 8, SWATCH * SWATCH_COLUMNS, SWATCH * (256 div SWATCH_COLUMNS));
  FPalettePaint.OnPaint := PalettePaintPaint;
  FPalettePaint.OnMouseDown := PalettePaintMouseDown;
end;

procedure TVoxelEditorForm.BuildToolbar;
var
  LTool: TVoxelEditorTool;
  LLeft: Integer;
  LLabel: TLabel;
begin
  FToolbar := TPanel.Create(Self);
  FToolbar.Parent := Self;
  FToolbar.Align := alTop;
  FToolbar.Height := 44;
  FToolbar.BevelOuter := bvNone;
  LLeft := 8;
  for LTool := Low(TVoxelEditorTool) to High(TVoxelEditorTool) do
  begin
    FToolButtons[LTool] := AddToolButton(LTool, TOOL_CAPTIONS[LTool], LLeft);
    Inc(LLeft, 56);
  end;
  FToolButtons[vetFreeDraw].Down := True;
  Inc(LLeft, 12);
  FColor1Panel := TPanel.Create(Self);
  FColor1Panel.Parent := FToolbar;
  FColor1Panel.SetBounds(LLeft, 8, 28, 28);
  FColor1Panel.ParentBackground := False;
  FColor1Panel.BevelKind := bkFlat;
  FColor1Panel.Cursor := crHandPoint;
  FColor1Panel.OnClick := Color1Click;
  Inc(LLeft, 34);
  FColor2Panel := TPanel.Create(Self);
  FColor2Panel.Parent := FToolbar;
  FColor2Panel.SetBounds(LLeft, 8, 28, 28);
  FColor2Panel.ParentBackground := False;
  FColor2Panel.BevelKind := bkFlat;
  FColor2Panel.Cursor := crHandPoint;
  FColor2Panel.OnClick := Color2Click;
  Inc(LLeft, 44);
  LLabel := TLabel.Create(Self);
  LLabel.Parent := FToolbar;
  LLabel.SetBounds(LLeft, 14, 40, 16);
  LLabel.Caption := 'Plane';
  Inc(LLeft, 44);
  FPlaneCombo := TComboBox.Create(Self);
  FPlaneCombo.Parent := FToolbar;
  FPlaneCombo.SetBounds(LLeft, 10, 120, 24);
  FPlaneCombo.Style := csDropDownList;
  FPlaneCombo.DropDownCount := 24;
  FPlaneCombo.OnChange := PlaneComboChange;
end;

procedure TVoxelEditorForm.BuildMenus;
const
  VIEW_CAPTIONS: array[vevFront..vevDown] of string = ('&Front', '&Back', '&Left', '&Right', '&Top', '&Down');
var
  LIndex: Integer;
  LEdit, LVoxel, LPalette, LView, LHelp, LSub: TMenuItem;
  LViewKind: TVoxelEditorView;
  LAxis: TVoxelEditorAxis;
begin
  FMenu := TMainMenu.Create(Self);
  FFileMenu := AddSubMenu(FMenu.Items, '&File');
  AddItem(FFileMenu, '&New...', NewClick, ShortCut(Ord('N'), [ssCtrl]));
  AddItem(FFileMenu, '&Open...', OpenClick, ShortCut(Ord('O'), [ssCtrl]));
  AddItem(FFileMenu, '&Save', SaveClick, ShortCut(Ord('S'), [ssCtrl]));
  AddItem(FFileMenu, 'Save &as...', SaveAsClick);
  AddItem(FFileMenu, '-', nil);
  LSub := AddSubMenu(FFileMenu, '&Import');
  AddItem(LSub, '&KVX voxel...', ImportKvxClick);
  AddItem(LSub, 'Slab6 &VOX voxel...', ImportVoxClick);
  AddItem(LSub, '&DDMESH...', ImportDdmeshClick);
  AddItem(LSub, '&Heightmap...', HeightmapClick);
  LSub := AddSubMenu(FFileMenu, '&Export');
  AddItem(LSub, 'Slab6 &VOX voxel...', ExportVoxClick);
  AddItem(LSub, '&Optimized mesh (DDMESH)...', ExportMeshClick);
  AddItem(LSub, 'Current &plane as picture...', ExportPlaneClick);
  for LViewKind := vevFront to vevDown do
    AddItem(LSub, VIEW_CAPTIONS[LViewKind] + ' view as picture...', ExportViewClick, 0, Ord(LViewKind));
  LSub := AddSubMenu(FFileMenu, '&Convert files');
  AddItem(LSub, 'KVX to DDMESH...', ConvertClick, 0, Ord(vebKvxToDdmesh));
  AddItem(LSub, 'DDVOX to DDMESH...', ConvertClick, 0, Ord(vebDdvoxToDdmesh));
  AddItem(LSub, 'DDVOX to Slab6 VOX...', ConvertClick, 0, Ord(vebDdvoxToVox));
  FRecentSeparator := AddItem(FFileMenu, '-', nil);
  for LIndex := 0 to MAX_RECENT_ITEMS - 1 do
  begin
    FRecentItems[LIndex] := AddItem(FFileMenu, '', RecentClick);
    FRecentItems[LIndex].Tag := LIndex;
    FRecentItems[LIndex].Visible := False;
  end;
  AddItem(FFileMenu, '-', nil);
  AddItem(FFileMenu, '&Close', CloseClick);

  LEdit := AddSubMenu(FMenu.Items, '&Edit');
  FUndoItem := AddItem(LEdit, '&Undo', UndoClick, ShortCut(Ord('Z'), [ssCtrl]));
  FRedoItem := AddItem(LEdit, '&Redo', RedoClick, ShortCut(Ord('Y'), [ssCtrl]));
  AddItem(LEdit, '-', nil);
  AddItem(LEdit, 'Cu&t', CutClick, ShortCut(Ord('X'), [ssCtrl]));
  AddItem(LEdit, '&Copy', CopyClick, ShortCut(Ord('C'), [ssCtrl]));
  AddItem(LEdit, '&Paste', PasteClick, ShortCut(Ord('V'), [ssCtrl]));
  AddItem(LEdit, 'C&lear', ClearClick, ShortCut(VK_DELETE, []));
  AddItem(LEdit, '-', nil);
  LSub := AddSubMenu(LEdit, 'Co&py view');
  for LViewKind := vevFront to vevDown do
    AddItem(LSub, VIEW_CAPTIONS[LViewKind], CopyViewClick, 0, Ord(LViewKind));
  LSub := AddSubMenu(LEdit, 'Paste vie&w');
  for LViewKind := vevFront to vevDown do
    AddItem(LSub, VIEW_CAPTIONS[LViewKind], PasteViewClick, 0, Ord(LViewKind));
  AddItem(LEdit, '-', nil);
  AddItem(LEdit, 'Flip &horizontally', FlipHorizontalClick);
  AddItem(LEdit, 'Flip &vertically', FlipVerticalClick);
  AddItem(LEdit, 'Rotate &left', RotateLeftClick);
  AddItem(LEdit, 'Rotate ri&ght', RotateRightClick);
  AddItem(LEdit, '-', nil);
  AddItem(LEdit, 'Import &picture...', ImportImageClick);

  LVoxel := AddSubMenu(FMenu.Items, '&Voxel');
  AddItem(LVoxel, 'Remove &non visible voxels', RemoveNonVisibleClick);
  AddItem(LVoxel, '&Rotate...', RotateClick);
  AddItem(LVoxel, 'Rotate &high quality...', RotateHqClick);
  AddItem(LVoxel, '&Crop heightmap...', CropClick);
  AddItem(LVoxel, '&Shrink heightmap...', ShrinkClick);
  AddItem(LVoxel, 'Apply &terrain texture...', TerrainClick);
  AddItem(LVoxel, '-', nil);
  AddItem(LVoxel, 'Count &colors used', CountColorsClick);
  AddItem(LVoxel, '&Greyscale', GrayScaleClick);
  AddItem(LVoxel, 'Convert to 256 colors &palette...', ConvertPaletteClick);

  LPalette := AddSubMenu(FMenu.Items, '&Palette');
  AddItem(LPalette, '&Doom', GamePaletteClick, 0, Ord(vepDoom));
  AddItem(LPalette, '&Heretic', GamePaletteClick, 0, Ord(vepHeretic));
  AddItem(LPalette, 'He&xen', GamePaletteClick, 0, Ord(vepHexen));
  AddItem(LPalette, '&Strife', GamePaletteClick, 0, Ord(vepStrife));
  AddItem(LPalette, '&Radix', GamePaletteClick, 0, Ord(vepRadix));
  AddItem(LPalette, '&Grey scale', GamePaletteClick, 0, Ord(vepOctree));

  LView := AddSubMenu(FMenu.Items, 'Vie&w');
  for LViewKind := vevFront to vevDown do
    AddItem(LView, VIEW_CAPTIONS[LViewKind], ViewClick, 0, Ord(LViewKind));
  AddItem(LView, '-', nil);
  for LAxis := veaX to veaZ do
    AddItem(LView, 'Slice &' + Chr(Ord('x') + Ord(LAxis) - Ord(veaX)), SliceClick, 0, Ord(LAxis));
  AddItem(LView, '-', nil);
  AddItem(LView, 'Level &up', LevelUpClick, ShortCut(VK_PRIOR, []));
  AddItem(LView, 'Level d&own', LevelDownClick, ShortCut(VK_NEXT, []));
  AddItem(LView, '-', nil);
  AddItem(LView, 'Zoom &in', ZoomInClick, ShortCut(VK_ADD, [ssCtrl]));
  AddItem(LView, 'Zoom &out', ZoomOutClick, ShortCut(VK_SUBTRACT, [ssCtrl]));

  LHelp := AddSubMenu(FMenu.Items, '&Help');
  AddItem(LHelp, '&About...', AboutClick);
  Menu := FMenu;
end;

procedure TVoxelEditorForm.Configure(const AServices: TToolsServices);
begin
  FPresenter := AServices.CreateVoxelEditor(Self);
end;

procedure TVoxelEditorForm.Start(const AVoxelFile: string);
begin
  FPresenter.Start(AVoxelFile);
end;

procedure TVoxelEditorForm.OpenVoxel(const AVoxelFile: string);
begin
  FPresenter.OpenVoxel(AVoxelFile);
end;

procedure TVoxelEditorForm.Finish;
begin
  if Assigned(FPresenter) then
    FPresenter.Shutdown;
end;

function TVoxelEditorForm.CanFinish: Boolean;
begin
  Result := (not Assigned(FPresenter)) or FPresenter.TryClose;
end;

// ---------------------------------------------------------------------------------------------------------------
// what the presenter shows
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorForm.ShowPlane(const AImage: TVoxelEditorImage; ASize, AZoom: Integer);
begin
  FImage := AImage;
  FSize := ASize;
  FZoom := AZoom;
  FPlanePaint.SetBounds(0, 0, FSize * FZoom + 1, FSize * FZoom + 1);
  FPlanePaint.Invalidate;
end;

procedure TVoxelEditorForm.ShowTitle(const ATitle: string);
begin
  Caption := ATitle;
end;

procedure TVoxelEditorForm.ShowState(const AState: TVoxelEditorState);
begin
  FUpdating := True;
  try
    FToolButtons[AState.Tool].Down := True;
    FToolButtons[vetElevate].Enabled := AState.CanElevate;
    FColor1Panel.Color := TColor(AState.Color1);
    FColor2Panel.Color := TColor(AState.Color2);
    FUndoItem.Enabled := AState.CanUndo;
    FRedoItem.Enabled := AState.CanRedo;
    FStatus.SimpleText := Format('%s     size %d x %d x %d     zoom %d', [AState.StatusText, AState.Size, AState.Size,
      AState.Size, AState.Zoom]);
  finally
    FUpdating := False;
  end;
end;

procedure TVoxelEditorForm.ShowPalette(const APalette: TVoxelEditorPalette);
begin
  FPalette := APalette;
  FPalettePaint.Invalidate;
end;

procedure TVoxelEditorForm.ShowRecentFiles(const ACaptions: TArray<string>);
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_RECENT_ITEMS - 1 do
  begin
    FRecentItems[LIndex].Visible := LIndex < Length(ACaptions);
    if LIndex < Length(ACaptions) then
      FRecentItems[LIndex].Caption := ACaptions[LIndex];
  end;
  FRecentSeparator.Visible := Length(ACaptions) > 0;
end;

procedure TVoxelEditorForm.ShowPlanes(const ANames: TArray<string>; ASelected: Integer);
var
  LIndex: Integer;
  LSame: Boolean;
begin
  FUpdating := True;
  try
    LSame := FPlaneCombo.Items.Count = Length(ANames);
    if not LSame then
    begin
      FPlaneCombo.Items.BeginUpdate;
      try
        FPlaneCombo.Items.Clear;
        for LIndex := 0 to High(ANames) do
          FPlaneCombo.Items.Add(ANames[LIndex]);
      finally
        FPlaneCombo.Items.EndUpdate;
      end;
    end;
    FPlaneCombo.ItemIndex := ASelected;
  finally
    FUpdating := False;
  end;
end;

procedure TVoxelEditorForm.ShowProgress(const AText: string; APercent: Integer);
begin
  if APercent < 0 then
    FStatus.SimpleText := ''
  else
    FStatus.SimpleText := Format('%s (%d%%)', [AText, APercent]);
  FStatus.Update;
end;

procedure TVoxelEditorForm.CloseWindow;
begin
  Close;
end;

// ---------------------------------------------------------------------------------------------------------------
// drawing
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorForm.PlanePaintPaint(ASender: TObject);
var
  LCanvas: TCanvas;
  LClip: TRect;
  LFirstX, LLastX, LFirstY, LLastY, LX, LY: Integer;
  LColor: Cardinal;
  LCell: TRect;
begin
  LCanvas := FPlanePaint.Canvas;
  if (FSize <= 0) or (Length(FImage) <> FSize * FSize) then
    Exit;
  LClip := LCanvas.ClipRect;
  LFirstX := Max(0, LClip.Left div FZoom);
  LLastX := Min(FSize - 1, LClip.Right div FZoom);
  LFirstY := Max(0, LClip.Top div FZoom);
  LLastY := Min(FSize - 1, LClip.Bottom div FZoom);
  for LX := LFirstX to LLastX do
    for LY := LFirstY to LLastY do
    begin
      LColor := FImage[LX * FSize + LY];
      LCell := Rect(LX * FZoom, LY * FZoom, (LX + 1) * FZoom + 1, (LY + 1) * FZoom + 1);
      if LColor = 0 then
      begin
        // no voxel: a dark cell with a cross
        LCanvas.Brush.Color := RGB(64, 64, 64);
        LCanvas.Pen.Color := clBlack;
        LCanvas.Rectangle(LCell);
        if FZoom >= 6 then
        begin
          LCanvas.Pen.Color := RGB(96, 96, 96);
          LCanvas.MoveTo(LCell.Left + 1, LCell.Top + 1);
          LCanvas.LineTo(LCell.Right - 1, LCell.Bottom - 1);
          LCanvas.MoveTo(LCell.Right - 2, LCell.Top + 1);
          LCanvas.LineTo(LCell.Left, LCell.Bottom - 1);
        end;
      end
      else
      begin
        LCanvas.Brush.Color := TColor(LColor);
        if FZoom >= 4 then
          LCanvas.Pen.Color := RGB(Max(0, Integer(LColor and $FF) - 40), Max(0, Integer((LColor shr 8) and $FF) - 40),
            Max(0, Integer((LColor shr 16) and $FF) - 40))
        else
          LCanvas.Pen.Color := TColor(LColor);
        LCanvas.Rectangle(LCell);
      end;
    end;
end;

procedure TVoxelEditorForm.PalettePaintPaint(ASender: TObject);
var
  LIndex: Integer;
  LRect: TRect;
begin
  for LIndex := 0 to 255 do
  begin
    LRect := Rect((LIndex mod SWATCH_COLUMNS) * SWATCH, (LIndex div SWATCH_COLUMNS) * SWATCH,
      (LIndex mod SWATCH_COLUMNS) * SWATCH + SWATCH, (LIndex div SWATCH_COLUMNS) * SWATCH + SWATCH);
    if FPalette[LIndex] = 0 then
    begin
      FPalettePaint.Canvas.Brush.Color := RGB(64, 64, 64);
      FPalettePaint.Canvas.FillRect(LRect);
      FPalettePaint.Canvas.Pen.Color := clWhite;
      FPalettePaint.Canvas.MoveTo(LRect.Left, LRect.Top);
      FPalettePaint.Canvas.LineTo(LRect.Right, LRect.Bottom);
    end
    else
    begin
      FPalettePaint.Canvas.Brush.Color := TColor(FPalette[LIndex]);
      FPalettePaint.Canvas.FillRect(LRect);
    end;
  end;
end;

// ---------------------------------------------------------------------------------------------------------------
// the mouse and the buttons
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorForm.PlanePaintMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  if AButton = mbLeft then
    FPresenter.MouseDown(vebLeft, AX, AY)
  else if AButton = mbRight then
    FPresenter.MouseDown(vebRight, AX, AY);
end;

procedure TVoxelEditorForm.PlanePaintMouseMove(ASender: TObject; AShift: TShiftState; AX, AY: Integer);
begin
  FPresenter.MouseMove(AX, AY);
end;

procedure TVoxelEditorForm.PlanePaintMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  FPresenter.MouseUp;
end;

procedure TVoxelEditorForm.PalettePaintMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
var
  LIndex: Integer;
begin
  LIndex := (AY div SWATCH) * SWATCH_COLUMNS + AX div SWATCH;
  if AButton = mbLeft then
    FPresenter.PickPaletteColor(LIndex, vebLeft)
  else if AButton = mbRight then
    FPresenter.PickPaletteColor(LIndex, vebRight);
end;

procedure TVoxelEditorForm.ToolClick(ASender: TObject);
begin
  if not FUpdating then
    FPresenter.SelectTool(TVoxelEditorTool((ASender as TSpeedButton).Tag));
end;

procedure TVoxelEditorForm.Color1Click(ASender: TObject);
begin
  FPresenter.ChooseColor(1);
end;

procedure TVoxelEditorForm.Color2Click(ASender: TObject);
begin
  FPresenter.ChooseColor(2);
end;

procedure TVoxelEditorForm.PlaneComboChange(ASender: TObject);
begin
  if (not FUpdating) and (FPlaneCombo.ItemIndex >= 0) then
    FPresenter.SelectPlaneByIndex(FPlaneCombo.ItemIndex);
end;

// ---------------------------------------------------------------------------------------------------------------
// the menus
// ---------------------------------------------------------------------------------------------------------------

procedure TVoxelEditorForm.NewClick(ASender: TObject);
begin
  FPresenter.NewVoxel;
end;

procedure TVoxelEditorForm.OpenClick(ASender: TObject);
begin
  FPresenter.OpenFile;
end;

procedure TVoxelEditorForm.RecentClick(ASender: TObject);
begin
  FPresenter.OpenRecent((ASender as TMenuItem).Tag);
end;

procedure TVoxelEditorForm.SaveClick(ASender: TObject);
begin
  FPresenter.Save;
end;

procedure TVoxelEditorForm.SaveAsClick(ASender: TObject);
begin
  FPresenter.SaveAs;
end;

procedure TVoxelEditorForm.ImportKvxClick(ASender: TObject);
begin
  FPresenter.ImportKvx;
end;

procedure TVoxelEditorForm.ImportVoxClick(ASender: TObject);
begin
  FPresenter.ImportVox;
end;

procedure TVoxelEditorForm.ImportDdmeshClick(ASender: TObject);
begin
  FPresenter.ImportDdmesh;
end;

procedure TVoxelEditorForm.ExportVoxClick(ASender: TObject);
begin
  FPresenter.ExportVox;
end;

procedure TVoxelEditorForm.ExportMeshClick(ASender: TObject);
begin
  FPresenter.ExportMesh;
end;

procedure TVoxelEditorForm.ExportPlaneClick(ASender: TObject);
begin
  FPresenter.ExportPlaneImage;
end;

procedure TVoxelEditorForm.ExportViewClick(ASender: TObject);
begin
  FPresenter.ExportViewImage(TVoxelEditorView((ASender as TMenuItem).Tag));
end;

procedure TVoxelEditorForm.ConvertClick(ASender: TObject);
begin
  FPresenter.ConvertFiles(TVoxelEditorBatch((ASender as TMenuItem).Tag));
end;

procedure TVoxelEditorForm.CloseClick(ASender: TObject);
begin
  FPresenter.RequestClose;
end;

procedure TVoxelEditorForm.UndoClick(ASender: TObject);
begin
  FPresenter.Undo;
end;

procedure TVoxelEditorForm.RedoClick(ASender: TObject);
begin
  FPresenter.Redo;
end;

procedure TVoxelEditorForm.CutClick(ASender: TObject);
begin
  FPresenter.Cut;
end;

procedure TVoxelEditorForm.CopyClick(ASender: TObject);
begin
  FPresenter.Copy;
end;

procedure TVoxelEditorForm.PasteClick(ASender: TObject);
begin
  FPresenter.Paste;
end;

procedure TVoxelEditorForm.ClearClick(ASender: TObject);
begin
  FPresenter.Clear;
end;

procedure TVoxelEditorForm.CopyViewClick(ASender: TObject);
begin
  FPresenter.CopyView(TVoxelEditorView((ASender as TMenuItem).Tag));
end;

procedure TVoxelEditorForm.PasteViewClick(ASender: TObject);
begin
  FPresenter.PasteView(TVoxelEditorView((ASender as TMenuItem).Tag));
end;

procedure TVoxelEditorForm.FlipHorizontalClick(ASender: TObject);
begin
  FPresenter.FlipHorizontal;
end;

procedure TVoxelEditorForm.FlipVerticalClick(ASender: TObject);
begin
  FPresenter.FlipVertical;
end;

procedure TVoxelEditorForm.RotateLeftClick(ASender: TObject);
begin
  FPresenter.RotateLeft;
end;

procedure TVoxelEditorForm.RotateRightClick(ASender: TObject);
begin
  FPresenter.RotateRight;
end;

procedure TVoxelEditorForm.ImportImageClick(ASender: TObject);
begin
  FPresenter.ImportImage;
end;

procedure TVoxelEditorForm.RemoveNonVisibleClick(ASender: TObject);
begin
  FPresenter.RemoveNonVisible;
end;

procedure TVoxelEditorForm.RotateClick(ASender: TObject);
begin
  FPresenter.Rotate;
end;

procedure TVoxelEditorForm.RotateHqClick(ASender: TObject);
begin
  FPresenter.RotateHighQuality;
end;

procedure TVoxelEditorForm.CropClick(ASender: TObject);
begin
  FPresenter.CropHeight;
end;

procedure TVoxelEditorForm.ShrinkClick(ASender: TObject);
begin
  FPresenter.ShrinkHeight;
end;

procedure TVoxelEditorForm.HeightmapClick(ASender: TObject);
begin
  FPresenter.ImportHeightmap;
end;

procedure TVoxelEditorForm.TerrainClick(ASender: TObject);
begin
  FPresenter.ApplyTerrainTexture;
end;

procedure TVoxelEditorForm.CountColorsClick(ASender: TObject);
begin
  FPresenter.CountColors;
end;

procedure TVoxelEditorForm.GrayScaleClick(ASender: TObject);
begin
  FPresenter.ToGrayScale;
end;

procedure TVoxelEditorForm.ConvertPaletteClick(ASender: TObject);
begin
  FPresenter.ConvertToPalette;
end;

procedure TVoxelEditorForm.GamePaletteClick(ASender: TObject);
begin
  FPresenter.ShowGamePalette(TVoxelEditorPaletteKind((ASender as TMenuItem).Tag));
end;

procedure TVoxelEditorForm.ViewClick(ASender: TObject);
begin
  FPresenter.SelectView(TVoxelEditorView((ASender as TMenuItem).Tag));
end;

procedure TVoxelEditorForm.SliceClick(ASender: TObject);
begin
  FPresenter.SelectSlice(TVoxelEditorAxis((ASender as TMenuItem).Tag), 0);
end;

procedure TVoxelEditorForm.LevelUpClick(ASender: TObject);
begin
  FPresenter.IncreaseLevel;
end;

procedure TVoxelEditorForm.LevelDownClick(ASender: TObject);
begin
  FPresenter.DecreaseLevel;
end;

procedure TVoxelEditorForm.ZoomInClick(ASender: TObject);
begin
  FPresenter.ZoomIn;
end;

procedure TVoxelEditorForm.ZoomOutClick(ASender: TObject);
begin
  FPresenter.ZoomOut;
end;

procedure TVoxelEditorForm.AboutClick(ASender: TObject);
begin
  FPresenter.About;
end;

procedure TVoxelEditorForm.FormCloseQueried(ASender: TObject; var ACanClose: Boolean);
begin
  // the window is hidden and not closed: a voxel with changes is asked about when the program ends
  ACanClose := True;
end;

procedure TVoxelEditorForm.FormClosed(ASender: TObject; var AAction: TCloseAction);
begin
  AAction := caHide;
end;

procedure TVoxelEditorForm.FormWheel(ASender: TObject; AShift: TShiftState; AWheelDelta: Integer;
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

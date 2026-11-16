{******************************************************************************}
{                                                                              }
{  DD_Tools: the dialogs of Windows for the voxel editor                        }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.VoxelDialogs;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Intf;

type
  /// <summary>
  ///   IVoxelEditorDialogs with the dialogs of the VCL: the file pickers (made when they are asked for, with the filters
  ///   of DD_VOXEL), the color dialog, the questions (size, angle, heights, palette) and the message boxes
  /// </summary>
  TVclVoxelEditorDialogs = class(TInterfacedObject, IVoxelEditorDialogs)
  strict private
    FTitle: string;
    FVersion: string;
    function PickToOpen(const AFilter: string; out AFileName: string): Boolean;
    function PickToSave(const AFilter, ADefaultExtension, ASuggestedName: string; out AFileName: string): Boolean;
  public
    constructor Create(const ATitle, AVersion: string);
    function PickVoxelToOpen(out AFileName: string): Boolean;
    function PickVoxelToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    function PickKvxToImport(out AFileName: string): Boolean;
    function PickVoxToImport(out AFileName: string): Boolean;
    function PickDdmeshToImport(out AFileName: string): Boolean;
    function PickVoxToExport(out AFileName: string): Boolean;
    function PickMeshToExport(out AFileName: string): Boolean;
    function PickImageToImport(out AFileName: string): Boolean;
    function PickImageToExport(out AFileName: string): Boolean;
    function PickPaletteFile(out AFileName: string): Boolean;
    function PickFilesToConvert(const AKind: string; out AFileNames: TArray<string>): Boolean;
    function PickColor(var AColor: Cardinal): Boolean;
    function AskNewSize(var ASize: Integer): Boolean;
    function AskRotation(var ADegrees: Double): Boolean;
    function AskHeightRange(const ATitle: string; const APreview: TVoxelEditorImage; ASize: Integer;
      var AMin, AMax: Integer): Boolean;
    function AskPaletteKind(out AKind: TVoxelEditorPaletteKind): Boolean;
    function AskSaveChanges: TVoxelEditorConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
  end;

implementation

uses
  System.Classes, System.Math,
  Winapi.Windows,
  Vcl.Controls, Vcl.Dialogs, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  DelphiDoom.Tools.Win.VoxelBitmaps;

const
  SFilterVoxels = 'DDVOX voxels (*.ddvox)|*.ddvox|All files (*.*)|*.*';
  SFilterKvx = 'KVX voxels (*.kvx)|*.kvx|All files (*.*)|*.*';
  SFilterVox = 'Slab6 VOX voxels (*.vox)|*.vox|All files (*.*)|*.*';
  SFilterMesh = 'DDMESH meshes (*.ddmesh)|*.ddmesh|All files (*.*)|*.*';
  SFilterImages = 'Pictures (*.bmp;*.png;*.jpg;*.jpeg;*.gif)|*.bmp;*.png;*.jpg;*.jpeg;*.gif|All files (*.*)|*.*';
  SFilterImagesToSave = 'PNG image (*.png)|*.png|JPEG image (*.jpg)|*.jpg|Bitmap (*.bmp)|*.bmp';
  SFilterPalettes = 'Palette files (*.pal;*.dat;*.bin;*.raw)|*.pal;*.dat;*.bin;*.raw|All files (*.*)|*.*';

type
  /// <summary>The picture of the front view of a voxel with the two heights of a crop or a shrink drawn on it</summary>
  THeightPreview = class
  public
    Image: TImage;
    Source: TBitmap;
    Lower, Upper: TTrackBar;
    procedure Redraw(ASender: TObject);
  end;

procedure THeightPreview.Redraw(ASender: TObject);
var
  LCanvas: TCanvas;
begin
  if not (Assigned(Image) and Assigned(Source) and Assigned(Lower) and Assigned(Upper)) then
    Exit;
  LCanvas := Image.Picture.Bitmap.Canvas;
  LCanvas.StretchDraw(Rect(0, 0, 256, 256), Source);
  LCanvas.Pen.Color := clRed;
  LCanvas.MoveTo(0, Lower.Position);
  LCanvas.LineTo(256, Lower.Position);
  LCanvas.Pen.Color := clLime;
  LCanvas.MoveTo(0, Upper.Position);
  LCanvas.LineTo(256, Upper.Position);
  Image.Invalidate;
end;

{ TVclVoxelEditorDialogs }

constructor TVclVoxelEditorDialogs.Create(const ATitle, AVersion: string);
begin
  inherited Create;
  FTitle := ATitle;
  FVersion := AVersion;
end;

function TVclVoxelEditorDialogs.PickToOpen(const AFilter: string; out AFileName: string): Boolean;
var
  LDialog: TOpenDialog;
begin
  AFileName := '';
  LDialog := TOpenDialog.Create(nil);
  try
    LDialog.Filter := AFilter;
    LDialog.Options := LDialog.Options + [ofFileMustExist];
    Result := LDialog.Execute;
    if Result then
      AFileName := LDialog.FileName;
  finally
    LDialog.Free;
  end;
end;

function TVclVoxelEditorDialogs.PickToSave(const AFilter, ADefaultExtension, ASuggestedName: string;
  out AFileName: string): Boolean;
var
  LDialog: TSaveDialog;
begin
  AFileName := '';
  LDialog := TSaveDialog.Create(nil);
  try
    LDialog.Filter := AFilter;
    LDialog.DefaultExt := ADefaultExtension;
    LDialog.Options := LDialog.Options + [ofOverwritePrompt];
    LDialog.FileName := ASuggestedName;
    Result := LDialog.Execute;
    if Result then
      AFileName := LDialog.FileName;
  finally
    LDialog.Free;
  end;
end;

function TVclVoxelEditorDialogs.PickVoxelToOpen(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterVoxels, AFileName);
end;

function TVclVoxelEditorDialogs.PickVoxelToSave(const ASuggestedName: string; out AFileName: string): Boolean;
begin
  Result := PickToSave(SFilterVoxels, 'ddvox', ASuggestedName, AFileName);
end;

function TVclVoxelEditorDialogs.PickKvxToImport(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterKvx, AFileName);
end;

function TVclVoxelEditorDialogs.PickVoxToImport(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterVox, AFileName);
end;

function TVclVoxelEditorDialogs.PickDdmeshToImport(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterMesh, AFileName);
end;

function TVclVoxelEditorDialogs.PickVoxToExport(out AFileName: string): Boolean;
begin
  Result := PickToSave(SFilterVox, 'vox', '', AFileName);
end;

function TVclVoxelEditorDialogs.PickMeshToExport(out AFileName: string): Boolean;
begin
  Result := PickToSave(SFilterMesh, 'ddmesh', '', AFileName);
end;

function TVclVoxelEditorDialogs.PickImageToImport(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterImages, AFileName);
end;

function TVclVoxelEditorDialogs.PickImageToExport(out AFileName: string): Boolean;
begin
  Result := PickToSave(SFilterImagesToSave, 'png', '', AFileName);
end;

function TVclVoxelEditorDialogs.PickPaletteFile(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterPalettes, AFileName);
end;

function TVclVoxelEditorDialogs.PickFilesToConvert(const AKind: string; out AFileNames: TArray<string>): Boolean;
var
  LDialog: TOpenDialog;
  LIndex: Integer;
begin
  AFileNames := nil;
  LDialog := TOpenDialog.Create(nil);
  try
    if AKind = 'kvx' then
      LDialog.Filter := SFilterKvx
    else
      LDialog.Filter := SFilterVoxels;
    LDialog.Options := LDialog.Options + [ofFileMustExist, ofAllowMultiSelect];
    Result := LDialog.Execute;
    if Result then
    begin
      SetLength(AFileNames, LDialog.Files.Count);
      for LIndex := 0 to LDialog.Files.Count - 1 do
        AFileNames[LIndex] := LDialog.Files[LIndex];
    end;
  finally
    LDialog.Free;
  end;
end;

function TVclVoxelEditorDialogs.PickColor(var AColor: Cardinal): Boolean;
var
  LDialog: TColorDialog;
begin
  LDialog := TColorDialog.Create(nil);
  try
    LDialog.Color := TColor(AColor);
    Result := LDialog.Execute;
    if Result then
      AColor := Cardinal(LDialog.Color) and $FFFFFF;
  finally
    LDialog.Free;
  end;
end;

function TVclVoxelEditorDialogs.AskNewSize(var ASize: Integer): Boolean;
var
  LText: string;
  LValue: Integer;
begin
  LText := IntToStr(ASize);
  Result := InputQuery(FTitle, 'Size of the new voxel (a side of the cube, 1 to 256 cells):', LText);
  if Result then
  begin
    LValue := StrToIntDef(Trim(LText), 0);
    Result := (LValue >= 1) and (LValue <= VOXEL_EDITOR_MAX_SIZE);
    if Result then
      ASize := LValue;
  end;
end;

function TVclVoxelEditorDialogs.AskRotation(var ADegrees: Double): Boolean;
var
  LText: string;
  LValue: Double;
begin
  LText := FloatToStr(ADegrees, TFormatSettings.Invariant);
  Result := InputQuery(FTitle, 'Angle of the rotation around the vertical axis, in degrees:', LText);
  if Result then
  begin
    Result := TryStrToFloat(Trim(LText), LValue, TFormatSettings.Invariant);
    if Result then
      ADegrees := LValue;
  end;
end;

function TVclVoxelEditorDialogs.AskHeightRange(const ATitle: string; const APreview: TVoxelEditorImage; ASize: Integer;
  var AMin, AMax: Integer): Boolean;
var
  LForm: TForm;
  LImage: TImage;
  LMin, LMax: TTrackBar;
  LOk, LCancel: TButton;
  LBitmap: TBitmap;
  LSource: TBitmap;
  LPreview: THeightPreview;
begin
  LForm := TForm.CreateNew(nil);
  LSource := TVoxelBitmaps.ToBitmap(APreview, ASize);
  LPreview := THeightPreview.Create;
  try
    LForm.Caption := ATitle;
    LForm.BorderStyle := bsDialog;
    LForm.Position := poScreenCenter;
    LForm.ClientWidth := 300;
    LForm.ClientHeight := 400;
    LImage := TImage.Create(LForm);
    LImage.Parent := LForm;
    LImage.SetBounds(22, 8, 256, 256);
    LBitmap := TBitmap.Create;
    LBitmap.PixelFormat := pf32bit;
    LBitmap.SetSize(256, 256);
    LImage.Picture.Bitmap := LBitmap;
    LBitmap.Free;
    LMin := TTrackBar.Create(LForm);
    LMin.Parent := LForm;
    LMin.SetBounds(8, 272, 284, 40);
    LMin.Min := 0;
    LMin.Max := 255;
    LMin.Position := EnsureRange(AMin, 0, 255);
    LMin.OnChange := LPreview.Redraw;
    LMax := TTrackBar.Create(LForm);
    LMax.Parent := LForm;
    LMax.SetBounds(8, 316, 284, 40);
    LMax.Min := 0;
    LMax.Max := 255;
    LMax.Position := EnsureRange(AMax, 0, 255);
    LMax.OnChange := LPreview.Redraw;
    LOk := TButton.Create(LForm);
    LOk.Parent := LForm;
    LOk.SetBounds(130, 364, 75, 28);
    LOk.Caption := 'OK';
    LOk.Default := True;
    LOk.ModalResult := mrOk;
    LCancel := TButton.Create(LForm);
    LCancel.Parent := LForm;
    LCancel.SetBounds(215, 364, 75, 28);
    LCancel.Caption := 'Cancel';
    LCancel.Cancel := True;
    LCancel.ModalResult := mrCancel;
    LPreview.Image := LImage;
    LPreview.Source := LSource;
    LPreview.Lower := LMin;
    LPreview.Upper := LMax;
    LPreview.Redraw(nil);
    Result := LForm.ShowModal = mrOk;
    if Result then
    begin
      AMin := LMin.Position;
      AMax := LMax.Position;
    end;
  finally
    LPreview.Free;
    LSource.Free;
    LForm.Free;
  end;
end;

function TVclVoxelEditorDialogs.AskPaletteKind(out AKind: TVoxelEditorPaletteKind): Boolean;
var
  LForm: TForm;
  LGroup: TRadioGroup;
  LOk, LCancel: TButton;
begin
  AKind := vepDoom;
  LForm := TForm.CreateNew(nil);
  try
    LForm.Caption := 'Convert to 256 colors palette';
    LForm.BorderStyle := bsDialog;
    LForm.Position := poScreenCenter;
    LForm.ClientWidth := 260;
    LForm.ClientHeight := 250;
    LGroup := TRadioGroup.Create(LForm);
    LGroup.Parent := LForm;
    LGroup.SetBounds(8, 8, 244, 196);
    LGroup.Caption := 'Palette';
    LGroup.Items.CommaText := 'Doom,Heretic,Hexen,Strife,Radix,"Optimized octree","Disk file (*.pal)"';
    LGroup.ItemIndex := 0;
    LOk := TButton.Create(LForm);
    LOk.Parent := LForm;
    LOk.SetBounds(96, 212, 75, 28);
    LOk.Caption := 'OK';
    LOk.Default := True;
    LOk.ModalResult := mrOk;
    LCancel := TButton.Create(LForm);
    LCancel.Parent := LForm;
    LCancel.SetBounds(177, 212, 75, 28);
    LCancel.Caption := 'Cancel';
    LCancel.Cancel := True;
    LCancel.ModalResult := mrCancel;
    Result := LForm.ShowModal = mrOk;
    if Result then
      AKind := TVoxelEditorPaletteKind(LGroup.ItemIndex);
  finally
    LForm.Free;
  end;
end;

function TVclVoxelEditorDialogs.AskSaveChanges: TVoxelEditorConfirmation;
begin
  case MessageBox(Application.ActiveFormHandle, 'Do you want to save changes?', PChar(FTitle),
    MB_YESNOCANCEL or MB_ICONQUESTION or MB_APPLMODAL) of
    IDYES:
      Result := vecYes;
    IDNO:
      Result := vecNo;
  else
    Result := vecCancel;
  end;
end;

procedure TVclVoxelEditorDialogs.ShowMessage(const AText: string);
begin
  MessageBox(Application.ActiveFormHandle, PChar(AText), PChar(FTitle), MB_OK or MB_ICONWARNING or MB_APPLMODAL);
end;

procedure TVclVoxelEditorDialogs.ShowAbout;
begin
  MessageBox(Application.ActiveFormHandle,
    PChar(Format('%s'#13#10'Version %s'#13#10#13#10'A tool for creating voxels for the DelphiDoom engine.'#13#10 +
      'Original DD_VOXEL by Jim Valavanis', [FTitle, FVersion])),
    PChar(FTitle), MB_OK or MB_ICONINFORMATION or MB_APPLMODAL);
end;

end.

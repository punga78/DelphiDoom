{******************************************************************************}
{                                                                              }
{  DD_Tools: the dialogs of Windows for the font editor                         }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.FontDialogs;

interface

uses
  System.SysUtils,
  DelphiDoom.FontEditor.Types,
  DelphiDoom.FontEditor.Intf;

type
  /// <summary>
  ///   IFontEditorDialogs with the dialogs of the VCL: the file pickers (made when they are asked for, with the
  ///   filters of DD_FONT), the color dialog, the message boxes
  /// </summary>
  TVclFontEditorDialogs = class(TInterfacedObject, IFontEditorDialogs)
  strict private
    FTitle: string;
    FVersion: string;
    function PickToOpen(const AFilter: string; out AFileName: string): Boolean;
    function PickToSave(const AFilter, ADefaultExtension, ASuggestedName: string; out AFileName: string): Boolean;
  public
    constructor Create(const ATitle, AVersion: string);
    function PickProjectToOpen(out AFileName: string): Boolean;
    function PickProjectToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    function PickWadToSave(out AFileName: string): Boolean;
    function PickImageToExport(out AFileName: string): Boolean;
    function PickPaletteFile(out AFileName: string): Boolean;
    function PickFontFile(out AFileName: string): Boolean;
    function PickColor(var AColor: Integer): Boolean;
    function AskSaveChanges: TFontEditorConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Dialogs, Vcl.Forms, Vcl.Graphics;

const
  SFilterProjects = 'Font projects (*.ddp)|*.ddp|All files (*.*)|*.*';
  SFilterWads = 'WAD files (*.wad)|*.wad|All files (*.*)|*.*';
  SFilterImages = 'PNG image (*.png)|*.png|JPEG image (*.jpg)|*.jpg|Bitmap (*.bmp)|*.bmp';
  SFilterPalettes = 'Palette files (*.pal;*.dat;*.bin;*.raw)|*.pal;*.dat;*.bin;*.raw|All files (*.*)|*.*';
  SFilterFonts = 'TrueType and OpenType fonts (*.ttf;*.otf)|*.ttf;*.otf|All files (*.*)|*.*';

{ TVclFontEditorDialogs }

constructor TVclFontEditorDialogs.Create(const ATitle, AVersion: string);
begin
  inherited Create;
  FTitle := ATitle;
  FVersion := AVersion;
end;

function TVclFontEditorDialogs.PickToOpen(const AFilter: string; out AFileName: string): Boolean;
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

function TVclFontEditorDialogs.PickToSave(const AFilter, ADefaultExtension, ASuggestedName: string;
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

function TVclFontEditorDialogs.PickProjectToOpen(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterProjects, AFileName);
end;

function TVclFontEditorDialogs.PickProjectToSave(const ASuggestedName: string; out AFileName: string): Boolean;
begin
  Result := PickToSave(SFilterProjects, 'ddp', ASuggestedName, AFileName);
end;

function TVclFontEditorDialogs.PickWadToSave(out AFileName: string): Boolean;
begin
  Result := PickToSave(SFilterWads, 'wad', '', AFileName);
end;

function TVclFontEditorDialogs.PickImageToExport(out AFileName: string): Boolean;
begin
  Result := PickToSave(SFilterImages, 'png', '', AFileName);
end;

function TVclFontEditorDialogs.PickPaletteFile(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterPalettes, AFileName);
end;

function TVclFontEditorDialogs.PickFontFile(out AFileName: string): Boolean;
begin
  Result := PickToOpen(SFilterFonts, AFileName);
end;

function TVclFontEditorDialogs.PickColor(var AColor: Integer): Boolean;
var
  LDialog: TColorDialog;
begin
  LDialog := TColorDialog.Create(nil);
  try
    LDialog.Color := TColor(AColor);
    Result := LDialog.Execute;
    if Result then
      AColor := Integer(LDialog.Color);
  finally
    LDialog.Free;
  end;
end;

function TVclFontEditorDialogs.AskSaveChanges: TFontEditorConfirmation;
begin
  case MessageBox(Application.ActiveFormHandle, 'Do you want to save changes?', PChar(FTitle),
    MB_YESNOCANCEL or MB_ICONQUESTION or MB_APPLMODAL) of
    IDYES:
      Result := fcYes;
    IDNO:
      Result := fcNo;
  else
    Result := fcCancel;
  end;
end;

procedure TVclFontEditorDialogs.ShowMessage(const AText: string);
begin
  MessageBox(Application.ActiveFormHandle, PChar(AText), PChar(FTitle), MB_OK or MB_ICONWARNING or MB_APPLMODAL);
end;

procedure TVclFontEditorDialogs.ShowAbout;
begin
  MessageBox(Application.ActiveFormHandle,
    PChar(Format('%s'#13#10'Version %s'#13#10#13#10'A tool for creating font images for Doom.'#13#10 +
      'Original DD_FONT by Jim Valavanis', [FTitle, FVersion])),
    PChar(FTitle), MB_OK or MB_ICONINFORMATION or MB_APPLMODAL);
end;

end.

{******************************************************************************}
{                                                                              }
{  DD_Tools: the dialogs of Windows for the endoom editor                       }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.EndoomDialogs;

interface

uses
  System.SysUtils,
  DelphiDoom.Endoom.TextArt.Types,
  DelphiDoom.EndoomEditor.Types,
  DelphiDoom.EndoomEditor.Intf;

type
  /// <summary>
  ///   IEndoomEditorDialogs with the dialogs of the VCL: the file pickers (made when they are asked for, with the
  ///   filters of ENDEDIT), the message boxes and the choice of the method of the text art
  /// </summary>
  TVclEndoomEditorDialogs = class(TInterfacedObject, IEndoomEditorDialogs)
  strict private
    FTitle: string;
    FVersion: string;
  public
    constructor Create(const ATitle, AVersion: string);
    function PickFileToOpen(out AFileName: string): Boolean;
    function PickFileToSave(const ASuggestedName: string; out AFileName: string): Boolean;
    function PickImageToExport(out AFileName: string): Boolean;
    function PickTextArtMethod(var AKind: TEndoomTextArtKind): Boolean;
    function AskSaveChanges: TEndoomConfirmation;
    procedure ShowMessage(const AText: string);
    procedure ShowAbout;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Dialogs, Vcl.Forms,
  frm_textartmethod;

const
  SFilterTextScreens = 'ENDOOM, ENDTEXT and ENDSTRF files (*.bin;*.lmp;*.dat)|*.bin;*.lmp;*.dat|All files (*.*)|*.*';
  SFilterImages = 'PNG image (*.png)|*.png|JPEG image (*.jpg)|*.jpg|Bitmap (*.bmp)|*.bmp';

{ TVclEndoomEditorDialogs }

constructor TVclEndoomEditorDialogs.Create(const ATitle, AVersion: string);
begin
  inherited Create;
  FTitle := ATitle;
  FVersion := AVersion;
end;

function TVclEndoomEditorDialogs.PickFileToOpen(out AFileName: string): Boolean;
var
  LDialog: TOpenDialog;
begin
  AFileName := '';
  LDialog := TOpenDialog.Create(nil);
  try
    LDialog.Filter := SFilterTextScreens;
    LDialog.Options := LDialog.Options + [ofFileMustExist];
    Result := LDialog.Execute;
    if Result then
      AFileName := LDialog.FileName;
  finally
    LDialog.Free;
  end;
end;

function TVclEndoomEditorDialogs.PickFileToSave(const ASuggestedName: string; out AFileName: string): Boolean;
var
  LDialog: TSaveDialog;
begin
  AFileName := '';
  LDialog := TSaveDialog.Create(nil);
  try
    LDialog.Filter := SFilterTextScreens;
    LDialog.Options := LDialog.Options + [ofOverwritePrompt];
    LDialog.FileName := ASuggestedName;
    Result := LDialog.Execute;
    if Result then
      AFileName := LDialog.FileName;
  finally
    LDialog.Free;
  end;
end;

function TVclEndoomEditorDialogs.PickImageToExport(out AFileName: string): Boolean;
var
  LDialog: TSaveDialog;
begin
  AFileName := '';
  LDialog := TSaveDialog.Create(nil);
  try
    LDialog.Filter := SFilterImages;
    LDialog.DefaultExt := 'png';
    LDialog.Options := LDialog.Options + [ofOverwritePrompt];
    Result := LDialog.Execute;
    if Result then
      AFileName := LDialog.FileName;
  finally
    LDialog.Free;
  end;
end;

function TVclEndoomEditorDialogs.PickTextArtMethod(var AKind: TEndoomTextArtKind): Boolean;
begin
  Result := TTextArtMethodForm.Choose(AKind);
end;

function TVclEndoomEditorDialogs.AskSaveChanges: TEndoomConfirmation;
begin
  case MessageBox(Application.ActiveFormHandle, 'Do you want to save changes?', PChar(FTitle),
    MB_YESNOCANCEL or MB_ICONQUESTION or MB_APPLMODAL) of
    IDYES:
      Result := ecYes;
    IDNO:
      Result := ecNo;
  else
    Result := ecCancel;
  end;
end;

procedure TVclEndoomEditorDialogs.ShowMessage(const AText: string);
begin
  MessageBox(Application.ActiveFormHandle, PChar(AText), PChar(FTitle), MB_OK or MB_ICONWARNING or MB_APPLMODAL);
end;

procedure TVclEndoomEditorDialogs.ShowAbout;
begin
  MessageBox(Application.ActiveFormHandle,
    PChar(Format('%s'#13#10'Version %s'#13#10#13#10'A tool for creating ENDTEXT screens.'#13#10 +
      'Original ENDEDIT by Jim Valavanis', [FTitle, FVersion])),
    PChar(FTitle), MB_OK or MB_ICONINFORMATION or MB_APPLMODAL);
end;

end.

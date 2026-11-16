{******************************************************************************}
{                                                                              }
{  DD_IDE: the file dialogs of Windows for the ide library                     }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Win.FileDialogs;

interface

uses
  System.SysUtils,
  Vcl.Dialogs,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   The open and save dialogs of the main window. The dialogs are components of the window, with
  ///   the filters and titles they always had; this class only opens them
  /// </summary>
  TVclIdeFileDialogs = class(TInterfacedObject, IIdeFileDialogs)
  strict private
    FOpenProject: TOpenDialog;
    FSaveProject: TSaveDialog;
    FAddActors: TOpenDialog;
    FAddScripts: TOpenDialog;
    FAddCompiledScripts: TOpenDialog;
    FSavePk3: TSaveDialog;
    FSaveMessages: TSaveDialog;
  public
    constructor Create(const AOpenProject: TOpenDialog; const ASaveProject: TSaveDialog;
      const AAddActors, AAddScripts, AAddCompiledScripts: TOpenDialog;
      const ASavePk3, ASaveMessages: TSaveDialog);
    function PickProjectToOpen(out AFileName: string): Boolean;
    function PickProjectToSave(out AFileName: string): Boolean;
    function PickItemsToAdd(const AKind: TIdeItemKind; out AFileNames: TArray<string>): Boolean;
    function PickPk3ToSave(out AFileName: string): Boolean;
    function PickMessagesFileToSave(out AFileName: string): Boolean;
  end;

  /// <summary>The "save compiled code" dialog of one script editor</summary>
  TVclIdePCodeDialog = class(TInterfacedObject, IIdePCodeDialog)
  strict private
    FDialog: TSaveDialog;
  public
    constructor Create(const ADialog: TSaveDialog);
    function PickPCodeFileToSave(const ADefaultName: string; out AFileName: string): Boolean;
  end;

implementation

{ TVclIdeFileDialogs }

constructor TVclIdeFileDialogs.Create(const AOpenProject: TOpenDialog; const ASaveProject: TSaveDialog;
  const AAddActors, AAddScripts, AAddCompiledScripts: TOpenDialog;
  const ASavePk3, ASaveMessages: TSaveDialog);
begin
  inherited Create;
  FOpenProject := AOpenProject;
  FSaveProject := ASaveProject;
  FAddActors := AAddActors;
  FAddScripts := AAddScripts;
  FAddCompiledScripts := AAddCompiledScripts;
  FSavePk3 := ASavePk3;
  FSaveMessages := ASaveMessages;
end;

function TVclIdeFileDialogs.PickProjectToOpen(out AFileName: string): Boolean;
begin
  Result := FOpenProject.Execute;
  if Result then
    AFileName := FOpenProject.FileName
  else
    AFileName := '';
end;

function TVclIdeFileDialogs.PickProjectToSave(out AFileName: string): Boolean;
begin
  Result := FSaveProject.Execute;
  if Result then
    AFileName := FSaveProject.FileName
  else
    AFileName := '';
end;

function TVclIdeFileDialogs.PickItemsToAdd(const AKind: TIdeItemKind;
  out AFileNames: TArray<string>): Boolean;
var
  LDialog: TOpenDialog;
  LIndex: Integer;
begin
  AFileNames := nil;
  case AKind of
    ikActor:
      LDialog := FAddActors;
    ikCompiledScript:
      LDialog := FAddCompiledScripts;
  else
    LDialog := FAddScripts;
  end;
  Result := LDialog.Execute;
  if Result then
  begin
    SetLength(AFileNames, LDialog.Files.Count);
    for LIndex := 0 to LDialog.Files.Count - 1 do
      AFileNames[LIndex] := LDialog.Files[LIndex];
  end;
end;

function TVclIdeFileDialogs.PickPk3ToSave(out AFileName: string): Boolean;
begin
  Result := FSavePk3.Execute;
  if Result then
    AFileName := FSavePk3.FileName
  else
    AFileName := '';
end;

function TVclIdeFileDialogs.PickMessagesFileToSave(out AFileName: string): Boolean;
begin
  Result := FSaveMessages.Execute;
  if Result then
    AFileName := FSaveMessages.FileName
  else
    AFileName := '';
end;

{ TVclIdePCodeDialog }

constructor TVclIdePCodeDialog.Create(const ADialog: TSaveDialog);
begin
  inherited Create;
  FDialog := ADialog;
end;

function TVclIdePCodeDialog.PickPCodeFileToSave(const ADefaultName: string;
  out AFileName: string): Boolean;
begin
  FDialog.FileName := ADefaultName;
  Result := FDialog.Execute;
  if Result then
    AFileName := FDialog.FileName
  else
    AFileName := '';
end;

end.

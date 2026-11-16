{******************************************************************************}
{                                                                              }
{  DelphiDoom: tools core library - the list of the recent files                }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.RecentFiles;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Tools.Intf;

type
  /// <summary>
  ///   The recent files of a tool (ee_filemenuhistory, ff_filemenuhistory, vxe_filemenuhistory
  ///   without the menu items: the window shows the captions that this class gives). A file goes
  ///   to the top; if it was in the list already (the case does not count) it moves. Unlike the
  ///   old classes, which kept 9 files for a menu of 10, the list keeps ALimit files
  /// </summary>
  TRecentFiles = class(TInterfacedObject, IRecentFiles)
  strict private
    FItems: TList<string>;
    FLimit: Integer;
    function IndexOfPath(const APath: string): Integer;
  public
    constructor Create(ALimit: Integer);
    destructor Destroy; override;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): string;
    procedure Add(const APath: string);
    procedure Remove(const APath: string);
    procedure Clear;
    function MenuCaption(AIndex: Integer): string;
    procedure LoadFrom(const ASettings: ISettingsStore; const ASection: string);
    procedure SaveTo(const ASettings: ISettingsStore; const ASection: string);
  end;

implementation

uses
  DelphiDoom.Tools.Types,
  DelphiDoom.Tools.PathText;

const
  /// <summary>The name of the setting of the first entry; the others count up from there</summary>
  SRecentFilesName = 'FILEMENUHISTORY';

{ TRecentFiles }

constructor TRecentFiles.Create(ALimit: Integer);
begin
  inherited Create;
  if ALimit < 1 then
    raise EToolsException.CreateFmt(SToolsBadLimit, [ALimit]);
  FLimit := ALimit;
  FItems := TList<string>.Create;
end;

destructor TRecentFiles.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TRecentFiles.IndexOfPath(const APath: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FItems.Count - 1 do
    if SameText(FItems[LIndex], APath) then
      Exit(LIndex);
  Result := -1;
end;

function TRecentFiles.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TRecentFiles.GetItem(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    raise EToolsException.CreateFmt(SToolsBadIndex, [AIndex, FItems.Count]);
  Result := FItems[AIndex];
end;

procedure TRecentFiles.Add(const APath: string);
var
  LPath: string;
  LIndex: Integer;
begin
  LPath := Trim(APath);
  if LPath = '' then
    Exit;
  LIndex := IndexOfPath(LPath);
  if LIndex >= 0 then
    FItems.Delete(LIndex);
  FItems.Insert(0, LPath);
  while FItems.Count > FLimit do
    FItems.Delete(FItems.Count - 1);
end;

procedure TRecentFiles.Remove(const APath: string);
var
  LIndex: Integer;
begin
  LIndex := IndexOfPath(Trim(APath));
  if LIndex >= 0 then
    FItems.Delete(LIndex);
end;

procedure TRecentFiles.Clear;
begin
  FItems.Clear;
end;

function TRecentFiles.MenuCaption(AIndex: Integer): string;
begin
  Result := Format('&%d. %s', [AIndex + 1, TToolPathText.Shorten(GetItem(AIndex), TOOLS_SHORT_NAME_LIMIT)]);
end;

procedure TRecentFiles.LoadFrom(const ASettings: ISettingsStore; const ASection: string);
var
  LIndex: Integer;
begin
  FItems.Clear;
  // the oldest first, so that Add leaves the newest on top, as the old code did
  for LIndex := FLimit - 1 downto 0 do
    Add(ASettings.ReadString(ASection, SRecentFilesName + IntToStr(LIndex), ''));
end;

procedure TRecentFiles.SaveTo(const ASettings: ISettingsStore; const ASection: string);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FLimit - 1 do
    if LIndex < FItems.Count then
      ASettings.WriteString(ASection, SRecentFilesName + IntToStr(LIndex), FItems[LIndex])
    else
      ASettings.WriteString(ASection, SRecentFilesName + IntToStr(LIndex), '');
end;

end.

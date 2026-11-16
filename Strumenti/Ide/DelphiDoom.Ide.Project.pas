{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - a project and its files                           }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Project;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Document,
  DelphiDoom.Ide.ProjectItem;

type
  /// <summary>
  ///   Asked when a rename would replace the text of a modified item with an existing file: gives
  ///   true if the item can be replaced (the user saved it or does not care)
  /// </summary>
  TIdeModifiedItemQuery = reference to function(const AItem: TIdeProjectItem): Boolean;

  /// <summary>Told every time somebody sets the game of the project, with the name as the ide keeps it</summary>
  TIdeGameChanged = reference to procedure(const AGame: string);

  /// <summary>
  ///   A project: the game it is written for and the list of its files. The project file is the
  ///   text of the document, so loading it loads the items too. It is the old TIDEProject
  /// </summary>
  TIdeProject = class(TIdeDocument, IIdeProjectContext)
  strict private
    FItems: TObjectList<TIdeProjectItem>;
    FGame: string;
    FPendingRename: string;
    FOnQueryModifiedItem: TIdeModifiedItemQuery;
    FOnGameChanged: TIdeGameChanged;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): TIdeProjectItem;
    function GetGame: string;
    procedure SetGame(const AGame: string);
    function CanCloseItemQuery(const AItem: TIdeProjectItem): Boolean;
    procedure ChangePath(const APath: string);
    procedure DoAdd(const AFileName: string; const AKind: TIdeItemKind);

    function GetFileName: string;
  protected
    procedure DataToFields(const AData: AnsiString); override;
    procedure FieldsToData(var AData: AnsiString); override;
    function GetModified: Boolean; override;
  public
    constructor Create(const AFileSystem: IIdeFileSystem; const ALog: IIdeLog;
      const AClock: IIdeClock; const AFileName: string = '');
    destructor Destroy; override;
    /// <summary>Adds a file (by name) unless the project has it already</summary>
    procedure Add(const AFileName: string; const AKind: TIdeItemKind);
    procedure Clear;
    procedure Delete(const AIndex: Integer); overload;
    procedure Delete(const AFileName: string); overload;
    procedure Delete(const AItem: TIdeProjectItem); overload;
    /// <summary>
    ///   Looks for an item by the path relative to the project, by the file name, or by the full
    ///   path, in this order, and without regard to the case
    /// </summary>
    function Find(const AFileName: string): TIdeProjectItem;
    function LoadFromFile(const AFileName: string): Boolean; override;
    function SaveToFile(const AFileName: string): Boolean; override;
    /// <summary>The first step of a rename: gives false if the project has no such item</summary>
    function CanRename(const AOldName: string): Boolean;
    /// <summary>
    ///   The second step: the item moves to a new name. If a file with that name exists the item
    ///   takes its text (after asking), otherwise the item is saved with the new name
    /// </summary>
    function ExecRename(const ANewName: string): Boolean;
    function Rename(const AOldName, ANewName: string): Boolean;
    /// <summary>Called by the owner: asks the user what to do with a modified item</summary>
    property OnQueryModifiedItem: TIdeModifiedItemQuery read FOnQueryModifiedItem write FOnQueryModifiedItem;
    property OnGameChanged: TIdeGameChanged read FOnGameChanged write FOnGameChanged;
    property Count: Integer read GetCount;
    /// <summary>
    ///   Doom, Heretic, Hexen, Strife, Radix or Mars. A name that is not known leaves the game as
    ///   it was and writes a warning, but the owner is told anyway (as the old code did)
    /// </summary>
    property Game: string read GetGame write SetGame;
    property Items[const AIndex: Integer]: TIdeProjectItem read GetItem;
  end;

implementation

uses
  DelphiDoom.Ide.Messages,
  DelphiDoom.Ide.Games,
  DelphiDoom.Ide.ProjectFormat;

{ TIdeProject }

constructor TIdeProject.Create(const AFileSystem: IIdeFileSystem; const ALog: IIdeLog;
  const AClock: IIdeClock; const AFileName: string);
begin
  // the items exist before the base constructor reads the file, which adds them
  FItems := TObjectList<TIdeProjectItem>.Create(True);
  FPendingRename := '';
  FGame := 'doom';
  inherited Create(AFileSystem, ALog, AClock, AFileName);
end;

destructor TIdeProject.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TIdeProject.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TIdeProject.GetItem(const AIndex: Integer): TIdeProjectItem;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Result := nil
  else
    Result := FItems[AIndex];
end;

function TIdeProject.GetGame: string;
begin
  Result := FGame;
end;

function TIdeProject.GetFileName: string;
begin
  Result := FileName;
end;

procedure TIdeProject.SetGame(const AGame: string);
var
  LName: string;
begin
  LName := TIdeGames.Normalize(AGame);
  if TIdeGames.IsKnown(LName) then
    FGame := LName
  else
    Log.WriteFormat(mkWarning, SUnknownGameType, [AGame]);
  if Assigned(FOnGameChanged) then
    FOnGameChanged(LName);
end;

procedure TIdeProject.ChangePath(const APath: string);
begin
  if APath <> '' then
    if not FileSystem.TrySetCurrentDirectory(APath) then
      Log.WriteFormat(mkWarning, SCannotAccessPath, [APath]);
end;

procedure TIdeProject.DoAdd(const AFileName: string; const AKind: TIdeItemKind);
begin
  FItems.Add(TIdeProjectItem.Create(Self, FileSystem, Log, Clock, AFileName, AKind));
end;

procedure TIdeProject.Add(const AFileName: string; const AKind: TIdeItemKind);
begin
  if Find(AFileName) = nil then
  begin
    DoAdd(AFileName, AKind);
    // the old code asked for the text here, which refreshes it
    GetData;
    Modified := True;
  end;
end;

procedure TIdeProject.Clear;
begin
  FItems.Clear;
end;

procedure TIdeProject.Delete(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;
  FItems.Delete(AIndex);
end;

procedure TIdeProject.Delete(const AFileName: string);
begin
  Delete(Find(AFileName));
end;

procedure TIdeProject.Delete(const AItem: TIdeProjectItem);
begin
  if AItem = nil then
    Exit;
  Delete(FItems.IndexOf(AItem));
end;

function TIdeProject.Find(const AFileName: string): TIdeProjectItem;
var
  LItem: TIdeProjectItem;
  LRelative, LExpanded: string;
begin
  LRelative := ExtractRelativePath(FileName, AFileName);
  for LItem in FItems do
    if AnsiCompareText(LItem.RelativePath, LRelative) = 0 then
      Exit(LItem);
  for LItem in FItems do
    if AnsiCompareText(LItem.FileName, AFileName) = 0 then
      Exit(LItem);
  LExpanded := FileSystem.ExpandFileName(AFileName);
  for LItem in FItems do
    if AnsiCompareText(FileSystem.ExpandFileName(LItem.FileName), LExpanded) = 0 then
      Exit(LItem);
  Result := nil;
end;

procedure TIdeProject.DataToFields(const AData: AnsiString);
var
  LDirective: TIdeProjectDirective;
begin
  Clear;
  for LDirective in TIdeProjectFormat.Parse(AData) do
    if LDirective.IsGame then
      Game := LDirective.Value
    else
      Add(LDirective.Value, LDirective.Kind);
  inherited DataToFields(AData);
end;

procedure TIdeProject.FieldsToData(var AData: AnsiString);
var
  LEntries: TArray<TIdeProjectEntry>;
  LIndex: Integer;
begin
  SetLength(LEntries, FItems.Count);
  for LIndex := 0 to FItems.Count - 1 do
  begin
    LEntries[LIndex].Kind := FItems[LIndex].Kind;
    LEntries[LIndex].RelativePath := FItems[LIndex].RelativePath;
  end;
  AData := TIdeProjectFormat.Serialize(FGame, LEntries);
end;

function TIdeProject.GetModified: Boolean;
var
  LItem: TIdeProjectItem;
begin
  Result := inherited GetModified;
  if Result then
    Exit;
  for LItem in FItems do
  begin
    Result := LItem.Modified;
    if Result then
      Exit;
  end;
end;

function TIdeProject.LoadFromFile(const AFileName: string): Boolean;
begin
  ChangePath(ExtractFilePath(AFileName));
  Result := inherited LoadFromFile(AFileName);
end;

function TIdeProject.SaveToFile(const AFileName: string): Boolean;
var
  LItem: TIdeProjectItem;
  LSaved: Boolean;
begin
  ChangePath(ExtractFilePath(AFileName));
  Result := inherited SaveToFile(AFileName);
  for LItem in FItems do
  begin
    LSaved := LItem.SaveToFile(LItem.FileName);
    Result := Result and LSaved;
  end;
end;

function TIdeProject.CanRename(const AOldName: string): Boolean;
begin
  Result := Find(AOldName) <> nil;
  if Result then
    FPendingRename := AOldName
  else
    FPendingRename := '';
end;

function TIdeProject.CanCloseItemQuery(const AItem: TIdeProjectItem): Boolean;
begin
  Result := True;
  if AItem.Modified then
    if Assigned(FOnQueryModifiedItem) then
      Result := FOnQueryModifiedItem(AItem);
end;

function TIdeProject.ExecRename(const ANewName: string): Boolean;
var
  LItem, LOther: TIdeProjectItem;
  LOldName: string;
begin
  if ANewName = '' then
    Exit(False);

  LOldName := FPendingRename;
  FPendingRename := '';
  if LOldName = '' then
    Exit(False);

  LItem := Find(LOldName);
  Result := LItem <> nil;
  if not Result then
    Exit;

  LOther := Find(ANewName);
  if LOther <> nil then
  begin
    Log.WriteFormat(mkError, SRenameAlreadyInProject, [LOldName, ANewName, ANewName]);
    Exit(False);
  end;

  if FileSystem.FileExists(ANewName) then
  begin
    if CanCloseItemQuery(LItem) then
    begin
      Result := LItem.LoadFromFile(ANewName);
      if Result then
        Log.WriteFormat(mkInfo, SRenameReplaced, [LOldName, ANewName]);
    end
    else
    begin
      Log.WriteFormat(mkWarning, SRenameSavePending, [LOldName, ANewName]);
      Result := False;
    end;
  end
  else
  begin
    Result := LItem.SaveToFile(ANewName);
    if Result then
      Log.WriteFormat(mkInfo, SRenameSavedAs, [LOldName, ANewName]);
  end;

  NotifyChanged;
end;

function TIdeProject.Rename(const AOldName, ANewName: string): Boolean;
begin
  Result := CanRename(AOldName);
  if Result then
    Result := ExecRename(ANewName);
end;

end.

{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - a text file the ide edits                         }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Document;

interface

uses
  System.SysUtils,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.UncountedObject,
  DelphiDoom.Ide.UndoHistory;

type
  /// <summary>
  ///   A file of bytes (a script, an actor list, a project) with its name, its text, the "modified"
  ///   flag, undo and redo, and the view that shows it. It is the old TBaseEditorObject without
  ///   the frames: whoever shows the document attaches an IIdeDocumentObserver
  /// </summary>
  TIdeDocument = class(TIdeUncountedObject)
  strict private
    FFileSystem: IIdeFileSystem;
    FLog: IIdeLog;
    FClock: IIdeClock;
    FHistory: TIdeUndoHistory;
    FData: AnsiString;
    FFileName: string;
    FModified: Boolean;
    FObserver: IIdeDocumentObserver;
    function BackupFile(const AFileName: string): Boolean;
  protected
    property FileSystem: IIdeFileSystem read FFileSystem;
    property Log: IIdeLog read FLog;
    property Clock: IIdeClock read FClock;
    function GetData: AnsiString; virtual;
    procedure SetData(const AData: AnsiString); virtual;
    function GetModified: Boolean; virtual;
    /// <summary>The fields of a descendant are rebuilt from the text that was read</summary>
    procedure DataToFields(const AData: AnsiString); virtual;
    /// <summary>The text is rebuilt from the fields of a descendant</summary>
    procedure FieldsToData(var AData: AnsiString); virtual;
    /// <summary>Tells the view that the document changed</summary>
    procedure NotifyChanged; virtual;
  public
    /// <summary>
    ///   A name that is not empty is loaded at once (and created empty if the file does not exist)
    /// </summary>
    constructor Create(const AFileSystem: IIdeFileSystem; const ALog: IIdeLog;
      const AClock: IIdeClock; const AFileName: string = '');
    destructor Destroy; override;
    /// <summary>Reads the file, which is created empty if it is missing. Gives false (with a message) if it fails</summary>
    function LoadFromFile(const AFileName: string): Boolean; virtual;
    /// <summary>Writes the file after a dated copy of the old one. Gives false (with a message) if it fails</summary>
    function SaveToFile(const AFileName: string): Boolean; virtual;
    function CanUndo: Boolean;
    function CanRedo: Boolean;
    procedure Undo;
    procedure Redo;
    /// <summary>Remembers the text the document has now, so that the next change can be undone</summary>
    procedure SaveUndo;
    /// <summary>Sets the text and tells the view</summary>
    procedure AdjustLayout(const AData: AnsiString);
    /// <summary>The view starts to follow the document, and is told the text at once</summary>
    procedure Attach(const AObserver: IIdeDocumentObserver);
    /// <summary>The view stops following the document</summary>
    procedure Detach;
    function ShortFileName: string;
    property Data: AnsiString read GetData write SetData;
    property FileName: string read FFileName;
    property Modified: Boolean read GetModified write FModified;
  end;

implementation

uses
  DelphiDoom.Ide.Messages;

{ TIdeDocument }

constructor TIdeDocument.Create(const AFileSystem: IIdeFileSystem; const ALog: IIdeLog;
  const AClock: IIdeClock; const AFileName: string);
begin
  inherited Create;
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FFileSystem := AFileSystem;
  FLog := ALog;
  FClock := AClock;
  FHistory := TIdeUndoHistory.Create(IDE_UNDO_LIMIT);
  FFileName := FFileSystem.ExpandFileName(AFileName);
  FData := '';
  FModified := False;
  if FFileName <> '' then
    LoadFromFile(FFileName);
end;

destructor TIdeDocument.Destroy;
begin
  FHistory.Free;
  inherited Destroy;
end;

function TIdeDocument.BackupFile(const AFileName: string): Boolean;
var
  LBackupName: string;
begin
  Result := True;
  if not FFileSystem.FileExists(AFileName) then
    Exit;
  LBackupName := AFileName + '_' + FormatDateTime('yyyymmdd', FClock.Now);
  if FFileSystem.FileExists(LBackupName) then
    LBackupName := LBackupName + '_latest';
  Result := FFileSystem.TryCopyFile(AFileName, LBackupName);
end;

function TIdeDocument.GetData: AnsiString;
begin
  FieldsToData(FData);
  Result := FData;
end;

procedure TIdeDocument.SetData(const AData: AnsiString);
begin
  if FData <> AData then
  begin
    FData := AData;
    FModified := True;
    DataToFields(AData);
  end;
end;

function TIdeDocument.GetModified: Boolean;
begin
  Result := FModified;
end;

procedure TIdeDocument.DataToFields(const AData: AnsiString);
begin
end;

procedure TIdeDocument.FieldsToData(var AData: AnsiString);
begin
end;

procedure TIdeDocument.NotifyChanged;
begin
  if Assigned(FObserver) then
    FObserver.DocumentChanged(GetData);
end;

function TIdeDocument.LoadFromFile(const AFileName: string): Boolean;
var
  LOldName: string;
  LText: AnsiString;
begin
  LOldName := FFileName;
  FFileName := FFileSystem.ExpandFileName(AFileName);
  if not FFileSystem.FileExists(FFileName) then
  begin
    if not FFileSystem.TryCreateEmptyFile(FFileName) then
    begin
      FLog.WriteFormat(mkError, SCannotCreateFile, [FFileName]);
      FFileName := FFileSystem.ExpandFileName(LOldName);
      Result := False;
      Exit;
    end;
  end;
  Result := FFileSystem.TryReadAllText(FFileName, LText);
  if Result then
  begin
    // as in the old code, a failure while the fields are rebuilt is a failure to read
    try
      FData := LText;
      DataToFields(FData);
      NotifyChanged;
    except
      Result := False;
    end;
  end;
  if not Result then
  begin
    FLog.WriteFormat(mkError, SCannotReadFile, [FFileName]);
    FFileName := FFileSystem.ExpandFileName(LOldName);
    Exit;
  end;
  FHistory.Clear;
  FModified := False;
  FLog.WriteFormat(mkNormal, SLoadingFile, [FFileName]);
end;

function TIdeDocument.SaveToFile(const AFileName: string): Boolean;
var
  LOldName: string;
begin
  LOldName := FFileName;
  FFileName := FFileSystem.ExpandFileName(AFileName);
  Result := BackupFile(AFileName);
  if Result then
    Result := FFileSystem.TryWriteAllText(FFileName, GetData);
  if not Result then
  begin
    FLog.WriteFormat(mkError, SCannotWriteFile, [FFileName]);
    FFileName := FFileSystem.ExpandFileName(LOldName);
    Exit;
  end;
  FModified := False;
  FLog.WriteFormat(mkNormal, SSavingFile, [FFileName]);
end;

function TIdeDocument.CanUndo: Boolean;
begin
  Result := FHistory.CanUndo;
end;

function TIdeDocument.CanRedo: Boolean;
begin
  Result := FHistory.CanRedo;
end;

procedure TIdeDocument.Undo;
begin
  if not CanUndo then
    Exit;
  FData := FHistory.Undo(GetData);
  DataToFields(FData);
  NotifyChanged;
end;

procedure TIdeDocument.Redo;
begin
  if not CanRedo then
    Exit;
  FData := FHistory.Redo(GetData);
  DataToFields(FData);
  NotifyChanged;
end;

procedure TIdeDocument.SaveUndo;
begin
  FHistory.Save(GetData);
end;

procedure TIdeDocument.AdjustLayout(const AData: AnsiString);
begin
  SetData(AData);
  NotifyChanged;
end;

procedure TIdeDocument.Attach(const AObserver: IIdeDocumentObserver);
begin
  FObserver := AObserver;
  if Assigned(FObserver) then
    FObserver.DocumentChanged(FData);
end;

procedure TIdeDocument.Detach;
begin
  FObserver := nil;
end;

function TIdeDocument.ShortFileName: string;
begin
  Result := ExtractFileName(FFileName);
end;

end.

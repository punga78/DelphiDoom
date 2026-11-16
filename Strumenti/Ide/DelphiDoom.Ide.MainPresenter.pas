{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the rules of the main window                      }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.MainPresenter;

interface

uses
  System.SysUtils,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Project,
  DelphiDoom.Ide.ProjectItem,
  DelphiDoom.Ide.Pk3Builder,
  DelphiDoom.Ide.MessageLog,
  DelphiDoom.Ide.Views.Intf;

type
  /// <summary>
  ///   What the main window does when the user asks: new, open and save a project, add, delete and
  ///   rename its files, open a file for editing, change the game, pack the pk3, and the message
  ///   list. The window shows the results and gives the presenter the names the user chose
  /// </summary>
  TIdeMainPresenter = class
  strict private
    FView: IIdeMainView;
    FFileSystem: IIdeFileSystem;
    FLog: TIdeMessageLog;
    FLogIntf: IIdeLog;
    FClock: IIdeClock;
    FMessages: IIdeMessageDialogs;
    FFiles: IIdeFileDialogs;
    FBusy: IIdeBusy;
    FClipboard: IIdeClipboard;
    FLibrary: IIdeGameLibrary;
    FPk3Builder: TIdePk3Builder;
    FVersionText: TFunc<string>;
    FTitle: string;
    FProject: TIdeProject;
    function AskSaveProject: TIdeConfirmation;
    function AskSaveItem(const AItem: TIdeProjectItem): Boolean;
    procedure CreateProject(const AFileName: string; const AIsNew: Boolean);
    procedure ChangeGame(const AGame: string);
    procedure UpdateCaption;
    procedure DoSave(const AFileName: string);
  public
    /// <summary>The message list belongs to the window, which is told when it changes</summary>
    constructor Create(const AView: IIdeMainView; const AFileSystem: IIdeFileSystem;
      const ALog: TIdeMessageLog; const AClock: IIdeClock; const AMessages: IIdeMessageDialogs;
      const AFiles: IIdeFileDialogs; const ABusy: IIdeBusy; const AClipboard: IIdeClipboard;
      const ALibrary: IIdeGameLibrary; const APk3Builder: TIdePk3Builder;
      const AVersionText: TFunc<string>; const ATitle: string);
    destructor Destroy; override;
    /// <summary>
    ///   The first project: the file given on the command line, or an empty one. A project that
    ///   is opened keeps its own game (the old code set it back to Doom)
    /// </summary>
    procedure Start(const ACommandLineProject: string);
    procedure NewProject;
    procedure OpenProject;
    procedure Save;
    procedure SaveAs;
    procedure Undo;
    procedure Redo;
    /// <summary>Asks to save a project that was changed; false if the user wants to stay</summary>
    function CheckCanClose: Boolean;
    procedure About;
    /// <summary>The user chose files to add: the kind says which dialog (actors, scripts, compiled scripts)</summary>
    procedure AddItems(const AKind: TIdeItemKind);
    /// <summary>The file with this name in the tree is opened for editing</summary>
    procedure EditItem(const AName: string);
    /// <summary>The file with this name in the tree is taken out of the project and its tab is closed</summary>
    procedure DeleteItem(const AName: string);
    /// <summary>
    ///   The user starts to edit the name of a line of the tree: only the files can be renamed (a branch of
    ///   the tree has no parent)
    /// </summary>
    function CanRename(const AName: string; const AIsBranch: Boolean): Boolean;
    /// <summary>
    ///   The user finished editing a name. Gives the text the line must show: the path the project
    ///   keeps, or the old name if the rename was refused. A file with an open tab shows the text as it was typed
    /// </summary>
    function Rename(const AOldName, ANewName: string; const AIsBranch: Boolean): string;
    function CanGeneratePk3: Boolean;
    procedure GeneratePk3;
    procedure CopyMessage(const AIndex: Integer);
    procedure SaveMessages;
    procedure ClearMessages;
    property Project: TIdeProject read FProject;
  end;

implementation

uses
  DelphiDoom.Ide.Messages;

{ TIdeMainPresenter }

constructor TIdeMainPresenter.Create(const AView: IIdeMainView; const AFileSystem: IIdeFileSystem;
  const ALog: TIdeMessageLog; const AClock: IIdeClock; const AMessages: IIdeMessageDialogs;
  const AFiles: IIdeFileDialogs; const ABusy: IIdeBusy; const AClipboard: IIdeClipboard;
  const ALibrary: IIdeGameLibrary; const APk3Builder: TIdePk3Builder;
  const AVersionText: TFunc<string>; const ATitle: string);
begin
  inherited Create;
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(ABusy) then
    raise EArgumentNilException.Create('ABusy');
  if not Assigned(AClipboard) then
    raise EArgumentNilException.Create('AClipboard');
  if not Assigned(ALibrary) then
    raise EArgumentNilException.Create('ALibrary');
  if not Assigned(APk3Builder) then
    raise EArgumentNilException.Create('APk3Builder');
  if not Assigned(AVersionText) then
    raise EArgumentNilException.Create('AVersionText');
  FView := AView;
  FFileSystem := AFileSystem;
  FLog := ALog;
  FLogIntf := ALog;
  FClock := AClock;
  FMessages := AMessages;
  FFiles := AFiles;
  FBusy := ABusy;
  FClipboard := AClipboard;
  FLibrary := ALibrary;
  FPk3Builder := APk3Builder;
  FVersionText := AVersionText;
  FTitle := ATitle;
end;

destructor TIdeMainPresenter.Destroy;
begin
  if Assigned(FView) then
  begin
    FView.CloseAllEditors;
    FView.ShowProject(nil);
  end;
  FProject.Free;
  inherited Destroy;
end;

function TIdeMainPresenter.AskSaveProject: TIdeConfirmation;
begin
  Result := FMessages.AskSaveChanges('Do you want to save changes?');
end;

function TIdeMainPresenter.AskSaveItem(const AItem: TIdeProjectItem): Boolean;
begin
  case FMessages.AskSaveChanges('Do you want to save changes to "' + AItem.RelativePath + '"?') of
    cfCancel:
      Result := False;
    cfNo:
      Result := True;
  else
    begin
      AItem.SaveToFile(AItem.FileName);
      Result := not AItem.Modified;
    end;
  end;
end;

procedure TIdeMainPresenter.ChangeGame(const AGame: string);
var
  LGame: string;
begin
  LGame := LowerCase(AGame);
  FBusy.Enter;
  try
    FLibrary.Open(LGame);
    try
      FView.UpdateLibraryGame(LGame);
    finally
      FLibrary.Close;
    end;
  finally
    FBusy.Leave;
  end;
end;

procedure TIdeMainPresenter.CreateProject(const AFileName: string; const AIsNew: Boolean);
begin
  FView.CloseAllEditors;
  // the project manager must let go of the old project before it is freed
  FView.ShowProject(nil);
  FreeAndNil(FProject);
  FProject := TIdeProject.Create(FFileSystem, FLogIntf, FClock, AFileName);
  FProject.OnQueryModifiedItem :=
    function(const AItem: TIdeProjectItem): Boolean
    begin
      Result := AskSaveItem(AItem);
    end;
  FProject.OnGameChanged :=
    procedure(const AGame: string)
    begin
      ChangeGame(AGame);
    end;
  // a new project is for Doom; a project that was read keeps the game of its file
  if AIsNew then
    FProject.Game := 'doom'
  else
    FProject.Game := FProject.Game;
  FView.ShowProject(FProject);
  UpdateCaption;
end;

procedure TIdeMainPresenter.UpdateCaption;
var
  LTab: string;
begin
  if FProject = nil then
    Exit;
  if FProject.ShortFileName = '' then
    LTab := 'Untitled'
  else
    LTab := FProject.ShortFileName;
  FView.SetCaptions(FTitle + ' - ' + LTab, LTab);
end;

procedure TIdeMainPresenter.Start(const ACommandLineProject: string);
begin
  if ACommandLineProject <> '' then
    CreateProject(ACommandLineProject, False)
  else
    CreateProject('', True);
end;

procedure TIdeMainPresenter.NewProject;
begin
  if CheckCanClose then
    CreateProject('', True);
end;

procedure TIdeMainPresenter.OpenProject;
var
  LFileName: string;
begin
  if not CheckCanClose then
    Exit;
  if FFiles.PickProjectToOpen(LFileName) then
    CreateProject(LFileName, False);
end;

procedure TIdeMainPresenter.DoSave(const AFileName: string);
begin
  if FProject = nil then
    Exit;
  FBusy.Enter;
  try
    FProject.SaveToFile(AFileName);
    UpdateCaption;
  finally
    FBusy.Leave;
  end;
end;

procedure TIdeMainPresenter.Save;
begin
  if FProject = nil then
    Exit;
  if FProject.FileName = '' then
    SaveAs
  else
    DoSave(FProject.FileName);
end;

procedure TIdeMainPresenter.SaveAs;
var
  LFileName: string;
begin
  if FProject = nil then
    Exit;
  if FFiles.PickProjectToSave(LFileName) then
    DoSave(LFileName);
end;

procedure TIdeMainPresenter.Undo;
begin
  if (FProject <> nil) and FProject.CanUndo then
    FProject.Undo;
end;

procedure TIdeMainPresenter.Redo;
begin
  if (FProject <> nil) and FProject.CanRedo then
    FProject.Redo;
end;

function TIdeMainPresenter.CheckCanClose: Boolean;
begin
  Result := True;
  if (FProject = nil) or not FProject.Modified then
    Exit;
  case AskSaveProject of
    cfCancel:
      Result := False;
    cfNo:
      Result := True;
  else
    begin
      Save;
      Result := not FProject.Modified;
    end;
  end;
end;

procedure TIdeMainPresenter.About;
begin
  FMessages.ShowAbout(Format('%s'#13#10'Version ' + FVersionText() +
    #13#10#13#10'A tool for creating SCRIPTS for the DelphiDoom engine.'#13#10 +
    #169' 2016 - 2022, jvalavanis@gmail.com', [FTitle]));
end;

procedure TIdeMainPresenter.AddItems(const AKind: TIdeItemKind);
var
  LFileNames: TArray<string>;
  LFileName: string;
begin
  if FProject = nil then
    Exit;
  if FFiles.PickItemsToAdd(AKind, LFileNames) then
  begin
    for LFileName in LFileNames do
      FProject.Add(LFileName, AKind);
    FProject.AdjustLayout(FProject.Data);
  end;
end;

procedure TIdeMainPresenter.EditItem(const AName: string);
var
  LItem: TIdeProjectItem;
begin
  if FProject = nil then
    Exit;
  LItem := FProject.Find(AName);
  if LItem = nil then
    Exit;
  if LItem.Kind in [ikScript, ikCompiledScript, ikActor, ikProject] then
    FView.OpenEditor(LItem);
end;

procedure TIdeMainPresenter.DeleteItem(const AName: string);
var
  LItem: TIdeProjectItem;
begin
  if FProject = nil then
    Exit;
  LItem := FProject.Find(AName);
  if LItem = nil then
    Exit;
  FView.CloseEditor(LItem);
  FProject.Delete(LItem);
  FProject.AdjustLayout(FProject.Data);
end;

function TIdeMainPresenter.CanRename(const AName: string; const AIsBranch: Boolean): Boolean;
begin
  if (FProject = nil) or AIsBranch then
    Exit(False);
  Result := FProject.CanRename(AName);
end;

function TIdeMainPresenter.Rename(const AOldName, ANewName: string; const AIsBranch: Boolean): string;
var
  LItem: TIdeProjectItem;
  LHadEditor: Boolean;
begin
  Result := ANewName;
  if (FProject = nil) or (ANewName = AOldName) or AIsBranch then
    Exit;
  LItem := FProject.Find(AOldName);
  if LItem = nil then
    Exit;
  LHadEditor := FView.HasEditor(LItem);
  if FProject.Rename(AOldName, ANewName) then
  begin
    if LHadEditor then
      FView.ActivateEditor(LItem, LItem.RelativePath)
    else
      Result := LItem.RelativePath;
  end
  else
    Result := AOldName;
end;

function TIdeMainPresenter.CanGeneratePk3: Boolean;
begin
  Result := (FProject <> nil) and (FProject.Count > 0);
end;

procedure TIdeMainPresenter.GeneratePk3;
var
  LFileName: string;
begin
  if not CanGeneratePk3 then
    Exit;
  if FFiles.PickPk3ToSave(LFileName) then
    FPk3Builder.Generate(FProject, LFileName);
end;

procedure TIdeMainPresenter.CopyMessage(const AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FLog.Count) then
    FClipboard.SetText(FLog[AIndex].Text);
end;

procedure TIdeMainPresenter.SaveMessages;
var
  LFileName: string;
begin
  if FFiles.PickMessagesFileToSave(LFileName) then
    FFileSystem.TrySaveTextFile(LFileName, FLog.AsText);
end;

procedure TIdeMainPresenter.ClearMessages;
begin
  FLog.Clear;
end;

end.

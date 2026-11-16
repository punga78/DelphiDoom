{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the rules of the script editor                    }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.ScriptEditorPresenter;

interface

uses
  System.SysUtils,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.ProjectItem,
  DelphiDoom.Ide.UncountedObject,
  DelphiDoom.Ide.CompileCommand,
  DelphiDoom.Ide.ParameterHints,
  DelphiDoom.Ide.EventSnippets,
  DelphiDoom.Ide.Views.Intf;

type
  /// <summary>
  ///   One editor tab: it follows a file of the project, shows its text (a compiled script is shown
  ///   as the disassembly), compiles, saves, keeps the list of the events and the hints of the
  ///   parameters. The tab only draws and passes on what the user did. The tab frees
  ///   the presenter, which stops following the file
  /// </summary>
  TIdeScriptEditorPresenter = class(TIdeUncountedObject, IIdeDocumentObserver)
  strict private
    FItem: TIdeProjectItem;
    FView: IIdeScriptEditorView;
    FCompiler: IIdeScriptCompiler;
    FLibrary: IIdeGameLibrary;
    FFileSystem: IIdeFileSystem;
    FFiles: IIdePCodeDialog;
    FBusy: IIdeBusy;
    FLog: IIdeLog;
    FCommand: TIdeCompileCommand;
    FHints: TIdeParameterHints;
    FEvents: TArray<TIdeEventEntry>;
    FLastGame: string;
    procedure GenerateHints(const AGame: string);
    procedure SavePCode(const APCode: string);
  public
    constructor Create(const AItem: TIdeProjectItem; const AView: IIdeScriptEditorView;
      const ACompiler: IIdeScriptCompiler; const ALibrary: IIdeGameLibrary;
      const AFileSystem: IIdeFileSystem; const AFiles: IIdePCodeDialog; const ABusy: IIdeBusy;
      const ALog: IIdeLog);
    destructor Destroy; override;
    /// <summary>The file asks the editor to show its text (it was loaded, renamed or changed)</summary>
    procedure DocumentChanged(const AData: AnsiString);
    /// <summary>Shows the buttons the kind of file allows and rereads the events and the hints for the game of the project</summary>
    procedure UpdateControls;
    /// <summary>The user typed in the editor: a script or an actor list takes the new text</summary>
    procedure EditorChanged(const AText: string; const AModified: Boolean);
    procedure Compile(const ASaveCode: Boolean);
    procedure Save;
    function EventCount: Integer;
    /// <summary>The name for the menu of an event</summary>
    function EventCaption(const AIndex: Integer): string;
    /// <summary>The name an event has in a script, in upper case</summary>
    function EventScriptName(const AIndex: Integer): string;
    /// <summary>The text with the event added at the end; the offset is where the caret goes</summary>
    function AppendEvent(const AIndex: Integer; const ACurrentText: string; out ACaretOffset: Integer): string;
    /// <summary>The function the caret is in the brackets of, with its parameters, for the hint</summary>
    function FindCall(const ALineText: string; const ACaretX: Integer;
      const AIsIdentChar: TFunc<Char, Boolean>; out AFunctionName: string;
      out AParameterIndex: Integer; out AParameters: string): Boolean;
    property Item: TIdeProjectItem read FItem;
  end;

implementation

uses
  DelphiDoom.Ide.Messages,
  DelphiDoom.Ide.PCodeFile;

{ TIdeScriptEditorPresenter }

constructor TIdeScriptEditorPresenter.Create(const AItem: TIdeProjectItem;
  const AView: IIdeScriptEditorView; const ACompiler: IIdeScriptCompiler;
  const ALibrary: IIdeGameLibrary; const AFileSystem: IIdeFileSystem;
  const AFiles: IIdePCodeDialog; const ABusy: IIdeBusy; const ALog: IIdeLog);
begin
  inherited Create;
  if not Assigned(AItem) then
    raise EArgumentNilException.Create('AItem');
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  if not Assigned(ACompiler) then
    raise EArgumentNilException.Create('ACompiler');
  if not Assigned(ALibrary) then
    raise EArgumentNilException.Create('ALibrary');
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(ABusy) then
    raise EArgumentNilException.Create('ABusy');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FItem := AItem;
  FView := AView;
  FCompiler := ACompiler;
  FLibrary := ALibrary;
  FFileSystem := AFileSystem;
  FFiles := AFiles;
  FBusy := ABusy;
  FLog := ALog;
  FCommand := TIdeCompileCommand.Create(ACompiler, ALog);
  FHints := TIdeParameterHints.Create;
  FLastGame := '';
  // the file tells its text now, which shows it
  FItem.Attach(Self);
end;

destructor TIdeScriptEditorPresenter.Destroy;
begin
  if Assigned(FItem) then
    FItem.Detach;
  FHints.Free;
  FCommand.Free;
  inherited Destroy;
end;

procedure TIdeScriptEditorPresenter.DocumentChanged(const AData: AnsiString);
begin
  FBusy.Enter;
  try
    case FItem.Kind of
      ikScript, ikActor:
        FView.ShowText(string(AData));
      ikCompiledScript:
        begin
          FLog.WriteFormat(mkNormal, SDisassembling, [FItem.Project.Game, FItem.FileName]);
          FView.ShowText(FCompiler.Disassemble(FItem.Project.Game, string(AData)));
        end;
    end;
    UpdateControls;
  finally
    FBusy.Leave;
  end;
end;

procedure TIdeScriptEditorPresenter.UpdateControls;
var
  LLines: TArray<string>;
begin
  FView.ShowTools(FItem.Kind);
  FEvents := nil;
  if FItem.Kind = ikScript then
    if FLibrary.TryGetLines(ldEvents, FItem.Project.Game, LLines) then
      FEvents := TIdeEventSnippets.Parse(LLines);
  GenerateHints(FItem.Project.Game);
end;

procedure TIdeScriptEditorPresenter.GenerateHints(const AGame: string);
var
  LUnits: TArray<TIdeUnitDeclarations>;
  LActorFunctions: TArray<string>;
begin
  if LowerCase(FLastGame) = LowerCase(AGame) then
    Exit;
  FLastGame := LowerCase(AGame);
  if not FLibrary.TryGetUnitFunctions(FLastGame, LUnits) then
    Exit;
  LActorFunctions := nil;
  if FItem.Kind = ikActor then
    if not FLibrary.TryGetLines(ldActorDefFunctions, FLastGame, LActorFunctions) then
      LActorFunctions := nil;
  FHints.Rebuild(LUnits, LActorFunctions);
end;

procedure TIdeScriptEditorPresenter.EditorChanged(const AText: string; const AModified: Boolean);
begin
  if AModified and (FItem.Kind in [ikScript, ikActor]) then
    FItem.Data := AnsiString(AText);
end;

procedure TIdeScriptEditorPresenter.SavePCode(const APCode: string);
var
  LFileName: string;
begin
  if FFiles.PickPCodeFileToSave(ChangeFileExt(FItem.FileName, '.ddout'), LFileName) then
    if not TIdePCodeFile.Save(FFileSystem, LFileName, APCode) then
      FLog.WriteFormat(mkError, SCannotWriteFile, [LFileName]);
end;

procedure TIdeScriptEditorPresenter.Compile(const ASaveCode: Boolean);
var
  LResult: TIdeCompileResult;
begin
  if FItem.Kind <> ikScript then
    Exit;
  FBusy.Enter;
  try
    LResult := FCommand.Execute(FItem.Project.Game, FItem.RelativePath, FView.EditorText);
    if LResult.Success and ASaveCode then
      SavePCode(LResult.PCode);
    if LResult.HasErrorLocation then
      FView.MoveCaretTo(LResult.ErrorLocation);
  finally
    FBusy.Leave;
  end;
end;

procedure TIdeScriptEditorPresenter.Save;
begin
  if FItem.Kind in [ikScript, ikActor] then
  begin
    FBusy.Enter;
    try
      FItem.SaveToFile(FItem.FileName);
    finally
      FBusy.Leave;
    end;
  end;
end;

function TIdeScriptEditorPresenter.EventCount: Integer;
begin
  Result := Length(FEvents);
end;

function TIdeScriptEditorPresenter.EventCaption(const AIndex: Integer): string;
begin
  Result := FEvents[AIndex].Name;
end;

function TIdeScriptEditorPresenter.EventScriptName(const AIndex: Integer): string;
begin
  Result := UpperCase(FEvents[AIndex].Name);
end;

function TIdeScriptEditorPresenter.AppendEvent(const AIndex: Integer; const ACurrentText: string;
  out ACaretOffset: Integer): string;
begin
  Result := TIdeEventSnippets.Append(FEvents[AIndex].Declaration, ACurrentText, ACaretOffset);
end;

function TIdeScriptEditorPresenter.FindCall(const ALineText: string; const ACaretX: Integer;
  const AIsIdentChar: TFunc<Char, Boolean>; out AFunctionName: string;
  out AParameterIndex: Integer; out AParameters: string): Boolean;
begin
  Result := FHints.TryFindCall(ALineText, ACaretX, AIsIdentChar, AFunctionName, AParameterIndex,
    AParameters);
end;

end.

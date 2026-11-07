{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - dialogs, windows and clipboard       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.FakeUi;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Project,
  DelphiDoom.Ide.ProjectItem,
  DelphiDoom.Ide.Views.Intf;

type
  /// <summary>Answers the questions with the answers the test queued, and remembers them</summary>
  TFakeIdeMessageDialogs = class(TInterfacedObject, IIdeMessageDialogs)
  public
    Answers: TQueue<TIdeConfirmation>;
    Questions: TStringList;
    About: string;
    constructor Create;
    destructor Destroy; override;
    function AskSaveChanges(const AQuestion: string): TIdeConfirmation;
    procedure ShowAbout(const AText: string);
  end;

  /// <summary>The file the user "picks" in each dialog is set by the test; an empty name means cancel</summary>
  TFakeIdeFileDialogs = class(TInterfacedObject, IIdeFileDialogs)
  public
    ProjectToOpen: string;
    ProjectToSave: string;
    ItemsToAdd: TArray<string>;
    Pk3ToSave: string;
    MessagesFile: string;
    PCodeFile: string;
    LastItemKind: TIdeItemKind;
    LastPCodeDefault: string;
    function PickProjectToOpen(out AFileName: string): Boolean;
    function PickProjectToSave(out AFileName: string): Boolean;
    function PickItemsToAdd(const AKind: TIdeItemKind; out AFileNames: TArray<string>): Boolean;
    function PickPk3ToSave(out AFileName: string): Boolean;
    function PickMessagesFileToSave(out AFileName: string): Boolean;
    function PickPCodeFileToSave(const ADefaultName: string; out AFileName: string): Boolean;
  end;

  TFakeIdeBusy = class(TInterfacedObject, IIdeBusy)
  public
    Depth: Integer;
    Entered: Integer;
    procedure Enter;
    procedure Leave;
  end;

  TFakeIdeClipboard = class(TInterfacedObject, IIdeClipboard)
  public
    Text: string;
    procedure SetText(const AText: string);
  end;

  /// <summary>The main window: writes down what it was asked to do</summary>
  TFakeIdeMainView = class(TInterfacedObject, IIdeMainView)
  public
    Calls: TStringList;
    EditorOpen: TList<TIdeProjectItem>;
    FailOnUpdateLibrary: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure CloseAllEditors;
    procedure ShowProject(const AProject: TIdeProject);
    procedure SetCaptions(const AWindowCaption, ATabCaption: string);
    procedure OpenEditor(const AItem: TIdeProjectItem);
    procedure CloseEditor(const AItem: TIdeProjectItem);
    function HasEditor(const AItem: TIdeProjectItem): Boolean;
    procedure ActivateEditor(const AItem: TIdeProjectItem; const ACaption: string);
    procedure UpdateLibraryGame(const AGame: string);
  end;

  /// <summary>A script editor window: keeps the text it was given</summary>
  TFakeIdeScriptEditorView = class(TInterfacedObject, IIdeScriptEditorView)
  public
    Text: string;
    Kind: TIdeItemKind;
    Caret: TIdeSourceLocation;
    CaretMoved: Boolean;
    ShowTextCount: Integer;
    function EditorText: string;
    procedure MoveCaretTo(const ALocation: TIdeSourceLocation);
    procedure ShowText(const AText: string);
    procedure ShowTools(const AKind: TIdeItemKind);
  end;

implementation

{ TFakeIdeMessageDialogs }

constructor TFakeIdeMessageDialogs.Create;
begin
  inherited Create;
  Answers := TQueue<TIdeConfirmation>.Create;
  Questions := TStringList.Create;
end;

destructor TFakeIdeMessageDialogs.Destroy;
begin
  Questions.Free;
  Answers.Free;
  inherited Destroy;
end;

function TFakeIdeMessageDialogs.AskSaveChanges(const AQuestion: string): TIdeConfirmation;
begin
  Questions.Add(AQuestion);
  if Answers.Count > 0 then
    Result := Answers.Dequeue
  else
    Result := cfCancel;
end;

procedure TFakeIdeMessageDialogs.ShowAbout(const AText: string);
begin
  About := AText;
end;

{ TFakeIdeFileDialogs }

function TFakeIdeFileDialogs.PickProjectToOpen(out AFileName: string): Boolean;
begin
  AFileName := ProjectToOpen;
  Result := AFileName <> '';
end;

function TFakeIdeFileDialogs.PickProjectToSave(out AFileName: string): Boolean;
begin
  AFileName := ProjectToSave;
  Result := AFileName <> '';
end;

function TFakeIdeFileDialogs.PickItemsToAdd(const AKind: TIdeItemKind;
  out AFileNames: TArray<string>): Boolean;
begin
  LastItemKind := AKind;
  AFileNames := ItemsToAdd;
  Result := Length(AFileNames) > 0;
end;

function TFakeIdeFileDialogs.PickPk3ToSave(out AFileName: string): Boolean;
begin
  AFileName := Pk3ToSave;
  Result := AFileName <> '';
end;

function TFakeIdeFileDialogs.PickMessagesFileToSave(out AFileName: string): Boolean;
begin
  AFileName := MessagesFile;
  Result := AFileName <> '';
end;

function TFakeIdeFileDialogs.PickPCodeFileToSave(const ADefaultName: string;
  out AFileName: string): Boolean;
begin
  LastPCodeDefault := ADefaultName;
  AFileName := PCodeFile;
  Result := AFileName <> '';
end;

{ TFakeIdeBusy }

procedure TFakeIdeBusy.Enter;
begin
  Inc(Depth);
  Inc(Entered);
end;

procedure TFakeIdeBusy.Leave;
begin
  Dec(Depth);
end;

{ TFakeIdeClipboard }

procedure TFakeIdeClipboard.SetText(const AText: string);
begin
  Text := AText;
end;

{ TFakeIdeMainView }

constructor TFakeIdeMainView.Create;
begin
  inherited Create;
  Calls := TStringList.Create;
  EditorOpen := TList<TIdeProjectItem>.Create;
end;

destructor TFakeIdeMainView.Destroy;
begin
  EditorOpen.Free;
  Calls.Free;
  inherited Destroy;
end;

procedure TFakeIdeMainView.CloseAllEditors;
begin
  Calls.Add('CloseAllEditors');
  EditorOpen.Clear;
end;

procedure TFakeIdeMainView.ShowProject(const AProject: TIdeProject);
begin
  Calls.Add('ShowProject ' + AProject.Game);
end;

procedure TFakeIdeMainView.SetCaptions(const AWindowCaption, ATabCaption: string);
begin
  Calls.Add('SetCaptions ' + AWindowCaption + ' | ' + ATabCaption);
end;

procedure TFakeIdeMainView.OpenEditor(const AItem: TIdeProjectItem);
begin
  Calls.Add('OpenEditor ' + AItem.RelativePath);
  if not EditorOpen.Contains(AItem) then
    EditorOpen.Add(AItem);
end;

procedure TFakeIdeMainView.CloseEditor(const AItem: TIdeProjectItem);
begin
  Calls.Add('CloseEditor ' + AItem.RelativePath);
  EditorOpen.Remove(AItem);
end;

function TFakeIdeMainView.HasEditor(const AItem: TIdeProjectItem): Boolean;
begin
  Result := EditorOpen.Contains(AItem);
end;

procedure TFakeIdeMainView.ActivateEditor(const AItem: TIdeProjectItem; const ACaption: string);
begin
  Calls.Add('ActivateEditor ' + ACaption);
end;

procedure TFakeIdeMainView.UpdateLibraryGame(const AGame: string);
begin
  Calls.Add('UpdateLibraryGame ' + AGame);
  if FailOnUpdateLibrary then
    raise Exception.Create('the panels failed');
end;

{ TFakeIdeScriptEditorView }

function TFakeIdeScriptEditorView.EditorText: string;
begin
  Result := Text;
end;

procedure TFakeIdeScriptEditorView.MoveCaretTo(const ALocation: TIdeSourceLocation);
begin
  Caret := ALocation;
  CaretMoved := True;
end;

procedure TFakeIdeScriptEditorView.ShowText(const AText: string);
begin
  Text := AText;
  Inc(ShowTextCount);
end;

procedure TFakeIdeScriptEditorView.ShowTools(const AKind: TIdeItemKind);
begin
  Kind := AKind;
end;

end.

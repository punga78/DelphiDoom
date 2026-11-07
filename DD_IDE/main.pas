unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, ComCtrls, Menus, ActnList, ImgList,
  frm_projectmanager, AppEvnts, StdActns, StdCtrls,
  frm_unitfunctions, frm_constants, frm_variables, frm_classes, frm_types,
  frm_actordef, frm_mobjinfo, frm_states, frm_sprites,
  frm_scripteditor,
  DelphiDoom.Ide.Types, DelphiDoom.Ide.Intf, DelphiDoom.Ide.Project,
  DelphiDoom.Ide.ProjectItem, DelphiDoom.Ide.MainPresenter, DelphiDoom.Ide.Views.Intf,
  DelphiDoom.Ide.Composition;

type
  /// <summary>
  ///   The main window of the ide. It shows the project, the tabs of the editors, the panels of
  ///   the library and the messages; what happens when the user asks something is decided by
  ///   TIdeMainPresenter, which this window gives the names the user chose
  /// </summary>
  TForm1 = class(TForm, IIdeMainView)
    AboutButton1: TSpeedButton;
    ActionQuit: TAction;
    ActionAbout: TAction;
    ActionRedo: TAction;
    ActionUndo: TAction;
    ActionSaveAs: TAction;
    ActionSave: TAction;
    ActionOpenProject: TAction;
    ActionNewProject: TAction;
    ActionList1: TActionList;
    Bevel1: TBevel;
    ExitButton1: TSpeedButton;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem25: TMenuItem;
    MenuItem26: TMenuItem;
    MenuItem27: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    NewButton1: TSpeedButton;
    OpenButton1: TSpeedButton;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel5: TPanel;
    Panel7: TPanel;
    LibraryPanel: TPanel;
    RedoButton1: TSpeedButton;
    SaveAsButton1: TSpeedButton;
    SaveButton1: TSpeedButton;
    SaveProjectDialog: TSaveDialog;
    LibrarySplitter: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    UndoButton1: TSpeedButton;
    PageControl2: TPageControl;
    TabSheet1: TTabSheet;
    Frame_ProjectManager1: TFrame_ProjectManager;
    ActionGoToLineNumber: TAction;
    OpenProjectDialog: TOpenDialog;
    StatusBar1: TStatusBar;
    ApplicationEvents1: TApplicationEvents;
    AddNewActorDialog1: TOpenDialog;
    AddNewScriptDialog1: TOpenDialog;
    EditCut1: TEditCut;
    EditCopy1: TEditCopy;
    EditPaste1: TEditPaste;
    EditSelectAll1: TEditSelectAll;
    EditDelete1: TEditDelete;
    SelectAll1: TMenuItem;
    EditUndo1: TEditUndo;
    NewActor1: TMenuItem;
    NewScript1: TMenuItem;
    NewCompiledScript1: TMenuItem;
    AddNewCompiledScriptDialog1: TOpenDialog;
    BottomPageControl: TPageControl;
    OutputTabSheet: TTabSheet;
    MessagesListBox: TListBox;
    ActionFind: TAction;
    ActionReplace: TAction;
    ActionSearchAgain: TAction;
    ActionProjectDeleteItem: TAction;
    N1: TMenuItem;
    GeneratePK31: TMenuItem;
    GeneratePK3SaveDialog: TSaveDialog;
    PopupMenu1: TPopupMenu;
    Clearmessages1: TMenuItem;
    SaveMessages1: TMenuItem;
    N2: TMenuItem;
    Copy1: TMenuItem;
    SaveMessagesDialog: TSaveDialog;
    Panel2: TPanel;
    LibraryButton1: TSpeedButton;
    LibraryPageControl: TPageControl;
    FunctionsTabSheet: TTabSheet;
    TabSheet3: TTabSheet;
    Frame_UnitFunctions1: TFrame_UnitFunctions;
    Frame_Constants1: TFrame_Constants;
    TabSheet2: TTabSheet;
    Frame_Variables1: TFrame_Variables;
    TabSheet4: TTabSheet;
    Frame_Classes1: TFrame_Classes;
    TabSheet5: TTabSheet;
    Frame_Types1: TFrame_Types;
    TabSheet6: TTabSheet;
    Frame_Actordef1: TFrame_Actordef;
    TabSheet7: TTabSheet;
    Frame_Mobjinfo1: TFrame_Mobjinfo;
    TabSheet8: TTabSheet;
    Frame_States1: TFrame_States;
    TabSheet9: TTabSheet;
    Frame_Sprites1: TFrame_Sprites;
    procedure ActionAboutExecute(Sender: TObject);
    procedure ActionNewProjectExecute(Sender: TObject);
    procedure ActionOpenProjectExecute(Sender: TObject);
    procedure ActionQuitExecute(Sender: TObject);
    procedure ActionRedoExecute(Sender: TObject);
    procedure ActionSaveAsExecute(Sender: TObject);
    procedure ActionSaveExecute(Sender: TObject);
    procedure ActionUndoExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure ActionGoToLineNumberExecute(Sender: TObject);
    procedure ApplicationEvents1Hint(Sender: TObject);
    procedure Frame_ProjectManager1AddActorButton1Click(Sender: TObject);
    procedure Frame_ProjectManager1TreeView1DblClick(Sender: TObject);
    procedure Frame_ProjectManager1AddScriptButton1Click(Sender: TObject);
    procedure Frame_ProjectManager1AddCompiledScriptButton1Click(
      Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure ActionFindExecute(Sender: TObject);
    procedure ActionReplaceExecute(Sender: TObject);
    procedure ActionSearchAgainExecute(Sender: TObject);
    procedure Frame_ProjectManager1TreeView1Editing(Sender: TObject;
      Node: TTreeNode; var AllowEdit: Boolean);
    procedure Frame_ProjectManager1TreeView1Edited(Sender: TObject;
      Node: TTreeNode; var S: String);
    procedure MessagesListBoxDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure MenuItem3Click(Sender: TObject);
    procedure ActionProjectDeleteItemExecute(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure GeneratePK31Click(Sender: TObject);
    procedure Copy1Click(Sender: TObject);
    procedure Clearmessages1Click(Sender: TObject);
    procedure SaveMessages1Click(Sender: TObject);
    procedure LibraryButton1Click(Sender: TObject);
    procedure LibraryPanelResize(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PageControl1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PageControl1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure PageControl1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure Frame_ProjectManager1GameTypeComboBoxChange(Sender: TObject);
  private
    FServices: TIdeServices;
    FPresenter: TIdeMainPresenter;
    FFileDialogs: IIdeFileDialogs;
    function ActiveEditorFrame: TFrame;
    function FindItemEditor(const AItem: TIdeProjectItem): TFrame_ScriptEditor;
    procedure SyncMessages;
    { IIdeMainView }
    procedure CloseAllEditors;
    procedure ShowProject(const AProject: TIdeProject);
    procedure SetCaptions(const AWindowCaption, ATabCaption: string);
    procedure OpenEditor(const AItem: TIdeProjectItem);
    procedure CloseEditor(const AItem: TIdeProjectItem);
    function HasEditor(const AItem: TIdeProjectItem): Boolean;
    procedure ActivateEditor(const AItem: TIdeProjectItem; const ACaption: string);
    procedure UpdateLibraryGame(const AGame: string);
  public
    /// <summary>
    ///   Gives the window the services it needs, and the window owns them from now on (it frees
    ///   them when it is destroyed). It must be called before Start
    /// </summary>
    procedure Configure(const AServices: TIdeServices);
    /// <summary>Opens the project of the command line, or starts a new one</summary>
    procedure Start(const ACommandLineProject: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ TForm1 }

uses
  DelphiDoom.Ide.Win.FileDialogs;

const
  MESSAGE_COLORS: array[TIdeMessageKind] of TColor = (
    TColor($100020), // normal
    TColor($208020), // info
    TColor($4040FF), // warning
    TColor($2020FF)  // error
  );

//==============================================================================
//
// TForm1.Configure
//
//==============================================================================
procedure TForm1.Configure(const AServices: TIdeServices);
begin
  FServices := AServices;
  FFileDialogs := TVclIdeFileDialogs.Create(OpenProjectDialog, SaveProjectDialog,
    AddNewActorDialog1, AddNewScriptDialog1, AddNewCompiledScriptDialog1,
    GeneratePK3SaveDialog, SaveMessagesDialog);
  FServices.Log.OnChanged :=
    procedure
    begin
      SyncMessages;
    end;
  FPresenter := TIdeMainPresenter.Create(Self, FServices.FileSystem, FServices.Log,
    FServices.Clock, FServices.MessageDialogs, FFileDialogs, FServices.Busy, FServices.Clipboard,
    FServices.GameLibrary, FServices.Pk3Builder,
    function: string
    begin
      Result := FServices.VersionText;
    end, FServices.Title);
  Frame_UnitFunctions1.Configure(FServices);
  Frame_Constants1.Configure(FServices);
  Frame_Variables1.Configure(FServices);
  Frame_Classes1.Configure(FServices);
  Frame_Types1.Configure(FServices);
  Frame_Actordef1.Configure(FServices);
  Frame_Mobjinfo1.Configure(FServices);
  Frame_States1.Configure(FServices);
  Frame_Sprites1.Configure(FServices);
end;

//==============================================================================
//
// TForm1.Start
//
//==============================================================================
procedure TForm1.Start(const ACommandLineProject: string);
begin
  FPresenter.Start(ACommandLineProject);
end;

//==============================================================================
//
// TForm1.FormCreate
//
//==============================================================================
procedure TForm1.FormCreate(Sender: TObject);
begin
  Scaled := False;
  LibraryPanel.Width := 16;
  LibraryPageControl.ActivePageIndex := 0;
  MessagesListBox.Style := lbOwnerDrawFixed;
end;

//==============================================================================
//
// TForm1.FormDestroy
//
//==============================================================================
procedure TForm1.FormDestroy(Sender: TObject);
begin
  if FServices <> nil then
    FServices.Log.OnChanged := nil;
  FreeAndNil(FPresenter);
  FreeAndNil(FServices);
end;

//==============================================================================
//
// TForm1.FormCloseQuery
//
//==============================================================================
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := FPresenter.CheckCanClose;
end;

//==============================================================================
//
// the actions
//
//==============================================================================
procedure TForm1.ActionNewProjectExecute(Sender: TObject);
begin
  FPresenter.NewProject;
end;

procedure TForm1.ActionAboutExecute(Sender: TObject);
begin
  FPresenter.About;
end;

procedure TForm1.ActionOpenProjectExecute(Sender: TObject);
begin
  FPresenter.OpenProject;
end;

procedure TForm1.ActionQuitExecute(Sender: TObject);
begin
  Close;
end;

procedure TForm1.ActionRedoExecute(Sender: TObject);
begin
  FPresenter.Redo;
end;

procedure TForm1.ActionSaveAsExecute(Sender: TObject);
begin
  FPresenter.SaveAs;
end;

procedure TForm1.ActionSaveExecute(Sender: TObject);
begin
  FPresenter.Save;
end;

procedure TForm1.ActionUndoExecute(Sender: TObject);
begin
  FPresenter.Undo;
end;

//==============================================================================
//
// TForm1.ActiveEditorFrame
//
//==============================================================================
function TForm1.ActiveEditorFrame: TFrame;
var
  i: integer;
  iTab: TTabSheet;
begin
  iTab := PageControl1.ActivePage;
  if iTab = nil then
  begin
    Result := nil;
    Exit;
  end;

  for i := 0 to iTab.ComponentCount - 1 do
    if iTab.Components[i].InheritsFrom(TFrame) then
    begin
      Result := iTab.Components[i] as TFrame;
      Exit;
    end;

  Result := nil;
end;

procedure TForm1.ActionGoToLineNumberExecute(Sender: TObject);
var
  frm: TFrame;
begin
  frm := ActiveEditorFrame;
  if frm is TFrame_ScriptEditor then
    (frm as TFrame_ScriptEditor).GoToLineNumber;
end;

procedure TForm1.ActionFindExecute(Sender: TObject);
var
  frm: TFrame;
begin
  frm := ActiveEditorFrame;
  if frm is TFrame_ScriptEditor then
    (frm as TFrame_ScriptEditor).ShowSearchDialog;
end;

procedure TForm1.ActionReplaceExecute(Sender: TObject);
var
  frm: TFrame;
begin
  frm := ActiveEditorFrame;
  if frm is TFrame_ScriptEditor then
    (frm as TFrame_ScriptEditor).ShowReplaceDialog;
end;

procedure TForm1.ActionSearchAgainExecute(Sender: TObject);
var
  frm: TFrame;
begin
  frm := ActiveEditorFrame;
  if frm is TFrame_ScriptEditor then
    (frm as TFrame_ScriptEditor).SearchAgain;
end;

procedure TForm1.ApplicationEvents1Hint(Sender: TObject);
begin
  StatusBar1.Panels[0].Text := Application.Hint;
end;

//==============================================================================
//
// the buttons and the tree of the project manager
//
//==============================================================================
procedure TForm1.Frame_ProjectManager1AddActorButton1Click(Sender: TObject);
begin
  FPresenter.AddItems(ikActor);
end;

procedure TForm1.Frame_ProjectManager1AddScriptButton1Click(Sender: TObject);
begin
  FPresenter.AddItems(ikScript);
end;

procedure TForm1.Frame_ProjectManager1AddCompiledScriptButton1Click(Sender: TObject);
begin
  FPresenter.AddItems(ikCompiledScript);
end;

procedure TForm1.Frame_ProjectManager1TreeView1DblClick(Sender: TObject);
begin
  if Frame_ProjectManager1.TreeView1.Selected <> nil then
    FPresenter.EditItem(Frame_ProjectManager1.TreeView1.Selected.Text);
end;

procedure TForm1.ActionProjectDeleteItemExecute(Sender: TObject);
begin
  if Frame_ProjectManager1.TreeView1.Selected <> nil then
    FPresenter.DeleteItem(Frame_ProjectManager1.TreeView1.Selected.Text);
end;

procedure TForm1.Frame_ProjectManager1TreeView1Editing(Sender: TObject;
  Node: TTreeNode; var AllowEdit: Boolean);
begin
  AllowEdit := FPresenter.CanRename(Node.Text, Node.Parent = nil);
end;

procedure TForm1.Frame_ProjectManager1TreeView1Edited(Sender: TObject;
  Node: TTreeNode; var S: String);
begin
  S := FPresenter.Rename(Node.Text, S, Node.Parent = nil);
end;

procedure TForm1.Frame_ProjectManager1GameTypeComboBoxChange(Sender: TObject);
begin
  Frame_ProjectManager1.GameTypeComboBoxChange(Sender);
end;

//==============================================================================
//
// the menus
//
//==============================================================================
procedure TForm1.MenuItem3Click(Sender: TObject);
var
  b: Boolean;
begin
  b := ActiveEditorFrame <> nil;
  ActionFind.Enabled := b;
  ActionGoToLineNumber.Enabled := b;
  ActionReplace.Enabled := b;
  ActionSearchAgain.Enabled := b;
end;

procedure TForm1.MenuItem10Click(Sender: TObject);
begin
  GeneratePK31.Enabled := FPresenter.CanGeneratePk3;
end;

procedure TForm1.GeneratePK31Click(Sender: TObject);
begin
  FPresenter.GeneratePk3;
end;

//==============================================================================
//
// the tabs of the editors
//
//==============================================================================
procedure TForm1.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
var
  i: integer;
begin
  for i := PageControl1.PageCount - 1 downto 0 do
    if not PageControl1.Pages[i].Enabled then
      PageControl1.Pages[i].Free;
  Done := True;
end;

function TForm1.FindItemEditor(const AItem: TIdeProjectItem): TFrame_ScriptEditor;
var
  TabSheet: TTabSheet;
  i, j: integer;
  frm: TFrame;
begin
  for i := PageControl1.PageCount - 1 downto 0 do
  begin
    TabSheet := PageControl1.Pages[i];
    for j := 0 to TabSheet.ComponentCount - 1 do
      if TabSheet.Components[j] is TFrame then
      begin
        frm := TabSheet.Components[j] as TFrame;
        if (frm.Parent = TabSheet) and (frm is TFrame_ScriptEditor) then
          if (frm as TFrame_ScriptEditor).Item = AItem then
          begin
            Result := frm as TFrame_ScriptEditor;
            Exit;
          end;
      end;
  end;
  Result := nil;
end;

procedure TForm1.CloseAllEditors;
var
  i: integer;
begin
  for i := PageControl1.PageCount - 1 downto 0 do
    PageControl1.Pages[i].Free;
end;

procedure TForm1.ShowProject(const AProject: TIdeProject);
begin
  Frame_ProjectManager1.AttachProject(AProject);
end;

procedure TForm1.SetCaptions(const AWindowCaption, ATabCaption: string);
begin
  if PageControl2.ActivePage = nil then
    Exit;
  PageControl2.ActivePage.Caption := ATabCaption;
  Caption := AWindowCaption;
end;

procedure TForm1.OpenEditor(const AItem: TIdeProjectItem);
var
  frm: TFrame_ScriptEditor;
  TabSheet: TTabSheet;
begin
  frm := FindItemEditor(AItem);
  if frm <> nil then
  begin
    if frm.Parent is TTabSheet then
    begin
      PageControl1.ActivePage := (frm.Parent as TTabSheet);
      Exit;
    end;
  end;

  TabSheet := TTabSheet.Create(self);
  TabSheet.PageControl := PageControl1;
  TabSheet.Align := alClient;
  TabSheet.Caption := AItem.RelativePath;
  PageControl1.ActivePage := TabSheet;

  frm := TFrame_ScriptEditor.Create(TabSheet);
  frm.Parent := TabSheet;
  frm.Align := alClient;
  frm.Configure(FServices, AItem);
end;

procedure TForm1.CloseEditor(const AItem: TIdeProjectItem);
var
  frm: TFrame_ScriptEditor;
begin
  frm := FindItemEditor(AItem);
  if frm <> nil then
    if frm.Parent is TTabSheet then
      (frm.Parent as TTabSheet).Free;
end;

function TForm1.HasEditor(const AItem: TIdeProjectItem): Boolean;
var
  frm: TFrame_ScriptEditor;
begin
  frm := FindItemEditor(AItem);
  Result := (frm <> nil) and (frm.Parent is TTabSheet);
end;

procedure TForm1.ActivateEditor(const AItem: TIdeProjectItem; const ACaption: string);
var
  frm: TFrame_ScriptEditor;
begin
  frm := FindItemEditor(AItem);
  if (frm <> nil) and (frm.Parent is TTabSheet) then
  begin
    PageControl1.ActivePage := (frm.Parent as TTabSheet);
    PageControl1.ActivePage.Caption := ACaption;
  end;
end;

procedure TForm1.UpdateLibraryGame(const AGame: string);
begin
  Frame_UnitFunctions1.UpdateGameControls(AGame);
  Frame_Constants1.UpdateGameControls(AGame);
  Frame_Variables1.UpdateGameControls(AGame);
  Frame_Classes1.UpdateGameControls(AGame);
  Frame_Types1.UpdateGameControls(AGame);
  Frame_Actordef1.UpdateGameControls(AGame);
  Frame_Mobjinfo1.UpdateGameControls(AGame);
  Frame_States1.UpdateGameControls(AGame);
  Frame_Sprites1.UpdateGameControls(AGame);
end;

//==============================================================================
//
// the message list
//
//==============================================================================
procedure TForm1.SyncMessages;
var
  i: integer;
begin
  MessagesListBox.Items.BeginUpdate;
  try
    MessagesListBox.Items.Clear;
    for i := 0 to FServices.Log.Count - 1 do
      MessagesListBox.Items.AddObject(FServices.Log[i].Text,
        Pointer(MESSAGE_COLORS[FServices.Log[i].Kind]));
    MessagesListBox.ItemIndex := MessagesListBox.Items.Count - 1;
  finally
    MessagesListBox.Items.EndUpdate;
  end;
end;

procedure TForm1.MessagesListBoxDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  log_color: TColor;
begin
  with Control as TListBox do
  begin
    log_color := TColor(Items.Objects[Index]);
    if log_color = MESSAGE_COLORS[mkError] then
      Canvas.Font.Style := [fsBold]
    else
      Canvas.Font.Style := [];

    Canvas.FillRect(Rect);
    Canvas.Font.Color := log_color;
    Canvas.TextOut(Rect.Left + 2, Rect.Top, Items[Index]);
  end;
end;

procedure TForm1.Copy1Click(Sender: TObject);
begin
  FPresenter.CopyMessage(MessagesListBox.ItemIndex);
end;

procedure TForm1.Clearmessages1Click(Sender: TObject);
begin
  FPresenter.ClearMessages;
end;

procedure TForm1.SaveMessages1Click(Sender: TObject);
begin
  FPresenter.SaveMessages;
end;

//==============================================================================
//
// the layout of the window
//
//==============================================================================
procedure TForm1.LibraryButton1Click(Sender: TObject);
var
  lWidth: integer;
begin
  if LibraryButton1.Down then
  begin
    if LibraryPanel.Width < 128 then
    begin
      if (Screen.WorkAreaWidth > 2000) and (ClientWidth > 1500) then
        lWidth := 768
      else if (Screen.WorkAreaWidth > 1500) and (ClientWidth > 1200) then
        lWidth := 512
      else if ClientWidth > 799 then
        lWidth := 296
      else
        lWidth := ClientWidth div 4;
      LibraryPanel.Width := lWidth;
    end;
  end
  else
    LibraryPanel.Width := 16;
end;

procedure TForm1.LibraryPanelResize(Sender: TObject);
begin
  LibraryButton1.Down := LibraryPanel.Width >= 128;
end;

procedure TForm1.PageControl1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   PageControl1.BeginDrag(False);
end;

procedure TForm1.PageControl1DragDrop(Sender, Source: TObject; X,
  Y: Integer);
const
  TCM_GETITEMRECT = $130A;
var
  i: Integer;
  r: TRect;
begin
  if Sender <> PageControl1 then
    Exit;
  for i := 0 to PageControl1.PageCount - 1 do
  begin
    PageControl1.Perform(TCM_GETITEMRECT, i, lParam(@r));
    if PtInRect(r, Point(X, Y)) then
    begin
      if i <> PageControl1.ActivePage.PageIndex then
        PageControl1.ActivePage.PageIndex := i;
      Exit;
    end;
  end;
end;

procedure TForm1.PageControl1DragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := Sender = PageControl1;
end;

end.

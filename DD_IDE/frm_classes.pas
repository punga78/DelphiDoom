unit frm_classes;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ImgList, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  SynEdit, SynHighlighterDDScript,
  DelphiDoom.Ide.Composition, DelphiDoom.Ide.Vcl.ExampleEdit, DelphiDoom.Ide.Vcl.TreePanel,
  DelphiDoom.Ide.ClassCatalog;

type
  /// <summary>
  ///   The classes a script can use, with their declarations. The tree comes from the class
  ///   catalog of the ide library; the panel only draws it (see TIdeTreePanel)
  /// </summary>
  TFrame_Classes = class(TFrame)
    ToolbarPanel: TPanel;
    EditorPanel: TPanel;
    Splitter1: TSplitter;
    DetailPanel: TPanel;
    Panel1: TPanel;
    SearchEdit: TEdit;
    ClearFilterSpeedButton: TSpeedButton;
    DeclPanel: TPanel;
    DeclEdit: TEdit;
    TreeView1: TTreeView;
    procedure SearchEditChange(Sender: TObject);
    procedure ClearFilterSpeedButtonClick(Sender: TObject);
    procedure DeclPanelResize(Sender: TObject);
    procedure TreeView1Editing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
  private
    { Private declarations }
    FServices: TIdeServices;
    FPanel: TIdeTreePanel;
    FCatalog: TIdeClassCatalog;
    SynEdit1: TIdeExampleSynEdit;
    SynPasSyn1: TSynDDScriptSyn;
    procedure OnExampleChange(Sender: TObject);
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// <summary>Gives the panel the services it needs; the panel is empty until the game is set</summary>
    procedure Configure(const AServices: TIdeServices);
    procedure UpdateGameControls(const game: string);
    procedure FocusAndSelectFirstItem;
  end;

implementation

{$R *.dfm}

uses
  DelphiDoom.Ide.Types, DelphiDoom.Ide.Outline;

constructor TFrame_Classes.Create(AOwner: TComponent);
begin
  inherited;

  SynEdit1 := TIdeExampleSynEdit.Create(Self);
  SynEdit1.Parent := DetailPanel;
  SynEdit1.Align := alClient;
  SynEdit1.Highlighter := nil;
  SynEdit1.OnChange := OnExampleChange;
  SynEdit1.Gutter.ShowLineNumbers := True;
  SynEdit1.Gutter.AutoSize := True;
  SynEdit1.MaxScrollWidth := 255;
  SynEdit1.WantTabs := True;

  SynPasSyn1 := TSynDDScriptSyn.Create(Self);

  SynEdit1.Highlighter := SynPasSyn1;
  SynEdit1.ReadOnly := True;
end;

destructor TFrame_Classes.Destroy;
begin
  FreeAndNil(FPanel);
  FreeAndNil(FCatalog);
  inherited;
end;

procedure TFrame_Classes.Configure(const AServices: TIdeServices);
begin
  FServices := AServices;
  SynEdit1.UseStore(FServices.CreateExampleStore('classes', '.ddscript'));
  FCatalog := TIdeClassCatalog.Create;
  FPanel := TIdeTreePanel.Create(TreeView1, nil, SearchEdit, ClearFilterSpeedButton,
    DeclEdit, DeclPanel, SynEdit1,
    function(const AGame: string): Boolean
    begin
      Result := FCatalog.Load(FServices.GameLibrary, AGame);
    end,
    function(const AFilter: string): TIdeOutline
    begin
      Result := FCatalog.BuildOutline(AFilter);
    end,
    nil);
end;

procedure TFrame_Classes.OnExampleChange(Sender: TObject);
begin
  if SynEdit1.Modified then
    SynEdit1.SaveExample;
end;

procedure TFrame_Classes.FocusAndSelectFirstItem;
begin
  if FPanel <> nil then
    FPanel.FocusFirst;
end;

procedure TFrame_Classes.UpdateGameControls(const game: string);
begin
  if FPanel <> nil then
    FPanel.UpdateGame(game);
end;

procedure TFrame_Classes.SearchEditChange(Sender: TObject);
begin
  if FPanel <> nil then
    FPanel.FilterChanged;
end;

procedure TFrame_Classes.ClearFilterSpeedButtonClick(Sender: TObject);
begin
  SearchEdit.Clear;
end;

procedure TFrame_Classes.DeclPanelResize(Sender: TObject);
begin
  DeclEdit.Width := DeclPanel.Width - 16;
end;

procedure TFrame_Classes.TreeView1Editing(Sender: TObject; Node: TTreeNode; var AllowEdit: Boolean);
begin
  AllowEdit := False;
end;

procedure TFrame_Classes.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  if FPanel <> nil then
    FPanel.SelectionChanged;
end;

end.

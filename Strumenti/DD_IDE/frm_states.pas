unit frm_states;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ImgList, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  DelphiDoom.Ide.Composition, DelphiDoom.Ide.Vcl.TreePanel, DelphiDoom.Ide.StateCatalog;

type
  /// <summary>
  ///   The states of a game with their fields. The tree and the list come from the catalog of the ide library;
  ///   the panel only draws them (see TIdeTreePanel)
  /// </summary>
  TFrame_States = class(TFrame)
    ToolbarPanel: TPanel;
    EditorPanel: TPanel;
    Splitter1: TSplitter;
    DetailPanel: TPanel;
    Panel1: TPanel;
    SearchEdit: TEdit;
    ClearFilterSpeedButton: TSpeedButton;
    HintPanel: TPanel;
    HintEdit: TEdit;
    TreeView1: TTreeView;
    ListView1: TListView;
    procedure SearchEditChange(Sender: TObject);
    procedure ClearFilterSpeedButtonClick(Sender: TObject);
    procedure HintPanelResize(Sender: TObject);
    procedure TreeView1Editing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
  private
    { Private declarations }
    FServices: TIdeServices;
    FPanel: TIdeTreePanel;
    FCatalog: TIdeStateCatalog;
  public
    { Public declarations }
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

destructor TFrame_States.Destroy;
begin
  FreeAndNil(FPanel);
  FreeAndNil(FCatalog);
  inherited;
end;

procedure TFrame_States.Configure(const AServices: TIdeServices);
begin
  FServices := AServices;
  FCatalog := TIdeStateCatalog.Create;
  FPanel := TIdeTreePanel.Create(TreeView1, ListView1, SearchEdit, ClearFilterSpeedButton,
    HintEdit, HintPanel, nil,
    function(const AGame: string): Boolean
    begin
      Result := FCatalog.Load(FServices.GameLibrary, AGame);
    end,
    function(const AFilter: string): TIdeOutline
    begin
      Result := FCatalog.BuildOutline(AFilter);
    end,
    function(const AText: string; const ALevel: Integer): TArray<TIdeRow>
    begin
      Result := FCatalog.RowsFor(AText);
    end);
end;

procedure TFrame_States.FocusAndSelectFirstItem;
begin
  if FPanel <> nil then
    FPanel.FocusFirst;
end;

procedure TFrame_States.UpdateGameControls(const game: string);
begin
  if FPanel <> nil then
    FPanel.UpdateGame(game);
end;

procedure TFrame_States.SearchEditChange(Sender: TObject);
begin
  if FPanel <> nil then
    FPanel.FilterChanged;
end;

procedure TFrame_States.ClearFilterSpeedButtonClick(Sender: TObject);
begin
  SearchEdit.Clear;
end;

procedure TFrame_States.HintPanelResize(Sender: TObject);
begin
  HintEdit.Width := HintPanel.Width - 16;
end;

procedure TFrame_States.TreeView1Editing(Sender: TObject; Node: TTreeNode; var AllowEdit: Boolean);
begin
  AllowEdit := False;
end;

procedure TFrame_States.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  if FPanel <> nil then
    FPanel.SelectionChanged;
end;

end.

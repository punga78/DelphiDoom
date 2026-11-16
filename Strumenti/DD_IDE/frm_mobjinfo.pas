unit frm_mobjinfo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ImgList, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  DelphiDoom.Ide.Composition, DelphiDoom.Ide.Vcl.TreePanel, DelphiDoom.Ide.MobjinfoCatalog;

type
  /// <summary>
  ///   The actors (mobjinfo) of a game with their fields. The tree and the list come from the catalog of the ide library;
  ///   the panel only draws them (see TIdeTreePanel)
  /// </summary>
  TFrame_Mobjinfo = class(TFrame)
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
    FCatalog: TIdeMobjinfoCatalog;
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

destructor TFrame_Mobjinfo.Destroy;
begin
  FreeAndNil(FPanel);
  FreeAndNil(FCatalog);
  inherited;
end;

procedure TFrame_Mobjinfo.Configure(const AServices: TIdeServices);
begin
  FServices := AServices;
  FCatalog := TIdeMobjinfoCatalog.Create;
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

procedure TFrame_Mobjinfo.FocusAndSelectFirstItem;
begin
  if FPanel <> nil then
    FPanel.FocusFirst;
end;

procedure TFrame_Mobjinfo.UpdateGameControls(const game: string);
begin
  if FPanel <> nil then
    FPanel.UpdateGame(game);
end;

procedure TFrame_Mobjinfo.SearchEditChange(Sender: TObject);
begin
  if FPanel <> nil then
    FPanel.FilterChanged;
end;

procedure TFrame_Mobjinfo.ClearFilterSpeedButtonClick(Sender: TObject);
begin
  SearchEdit.Clear;
end;

procedure TFrame_Mobjinfo.HintPanelResize(Sender: TObject);
begin
  HintEdit.Width := HintPanel.Width - 16;
end;

procedure TFrame_Mobjinfo.TreeView1Editing(Sender: TObject; Node: TTreeNode; var AllowEdit: Boolean);
begin
  AllowEdit := False;
end;

procedure TFrame_Mobjinfo.TreeView1Change(Sender: TObject; Node: TTreeNode);
begin
  if FPanel <> nil then
    FPanel.SelectionChanged;
end;

end.

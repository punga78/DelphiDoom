unit frm_variables;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ImgList,
  ComCtrls,
  StdCtrls,
  Buttons,
  ExtCtrls,
  SynEdit,
  SynHighlighterDDScript,
  DelphiDoom.Ide.Composition,
  DelphiDoom.Ide.Vcl.ExampleEdit,
  DelphiDoom.Ide.Vcl.ListPanel;

type
  /// <summary>
  ///   The global variables a script can use, with their types. The rows, the filter and the order come from the table of the ide library;
  ///   the panel only draws them (see TIdeListPanel)
  /// </summary>
  TFrame_Variables = class(TFrame)
    ToolbarPanel: TPanel;
    EditorPanel: TPanel;
    Splitter1: TSplitter;
    DetailPanel: TPanel;
    Panel1: TPanel;
    ListView1: TListView;
    SearchEdit: TEdit;
    ClearFilterSpeedButton: TSpeedButton;
    DeclPanel: TPanel;
    DeclEdit: TEdit;
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure ListView1Compare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure ListView1ColumnClick(Sender: TObject; Column: TListColumn);
    procedure SearchEditChange(Sender: TObject);
    procedure ClearFilterSpeedButtonClick(Sender: TObject);
    procedure ListView1Change(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure DeclPanelResize(Sender: TObject);
  private
    { Private declarations }
    FServices: TIdeServices;
    FPanel: TIdeListPanel;
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
  DelphiDoom.Ide.LibraryTable,
  DelphiDoom.Ide.NameValueTable;

constructor TFrame_Variables.Create(AOwner: TComponent);
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

destructor TFrame_Variables.Destroy;
begin
  FreeAndNil(FPanel);
  inherited;
end;

procedure TFrame_Variables.Configure(const AServices: TIdeServices);
var
  LTable: TIdeLibraryTable;
begin
  FServices := AServices;
  SynEdit1.UseStore(FServices.CreateExampleStore('vars', '.ddscript'));
  LTable := TIdeNameValueTable.Create(nvVariables);
  FPanel := TIdeListPanel.Create(ListView1, SearchEdit, ClearFilterSpeedButton, DeclEdit,
    DeclPanel, SynEdit1, LTable, 0);
end;

procedure TFrame_Variables.OnExampleChange(Sender: TObject);
begin
  if SynEdit1.Modified then
    SynEdit1.SaveExample;
end;

procedure TFrame_Variables.FocusAndSelectFirstItem;
begin
  if FPanel <> nil then
    FPanel.FocusFirst;
end;

procedure TFrame_Variables.UpdateGameControls(const game: string);
begin
  if FPanel <> nil then
    FPanel.UpdateGame(FServices.GameLibrary, game);
end;

procedure TFrame_Variables.ListView1Data(Sender: TObject; Item: TListItem);
begin
  //
end;

procedure TFrame_Variables.ListView1Compare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
begin
  // the table gives the rows already sorted
  Compare := 0;
end;

procedure TFrame_Variables.ListView1ColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FPanel <> nil then
    FPanel.ColumnClicked(Column);
end;

procedure TFrame_Variables.SearchEditChange(Sender: TObject);
begin
  if FPanel <> nil then
    FPanel.FilterChanged;
end;

procedure TFrame_Variables.ClearFilterSpeedButtonClick(Sender: TObject);
begin
  SearchEdit.Clear;
end;

procedure TFrame_Variables.ListView1Change(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if FPanel <> nil then
    FPanel.SelectionChanged;
end;

procedure TFrame_Variables.DeclPanelResize(Sender: TObject);
begin
  DeclEdit.Width := DeclPanel.Width - 16;
end;

end.

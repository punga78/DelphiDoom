{******************************************************************************}
{                                                                              }
{  DD_IDE: what the tree panels of the library draw                            }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Vcl.TreePanel;

interface

uses
  System.SysUtils,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.Buttons,
  Vcl.ExtCtrls,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Outline,
  DelphiDoom.Ide.Vcl.ExampleEdit;

type
  /// <summary>Loads the data of a game into a catalog; false if the library has none</summary>
  TIdeTreeLoader = reference to function(const AGame: string): Boolean;
  /// <summary>Builds the outline for a filter; the panel frees it</summary>
  TIdeTreeOutlineBuilder = reference to function(const AFilter: string): TIdeOutline;
  /// <summary>The rows of the list for the line selected in the tree (its text and its level)</summary>
  TIdeTreeRowsBuilder = reference to function(const AText: string; const ALevel: Integer): TArray<TIdeRow>;

  /// <summary>
  ///   The part the four tree panels (classes, sprites, states, mobjinfo) share: the tree view filled
  ///   from an outline, the filter box, the line that shows the text of the selected node, and, for
  ///   three of them, the list of the fields. The catalog of the ide library makes the outline and
  ///   the rows; this class only draws them
  /// </summary>
  TIdeTreePanel = class
  strict private
    FTree: TTreeView;
    FList: TListView;
    FSearch: TEdit;
    FClearButton: TSpeedButton;
    FText: TEdit;
    FTextPanel: TPanel;
    FExample: TIdeExampleSynEdit;
    FLoad: TIdeTreeLoader;
    FBuildOutline: TIdeTreeOutlineBuilder;
    FBuildRows: TIdeTreeRowsBuilder;
    FGame: string;
    FFilling: Boolean;
    procedure FillList;
  public
    /// <summary>The list and the example may be nil (the classes have no list, the others no example)</summary>
    constructor Create(const ATree: TTreeView; const AList: TListView; const ASearch: TEdit;
      const AClearButton: TSpeedButton; const AText: TEdit; const ATextPanel: TPanel;
      const AExample: TIdeExampleSynEdit; const ALoad: TIdeTreeLoader;
      const ABuildOutline: TIdeTreeOutlineBuilder; const ABuildRows: TIdeTreeRowsBuilder);
    procedure UpdateGame(const AGame: string);
    procedure FillTree;
    procedure FocusFirst;
    procedure FilterChanged;
    procedure SelectionChanged;
  end;

implementation

{ TIdeTreePanel }

constructor TIdeTreePanel.Create(const ATree: TTreeView; const AList: TListView;
  const ASearch: TEdit; const AClearButton: TSpeedButton; const AText: TEdit;
  const ATextPanel: TPanel; const AExample: TIdeExampleSynEdit; const ALoad: TIdeTreeLoader;
  const ABuildOutline: TIdeTreeOutlineBuilder; const ABuildRows: TIdeTreeRowsBuilder);
begin
  inherited Create;
  FTree := ATree;
  FList := AList;
  FSearch := ASearch;
  FClearButton := AClearButton;
  FText := AText;
  FTextPanel := ATextPanel;
  FExample := AExample;
  FLoad := ALoad;
  FBuildOutline := ABuildOutline;
  FBuildRows := ABuildRows;
  FGame := '';
end;

procedure TIdeTreePanel.UpdateGame(const AGame: string);
begin
  if FGame = LowerCase(AGame) then
    Exit;
  FGame := LowerCase(AGame);
  if FLoad(FGame) then
    FillTree;
end;

procedure TIdeTreePanel.FillTree;
var
  LOutline: TIdeOutline;

  procedure AddNode(const AParent: TTreeNode; const ANode: TIdeOutlineNode);
  var
    LNode: TTreeNode;
    LChild: TIdeOutlineNode;
  begin
    LNode := FTree.Items.AddChild(AParent, ANode.Text);
    for LChild in ANode.Children do
      AddNode(LNode, LChild);
  end;

var
  LRoot: TIdeOutlineNode;
begin
  LOutline := FBuildOutline(FSearch.Text);
  FFilling := True;
  FTree.Items.BeginUpdate;
  try
    FTree.Items.Clear;
    for LRoot in LOutline.Roots do
      AddNode(nil, LRoot);
  finally
    FTree.Items.EndUpdate;
    FFilling := False;
    LOutline.Free;
    FocusFirst;
  end;
end;

procedure TIdeTreePanel.FocusFirst;
var
  i: Integer;
begin
  if FTree.Items.Count > 0 then
  begin
    for i := 1 to FTree.Items.Count - 1 do
      FTree.Items[i].Focused := False;
    FTree.Selected := FTree.Items[0];
    FTree.Items[0].Focused := False;
  end;
end;

procedure TIdeTreePanel.FilterChanged;
begin
  FillTree;
  FClearButton.Visible := FSearch.Text <> '';
end;

procedure TIdeTreePanel.FillList;
var
  LRows: TArray<TIdeRow>;
  LRow: TIdeRow;
  LItem: TListItem;
  LValue: string;
  LSelected: TTreeNode;
begin
  if (FList = nil) or not Assigned(FBuildRows) then
    Exit;
  LRows := nil;
  LSelected := FTree.Selected;
  if LSelected <> nil then
    LRows := FBuildRows(LSelected.Text, LSelected.Level);
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for LRow in LRows do
    begin
      LItem := FList.Items.Add;
      LItem.Caption := LRow.Caption;
      for LValue in LRow.Values do
        LItem.SubItems.Add(LValue);
      LItem.Data := Pointer(LRow.Tag);
    end;
  finally
    FList.Items.EndUpdate;
  end;
end;

procedure TIdeTreePanel.SelectionChanged;
var
  LNode: TTreeNode;
begin
  if FFilling then
    Exit;
  LNode := FTree.Selected;
  if LNode = nil then
    Exit;
  FText.Text := LNode.Text;
  FText.Hint := FText.Text;
  FTextPanel.Hint := FText.Text;
  if FExample <> nil then
  begin
    // the example is the one of the class the node belongs to
    while LNode.Parent <> nil do
      LNode := LNode.Parent;
    FExample.SelectExample(LNode.Text);
  end;
  FillList;
end;

end.

{******************************************************************************}
{                                                                              }
{  DD_IDE: what the list panels of the library draw                            }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Vcl.ListPanel;

interface

uses
  System.SysUtils,
  Vcl.ComCtrls,
  Vcl.StdCtrls,
  Vcl.Buttons,
  Vcl.ExtCtrls,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.LibraryTable,
  DelphiDoom.Ide.Vcl.ExampleEdit;

type
  /// <summary>
  ///   The part the five list panels (functions, constants, variables, types, actor functions)
  ///   share: the list view with the rows of the table, the filter box, the header that sorts, and the
  ///   line with the declaration of the item that is selected. The panel gives its
  ///   controls and the table; the rows, the filter and the order come from the table
  /// </summary>
  TIdeListPanel = class
  strict private
    FListView: TListView;
    FSearch: TEdit;
    FClearButton: TSpeedButton;
    FDeclaration: TEdit;
    FDeclarationPanel: TPanel;
    FExample: TIdeExampleSynEdit;
    FTable: TIdeLibraryTable;
    FSortColumn: Integer;
    FGame: string;
  public
    /// <summary>The panel owns the table</summary>
    constructor Create(const AListView: TListView; const ASearch: TEdit;
      const AClearButton: TSpeedButton; const ADeclaration: TEdit; const ADeclarationPanel: TPanel;
      const AExample: TIdeExampleSynEdit; const ATable: TIdeLibraryTable;
      const ADefaultSortColumn: Integer);
    destructor Destroy; override;
    /// <summary>The panel shows the data of a game, if it is not the game it shows already</summary>
    procedure UpdateGame(const ALibrary: IIdeGameLibrary; const AGame: string);
    procedure Fill;
    procedure FocusFirst;
    procedure ColumnClicked(const AColumn: TListColumn);
    procedure FilterChanged;
    procedure ClearFilter;
    procedure SelectionChanged;
    procedure ResizeDeclaration;
  end;

implementation

{ TIdeListPanel }

constructor TIdeListPanel.Create(const AListView: TListView; const ASearch: TEdit;
  const AClearButton: TSpeedButton; const ADeclaration: TEdit; const ADeclarationPanel: TPanel;
  const AExample: TIdeExampleSynEdit; const ATable: TIdeLibraryTable;
  const ADefaultSortColumn: Integer);
begin
  inherited Create;
  FListView := AListView;
  FSearch := ASearch;
  FClearButton := AClearButton;
  FDeclaration := ADeclaration;
  FDeclarationPanel := ADeclarationPanel;
  FExample := AExample;
  FTable := ATable;
  FSortColumn := ADefaultSortColumn;
  FGame := '';
end;

destructor TIdeListPanel.Destroy;
begin
  FTable.Free;
  inherited Destroy;
end;

procedure TIdeListPanel.UpdateGame(const ALibrary: IIdeGameLibrary; const AGame: string);
begin
  if FGame = LowerCase(AGame) then
    Exit;
  FGame := LowerCase(AGame);
  if FTable.Load(ALibrary, FGame) then
    Fill;
end;

procedure TIdeListPanel.Fill;
var
  LRows: TArray<TIdeRow>;
  LRow: TIdeRow;
  LItem: TListItem;
  LValue: string;
begin
  LRows := FTable.Rows(FSearch.Text, FSortColumn);
  FListView.Items.BeginUpdate;
  try
    FListView.Items.Clear;
    for LRow in LRows do
    begin
      LItem := FListView.Items.Add;
      LItem.Caption := LRow.Caption;
      for LValue in LRow.Values do
        LItem.SubItems.Add(LValue);
      LItem.Data := Pointer(LRow.Tag);
    end;
  finally
    FListView.Items.EndUpdate;
    FocusFirst;
  end;
end;

procedure TIdeListPanel.FocusFirst;
begin
  if FListView.Items.Count > 0 then
  begin
    FListView.Selected := FListView.Items[0];
    FListView.ItemFocused := FListView.Selected;
  end;
end;

procedure TIdeListPanel.ColumnClicked(const AColumn: TListColumn);
begin
  FSortColumn := AColumn.Index;
  Fill;
end;

procedure TIdeListPanel.FilterChanged;
begin
  Fill;
  FClearButton.Visible := FSearch.Text <> '';
end;

procedure TIdeListPanel.ClearFilter;
begin
  FSearch.Clear;
end;

procedure TIdeListPanel.SelectionChanged;
var
  LTag: Integer;
begin
  if FListView.Selected <> nil then
  begin
    LTag := Integer(FListView.Selected.Data);
    FDeclaration.Text := FTable.Declaration(LTag);
    FDeclaration.Hint := FDeclaration.Text;
    FDeclarationPanel.Hint := FDeclaration.Text;
    FExample.SelectExample(FTable.NameOf(LTag));
  end;
end;

procedure TIdeListPanel.ResizeDeclaration;
begin
  FDeclaration.Width := FDeclarationPanel.Width - 16;
end;

end.
